# Kimball Bus Matrix — Template

> Copy this file to `docs/bus-matrix-<domain>.md` and fill in for each domain (AP, AR, Projects, etc.).

| Business Process | Fact Table / Grain | Dim A | Dim B | Dim C | Dim D | Other Dims | Notes |
|------------------|--------------------|:-----:|:-----:|:-----:|:-----:|------------|-------|
| (process)        | (F_* at natural grain) |  ✔  |  ✔  | key   | opt   | (list)     | (constraints, keys) |

**Guidelines**
- Facts at **one grain** only. Avoid mixing subledger/SLA/GL in a single table.
- Use **conformed dimensions** across processes (Time, COA, Org, etc.).
- When necessary, provide **bridge tables** for ragged/time-varying hierarchies.
- Document **primary keys** and **surrogate keys** for each fact and dimension.
- Record **version** (e.g., 25C) to tie to source application release.
