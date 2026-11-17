#!/usr/bin/env python3
"""Compile the TAYJAY build with luau-compile and measure local-register headroom.

Luau allows at most 200 registers (locals + temporaries) per function. The main
script keeps most of its state as locals inside one big xpcall scope, so it can
hit that limit as features are added. This check:

  1. Builds src/ into a temporary file and compiles it at -O1 (fails on error).
  2. Measures headroom: how many extra live locals the main scope and the FPS
     scope can still take before -O1 compilation fails (binary search with
     probe locals injected at the start of each scope and kept alive to its end).
  3. Warns (GitHub annotation) when headroom drops below --warn-below.
  4. Reports -O0 status for information only.

Usage:
  python3 tools/check_locals.py --luau-compile /path/to/luau-compile
  python3 tools/check_locals.py --warn-below 30 --fail-below 5
  python3 tools/check_locals.py --extra "Tayjay Farm.lua"   # also compile-check other files
"""
import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build  # noqa: E402
import where  # noqa: E402

LIMIT = 200
# (scope name, module after which probes are declared, module before which probes are used)
SCOPES = [
    ("main scope", "boot/main_open.lua", "boot/fps_scope_open.lua"),
    ("FPS scope", "boot/fps_scope_open.lua", "boot/main_close.lua"),
]


def compile_lua(luau_compile, data, opt):
    with tempfile.NamedTemporaryFile("wb", suffix=".lua", delete=False) as f:
        f.write(data)
        path = f.name
    try:
        r = subprocess.run([luau_compile, "--null", f"-O{opt}", path],
                           capture_output=True, text=True)
        out = (r.stdout + r.stderr).strip()
        ok = r.returncode == 0 and "CompileError" not in out and "SyntaxError" not in out
        return ok, out.replace(path, "TAYJAY MAIN.lua")
    finally:
        os.unlink(path)


def build_with_probe(modules, after, before, n):
    decl = "".join(f"local __tjprobe{i} = tostring({i})\n" for i in range(n)).encode()
    use = "".join(f"_G.__tjprobe = __tjprobe{i}\n" for i in range(n)).encode()
    parts = []
    for path in modules:
        rel = path.relative_to(build.SRC).as_posix()
        if rel == before:
            parts.append(use)
        parts.append(path.read_bytes())
        if rel == after:
            parts.append(decl)
    return b"".join(parts)


def headroom(luau_compile, modules, after, before):
    lo, hi = 0, LIMIT + 1
    ok, _ = compile_lua(luau_compile, build_with_probe(modules, after, before, 0), 1)
    if not ok:
        return None
    while hi - lo > 1:
        mid = (lo + hi) // 2
        ok, _ = compile_lua(luau_compile, build_with_probe(modules, after, before, mid), 1)
        lo, hi = (mid, hi) if ok else (lo, mid)
    return lo


def annotate(level, msg):
    if os.environ.get("GITHUB_ACTIONS"):
        print(f"::{level}::{msg}")
    else:
        print(f"{level.upper()}: {msg}")


def first_error(out):
    lines = out.splitlines()
    for line in lines:
        if "Error" in line:
            return line.strip()
    return lines[0].strip() if lines else "unknown error"


def map_error(out):
    m = re.search(r"MAIN\.lua\((\d+),\d+\)", out)
    if not m:
        return ""
    rel, line = where.locate(int(m.group(1)), where.module_ranges())
    return f" -> {rel}:{line}" if rel else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau-compile", default=shutil.which("luau-compile") or "luau-compile")
    ap.add_argument("--warn-below", type=int, default=30,
                    help="warn when free registers in a scope drop below this (default 30)")
    ap.add_argument("--fail-below", type=int, default=0,
                    help="fail when free registers drop below this (default 0 = never)")
    ap.add_argument("--extra", nargs="*", default=[],
                    help="other .lua files to compile-check at -O1")
    args = ap.parse_args()

    modules = build.read_manifest()
    data = build.build()
    summary = ["## Luau compile check", ""]
    rc = 0

    ok, out = compile_lua(args.luau_compile, data, 1)
    if not ok:
        first = first_error(out)
        annotate("error", f"TAYJAY MAIN.lua fails to compile at -O1: {first}{map_error(out)}")
        summary.append(f"- ❌ `TAYJAY MAIN.lua` -O1: `{first}`{map_error(out)}")
        rc = 1
    else:
        print("TAYJAY MAIN.lua: -O1 compile OK")
        summary.append("- ✅ `TAYJAY MAIN.lua` compiles at -O1")
        summary += ["", f"| Scope | Free registers at -O1 (limit {LIMIT}) | Status |", "|---|---|---|"]
        for name, after, before in SCOPES:
            free = headroom(args.luau_compile, modules, after, before)
            if free is None:
                status = "probe failed"
                annotate("warning", f"{name}: could not measure headroom")
            elif free < args.fail_below:
                status = "❌ below fail threshold"
                annotate("error", f"{name}: only {free} free registers left (fail below {args.fail_below})")
                rc = 1
            elif free < args.warn_below:
                status = "⚠️ near limit"
                annotate("warning", f"{name}: only {free} of {LIMIT} registers free at -O1 "
                                    f"(warn below {args.warn_below}). Move locals into tables (e.g. TJ.*).")
            else:
                status = "✅ ok"
            print(f"{name}: {free} free registers at -O1 [{status}]")
            summary.append(f"| {name} | {free} | {status} |")

    ok0, out0 = compile_lua(args.luau_compile, data, 0)
    first0 = first_error(out0)
    if ok0:
        summary += ["", "- ℹ️ -O0: compiles"]
    else:
        print(f"info: -O0 does not compile: {first0}{map_error(out0)}")
        summary += ["", f"- ℹ️ -O0 (info only, not enforced): `{first0}`{map_error(out0)}"]

    for extra in args.extra:
        p = build.ROOT / extra
        okx, outx = compile_lua(args.luau_compile, p.read_bytes(), 1)
        first = first_error(outx)
        if okx:
            print(f"{extra}: -O1 compile OK")
            summary.append(f"- ✅ `{extra}` compiles at -O1")
        else:
            annotate("error", f"{extra} fails to compile at -O1: {first.replace('TAYJAY MAIN.lua', extra)}")
            summary.append(f"- ❌ `{extra}` -O1: `{first.replace('TAYJAY MAIN.lua', extra)}`")
            rc = 1

    step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if step_summary:
        with open(step_summary, "a", encoding="utf-8") as f:
            f.write("\n".join(summary) + "\n")
    return rc


if __name__ == "__main__":
    sys.exit(main())
