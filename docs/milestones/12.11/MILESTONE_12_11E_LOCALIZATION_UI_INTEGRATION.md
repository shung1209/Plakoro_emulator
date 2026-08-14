# Milestone 12.11e — Localization UX & UI Integration

Status: **READY FOR TEST**

## Language selector

A reusable `LanguageSelector` is now shown in the headers of:

- Battle Preparation
- Battle
- Content Studio

It discovers all valid bundled/user JSON languages through `LocalizationService`.
Selecting a language applies immediately and persists through the foundation service.

## First UI migration

The first migration intentionally focuses on primary navigation and player-facing state.

### Preparation

- page title
- Content Studio
- Refresh
- Edit Enerkoro
- Configure Battle / Moves
- Start Battle

### Battle

- page title
- Back to Preparation
- Restart / Result Restart
- Moves
- Roll Result
- Battle Timeline
- Player Turn / AI Turn
- Victory / Defeat / Battle Finished
- result summary labels

### Content Studio

- page title
- Validate Database
- Back to Preparation
- Pokémon / Charakoro / Move / Model Weight tabs
- Advanced / Technical Details

Technical/editor-specific labels remain English for now and continue to use the English
fallback until migrated in later localization polish.

## Updating existing user language files

Bundled locale strings are now merged underneath matching user locale JSON. This means
new application keys can be added in updates without overwriting the user's language
file. User keys always win.

## Regression

Run:

`res://scenes/tests/Milestone1211eLocalizationUIRegressionTest.tscn`

Expected marker:

`=== V2 Milestone 12.11e Localization UI Regression Passed ===`

## Fix 1 — Model Weight utility dirty-state regression

Localization UI integration exposed a navigation regression where the Content Studio
Unsaved Changes guard could appear around Model Weight Generator navigation.

The guard now has an explicit utility boundary:

- dirty Pokémon / Charakoro / Move → Model Weight Generator: no dialog
- Model Weight Generator → Pokémon / Charakoro / Move: no dialog
- ordinary editor-to-editor navigation remains protected by Unsaved Changes
- Model Weight Generator remains outside the Content Studio authoring document state

Regression scene:

`res://scenes/tests/Milestone1211eModelWeightUnsavedGuardRegressionTest.tscn`

Expected marker:

`=== V2 Milestone 12.11e Model Weight Unsaved Guard Regression Passed ===`

## Final Coverage Pass

Primary localization coverage now also includes Enerkoro Builder and Model Weight
Generator. Enerkoro Builder has its own header Language Selector. Model Weight
Generator uses a live localized-control registry so changing language does not rebuild
the utility or discard imported model/orientation state.

Final regression:

`res://scenes/tests/Milestone1211eLocalizationCoverageFinalRegressionTest.tscn`

Expected marker:

`=== V2 Milestone 12.11e Localization Coverage Final Regression Passed ===`
