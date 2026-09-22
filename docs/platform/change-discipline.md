# Change Discipline

Contract-first workflow for column, grain, or naming changes across all P2C domains.

## Change order

1. Update `contracts/<domain>/*.yml`
2. Update matching `sql/bip/<domain>/*.sql`
3. Update `sql/<domain>/` layered SQL if applicable
4. Update `powerbi/queries/<domain>/*.m` and `powerbi/model.json`
5. Update domain bus matrix and lineage docs if grain or source assumptions changed
6. Run validations (see README)

## Grain guardrails

- Do not mix grains in one fact
- Do not join payment schedules to distributions and sum schedule amounts
- Cross-stage P2C links use bridges and conformed keys, not blended rows
- Convenience aggregates (e.g. transaction header summary) must be clearly named and secondary to the canonical distribution-grain fact

## New domain checklist

Before merging a new P2C stage:

1. Add row to domain registry in README and [`../conceptual/capex-lifecycle.md`](../conceptual/capex-lifecycle.md)
2. Copy [`bus-matrix-template.md`](bus-matrix-template.md) to `docs/domains/<domain>/bus-matrix.md`
3. Add contracts under `contracts/<domain>/`
4. Add BIP and layered SQL
5. Extend `scripts/check_docs.py` required docs if the domain is active

**Version:** 26B
