#!/usr/bin/env python3
"""Build TAYJAY MAIN.lua from src/ modules.

Usage:
  python3 tools/build.py           # write TAYJAY MAIN.lua
  python3 tools/build.py --check   # exit 1 if TAYJAY MAIN.lua is out of date
  python3 tools/build.py --out dist/TAYJAY.lua

Modules are concatenated byte-for-byte in the order listed in src/manifest.txt.
Every module runs inside the same xpcall scope, so locals declared in an earlier
module stay visible to later modules exactly as in the single-file script.
"""
import argparse
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
MANIFEST = SRC / "manifest.txt"
DEFAULT_OUT = ROOT / "TAYJAY MAIN.lua"


def read_manifest():
    paths = []
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        rel = line.split("|", 1)[0].strip()
        path = SRC / rel
        if not path.is_file():
            sys.exit(f"build: missing module listed in manifest: src/{rel}")
        paths.append(path)
    listed = {p.resolve() for p in paths}
    for extra in sorted(SRC.rglob("*.lua")):
        if extra.resolve() not in listed:
            sys.exit(f"build: module not listed in manifest: {extra.relative_to(ROOT)}")
    return paths


def build():
    return b"".join(p.read_bytes() for p in read_manifest())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="verify output is up to date")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    data = build()
    if args.check:
        if not out.is_file() or out.read_bytes() != data:
            print(f"build: {out.name} is out of date. Run: python3 tools/build.py")
            return 1
        print(f"build: {out.name} is up to date ({len(data)} bytes)")
        return 0
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(data)
    print(f"build: wrote {out} ({len(data)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
