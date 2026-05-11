#!/usr/bin/env python3
# claude-hook: event=PreToolUse matcher=Bash
"""PreToolUse(Bash) guard: enforce CLAUDE.md safety rules + probe-rs probe exclusion.

Combines:
  - rm guard (use `trash` instead)
  - git checkout guard (must stash first)
  - probe-rs / pyOCD process pre-cleanup before probe commands
    (pyOCD entry retained for legacy installs; probe-rs is the canonical
    driver since Phase 4a of the probe-rs migration)

Exit codes:
  0 = allow
  2 = block (stderr sent to Claude as feedback)

Packaged by: arm-embedded
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


# ── Safety Guards ──


def _check_rm(command: str) -> str | None:
    """Block rm commands on project files. Allow rm on /tmp/ and build/."""
    if not re.search(r"\brm\s", command):
        return None
    safe_patterns = [
        r"\brm\s[^;|&]*(/tmp/|/var/|build/|\$TMPDIR)",
        r"\brm\s+-f\s+\$TMPDIR",
    ]
    for pattern in safe_patterns:
        if re.search(pattern, command):
            return None
    return (
        "rm はプロジェクトファイルに対して使用禁止です。"
        "代わりに `trash` コマンドを使用してください (CLAUDE.md: 'use trash not rm')。"
        "build/ や /tmp/ への rm は許可されています。"
    )


def _check_git_checkout(command: str) -> str | None:
    """Warn about git checkout/switch without stash."""
    is_checkout = re.search(r"\bgit\s+checkout\b", command)
    is_switch = re.search(r"\bgit\s+switch\b", command)
    if not is_checkout and not is_switch:
        return None
    if is_checkout:
        if re.search(r"\bgit\s+checkout\s+--\s", command):
            return None
        if re.search(r"\bgit\s+checkout\s+-b\b", command):
            return None
    if is_switch:
        if re.search(r"\bgit\s+switch\s+(-c|--create)\b", command):
            return None
    return (
        "git checkout/switch でブランチ切替する前に `git stash` を実行してください "
        "(CLAUDE.md: 'MUST git stash before checkout')。"
        "新規ブランチ作成 (-b / -c) やファイル単位の checkout (-- file) は許可されています。"
    )


# ── Probe-rs / pyOCD Probe Cleanup ──

PROBE_COMMANDS = re.compile(
    r"\b(probe-rs|pyocd)\s+(download|flash|attach|reset|read|write|gdb|commander|rtt|gdbserver|erase|info|run|list)"
)


def _cleanup_probes_if_needed(command: str) -> None:
    """Auto-cleanup orphaned probe-rs / pyocd / openocd / gdb processes before
    probe commands. probe-rs CLI has no equivalent `cleanup` subcommand, so
    we do the kill loop inline here.
    """
    if not PROBE_COMMANDS.search(command):
        return

    killed = 0
    for proc_name in ("probe-rs", "openocd", "arm-none-eabi-gdb", "pyocd"):
        try:
            r = subprocess.run(
                ["pgrep", "-fl", proc_name],
                capture_output=True, text=True, timeout=5,
            )
        except Exception:
            continue
        for line in r.stdout.splitlines():
            try:
                pid_str = line.split()[0]
            except IndexError:
                continue
            if "_server.py" in line or "mcp" in line.lower() or "pyocd_tool" in line:
                continue
            try:
                pid = int(pid_str)
            except ValueError:
                continue
            try:
                import os
                os.kill(pid, 15)
                killed += 1
            except Exception:
                pass
    if killed:
        print(
            f"probe-rs: {killed} orphaned process(es) cleaned up",
            file=sys.stderr,
        )


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError, ValueError):
        return

    command = data.get("tool_input", {}).get("command", "")
    if not command:
        return

    # Safety guards (block on failure)
    checks = [_check_rm, _check_git_checkout]
    for check in checks:
        reason = check(command)
        if reason is not None:
            print(reason, file=sys.stderr)
            sys.exit(2)

    # probe-rs / pyOCD orphan cleanup (non-blocking)
    _cleanup_probes_if_needed(command)


if __name__ == "__main__":
    main()
