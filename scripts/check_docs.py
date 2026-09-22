import sys, pathlib
required = [
    "README.md",
    "docs/conceptual/capex-lifecycle.md",
    "docs/conceptual/procure-to-capitalize.md",
    "docs/domains/fa/bus-matrix.md",
    "docs/domains/ap/bus-matrix.md",
    "docs/domains/projects/bus-matrix.md",
    "docs/platform/change-discipline.md",
    "docs/platform/conformed-dimensions.md",
]
missing = [p for p in required if not pathlib.Path(p).exists()]
if missing:
    print(f"[FAIL] missing required docs: {missing}")
    sys.exit(1)
print("[OK] docs present")
