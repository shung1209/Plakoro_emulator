# 12.12i Fix 3 — Content Studio Editor + Move Localization Storage

Status: READY FOR TEST

## Content Studio audit

Pokémon / Charakoro / Move Editor visible text was re-audited. Runtime hardcoded
status/button strings found during this pass were routed through LocalizationService.

Technical schema names such as `species_id`, `move_name_id`, `energy_cost[]`,
`base_actions[]`, and `outcome_rules[]` intentionally remain technical identifiers.

Audit:
`docs/audit/M12_12I_FIX3_CONTENT_STUDIO_EDITOR_LOCALIZATION_AUDIT.csv`

## Separate Move localization JSON

Traditional Chinese Move content is now stored separately:

`res://language/content/zh_TW_moves.json`

The base pack remains:

`res://language/content/zh_TW.json`

GameContentLocalizationService now merges every JSON document in the content folder
whose declared `locale` matches the active locale. This also works for user packs, e.g.:

`user://user_database/language/content/my_zh_TW_moves.json`

A Move fragment can contain:
- `move.<move_name_id>.name`
- `move.<move_name_id>.description`
- `move.<move_name_id>.effect_0`
- `move.<move_name_id>.effect_1`
- etc.

Existing single-file packs remain compatible.

Move entries moved to the dedicated zh_TW Move file: 46.

Regression:
`res://scenes/tests/Milestone1212iFix3ContentStudioEditorAndMoveLocalizationRegressionTest.tscn`

## r2 — Editor explanation/runtime cleanup

Localized the remaining explanatory paths visible in the Pokémon, Charakoro, and Move
editors: new-content guide hints, dependency/reference summaries, profile source,
validation messages, orientation captions, source marks, and library Pokémon/Move
display names. The obsolete Milestone 12.8g footer is hidden from the normal UI.
