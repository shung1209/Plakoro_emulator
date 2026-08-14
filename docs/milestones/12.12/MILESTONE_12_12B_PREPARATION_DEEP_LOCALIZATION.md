# Milestone 12.12b — Battle Preparation Deep Localization

Status: **READY FOR TEST**

## Coverage

Battle Preparation now localizes:

- main section headings
- Pokémon / opponent summary labels
- Resolution mode labels/options
- Battle Setup dialog title/actions/hint
- Player/AI setup headings
- AI difficulty options
- Player Enerkoro source options/status
- setup readiness and selected-move counts
- database/loadout/setup status messages
- loadout, type, HP and weakness summary labels
- missing Move / missing Enerkoro feedback
- Move Coverage rating text
- overall loadout analysis/status/signature
- Move Draft status
- validation wrappers and Player/AI error prefixes
- energy-cost/usage summary headings

Dynamic Preparation sentences use `LocalizationService.tr_format()` with named
parameters, so Chinese and future languages are not forced into English word order.

## Data-source gate

The regression also confirms the runtime editable directories remain:

- Pokémon: `user://user_database/pokemon`
- Moves: `user://user_database/move_cards`
- Charakoro: `user://user_database/kyokoro_profiles`

`DatabaseService` continues to use bundled `res://database` as the base layer and the
above `user://` directories as the user override layer.

## Regression

Run:

`res://scenes/tests/Milestone1212bPreparationDeepLocalizationRegressionTest.tscn`

Expected:

`=== V2 Milestone 12.12b Preparation Deep Localization Regression Passed ===`
