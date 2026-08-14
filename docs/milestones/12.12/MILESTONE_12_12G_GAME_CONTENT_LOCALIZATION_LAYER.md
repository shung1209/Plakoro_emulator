# Milestone 12.12g — Game Content Localization Layer

Status: **READY FOR TEST**

## Architecture

UI/application strings remain in:
- `res://language/<locale>.json`
- `user://user_database/language/<locale>.json`

Game-content strings now use a separate layer:
- built-in: `res://language/content/<locale>.json`
- user override: `user://user_database/language/content/<any_filename>.json`

Keys are stable semantic content keys:
- `pokemon.<species_id>.name`
- `move.<move_name_id>.name`
- `move.<move_name_id>.description`
- `move.<move_name_id>.effect_<index>`
- `type.<type_id>.name`

The source JSON remains authoritative gameplay data. Localization changes presentation
only; IDs, references, opcodes, damage, costs, conditions, and battle semantics are not
translated.

Missing localized game content falls back:
current locale content -> English content pack -> source document display/raw text.

The bundled English content pack was generated from the current database source text.
The bundled zh_TW pack contains only a conservative set of known Pokémon/type labels;
untranslated Move text intentionally falls back rather than inventing translations.

Example user pack:
`docs/examples/game_content_language_pack_zh_TW.example.json`

Regression:
`res://scenes/tests/Milestone1212gGameContentLocalizationLayerRegressionTest.tscn`

Expected:
`=== V2 Milestone 12.12g Game Content Localization Layer Regression Passed ===`
