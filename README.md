# PLAKORO V2

PLAKORO V2 is the current Godot project for the Pokémon / Charakoro-style dice battle prototype.

## Current baseline

- Milestone 12.9 — Battle GUI UX: **PASS / CLOSED**
- Milestone 12.10 — Ordinary User End-to-End Regression: **PASS / CLOSED**
- Milestone 12.11 — Project UX / Tool Integration / Localization Foundation: **CLOSED**
- Milestone 12.12 — Deep Localization: **PASS / CLOSED**
- 12.12j Observer-Only Responsive Localization Regression: **PASS**
- 12.12k Full Localization Final Gate: **PASS**
- Main scene: `res://scenes/ui/BattlePreparationUI.tscn`

## Built-in languages

- English — `en_US`
- Traditional Chinese — `zh_TW`
- Spanish (Spain) — `es_ES`
- Japanese — `ja_JP`

Runtime UI language packs are under `language/`.
Game-content localization fragments are under `language/content/`.
User overrides remain under `user://user_database/language/`.

## Main user flow

`Content Studio → Save/Reload → Preparation → Battle → Result → Rematch / Preparation`

## Project structure

- `scenes/ui/` — production UI scenes
- `scenes/ui/components/` — reusable UI components
- `scripts/battle/` — Battle runtime, rules and opcode execution
- `scripts/content/` — Content Studio and database services
- `scripts/dice/` — Enerkoro / Charakoro runtime and setup
- `scripts/loadout/` — Player / AI Battle loadouts
- `scripts/ui/` — UI controllers and presentation helpers
- `database/` — packaged canonical runtime content
- `language/` — built-in UI and game-content localization
- `assets/` — images, models and UI assets
- `docs/milestones/` — historical milestone implementation notes
- `docs/audit/` — validation and localization audits
- `docs/maintenance/` — cleanup / maintenance records

## Release cleanup

Historical regression assets have been removed from the release baseline:

- `scenes/tests/` — removed
- `scripts/tests/` — removed

The regression work remains documented under `docs/milestones/`, but test-only scenes/scripts
are not shipped in this cleaned project baseline.

See `MILESTONE_ROADMAP.md` and `MILESTONE_12_COMPLETION.md` for the consolidated status.
