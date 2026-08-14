# Milestone 12.12i Fix 2 — Runtime Game Content Localization Coverage

Status: **READY FOR TEST**

This hotfix closes the gap between the game-content language packs and the actual
Preparation/Battle presentation paths.

Fixed runtime surfaces:
- Preparation Pokémon display name
- Preparation Pokémon Type and Weakness Type
- Preparation selected Move names
- Preparation Move description/effect presentation
- Battle player/enemy Pokémon display names
- Battle player/enemy Type and Weakness Type
- Battle outcome Pokémon names
- Battle Move names in outcome/timeline presentation
- special target-Move selection labels
- Timeline Move labels

Verified zh_TW entries were also added for the currently demonstrated Pinsir/Charmander
flow:
- Pinsir -> 凱羅斯
- Charmander -> 小火龍
- Grass / Fire / Flying / Water / Fighting
- Berserk Swing / Brick Break / Concentrate / Deadly Scissors
- their currently sourced effect descriptions

This does not alter Pokémon IDs, move_name_id, battle rules, or database references.

Regression:
`res://scenes/tests/Milestone1212iFix2RuntimeGameContentLocalizationRegressionTest.tscn`

Expected:
`=== V2 Milestone 12.12i Fix 2 Runtime Game Content Localization Regression Passed ===`

## r1 — Preparation localized description scope fix

`localized_move_description` is now declared directly after `effect_preview` is built,
before the trigger-group loop and fallback-effect branch. Both branches therefore share
the same Move-level localized description.

## r2 — Battle Loadout dialog coverage

Localized the separate Battle Loadout authoring/presentation path:
- Player/AI Pokémon OptionButton labels
- Move CheckBox labels
- hover popup Move name and Type
- Damage / Energy Cost / Move ID headings
- Move Effect / Charakoro Trigger / Charakoro Effect headings
- Charakoro orientation captions
- localized Move description/effect data passed into the hover popup
- Pinsir and Charmander move-name coverage for the currently available loadouts

## r3 — Battle runtime UI coverage

Closed the remaining direct raw-data paths in BattleGameUI and PlakoroMoveButton:
- player/enemy Pokémon names
- player/enemy Type
- Weakness Type
- Move button titles
- Move button damage/availability captions
- Battle Move hover localized name/type/effect text
- locale switch now rebuilds existing custom Move buttons so their child labels refresh

## r4 — Battle Dice Result + Outcome Message coverage

Closed the remaining runtime paths visible after r3:
- BattleDiceRollPresenter Energy labels now use Game Content Type localization
- mixed Energy results localize each Type independently
- Charakoro orientation label/tooltip uses orientation translation keys
- Battle outcome actor/target Pokémon names are localized before message construction
- BattleOutcomeFeedback localizes Move names
- Timeline Move-name path is also localized

## r5 — Enerkoro Builder deep runtime coverage + Content Studio compile fix

- Fixed `database_integrity_text` stale identifier; language-pack report now targets the declared `database_integrity_report`.
- Localized Enerkoro die title/hint, palette Close button, Energy names, face orientation names, FIXED/DOUBLE/SINGLE labels, palette prompts and duplicate-fixed-face validation reason.
- Builder context Pokémon display name now goes through the game-content localization layer.
- Locale switching now relocalizes dynamically-created Enerkoro die editors instead of leaving their old-language labels alive.
- Advanced toggle caption is reapplied on locale refresh.

## r6 — Enerkoro Move Readiness localization + Energy icons

`MoveCoverageCard` was still a legacy text-only component. It now:
- localizes Move names from semantic `move_name_id`
- localizes Requires / success / most-missing / average-shortfall labels
- localizes the missing Energy Type
- uses `EnergyCostChip` so required Energy is rendered with the same real Energy icons used elsewhere
- preserves raw gameplay IDs/counts while localizing presentation only

`MoveCoverageResultData` now carries `move_name_id` so presentation does not need to infer a semantic key from a translated display name.

## r7 — Enerkoro Energy Preview localization + regression correction

- `EnergyDieIconPreview` now localizes Dice / Fixed / Double / Single captions and Energy tooltips.
- `EnergyDiceIconSummary` localizes missing-setup feedback.
- Added zh_TW Move names for the currently demonstrated Gyro Ball / Hard Impact / Iron Tail / Wild Tackle cards when those semantic IDs exist in the built-in content pack.
- r6 regression now checks substring content inside the multiline detail Label instead of incorrectly requiring each detail line to be a separate Label.
