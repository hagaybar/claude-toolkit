#!/usr/bin/env python3
"""Deterministic storage operations for the session-handoff skill.

Handoffs live in ~/.claude/handoffs/, which is its own git repo,
auto-committed on every save. Project slug is derived from the git
remote URL of the current working directory (fallback: directory name),
so the same project resolves identically from any clone or worktree.

Commands:
  resolve         Print slug and paths for the current project.
  save <file>     Install <file> as the new handoff (timestamped archive
                  + latest.md), then git-commit the handoffs repo.
  latest          Print path of latest.md for the current project, or NONE.
  list            List archived handoffs for the current project, newest first.
"""

import datetime
import re
import shutil
import subprocess
import sys
from pathlib import Path

HANDOFFS_ROOT = Path.home() / ".claude" / "handoffs"


def run(cmd, cwd=None, check=True):
    return subprocess.run(
        cmd, cwd=cwd, check=check, capture_output=True, text=True
    )


def project_slug():
    """Slug from git remote URL; fallback to cwd directory name."""
    try:
        url = run(["git", "remote", "get-url", "origin"]).stdout.strip()
        # e.g. git@github.com:hagaybar/rare-books-bot.git -> hagaybar__rare-books-bot
        m = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?$", url)
        if m:
            return f"{m.group(1)}__{m.group(2)}"
    except subprocess.CalledProcessError:
        pass
    try:
        top = run(["git", "rev-parse", "--show-toplevel"]).stdout.strip()
        return Path(top).name
    except subprocess.CalledProcessError:
        return Path.cwd().name


def ensure_repo():
    HANDOFFS_ROOT.mkdir(parents=True, exist_ok=True)
    if not (HANDOFFS_ROOT / ".git").exists():
        run(["git", "init"], cwd=HANDOFFS_ROOT)
        # A repo needs an identity to commit; set a local one if none exists.
        for key, val in [("user.name", "session-handoff"),
                         ("user.email", "handoff@local")]:
            if run(["git", "config", key], cwd=HANDOFFS_ROOT,
                   check=False).returncode != 0:
                run(["git", "config", key, val], cwd=HANDOFFS_ROOT)


def project_dir():
    d = HANDOFFS_ROOT / project_slug()
    d.mkdir(parents=True, exist_ok=True)
    return d


def cmd_resolve():
    d = project_dir()
    print(f"slug: {project_slug()}")
    print(f"dir: {d}")
    print(f"latest: {d / 'latest.md'}")


def cmd_save(src):
    src = Path(src)
    if not src.is_file():
        sys.exit(f"error: no such file: {src}")
    ensure_repo()
    d = project_dir()
    stamp = datetime.datetime.now().strftime("%Y-%m-%d-%H%M")
    archive = d / f"{stamp}.md"
    if archive.exists():  # two saves in the same minute
        archive = d / f"{stamp}-{datetime.datetime.now().strftime('%S')}.md"
    shutil.copy2(src, archive)
    shutil.copy2(src, d / "latest.md")
    run(["git", "add", "-A"], cwd=HANDOFFS_ROOT)
    msg = f"handoff: {project_slug()} {stamp}"
    run(["git", "commit", "-m", msg], cwd=HANDOFFS_ROOT)
    print(f"saved: {archive}")
    print(f"latest: {d / 'latest.md'}")
    print(f"committed: {msg}")


def cmd_latest():
    p = project_dir() / "latest.md"
    print(p if p.is_file() else "NONE")


def cmd_list():
    d = project_dir()
    archives = sorted(
        (f for f in d.glob("*.md") if f.name != "latest.md"),
        key=lambda f: f.stat().st_mtime,
        reverse=True,
    )
    if not archives:
        print("NONE")
        return
    for f in archives:
        print(f)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd = sys.argv[1]
    if cmd == "resolve":
        cmd_resolve()
    elif cmd == "save":
        if len(sys.argv) != 3:
            sys.exit("usage: handoff.py save <file>")
        cmd_save(sys.argv[2])
    elif cmd == "latest":
        cmd_latest()
    elif cmd == "list":
        cmd_list()
    else:
        sys.exit(f"unknown command: {cmd}\n{__doc__}")


if __name__ == "__main__":
    main()
