# Milestone 12.12c — Battle Deep Localization

Status: **READY FOR TEST**

## Coverage

The Battle runtime now deep-localizes primary player-facing runtime text:

- turn header and persistent Turn Banner
- action phases (choose / roll / target / resolve / AI / finished)
- player/AI identity labels, type and weakness wrappers
- battle setup source summary
- Energy requirement feedback
- Charakoro trigger feedback
- special Move target-selection prompt
- unavailable Move reasons
- AI thinking/failure and ordinary move prompts
- step-by-step damage / weakness / self-damage messages
- Victory / Defeat / Battle finished messages
- Result summary and HP summary
- prototype Battle outcome summary
- condition/status/temporary-effect outcome feedback
- pending temporary-effect badges and tooltips
- Battle Timeline titles, energy check, AI decision and damage calculation text
- exit confirmation / Technical label

Dynamic messages use `LocalizationService.tr_format()` so locale-specific word order is
not tied to English concatenation.

## Data-source gate

Battle continues to consume editable Pokémon / Move / Charakoro data from the runtime
`DatabaseService` user override layer:

- `user://user_database/pokemon`
- `user://user_database/move_cards`
- `user://user_database/kyokoro_profiles`

Bundled `res://database` remains the base/fallback layer.

## Scope boundary

This milestone intentionally does not localize Pokémon names, Move names, Type names, or
user-authored Move effect descriptions themselves. Those are game-content localization
and belong to 12.12g.

Technical opcode/debug output may remain English.

## Regression

Run:

`res://scenes/tests/Milestone1212cBattleDeepLocalizationRegressionTest.tscn`

Expected marker:

`=== V2 Milestone 12.12c Battle Deep Localization Regression Passed ===`
