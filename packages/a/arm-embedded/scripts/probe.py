#!/usr/bin/env python3
"""UMI canonical probe-rs Python wrapper (Phase 1 of probe-rs migration).

This module exposes the subprocess-based probe-rs operations that downstream
UMI tooling (MCP server, verify scripts, xmake flash plugin) needs. The
public surface follows the design in
`plans/proposals/probe-rs-migration/proposal.md` §4:

    class UmiProbe(chip, probe_uid=None, speed_khz=None, protocol="swd")
      warmup()                          -> None
      flash(elf, *, verify=True)        -> None
      reset(halt=False)                 -> None
      read_word(addr)                   -> int
      read_words(addr, count)           -> list[int]
      write_word(addr, value)           -> None
      read_symbol(elf, name)            -> (addr, value)
      read_symbols(elf, names)          -> dict[name, value]
      read_symbols_series(elf, names, intervals_ms) -> [samples]
      rtt_capture(duration_s, channels) -> str
      target_info()                     -> dict
      read_registers()                  -> dict   # Phase 2 stub (Decision Q1)

    list_probes()                       -> list[dict]
    resolve_probe(chip, mcu_hint=None)  -> UmiProbe
    nm_symbols(elf, names)              -> dict[name, addr]

`chip` may be either:
  * a probe-rs `--chip` value (e.g. "STM32G431KB", "RP235x"), OR
  * an MCU short name from `lib/umibuild/database/mcu/<name>.lua` (e.g.
    "stm32g431kb", "rp2350b") — looked up in `tools/firmware/probe_targets.json`.

This file is intentionally a *thin* wrapper. Heavyweight session reuse is
deferred to Phase 10 (`tools/firmware/umi-probed` Rust daemon).
"""
from __future__ import annotations

import json
import logging
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Sequence

REPO_ROOT = Path(__file__).resolve().parents[2]


def _resolve_probe_targets_json() -> Path:
    """Locate probe_targets.json without hard-coding a single layout.

    The wrapper can be consumed by:
      * The UMI repo (file lives at `<repo>/tools/firmware/probe_targets.json`).
      * The `synthernet-xmake-repo` arm-embedded package (file lives next to
        this script in `scripts/probe_targets.json`).
    """
    here = Path(__file__).resolve()
    candidates = [
        here.parent / "probe_targets.json",
        here.parents[2] / "tools" / "firmware" / "probe_targets.json",
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return candidates[0]  # used only for error reporting


PROBE_TARGETS_JSON = _resolve_probe_targets_json()

logger = logging.getLogger("umi.probe")


class ProbeError(RuntimeError):
    """Generic probe-rs invocation failure (subprocess non-zero exit)."""

    def __init__(self, message: str, *, command: Sequence[str] | None = None,
                 stderr: str | None = None) -> None:
        super().__init__(message)
        self.command = list(command) if command else None
        self.stderr = stderr


class ProbeNotFoundError(ProbeError):
    """Requested probe could not be enumerated."""


class ChipNotKnownError(ProbeError):
    """Requested chip name is not in the MCU database."""


def _probe_rs_binary() -> str:
    """Return the absolute path to the `probe-rs` CLI."""
    path = shutil.which("probe-rs")
    if not path:
        raise ProbeError("`probe-rs` CLI not found on PATH; activate the Nix shell")
    return path


# ---------------------------------------------------------------------------
# Chip / target mapping
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class _TargetEntry:
    short: str
    device_name: str
    probe_rs_chip: str
    extra: dict[str, Any] = field(default_factory=dict)


def _load_targets() -> dict[str, _TargetEntry]:
    if not PROBE_TARGETS_JSON.is_file():
        raise ChipNotKnownError(
            f"{PROBE_TARGETS_JSON} is missing; "
            f"regenerate via the consuming project's MCU database "
            f"(UMI: `python3 lib/umibuild/scripts/export_probe_targets.py`)."
        )
    data = json.loads(PROBE_TARGETS_JSON.read_text(encoding="utf-8"))
    out: dict[str, _TargetEntry] = {}
    for short, entry in data.get("targets", {}).items():
        out[short] = _TargetEntry(
            short=short,
            device_name=entry.get("device_name", short),
            probe_rs_chip=entry.get("probe_rs_chip") or "",
            extra={k: v for k, v in entry.items()
                   if k not in {"device_name", "probe_rs_chip"}},
        )
    return out


def resolve_chip(name: str) -> str:
    """Map an MCU short name (`stm32g431kb`) to a probe-rs chip name.

    If `name` already looks like a probe-rs chip (uppercase / "RP235x"), it
    is returned as-is. Otherwise we look it up in `probe_targets.json`.
    """
    if not name:
        raise ChipNotKnownError("empty chip name")
    # Heuristic: probe-rs chip names start with capital letters or include
    # uppercase letters; UMI short names are all-lowercase.
    if name != name.lower():
        return name
    targets = _load_targets()
    entry = targets.get(name)
    if not entry or not entry.probe_rs_chip:
        known = ", ".join(sorted(targets)) or "(none)"
        raise ChipNotKnownError(
            f"unknown MCU short name {name!r}; known: {known}"
        )
    return entry.probe_rs_chip


def detect_mcu_from_probe(probe_uid: str) -> str | None:
    """Return the MCU short name (e.g. "stm32f407vg") that owns this probe.

    Matches the probe UID's `VID:PID` prefix against `debug.probe_vid_pid`
    entries in the MCU database. Returns None if no match (caller must
    fall back to an explicit MCU argument).

    `probe_uid` is the UID as printed by `probe-rs list`, e.g.
    `0483:374b:0669FF3731324B4D43183949` or `2e8a:000c-0:E663...`.
    """
    if not probe_uid:
        return None
    # Normalize: split off any "-N" core selector after the PID block.
    head = probe_uid.split(":", 2)
    if len(head) < 2:
        return None
    pid_with_suffix = head[1].split("-", 1)[0]
    vid_pid = f"{head[0]}:{pid_with_suffix}".lower()
    targets = _load_targets()
    for short, entry in targets.items():
        match = (entry.extra.get("probe_vid_pid") or "").lower()
        if match and match == vid_pid:
            return short
    return None


# ---------------------------------------------------------------------------
# Probe enumeration
# ---------------------------------------------------------------------------

# probe-rs list output line example:
#   [1]: STLink V2-1 -- 0483:374b:0669FF3731324B4D43183949 (ST-LINK)
_LIST_RE = re.compile(
    r"^\[\d+\]:\s+(?P<name>.+?)\s+--\s+(?P<uid>[0-9a-fA-F:\-]+?)\s+\((?P<kind>[^)]+)\)\s*$"
)


def list_probes() -> list[dict[str, str | None]]:
    """Return one dict per attached probe.

    Each dict has: `name`, `uid` (VID:PID:SERIAL, with optional `-N:` core
    selector preserved as printed by probe-rs), `kind` (probe class), and
    `mcu` (the MCU short name auto-detected from `probe_targets.json`'s
    `debug.probe_vid_pid` map, or None when unknown).
    """
    proc = subprocess.run(
        [_probe_rs_binary(), "list"], capture_output=True, text=True
    )
    if proc.returncode != 0:
        raise ProbeError(
            f"`probe-rs list` failed: {proc.stderr.strip()}",
            command=[_probe_rs_binary(), "list"],
            stderr=proc.stderr,
        )
    out: list[dict[str, str | None]] = []
    for line in proc.stdout.splitlines():
        m = _LIST_RE.match(line)
        if m:
            uid = m.group("uid").strip()
            out.append({"name": m.group("name").strip(),
                        "uid": uid,
                        "kind": m.group("kind").strip(),
                        "mcu": detect_mcu_from_probe(uid)})
    return out


def autoresolve(mcu: str | None = None) -> tuple[str, str, str]:
    """Auto-pick (mcu_short, chip, probe_uid) from `mcu` hint + probes attached.

    - If `mcu` is given, use it; also pick the matching attached probe.
    - If `mcu` is empty / None and exactly one probe is attached with a
      known `probe_vid_pid`, use that probe's MCU.
    - If `mcu` is empty / None and multiple probes attach with known MCUs,
      raise — the caller must disambiguate.
    """
    probes = list_probes()
    if not probes:
        raise ProbeNotFoundError("no probes attached")

    if mcu:
        chip = resolve_chip(mcu)
        # Pick the matching probe if any; otherwise use the first attached.
        targets = _load_targets()
        entry = targets.get(mcu) if mcu == mcu.lower() else None
        wanted = (entry.extra.get("probe_vid_pid") if entry else None) or ""
        wanted = wanted.lower()
        if wanted:
            for p in probes:
                head = (p["uid"] or "").split(":", 2)
                if len(head) >= 2:
                    pid_clean = head[1].split("-", 1)[0]
                    if f"{head[0]}:{pid_clean}".lower() == wanted:
                        return mcu, chip, p["uid"]  # type: ignore[return-value]
        # Fall back: single attached probe.
        if len(probes) == 1:
            return mcu, chip, probes[0]["uid"]  # type: ignore[return-value]
        raise ProbeNotFoundError(
            f"could not bind mcu {mcu!r} to a probe; attached: "
            + ", ".join(f"{p['uid']}({p['mcu']})" for p in probes)
        )

    # No MCU hint: auto-detect via single attached probe.
    detected = [p for p in probes if p["mcu"]]
    if len(detected) == 1:
        return detected[0]["mcu"], resolve_chip(detected[0]["mcu"]), detected[0]["uid"]  # type: ignore[return-value]
    if len(detected) > 1:
        raise ProbeNotFoundError(
            "multiple probes attached with known MCU bindings; pass --mcu: "
            + ", ".join(f"{p['mcu']}@{p['uid']}" for p in detected)
        )
    raise ProbeNotFoundError(
        "no attached probe has a probe_vid_pid match; pass --mcu explicitly"
    )


def _resolve_probe_uid(chip: str, hint: str | None) -> str | None:
    """Pick a probe UID for the given chip. None means "let probe-rs choose"."""
    probes = list_probes()
    if not probes:
        return None
    if hint:
        for p in probes:
            if hint in p["uid"] or hint == p["name"]:
                return p["uid"]
        raise ProbeNotFoundError(
            f"no attached probe matches hint {hint!r}; saw: "
            + ", ".join(p["uid"] for p in probes)
        )
    if len(probes) == 1:
        return probes[0]["uid"]
    # Multiple probes attached: caller must disambiguate.
    return None


def resolve_probe(chip: str, *, mcu_hint: str | None = None,
                  speed_khz: int | None = None,
                  protocol: str = "swd") -> "UmiProbe":
    """Construct an `UmiProbe` after auto-resolving the probe UID if possible."""
    chip_name = resolve_chip(chip)
    uid = _resolve_probe_uid(chip_name, mcu_hint)
    return UmiProbe(chip=chip_name, probe_uid=uid, speed_khz=speed_khz,
                    protocol=protocol)


# ---------------------------------------------------------------------------
# ELF symbol resolution
# ---------------------------------------------------------------------------

def _nm_binary() -> str:
    for candidate in ("arm-none-eabi-nm", "nm"):
        path = shutil.which(candidate)
        if path:
            return path
    raise ProbeError("neither `arm-none-eabi-nm` nor `nm` is on PATH")


def nm_symbols_with_size(elf: Path | str,
                          names: Iterable[str]) -> dict[str, tuple[int, int]]:
    """Return (addr, size_bytes) per symbol.

    Uses `nm --print-size` (or `nm -S`). Symbols without a recorded size
    report `size == 0` and the caller must decide how many bytes to read.
    """
    elf_path = Path(elf)
    if not elf_path.is_file():
        raise FileNotFoundError(elf_path)
    requested = list(dict.fromkeys(names))
    proc = subprocess.run(
        [_nm_binary(), "--print-size", str(elf_path)],
        capture_output=True, text=True, check=True,
    )
    table: dict[str, tuple[int, int]] = {}
    for line in proc.stdout.splitlines():
        parts = line.split()
        # With --print-size: addr [size] kind name
        if len(parts) < 3:
            continue
        try:
            addr = int(parts[0], 16)
        except ValueError:
            continue
        if len(parts) >= 4:
            try:
                size = int(parts[1], 16)
            except ValueError:
                size = 0
            name = parts[3]
        else:
            size = 0
            name = parts[2]
        table[name] = (addr, size)
    out: dict[str, tuple[int, int]] = {}
    missing: list[str] = []
    for name in requested:
        if name in table:
            out[name] = table[name]
        else:
            missing.append(name)
    if missing:
        raise ProbeError(f"symbols not found in {elf_path.name}: {missing}")
    return out


def nm_symbols(elf: Path | str, names: Iterable[str]) -> dict[str, int]:
    """Return address for each requested symbol. Raises if any is missing.

    This is the address-only convenience wrapper around
    `nm_symbols_with_size()`; callers that need byte-size for bulk memory
    reads should use the sized variant.
    """
    elf_path = Path(elf)
    if not elf_path.is_file():
        raise FileNotFoundError(elf_path)
    requested = list(dict.fromkeys(names))  # preserve order, dedup
    proc = subprocess.run(
        [_nm_binary(), str(elf_path)], capture_output=True, text=True, check=True
    )
    table: dict[str, int] = {}
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue
        addr_str, _kind, sym = parts[0], parts[1], parts[2]
        try:
            table[sym] = int(addr_str, 16)
        except ValueError:
            continue
    out: dict[str, int] = {}
    missing: list[str] = []
    for name in requested:
        if name in table:
            out[name] = table[name]
        else:
            missing.append(name)
    if missing:
        raise ProbeError(f"symbols not found in {elf_path.name}: {missing}")
    return out


# ---------------------------------------------------------------------------
# UmiProbe
# ---------------------------------------------------------------------------

@dataclass
class UmiProbe:
    """Thin subprocess wrapper around the `probe-rs` CLI for one (chip, probe)."""

    chip: str
    probe_uid: str | None = None
    speed_khz: int | None = None
    protocol: str = "swd"
    timeout_s: float = 30.0

    # Run `probe-rs info` lazily once per UmiProbe lifetime. This is the
    # standard RP2350 attach warmup (proposal §4 / §7 Phase 1).
    _warmed_up: bool = field(default=False, init=False, repr=False)

    # Common argument prefix for every probe-rs subprocess call.
    def _base_args(self) -> list[str]:
        args: list[str] = ["--chip", self.chip, "--protocol", self.protocol]
        if self.probe_uid:
            args.extend(["--probe", self.probe_uid])
        if self.speed_khz:
            args.extend(["--speed", str(self.speed_khz)])
        return args

    def _run(self, subcommand: str, *args: str,
             check: bool = True) -> subprocess.CompletedProcess[str]:
        cmd = [_probe_rs_binary(), subcommand, *self._base_args(), *args]
        logger.debug("exec: %s", " ".join(cmd))
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=self.timeout_s
        )
        if check and proc.returncode != 0:
            raise ProbeError(
                f"`probe-rs {subcommand}` failed (exit {proc.returncode}): "
                f"{proc.stderr.strip()}",
                command=cmd, stderr=proc.stderr,
            )
        return proc

    # --- lifecycle ---------------------------------------------------------

    def warmup(self) -> None:
        """Run `probe-rs info` once. Required as RP2350 attach gate."""
        if self._warmed_up:
            return
        # `info` is a read-only attach; errors here are surfaced to caller.
        self._run("info")
        self._warmed_up = True

    def __enter__(self) -> "UmiProbe":
        self.warmup()
        return self

    def __exit__(self, *exc: Any) -> None:
        # No persistent session for subprocess wrapper; nothing to release.
        return None

    # --- target operations -------------------------------------------------

    def reset(self, *, halt: bool = False) -> None:
        args = ["--halt-afterwards"] if halt else []
        self._run("reset", *args)

    def flash(self, elf: Path | str, *, verify: bool = True) -> None:
        elf_path = Path(elf)
        if not elf_path.is_file():
            raise FileNotFoundError(elf_path)
        # `probe-rs run` is "flash + reset + RTT/halt-noop", `download` is
        # flash-only. We use `download` for the explicit Phase 1 flash API.
        args = [str(elf_path)]
        if verify:
            args.append("--verify")
        self._run("download", *args)

    def flash_bin(self, image: Path | str, *, base_address: int,
                  verify: bool = True) -> None:
        """Flash a raw binary image at `base_address`.

        Used by the STM32F4 verify path to drop a `synth_app.umia` payload
        at `0x08060000` after the umi_os ELF is flashed. probe-rs accepts
        `--binary-format bin --base-address ...` for raw byte uploads.
        """
        image_path = Path(image)
        if not image_path.is_file():
            raise FileNotFoundError(image_path)
        args = [
            "--binary-format", "bin",
            "--base-address", f"0x{base_address:x}",
        ]
        if verify:
            args.append("--verify")
        args.append(str(image_path))
        self._run("download", *args)

    # --- memory access -----------------------------------------------------

    def read_word(self, addr: int) -> int:
        return self.read_words(addr, 1)[0]

    def read_words(self, addr: int, count: int) -> list[int]:
        if count <= 0:
            return []
        self.warmup()
        proc = self._run("read", "b32", f"0x{addr:08x}", str(count))
        # Output: hex words separated by whitespace, possibly multi-line.
        words: list[int] = []
        for token in proc.stdout.split():
            try:
                words.append(int(token, 16))
            except ValueError:
                continue
        if len(words) != count:
            raise ProbeError(
                f"`probe-rs read` returned {len(words)} words, expected {count}",
                command=None, stderr=proc.stdout,
            )
        return words

    def write_word(self, addr: int, value: int) -> None:
        self.warmup()
        self._run("write", "b32", f"0x{addr:08x}", f"0x{value:08x}")

    def sample_addresses_at_intervals(
        self,
        addresses: dict[str, int],
        intervals_ms: list[int],
    ) -> list[dict[str, int]]:
        """Sample multiple addresses at the specified intervals.

        Used by the per-board verify scripts to replace the pyOCD pattern
        `go; sleep N; halt; read32 ...; go`. probe-rs `read` implicitly
        halts and resumes per invocation, so the sequence becomes:
            sleep N -> read each address -> sleep next N -> ...

        Returns one dict per interval: `{label: value, ...}`.
        """
        import time
        self.warmup()
        samples: list[dict[str, int]] = []
        for interval_ms in intervals_ms:
            if interval_ms > 0:
                time.sleep(interval_ms / 1000.0)
            snapshot: dict[str, int] = {}
            for label, addr in addresses.items():
                snapshot[label] = self.read_word(addr)
            samples.append(snapshot)
        return samples

    def read_bytes(self, addr: int, size: int) -> bytes:
        """Read `size` bytes at `addr`. Pads with a final partial word read."""
        if size <= 0:
            return b""
        word_count = (size + 3) // 4
        words = self.read_words(addr, word_count)
        buf = bytearray()
        for w in words:
            buf.extend(int(w).to_bytes(4, "little"))
        return bytes(buf[:size])

    # --- ELF symbol shortcuts ---------------------------------------------

    def read_symbol(self, elf: Path | str, name: str,
                    size: int = 4) -> tuple[int, int | list[int]]:
        """Read 1 word (size=4) or N bytes (size>=4) at `name`'s address."""
        addr = nm_symbols(elf, [name])[name]
        if size == 4:
            return addr, self.read_word(addr)
        count = (size + 3) // 4
        return addr, self.read_words(addr, count)

    def read_symbol_bytes(self, elf: Path | str, name: str,
                          size: int = 0) -> tuple[int, bytes]:
        """Read raw bytes at `name`'s address.

        If `size == 0`, the symbol's recorded size from `nm --print-size` is
        used. Raises if the symbol has no size and none is supplied.
        """
        sized = nm_symbols_with_size(elf, [name])[name]
        addr, sym_size = sized
        if size <= 0:
            size = sym_size
        if size <= 0:
            raise ProbeError(
                f"symbol {name!r} has no recorded size; pass `size=` explicitly"
            )
        return addr, self.read_bytes(addr, size)

    def read_symbols(self, elf: Path | str, names: Sequence[str]) -> dict[str, int]:
        """Bulk read of 32-bit symbols. Each symbol is treated as one word."""
        addrs = nm_symbols(elf, names)
        out: dict[str, int] = {}
        for name, addr in addrs.items():
            out[name] = self.read_word(addr)
        return out

    def read_symbols_blocks(self, elf: Path | str,
                            names: Sequence[str],
                            default_size: int = 64) -> dict[str, dict[str, Any]]:
        """Bulk read of variable-size blocks (one subprocess per symbol).

        Returns `{name: {"address": addr, "size": size, "words": [...], "hex": "..."}}`
        where `hex` is the raw little-endian byte stream (pyocd-compatible).
        Symbols without a recorded size fall back to `default_size` bytes.
        """
        sized = nm_symbols_with_size(elf, names)
        out: dict[str, dict[str, Any]] = {}
        for name in names:
            addr, sym_size = sized[name]
            size = sym_size if sym_size > 0 else default_size
            byte_count = max(size, 4)
            word_count = (byte_count + 3) // 4
            words = self.read_words(addr, word_count)
            raw = b"".join(int(w).to_bytes(4, "little") for w in words)[:size]
            out[name] = {
                "address": f"0x{addr:08X}",
                "size": size,
                "words": [f"0x{w:08X}" for w in words],
                "hex": raw.hex(),
            }
        return out

    def read_symbols_series(self, elf: Path | str, names: Sequence[str],
                            samples: int, interval_ms: int,
                            *, halt: bool = False,
                            default_size: int = 64) -> list[dict[str, Any]]:
        """Sample `names` `samples` times every `interval_ms`.

        Returns one dict per sample with `{index, t_ms, symbols: {...}}`.

        Note: subprocess-per-read overhead (~100 ms) dominates timing
        precision; Phase 10 (`tools/firmware/umi-probed` Rust daemon)
        eliminates this for high-rate sampling.
        """
        import time
        if samples < 1:
            raise ProbeError("samples must be >= 1")
        sized = nm_symbols_with_size(elf, names)
        t0 = time.monotonic()
        out: list[dict[str, Any]] = []
        for i in range(samples):
            symbols: dict[str, dict[str, Any]] = {}
            for name in names:
                addr, sym_size = sized[name]
                size = sym_size if sym_size > 0 else default_size
                byte_count = max(size, 4)
                word_count = (byte_count + 3) // 4
                if halt:
                    # probe-rs read implicitly halts; explicit halt+resume
                    # would require a long-lived session, deferred to Phase 10.
                    pass
                words = self.read_words(addr, word_count)
                raw = b"".join(int(w).to_bytes(4, "little") for w in words)[:size]
                symbols[name] = {
                    "address": f"0x{addr:08X}",
                    "size": size,
                    "words": [f"0x{w:08X}" for w in words],
                    "hex": raw.hex(),
                }
            out.append({
                "index": i,
                "t_ms": round((time.monotonic() - t0) * 1000.0, 3),
                "symbols": symbols,
            })
            if i + 1 < samples and interval_ms > 0:
                time.sleep(interval_ms / 1000.0)
        return out

    # --- diagnostic surfaces ----------------------------------------------

    def target_info(self) -> dict[str, Any]:
        """Return raw `probe-rs info` stdout in a `{ "info": ... }` envelope."""
        proc = self._run("info")
        return {"chip": self.chip, "info": proc.stdout, "stderr": proc.stderr}

    def read_registers(self) -> dict[str, Any]:
        """Phase 2 stub. See decision Q1 in proposal §8.1.

        probe-rs CLI does not expose a register-dump subcommand; the Rust
        library `Core::read_core_reg()` is the only path. Phase 10 introduces
        a Rust daemon to surface it. Until then, callers receive a structured
        empty response and a warning is logged.
        """
        logger.warning(
            "read_registers() is stubbed pending the Phase 10 umi-probed daemon"
        )
        return {
            "registers": {},
            "note": ("read_registers temporarily unavailable in probe-rs CLI path; "
                     "use Phase 10 daemon"),
        }

    def rtt_capture(self, duration_s: float, *, channels: Sequence[int] = (0,)) -> str:
        """Capture defmt/RTT output for `duration_s` seconds, return stdout."""
        if duration_s <= 0:
            return ""
        # `probe-rs attach` keeps running; we time out after duration_s and
        # capture whatever was streamed. probe-rs respects SIGTERM.
        cmd = [_probe_rs_binary(), "attach", *self._base_args()]
        # `--rtt-channels` is the conventional flag; older probe-rs uses
        # plain `attach` with all channels. We forward the channel hint as
        # an env var so legacy / future probe-rs versions both work.
        env_addendum = {"PROBE_RS_RTT_CHANNELS": ",".join(str(c) for c in channels)}
        try:
            proc = subprocess.run(
                cmd, capture_output=True, text=True, timeout=duration_s,
                env={**__import__("os").environ, **env_addendum},
            )
            return proc.stdout
        except subprocess.TimeoutExpired as exc:
            return exc.stdout.decode("utf-8", errors="replace") if exc.stdout else ""


# ---------------------------------------------------------------------------
# CLI entrypoint (debugging / Phase 0 evidence)
# ---------------------------------------------------------------------------

def _cli(argv: Sequence[str]) -> int:
    import argparse
    ap = argparse.ArgumentParser(description="UMI probe-rs wrapper smoke utility")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list", help="enumerate attached probes")
    p_targets = sub.add_parser("targets", help="dump resolved chip table")
    p_targets.add_argument("--mcu", default=None,
                           help="resolve a single MCU short name")
    args = ap.parse_args(argv)

    if args.cmd == "list":
        for p in list_probes():
            mcu = p.get("mcu") or "(unknown)"
            print(f"{p['name']:30s} {p['uid']:50s} {p['kind']:12s} -> {mcu}")
        return 0
    if args.cmd == "targets":
        targets = _load_targets()
        if args.mcu:
            entry = targets.get(args.mcu)
            if not entry:
                print(f"unknown MCU: {args.mcu}", file=sys.stderr)
                return 1
            print(json.dumps({"short": entry.short,
                              "device_name": entry.device_name,
                              "probe_rs_chip": entry.probe_rs_chip,
                              **entry.extra}, indent=2))
            return 0
        for short, entry in sorted(targets.items()):
            print(f"{short:14s} -> {entry.probe_rs_chip}")
        return 0
    return 2


if __name__ == "__main__":
    sys.exit(_cli(sys.argv[1:]))
