"""Git-based lib/ C++ change detection for Claude Code hooks.

Detects uncommitted changes to lib/**/*.{cc,hh} using git directly.
No snapshot files, no session IDs, no $TMPDIR state — git is the
single source of truth.

Handles:
- Staged changes (git add)
- Unstaged modifications
- Untracked new files
- Worktrees (each has its own git state)
- Context continuation (git state is always current)

Used by stop hooks to determine if lib/ C++ files have untested changes.

The "tested" state is tracked by a single marker file per worktree,
containing the git tree hash of lib/ at the time tests last passed.
If the current tree hash matches, no changes need testing.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

_EXTENSIONS = (".cc", ".hh")


def _git(*args: str, cwd: str = "") -> str:
    """Run a git command and return stdout. Returns empty string on failure."""
    try:
        r = subprocess.run(
            ["git", *args],
            capture_output=True,
            text=True,
            timeout=10,
            cwd=cwd or None,
        )
        return r.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return ""


def _project_dir() -> str:
    """Resolve project root from env or git."""
    d = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if d:
        return d
    return _git("rev-parse", "--show-toplevel")


def _lib_tree_hash(project_dir: str) -> str:
    """Get the current working-tree hash for lib/ (includes uncommitted changes).

    Uses git write-tree with --prefix after updating the index,
    giving us a hash that represents the exact current state of lib/.
    """
    # Hash of the working tree state: staged + unstaged + untracked
    # We use ls-files to get a fingerprint instead of write-tree
    # because write-tree only covers the index, not working tree changes.
    #
    # Strategy: hash the output of `git diff` + `git diff --cached` + untracked list
    # for lib/ — this captures ALL uncommitted state.
    parts = []

    # Unstaged changes
    diff = _git("diff", "--", "lib/", cwd=project_dir)
    if diff:
        parts.append(diff)

    # Staged changes
    cached = _git("diff", "--cached", "--", "lib/", cwd=project_dir)
    if cached:
        parts.append(cached)

    # Untracked files in lib/
    untracked = _git(
        "ls-files", "--others", "--exclude-standard", "--", "lib/",
        cwd=project_dir,
    )
    if untracked:
        # Include file contents for untracked files
        for f in untracked.splitlines():
            if f.endswith(_EXTENSIONS):
                parts.append(f"untracked:{f}")

    if not parts:
        # No uncommitted changes — use HEAD tree hash for lib/
        return _git("rev-parse", "HEAD:lib", cwd=project_dir)

    # Hash the combined diff content for a unique fingerprint
    import hashlib
    content = "\n".join(parts)
    return hashlib.sha256(content.encode()).hexdigest()


def _marker_path(project_dir: str) -> Path:
    """Marker file path — stored inside .git (worktree-local, not shared).

    Using .git/claude_lib_tested avoids $TMPDIR pollution and is
    automatically scoped to the worktree (git uses separate .git dirs
    for worktrees).
    """
    git_dir = _git("rev-parse", "--git-dir", cwd=project_dir)
    if not git_dir:
        # Fallback (should not happen in a git repo)
        return Path(project_dir) / ".git" / "claude_lib_tested"
    if not os.path.isabs(git_dir):
        git_dir = os.path.join(project_dir, git_dir)
    return Path(git_dir) / "claude_lib_tested"


def mark_tested() -> None:
    """Record that tests passed for the current lib/ state.

    Writes the current lib/ tree hash to .git/claude_lib_tested.
    """
    project_dir = _project_dir()
    if not project_dir:
        return
    tree_hash = _lib_tree_hash(project_dir)
    if not tree_hash:
        return
    try:
        _marker_path(project_dir).write_text(tree_hash)
    except OSError:
        pass


def changed_files() -> list[str]:
    """Return lib/ C++ files that have uncommitted changes since last test pass.

    Returns empty list if:
    - Not in a git repo
    - No uncommitted changes to lib/ C++ files
    - Current lib/ state matches the last tested state
    """
    project_dir = _project_dir()
    if not project_dir:
        return []

    # Check if current state matches tested state
    marker = _marker_path(project_dir)
    try:
        tested_hash = marker.read_text().strip()
    except OSError:
        tested_hash = ""

    current_hash = _lib_tree_hash(project_dir)
    if current_hash and current_hash == tested_hash:
        return []  # Tests already passed for this exact state

    # Collect changed lib/ C++ files
    changed: list[str] = []

    # Unstaged modifications
    diff_files = _git("diff", "--name-only", "--", "lib/", cwd=project_dir)
    if diff_files:
        for f in diff_files.splitlines():
            if f.endswith(_EXTENSIONS):
                changed.append(f)

    # Staged modifications
    cached_files = _git(
        "diff", "--cached", "--name-only", "--", "lib/", cwd=project_dir,
    )
    if cached_files:
        for f in cached_files.splitlines():
            if f.endswith(_EXTENSIONS) and f not in changed:
                changed.append(f)

    # Untracked new files
    untracked = _git(
        "ls-files", "--others", "--exclude-standard", "--", "lib/",
        cwd=project_dir,
    )
    if untracked:
        for f in untracked.splitlines():
            if f.endswith(_EXTENSIONS) and f not in changed:
                changed.append(f)

    return changed
