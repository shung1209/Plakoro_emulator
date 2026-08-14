# Milestone 12.12d — Content Studio Deep Localization

Status: **READY FOR TEST**

## Scope

Deep localization coverage for the Pokémon / Charakoro / Move authoring workflow:

- Content Studio tabs and common actions
- library search, source/type filters, visible-count status
- Pokémon / Charakoro / Move section headings and editor actions
- source state: Built-in / Modified / User Created / New Content
- save / create / override / remove override / delete state
- unsaved-change dialog and discard action
- restore built-in workflow
- delete workflow
- duplicate workflow
- validation status and validation issue wrapper
- Enerkoro/default-dice status surfaced inside Pokémon Editor
- Charakoro reference list
- Move Energy preview / damage preview / empty effects
- Pokémon image/asset status
- Database Integrity dialog title

Technical schema field names and raw JSON/opcodes remain intentionally technical.
Game-content names and descriptions remain outside this milestone and are handled by
12.12g.

## Regression

Run:

`res://scenes/tests/Milestone1212dContentStudioDeepLocalizationRegressionTest.tscn`

Expected:

`=== V2 Milestone 12.12d Content Studio Deep Localization Regression Passed ===`

## Hotfix 12.12d-r1

Fixed Content Studio startup regression where `_apply_localized_text()` triggered
validation before `weakness_type_option` was populated. This caused `selected == -1`,
an out-of-bounds metadata lookup, and a subsequent invalid String conversion.
Dynamic localization refresh now runs only after editor controls are initialized,
and `_collect_data()` includes a defensive selection guard.

## r2 — Regression expectation fix

The r1 runtime initialization fix was correct. The 12.12d regression itself still
expected the English text `Pokémon Editor` after switching to `zh_TW`.

The established Traditional Chinese language pack defines:

`content_studio.pokemon_editor = Pokémon 編輯器`

The regression expectation now matches the actual locale contract.

## r3 — Multiline translation normalization

The r2 regression exposed that some newly-added multiline translation values contained
literal `\n` text rather than actual newline characters after JSON parsing.

The language packs now store real newline semantics for multiline Content Studio,
Preparation, and Battle strings. This prevents dialogs/status text from displaying
backslash characters and makes `tr_format()` output match the intended UI layout.

## r4 — Legacy user-language compatibility

The r3 bundled JSON files were correct, but `LocalizationService` intentionally merges
`user://user_database/language` over `res://language`. An older user language pack can
therefore keep a double-escaped `\\n` value and override the corrected bundled key.

`tr_key()` now normalizes legacy literal `\\n` / `\\t` sequences at runtime. This keeps
existing user language packs compatible without deleting, rewriting, or relocating the
user's files.

## r5 — Escape normalization correction

r4's compatibility helper searched for two literal backslashes followed by `n`.
A legacy parsed language value contains one literal backslash followed by `n`.
The GDScript replacement pattern is corrected from `"\\\\n"` semantics to `"\\n"`
semantics, and likewise for tabs.
