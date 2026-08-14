# Test and Project Cleanup

Release cleanup performed after **12.12k Full Localization Final Gate PASS**.

## Removed from release baseline

- `33` files from `scenes/tests/`
- `32` files from `scripts/tests/`

The historical regression implementation notes remain under `docs/milestones/`.
Test-only runtime resources are intentionally not shipped in this cleaned baseline.

## Documentation organization

Project root Markdown is limited to:

- `README.md`
- `MILESTONE_ROADMAP.md`
- `MILESTONE_12_COMPLETION.md`

Historical milestone notes are stored under:

- `docs/milestones/12.11/`
- `docs/milestones/12.12/`

Language and validation audits are stored under `docs/audit/`.

## Production-resource policy

No production scene or script was deleted as part of this cleanup.
Only dedicated `scenes/tests/` and `scripts/tests/` trees were removed.
