import sys, yaml, pathlib
required = {"name","grain","primary_key","columns","version"}
ok = True
for yml in pathlib.Path("contracts").glob("*.yml"):
    doc = yaml.safe_load(open(yml, encoding="utf-8"))
    miss = required - set(doc)
    if miss:
        print(f"[FAIL] {yml}: missing {miss}"); ok=False
if not ok: sys.exit(1)
print("[OK] contracts validated")
