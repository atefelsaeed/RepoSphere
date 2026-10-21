#!/usr/bin/env python3
"""Removes `const` keywords that the analyzer flags after strings became
non-constant (invalid_constant & friends). Loops until stable."""
import re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAT = re.compile(r"error • .* • (lib/\S+?):(\d+):(\d+) • (invalid_constant|const_with_non_const|non_constant_list_element|const_initialized_with_non_constant_value|const_eval_method_invocation|const_constructor_param_type_mismatch|non_constant_map_element|const_eval_property_access)")

for _ in range(40):
    out = subprocess.run(["flutter", "analyze"], cwd=ROOT, capture_output=True, text=True).stdout
    hits = PAT.findall(out)
    if not hits:
        print("clean of const errors"); break
    # fix bottom-up per file so offsets stay valid
    byfile = {}
    for f, ln, col, _ in hits:
        byfile.setdefault(f, []).append((int(ln), int(col)))
    changed = False
    for f, locs in byfile.items():
        lines = (ROOT / f).read_text().split("\n")
        for ln, col in sorted(set(locs), reverse=True):
            # find nearest preceding `const ` at or before (ln, col)
            for k in range(ln - 1, max(ln - 12, -1), -1):
                text = lines[k]
                scan = text if k < ln - 1 else text[:col]
                idx = scan.rfind("const ")
                if idx >= 0:
                    lines[k] = text[:idx] + text[idx + 6:]
                    changed = True
                    break
        (ROOT / f).write_text("\n".join(lines))
    if not changed:
        print("could not fix automatically"); print(out[-1500:]); sys.exit(1)
