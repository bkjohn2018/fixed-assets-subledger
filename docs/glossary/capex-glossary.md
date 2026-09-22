# CapEx Lifecycle Glossary

| Term | Definition |
|------|------------|
| **Capital Expenditure Lifecycle (CapEx Lifecycle)** | Platform conceptual model for capital investment analytics from commitment through in-service assets |
| **Procure-to-Capitalize (P2C)** | Domain process vocabulary: Procure → Pay → Collect → Capitalize |
| **Procure** | P2C stage: PO commitments and receipts |
| **Pay** | P2C stage: AP invoices, payment schedules, supplier spend |
| **Collect** | P2C stage: project and CIP cost collection |
| **Capitalize** | P2C stage: fixed asset additions, depreciation, NBV |
| **Natural grain** | One row per business event at the finest useful level for that process |
| **Conformed dimension** | Shared dimension reused across facts (e.g. `D_COA`, `D_Supplier`) |
| **Bridge column** | Non-additive classification field linking facts at different grains |
| **Contract** | YAML declaration of grain, primary key, and columns; logical layer source of truth |

**Version:** 26B
