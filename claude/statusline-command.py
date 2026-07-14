#!/usr/bin/env python3
"""Stdlib-only Claude Code statusline renderer."""
import json
import os
import re
import subprocess
import sys

try:
    data = json.load(sys.stdin)
except ValueError:
    data = {}


def get(path, default=None):
    cur = data
    for key in path.split("."):
        if not isinstance(cur, dict) or cur.get(key) is None:
            return default
        cur = cur[key]
    return cur


model = get("model.display_name", "unknown")
effort = get("effort.level")
cwd = get("workspace.current_dir") or get("cwd")

used = get("context_window.total_input_tokens")
total = get("context_window.context_window_size")
pct = get("context_window.used_percentage")
cost = get("cost.total_cost_usd")

# colors
DIM = "\x1b[2m"
BOLD = "\x1b[1m"
RED = "\x1b[31m"
GRN = "\x1b[32m"
YEL = "\x1b[33m"
BLU = "\x1b[34m"
MAG = "\x1b[35m"
CYN = "\x1b[36m"
ORG = "\x1b[38;5;208m"
CHR = "\x1b[38;5;154m"
RESET = "\x1b[0m"


def git(*args):
    try:
        result = subprocess.run(
            ["git", "-C", cwd, *args], capture_output=True, text=True
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


# short model: drop leading "Claude " and parenthesized suffix
short_model = re.sub(r" *\(.*\)$", "", re.sub(r"^Claude ", "", model))

# effort: green / chartreuse / yellow / orange / red by level
effort_str = ""
if effort:
    effort_color = {"low": GRN, "medium": CHR, "high": YEL, "xhigh": ORG}.get(
        effort, RED
    )
    effort_str = f"{DIM}[{RESET}{effort_color}{effort}{RESET}{DIM}]{RESET}"

# location: repo[/subpath]:branch
loc = ""
if cwd:
    branch = git("symbolic-ref", "--short", "HEAD") or git(
        "rev-parse", "--short", "HEAD"
    )
    toplevel = git("rev-parse", "--show-toplevel")

    if toplevel:
        base = os.path.basename(toplevel)
        subpath = cwd[len(toplevel):].lstrip("/")
        if len(subpath) > 25:
            subpath = "…/" + os.path.basename(subpath)
        if subpath:
            repo_part = f"{CYN}{base}{RESET}{DIM}/{subpath}{RESET}"
        else:
            repo_part = f"{CYN}{base}{RESET}"
    else:
        repo_part = f"{CYN}{os.path.basename(cwd)}{RESET}"

    if branch:
        loc = f"{repo_part}{DIM}:{RESET}{MAG}{branch}{RESET}"
    else:
        loc = repo_part

# context: green / yellow / red by usage
ctx = ""
if used is not None and total is not None:
    pct_int = int(float(pct or 0))
    if pct_int >= 85:
        color = RED
    elif pct_int >= 70:
        color = ORG
    elif float(used) >= 150000:
        color = YEL
    else:
        color = GRN
    used_k = f"{float(used) / 1000:.1f}k"
    if pct is not None:
        ctx = f"{color}{used_k}{RESET} {DIM}({RESET}{color}{float(pct):.0f}%{RESET}{DIM}){RESET}"
    else:
        ctx = f"{color}{used_k}{RESET}"

# cost
cost_str = f"{BLU}${float(cost):.2f}{RESET}" if cost is not None else ""

sep = f"{DIM} · {RESET}"
out = f"{BOLD}{short_model}{RESET}{effort_str}"
for part in (ctx, cost_str, loc):
    if part:
        out += sep + part
sys.stdout.write(out)
