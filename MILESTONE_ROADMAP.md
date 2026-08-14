# PLAKORO V2 — Milestone Roadmap

## Current baseline

| Milestone | Scope | Status |
| --- | --- | --- |
| 12.1–12.8 | Authoring, opcode, Content Studio and Preparation foundation | COMPLETE |
| 12.9 | Battle GUI UX | PASS / CLOSED |
| 12.10 | Ordinary User End-to-End Regression | PASS / CLOSED |
| 12.11 | Project UX / Tool Integration / Localization Foundation | CLOSED |
| 12.12a–i | Deep Localization / Language Pack Validation | PASS |
| 12.12j | Observer-Only Responsive Localization Regression | PASS |
| 12.12k | Full Localization Final Gate | PASS / CLOSED |

## Accepted user flow

`Content Studio → Save/Reload → Preparation → Battle → Result → Rematch / Preparation`

## Localization baseline

Built-in locales:

- `en_US`
- `zh_TW`
- `es_ES`
- `ja_JP`

The project uses `res://language` for built-in packs and
`user://user_database/language` for user language overrides.

## Documentation

- Consolidated completion: `MILESTONE_12_COMPLETION.md`
- 12.11 history: `docs/milestones/12.11/`
- 12.12 history: `docs/milestones/12.12/`
- Audits: `docs/audit/`
- Maintenance: `docs/maintenance/`

## Release policy

Historical regression scenes/scripts are removed from the cleaned release baseline.
Future regressions should be developed separately and must not mutate production UI simply
to satisfy test geometry.

## Next milestone

Milestone 12 is closed at the 12.12k localization final gate. The next milestone is TBD.
