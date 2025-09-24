import sys, yaml, pathlib
required = {"name","grain","primary_key","columns","version"}
ok = True
for yml in pathlib.Path("contracts").glob("*.yml"):
    with open(yml, encoding="utf-8") as f:
        doc = yaml.safe_load(f)
    missing = required - set(doc)
    if missing:
        print(f"[FAIL] {yml}: missing {missing}")
        ok = False
if not ok:
    sys.exit(1)
print("[OK] contracts validated")
