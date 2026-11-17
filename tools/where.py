#!/usr/bin/env python3
"""Map line numbers in "TAYJAY MAIN.lua" back to src/ modules.

Usage:
  python3 tools/where.py 4329
  python3 tools/where.py 160 4329 5692
  python3 tools/where.py "TAYJAY MAIN.lua:4329: attempt to index nil"
  python3 tools/where.py --map            # list every module with its line range
  echo "<error/traceback text>" | python3 tools/where.py -

Any ":<number>" after "MAIN.lua" (or a bare number) in the input is mapped.
Line ranges are computed from src/manifest.txt, so the build output must be
up to date (python3 tools/build.py --check).
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build  # noqa: E402


def module_ranges():
    ranges, start = [], 1
    for path in build.read_manifest():
        count = path.read_bytes().count(b"\n")
        text = path.read_bytes()
        if text and not text.endswith(b"\n"):
            count += 1
        end = start + count - 1
        ranges.append((start, end, path.relative_to(build.ROOT).as_posix()))
        start = end + 1
    return ranges


def locate(line, ranges):
    for start, end, rel in ranges:
        if start <= line <= end:
            return rel, line - start + 1
    return None, None


def numbers_from(text):
    hits = re.findall(r"MAIN\.lua[\"']?\]?:(\d+)", text)
    if hits:
        return [int(h) for h in hits]
    return [int(n) for n in re.findall(r"\b(\d+)\b", text)]


def main(argv):
    ranges = module_ranges()
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0
    if argv[0] == "--map":
        for start, end, rel in ranges:
            print(f"{start:>5}-{end:<5} {rel}")
        return 0
    text = sys.stdin.read() if argv == ["-"] else " ".join(argv)
    lines = numbers_from(text)
    if not lines:
        print("where: no line numbers found")
        return 1
    rc = 0
    for line in lines:
        rel, local = locate(line, ranges)
        if rel is None:
            print(f"MAIN:{line} -> (outside build, last line is {ranges[-1][1]})")
            rc = 1
        else:
            print(f"MAIN:{line} -> {rel}:{local}")
    if not build.DEFAULT_OUT.is_file() or build.DEFAULT_OUT.read_bytes() != build.build():
        print("where: warning: TAYJAY MAIN.lua is out of date with src/, line numbers may be off")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
