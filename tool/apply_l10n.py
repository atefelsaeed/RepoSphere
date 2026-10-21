#!/usr/bin/env python3
"""One-off helper used to move hard-coded UI strings of a Dart file into the
string tables. Usage (from Python):  apply(path, {literal: (key, en, ar, [ph])}).

 - replaces 'literal' with l.key (or l.key(args) when the mapping value has an
   explicit expression as 5th item),
 - registers new keys in tool/strings_legacy.py,
 - inserts `final l = context.l10n;` in build methods that use `l.`,
 - adds the l10n import.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEG = ROOT / "tool" / "strings_legacy.py"


def register(entries):
    src = LEG.read_text()
    existing = set(re.findall(r'^    "(\w+)":', src, re.M))
    add = ""
    for key, en, ar, ph in entries:
        if key in existing:
            continue
        add += f'    "{key}": ({en!r}, {ar!r}, {ph!r}),\n'
    if add:
        src = src.rstrip()
        assert src.endswith("LEGACY = {}") or src.endswith("}")
        if src.endswith("LEGACY = {}"):
            src = "LEGACY = {\n" + add + "}\n"
            src = "# key: (english, arabic, [placeholders])   -- see gen_arb.py\n" + src
        else:
            src = src[:-1] + add + "}\n"
        LEG.write_text(src)


def apply(rel, mapping, l10n_import):
    p = ROOT / rel
    s = p.read_text()
    entries = []
    for lit, spec in mapping.items():
        key, en, ar, ph = spec[:4]
        expr = spec[4] if len(spec) > 4 else f"l.{key}"
        if key not in ("",):
            entries.append((key, en, ar, ph))
        quoted = [f"'{lit}'", f'"{lit}"']
        for q in quoted:
            s = s.replace(q, expr)
    register([e for e in entries if e[1] is not None])
    # drop `const` directly before widgets that now hold non-const l.x (fixed later by analyzer loop)
    # insert `final l` into build methods that use it
    out, i = [], 0
    for m in re.finditer(r"Widget build\(BuildContext context[^)]*\)\s*\{", s):
        pass
    pos = 0
    res = ""
    for m in re.finditer(r"Widget build\(BuildContext context[^)]*\)\s*\{", s):
        start = m.end()
        depth, j = 1, start
        while depth and j < len(s):
            if s[j] == "{": depth += 1
            elif s[j] == "}": depth -= 1
            j += 1
        body = s[start:j]
        res += s[pos:start]
        if re.search(r"\bl\.[a-zA-Z]", body) and "final l = " not in body:
            res += "\n    final l = context.l10n;"
        pos = start
    res += s[pos:]
    s = res
    if l10n_import not in s:
        # after the last import line
        imports = list(re.finditer(r"^import .*;\n", s, re.M))
        last = imports[-1]
        s = s[: last.end()] + l10n_import + "\n" + s[last.end():]
    p.write_text(s)
