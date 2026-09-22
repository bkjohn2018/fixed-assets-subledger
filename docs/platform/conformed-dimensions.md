# Conformed Dimensions

Dimensions listed here are **shared across P2C stages**. Each domain bus matrix marks which dimensions apply to its facts.

| Dimension | Key | Used by | Definition |
|-----------|-----|---------|------------|
| `D_Supplier` | `VENDOR_ID` / `SUPPLIER_ID` | Pay, Procure (planned) | Oracle Fusion supplier master |
| `D_Project` | `PROJECT_ID` | Collect, Pay (bridge) | Oracle Projects project; AP `PJC_PROJECT_ID` maps to this canonical natural key |
| `D_Task` | `TASK_ID` | Collect, Pay (bridge when available) | Project task within `D_Project`; interpret only with its project context |
| `D_COA` | `CODE_COMBINATION_ID` | Pay, Collect, Capitalize | Chart of accounts segment combination |
| `D_Asset` | `ASSET_ID` | Collect (posted status), Capitalize | Fixed asset master; populated on Projects status only when posted FA evidence exists |
| `D_Book` | `BOOK_TYPE_CODE` | Capitalize | Asset book (corporate, tax, etc.) |
| `D_Time` | date role per fact | All | Conformed date dimension with role-playing keys |
| `D_Category` | `CATEGORY_ID` | Capitalize | FA category |
| `D_Location` | location key | Capitalize (optional) | Asset location |
| `D_BusinessUnit` | `ORG_ID` | Pay, Procure (planned) | Operating unit context |

Dimensions may ship as **stub tables** in the Power BI model until a shared dimension repo is wired. Facts always carry the natural keys listed in their contracts.

Projects uses `PROJECT_ID` and `TASK_ID` as canonical conformed natural keys. Its cost-to-asset-line bridge carries lineage only; conformed dimensions filter the owning facts instead of turning the bridge into an additive fact. Candidate-review attributes belong to the as-of status fact and do not change dimension meaning or establish an accounting conclusion.

**Version:** 26B
