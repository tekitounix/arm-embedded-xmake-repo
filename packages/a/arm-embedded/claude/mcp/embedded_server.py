#!/usr/bin/env python3
"""Embedded MCP Server — ARM embedded development tool server for Claude Code.

Shipped by the synthernet-xmake-repo `arm-embedded` package. Mirrors
the UMI Phase 2 MCP server: every probe-side call flows through
`probe.py` (a probe-rs CLI subprocess wrapper). pyOCD is no longer
imported.

Registration:
  xmake setup-claude (or the consuming project's equivalent) installs
  this file into the project's MCP server configuration.

Dependencies:
  pip install "mcp[cli]"
  probe-rs (CLI on PATH; use Nix `pkgs.probe-rs-tools` or
  `cargo install probe-rs-tools`)
"""

from __future__ import annotations

import asyncio
import fcntl
import json
import os
import re
import struct
import subprocess
import sys
import time
import traceback
from pathlib import Path

from mcp.server.fastmcp import FastMCP


# Locate the bundled probe.py wrapper. When this MCP server is installed by
# the arm-embedded package it sits at `.../claude/mcp/embedded_server.py`
# with `probe.py` available at `.../scripts/probe.py` (sibling of
# `claude/`). When the consumer project has its own copy of probe.py
# (e.g. UMI's `tools/firmware/probe.py`), that copy is preferred via
# `UMI_PROJECT_DIR` so the chip database stays in lockstep with the
# project's MCU lua DB.
def _locate_probe_module() -> Path | None:
    here = Path(__file__).resolve()
    candidates = [
        here.parent.parent.parent / "scripts",  # package install layout
        here.parent.parent.parent / "tools" / "firmware",  # UMI repo layout
    ]
    project_root_env = os.environ.get("UMI_PROJECT_DIR")
    if project_root_env:
        candidates.insert(0, Path(project_root_env) / "tools" / "firmware")
    for candidate in candidates:
        if (candidate / "probe.py").is_file():
            return candidate
    return None


_probe_dir = _locate_probe_module()
if _probe_dir is not None:
    sys.path.insert(0, str(_probe_dir))

import probe  # noqa: E402

app = FastMCP("embedded")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def resolve_project_dir() -> str:
    """Resolve the consuming project root directory.

    Priority:
      1. `UMI_PROJECT_DIR` env (worktree agents set this explicitly).
      2. Current working directory at MCP startup (best-effort fallback).
    The packaged install path is irrelevant — this MCP server is meant to
    drive whatever project invokes it.
    """
    env = os.environ.get("UMI_PROJECT_DIR")
    if env:
        return env
    return os.getcwd()


def _run(args: list[str], timeout: int = 30, cwd: str | None = None) -> dict:
    if cwd is None and args and args[0] == "xmake":
        cwd = resolve_project_dir()
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout, cwd=cwd)
        return {
            "success": r.returncode == 0,
            "stdout": r.stdout.strip(),
            "stderr": r.stderr.strip(),
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "stdout": "", "stderr": f"Timed out ({timeout}s)"}
    except FileNotFoundError as e:
        return {"success": False, "stdout": "", "stderr": str(e)}


def _get_current_mode() -> str | None:
    r = _run(["xmake", "show"], timeout=10)
    output = r["stdout"] + "\n" + r["stderr"]
    for line in output.splitlines():
        clean = re.sub(r"\x1b\[[0-9;]*m", "", line)
        m = re.match(r"\s*mode\s*[:=]\s*(\w+)", clean)
        if m:
            return m.group(1)
    return None


def _err(exc: BaseException) -> str:
    return json.dumps({"error": str(exc), "traceback": traceback.format_exc()}, indent=2)


# ---------------------------------------------------------------------------
# Two-layer probe lock: asyncio.Lock (intra-process) + fcntl.flock (inter-process)
# ---------------------------------------------------------------------------

_probe_locks: dict[str, asyncio.Lock] = {}


def _get_probe_lock(probe_uid: str) -> asyncio.Lock:
    if probe_uid not in _probe_locks:
        _probe_locks[probe_uid] = asyncio.Lock()
    return _probe_locks[probe_uid]


def _acquire_file_lock(probe_uid: str, timeout: float = 30.0) -> int:
    safe_id = re.sub(r"[^A-Za-z0-9]+", "_", probe_uid)
    lock_path = Path(f"/tmp/umi-probe-{os.getuid()}-{safe_id}.lock")
    fd = os.open(str(lock_path), os.O_CREAT | os.O_WRONLY, 0o600)
    deadline = time.monotonic() + timeout
    while True:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return fd
        except BlockingIOError:
            if time.monotonic() >= deadline:
                os.close(fd)
                raise TimeoutError(
                    f"could not acquire probe lock {lock_path} within {timeout}s"
                )
            time.sleep(0.1)


def _release_file_lock(fd: int) -> None:
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
    finally:
        os.close(fd)


async def _with_probe(mcu: str, fn):
    """Resolve (mcu, chip, probe_uid), grab two-layer lock, invoke fn(p, mcu).

    `fn` receives a fresh `probe.UmiProbe` bound to the resolved probe and
    the resolved mcu short name; on exception we surface a JSON envelope so
    MCP callers never see an uncaught traceback.
    """
    try:
        mcu_resolved, chip, uid = probe.autoresolve(mcu or None)
    except Exception as exc:  # noqa: BLE001
        return _err(exc)

    async with _get_probe_lock(uid):
        fd = _acquire_file_lock(uid)
        try:
            p = probe.UmiProbe(chip=chip, probe_uid=uid)
            return fn(p, mcu_resolved)
        except Exception as exc:  # noqa: BLE001
            return _err(exc)
        finally:
            _release_file_lock(fd)


# ===========================================================================
# umitest — Test execution
# ===========================================================================

@app.tool()
def run_tests(filter: str = "") -> str:
    """Run xmake tests.

    Args:
        filter: Test filter (e.g. "test_umidbg/*"). Empty = all tests.
    """
    args = ["xmake", "test"]
    if filter:
        args.append(filter)
    result = _run(args, timeout=120)
    m = re.findall(r"(\d+)/(\d+)\s+tests?\s+passed", result["stdout"])
    if m:
        passed, total = int(m[-1][0]), int(m[-1][1])
        result["passed"] = passed
        result["total"] = total
        result["all_passed"] = passed == total
    return json.dumps(result, indent=2)


@app.tool()
def build_target(target: str, mode: str = "release") -> str:
    """Build an xmake target.

    Auto-fallbacks to debug if release fails. Restores original mode after.

    Args:
        target: Build target name.
        mode: Build mode ("debug" or "release").
    """
    original_mode = _get_current_mode()

    def _restore_mode() -> None:
        if original_mode:
            _run(["xmake", "f", "-m", original_mode, "-y"], timeout=30)

    cfg = _run(["xmake", "f", "-m", mode, "-y"], timeout=30)
    if not cfg["success"]:
        return json.dumps({"error": "Config failed", "detail": cfg}, indent=2)

    build = _run(["xmake", "build", target], timeout=120)
    if build["success"]:
        build["mode"] = mode
        _restore_mode()
        return json.dumps(build, indent=2)

    if mode == "release":
        cfg2 = _run(["xmake", "f", "-m", "debug", "-y"], timeout=30)
        if cfg2["success"]:
            build2 = _run(["xmake", "build", target], timeout=120)
            build2["mode"] = "debug"
            build2["fallback_from"] = "release"
            if not build2["success"]:
                build2["release_error"] = build.get("stdout", "")
            _restore_mode()
            return json.dumps(build2, indent=2)

    build["mode"] = mode
    _restore_mode()
    return json.dumps(build, indent=2)


# ===========================================================================
# xmake general tools
# ===========================================================================

@app.tool()
def list_targets(filter: str = "") -> str:
    """List xmake targets, optionally filtered by name."""
    r = _run(["xmake", "show", "-l", "targets", "--all"], timeout=10)
    if not r["success"]:
        return json.dumps({"error": "Failed to list targets", "detail": r}, indent=2)
    clean = re.sub(r"\x1b\[[0-9;]*m", "", r["stdout"])
    targets = sorted(set(t.strip() for t in re.split(r"[\s,]+", clean) if t.strip()))
    if filter:
        targets = [t for t in targets if filter.lower() in t.lower()]
    return json.dumps({"targets": targets, "count": len(targets)}, indent=2)


@app.tool()
def run_target(target: str, timeout_s: int = 60) -> str:
    """Build and run an xmake target (host-side only)."""
    build = _run(["xmake", "build", target], timeout=120)
    if not build["success"]:
        return json.dumps({"error": "Build failed", "detail": build}, indent=2)
    run = _run(["xmake", "run", target], timeout=timeout_s)
    return json.dumps({"build": build, "run": run}, indent=2)


@app.tool()
def run_benchmark(target: str) -> str:
    """Build and run a benchmark target (host-side only)."""
    return run_target(target, timeout_s=60)


def _parse_build_size(stdout: str) -> dict | None:
    flash_m = re.search(r"Flash:\s+(\d+)\s*/\s*(\d+)\s*bytes\s*\(([0-9.]+)%\)", stdout)
    ram_m = re.search(
        r"RAM:\s+(\d+)\s*/\s*(\d+)\s*bytes\s*\(([0-9.]+)%\)"
        r"(?:\s*\[data:\s*(\d+),\s*bss:\s*(\d+)\])?",
        stdout,
    )
    if not flash_m:
        return None
    result: dict = {
        "flash_used": int(flash_m.group(1)),
        "flash_total": int(flash_m.group(2)),
        "flash_percent": float(flash_m.group(3)),
    }
    if ram_m:
        result["ram_used"] = int(ram_m.group(1))
        result["ram_total"] = int(ram_m.group(2))
        result["ram_percent"] = float(ram_m.group(3))
        if ram_m.group(4):
            result["ram_data"] = int(ram_m.group(4))
            result["ram_bss"] = int(ram_m.group(5))
    return result


@app.tool()
def build_size(target: str, mode: str = "release") -> str:
    """Build a target and report flash/RAM usage."""
    original_mode = _get_current_mode()

    def _restore_mode() -> None:
        if original_mode:
            _run(["xmake", "f", "-m", original_mode, "-y"], timeout=30)

    cfg = _run(["xmake", "f", "-m", mode, "-y"], timeout=30)
    if not cfg["success"]:
        _restore_mode()
        return json.dumps({"error": "Config failed", "detail": cfg}, indent=2)
    build = _run(["xmake", "build", target], timeout=120)
    sizes = _parse_build_size(build["stdout"]) if build["success"] else None
    _restore_mode()
    return json.dumps({"build_success": build["success"], "size": sizes,
                       "stdout": build["stdout"]}, indent=2)


# ===========================================================================
# Probe-side tools (probe-rs CLI through tools/firmware/probe.py)
# ===========================================================================

@app.tool()
def probe_list() -> str:
    """List all attached debug probes.

    Returns UID + auto-detected MCU per probe (resolved via
    `probe_vid_pid` map in `lib/umibuild/database/mcu/<name>.lua`).
    """
    try:
        probes = probe.list_probes()
    except Exception as exc:  # noqa: BLE001
        return _err(exc)
    return json.dumps({"probes": probes, "count": len(probes)}, indent=2)


@app.tool()
def cleanup_processes() -> str:
    """Kill orphaned probe-rs / gdb / openocd / pyocd debug processes."""
    out: dict = {"killed": [], "errors": []}
    for pattern in ("probe-rs", "openocd", "arm-none-eabi-gdb", "pyocd"):
        r = subprocess.run(["pgrep", "-fl", pattern], capture_output=True, text=True)
        for line in r.stdout.splitlines():
            try:
                pid = int(line.strip().split()[0])
            except (IndexError, ValueError):
                continue
            try:
                os.kill(pid, 15)
                out["killed"].append({"pid": pid, "pattern": pattern,
                                       "cmd": line.strip()})
            except ProcessLookupError:
                pass
            except Exception as exc:  # noqa: BLE001
                out["errors"].append({"pid": pid, "error": str(exc)})
    return json.dumps(out, indent=2)


@app.tool()
async def flash(binary: str, mcu: str = "") -> str:
    """Flash firmware to the target.

    Args:
        binary: Path to .bin/.elf file.
        mcu: MCU target (e.g. "stm32f407vg"). Empty = auto-detect.
    """
    binary_path = Path(binary)
    if not binary_path.is_file():
        return json.dumps({"error": f"file not found: {binary}"}, indent=2)

    def do_flash(p: probe.UmiProbe, mcu_resolved: str) -> str:
        p.flash(binary_path, verify=True)
        p.reset(halt=False)
        return json.dumps({"success": True, "mcu": mcu_resolved,
                           "probe": p.probe_uid, "binary": str(binary_path)}, indent=2)

    return await _with_probe(mcu, do_flash)


@app.tool()
async def reset(mcu: str = "") -> str:
    """Reset the target MCU."""
    def do_reset(p: probe.UmiProbe, mcu_resolved: str) -> str:
        p.reset(halt=False)
        return json.dumps({"success": True, "mcu": mcu_resolved,
                           "probe": p.probe_uid}, indent=2)
    return await _with_probe(mcu, do_reset)


@app.tool()
async def target_status(mcu: str = "") -> str:
    """Probe the target (probe-rs info). Returns SWD/CPU/AP details."""
    def do_status(p: probe.UmiProbe, mcu_resolved: str) -> str:
        info = p.target_info()
        return json.dumps({"success": True, "mcu": mcu_resolved,
                           "probe": p.probe_uid, "info": info["info"],
                           "stderr": info["stderr"]}, indent=2)
    return await _with_probe(mcu, do_status)


@app.tool()
async def read_memory(address: str, size: int = 4, mcu: str = "") -> str:
    """Read target memory.

    Args:
        address: Hex address (e.g. "0x20000230").
        size: Number of bytes (default 4).
        mcu: MCU target. Empty = auto-detect.
    """
    try:
        addr = int(address, 16) if isinstance(address, str) else int(address)
    except ValueError as exc:
        return json.dumps({"error": f"invalid address: {address}: {exc}"}, indent=2)

    def do_read(p: probe.UmiProbe, mcu_resolved: str) -> str:
        data = p.read_bytes(addr, int(size))
        words = []
        for i in range(0, len(data), 4):
            chunk = data[i : i + 4].ljust(4, b"\x00")
            words.append(f"0x{int.from_bytes(chunk, 'little'):08X}")
        return json.dumps({
            "success": True, "mcu": mcu_resolved, "probe": p.probe_uid,
            "address": f"0x{addr:08X}", "size": int(size),
            "hex": data.hex(), "words": words,
        }, indent=2)

    return await _with_probe(mcu, do_read)


@app.tool()
async def read_memory_after_run(
    address: str, size: int = 4, run_ms: int = 5000, mcu: str = ""
) -> str:
    """Reset target, run for `run_ms` ms, then read memory."""
    try:
        addr = int(address, 16) if isinstance(address, str) else int(address)
    except ValueError as exc:
        return json.dumps({"error": f"invalid address: {address}: {exc}"}, indent=2)

    def do_run_read(p: probe.UmiProbe, mcu_resolved: str) -> str:
        p.reset(halt=False)
        time.sleep(max(0, int(run_ms)) / 1000.0)
        data = p.read_bytes(addr, int(size))
        words = []
        for i in range(0, len(data), 4):
            chunk = data[i : i + 4].ljust(4, b"\x00")
            words.append(f"0x{int.from_bytes(chunk, 'little'):08X}")
        return json.dumps({
            "success": True, "mcu": mcu_resolved, "probe": p.probe_uid,
            "address": f"0x{addr:08X}", "size": int(size),
            "run_ms": int(run_ms),
            "hex": data.hex(), "words": words,
        }, indent=2)

    return await _with_probe(mcu, do_run_read)


@app.tool()
async def read_symbol(elf: str, symbol: str, size: int = 0, mcu: str = "") -> str:
    """Read memory at an ELF symbol (auto-size from nm if `size == 0`)."""
    def do_read_symbol(p: probe.UmiProbe, mcu_resolved: str) -> str:
        addr, data = p.read_symbol_bytes(elf, symbol, size=int(size))
        words = []
        for i in range(0, len(data), 4):
            chunk = data[i : i + 4].ljust(4, b"\x00")
            words.append(f"0x{int.from_bytes(chunk, 'little'):08X}")
        return json.dumps({
            "success": True, "mcu": mcu_resolved, "probe": p.probe_uid,
            "elf": elf, "symbol": symbol,
            "address": f"0x{addr:08X}", "size": len(data),
            "hex": data.hex(), "words": words,
        }, indent=2)

    return await _with_probe(mcu, do_read_symbol)


@app.tool()
async def read_symbols(elf: str, symbols: str, mcu: str = "") -> str:
    """Read multiple ELF symbols (one read per symbol)."""
    symbol_list = [s.strip() for s in symbols.split(",") if s.strip()]
    if not symbol_list:
        return json.dumps({"error": "symbols is empty"}, indent=2)

    def do_read_symbols(p: probe.UmiProbe, mcu_resolved: str) -> str:
        blocks = p.read_symbols_blocks(elf, symbol_list)
        return json.dumps({
            "success": True, "mcu": mcu_resolved, "probe": p.probe_uid,
            "elf": elf, "symbols": blocks,
        }, indent=2)

    return await _with_probe(mcu, do_read_symbols)


@app.tool()
async def read_symbols_series(
    elf: str,
    symbols: str,
    repeat: int = 5,
    interval_ms: int = 100,
    mcu: str = "",
    halt: bool = False,
) -> str:
    """Sample ELF symbols `repeat` times every `interval_ms`."""
    symbol_list = [s.strip() for s in symbols.split(",") if s.strip()]
    if not symbol_list:
        return json.dumps({"error": "symbols is empty"}, indent=2)
    if int(repeat) < 1:
        return json.dumps({"error": "repeat must be >= 1"}, indent=2)
    if int(interval_ms) < 0:
        return json.dumps({"error": "interval_ms must be >= 0"}, indent=2)

    def do_series(p: probe.UmiProbe, mcu_resolved: str) -> str:
        samples = p.read_symbols_series(
            elf=elf, names=symbol_list,
            samples=int(repeat), interval_ms=int(interval_ms),
            halt=bool(halt),
        )
        return json.dumps({
            "uid": p.probe_uid, "mcu": mcu_resolved, "elf": elf,
            "symbols": symbol_list, "repeat": int(repeat),
            "interval_ms": int(interval_ms), "halt": bool(halt),
            "samples": samples,
        }, indent=2)

    return await _with_probe(mcu, do_series)


@app.tool()
async def usb_audio_counters(
    elf: str,
    symbols: str,
    repeat: int = 5,
    interval_ms: int = 100,
    mcu: str = "",
    halt: bool = False,
) -> str:
    """Alias for read_symbols_series with default USB-audio counter cadence."""
    return await read_symbols_series(
        elf=elf, symbols=symbols, repeat=repeat,
        interval_ms=interval_ms, mcu=mcu, halt=halt,
    )


@app.tool()
def resolve_symbol(elf: str, name: str) -> str:
    """Resolve an ELF symbol to its (address, size) via arm-none-eabi-nm."""
    try:
        addr, size = probe.nm_symbols_with_size(elf, [name])[name]
        return json.dumps({"symbol": name, "address": f"0x{addr:08X}",
                           "size": size}, indent=2)
    except Exception as exc:  # noqa: BLE001
        return _err(exc)


@app.tool()
async def read_registers(mcu: str = "") -> str:
    """Read core registers.

    Currently returns a Phase 10 stub: probe-rs CLI has no register-dump
    subcommand; `tools/firmware/umi-probed` (Rust daemon embedding the
    probe-rs library) will deliver the real implementation. See proposal
    §8.1 decision Q1.
    """
    def do_regs(p: probe.UmiProbe, mcu_resolved: str) -> str:
        return json.dumps({"mcu": mcu_resolved, "probe": p.probe_uid,
                           **p.read_registers()}, indent=2)
    return await _with_probe(mcu, do_regs)


@app.tool()
async def read_dma_audio(address: str, size: int = 512, mcu: str = "") -> str:
    """Read a DMA I2S buffer and decode as 24-bit stereo audio."""
    try:
        addr = int(address, 16) if isinstance(address, str) else int(address)
    except ValueError as exc:
        return json.dumps({"error": f"invalid address: {address}: {exc}"}, indent=2)

    def do_dma(p: probe.UmiProbe, mcu_resolved: str) -> str:
        data = p.read_bytes(addr, int(size))
        words: list[int] = []
        for i in range(0, len(data), 4):
            words.append(struct.unpack_from("<I", data, i)[0])

        frames: list[dict[str, int]] = []
        for i in range(0, len(words), 2):
            if i + 1 >= len(words):
                break
            w0 = words[i]
            w1 = words[i + 1]
            l_hi = w0 & 0xFFFF
            l_lo = (w0 >> 16) & 0xFFFF
            r_hi = w1 & 0xFFFF
            r_lo = (w1 >> 16) & 0xFFFF
            l_val = ((l_hi << 16) | l_lo) >> 8
            r_val = ((r_hi << 16) | r_lo) >> 8
            if l_val & 0x800000:
                l_val -= 0x1000000
            if r_val & 0x800000:
                r_val -= 0x1000000
            frames.append({"L": l_val, "R": r_val})

        l_vals = [f["L"] for f in frames]
        r_vals = [f["R"] for f in frames]
        max_24 = 8388607
        l_crosses = sum(1 for i in range(1, len(l_vals))
                         if (l_vals[i] >= 0) != (l_vals[i - 1] >= 0))
        r_crosses = sum(1 for i in range(1, len(r_vals))
                         if (r_vals[i] >= 0) != (r_vals[i - 1] >= 0))
        lr_match = sum(1 for l, r in zip(l_vals, r_vals) if l == r)
        all_zero = sum(1 for l, r in zip(l_vals, r_vals) if l == 0 and r == 0)

        return json.dumps({
            "success": True, "mcu": mcu_resolved, "probe": p.probe_uid,
            "address": f"0x{addr:08X}", "frames": len(frames),
            "analysis": {
                "L_range": [min(l_vals), max(l_vals)] if l_vals else [0, 0],
                "R_range": [min(r_vals), max(r_vals)] if r_vals else [0, 0],
                "L_range_pct": (
                    [round(min(l_vals) / max_24 * 100, 1),
                     round(max(l_vals) / max_24 * 100, 1)]
                    if l_vals else [0.0, 0.0]
                ),
                "R_range_pct": (
                    [round(min(r_vals) / max_24 * 100, 1),
                     round(max(r_vals) / max_24 * 100, 1)]
                    if r_vals else [0.0, 0.0]
                ),
                "L_zero_crossings": l_crosses,
                "R_zero_crossings": r_crosses,
                "LR_match": f"{lr_match}/{len(frames)}",
                "all_zero_frames": f"{all_zero}/{len(frames)}",
            },
            "sample_data": frames[:8],
        }, indent=2)

    return await _with_probe(mcu, do_dma)


@app.tool()
async def rtt_capture(duration: int = 5, mcu: str = "") -> str:
    """Capture RTT output for `duration` seconds."""
    def do_rtt(p: probe.UmiProbe, mcu_resolved: str) -> str:
        text = p.rtt_capture(duration_s=float(duration), channels=(0,))
        return json.dumps({"success": True, "mcu": mcu_resolved,
                           "probe": p.probe_uid, "duration_s": int(duration),
                           "stdout": text}, indent=2)
    return await _with_probe(mcu, do_rtt)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    app.run()
