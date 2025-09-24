import sys, pathlib
required = ["docs/bus-matrix.md", "README.md"]
missing = [p for p in required if not pathlib.Path(p).exists()]
if missing:
    print(f"[FAIL] missing required docs: {missing}")
    sys.exit(1)
print("[OK] docs present")
