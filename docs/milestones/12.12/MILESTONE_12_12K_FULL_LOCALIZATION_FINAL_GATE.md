# Milestone 12.12k — Full Localization Final Gate

Status: **PASS / CLOSED**

Base:
- 12.12j Restart R3 (observer-only responsive regression passed)

Integrated language bundle:
- `language(3).zip`

Built-in locales after integration:
- English (en_US)
- Traditional Chinese (zh_TW)
- Spanish — Spain (es_ES)
- Japanese (ja_JP)

Integration behavior:
- UI packs are installed under `res://language/<locale>.json`.
- Game-content fragments are installed under `res://language/content/`.
- Existing en_US / zh_TW files in the supplied bundle match the 12.12j baseline.
- Locale discovery remains automatic through LocalizationService.
- Game-content fragments are merged automatically by declared locale through
  GameContentLocalizationService.
- No responsive/layout production files were modified.

Final Gate regression:
`res://scenes/tests/Milestone1212kFullLocalizationFinalGateRegressionTest.tscn`

The gate:
1. reloads language discovery,
2. verifies en_US / zh_TW / es_ES / ja_JP,
3. activates every locale,
4. checks representative Preparation / Battle / Content Studio / Enerkoro /
   Model Weight UI translations,
5. checks Pokémon name, Move name, Move description, and multi-effect Move content,
6. enters the major localized scenes sequentially without changing layout,
7. confirms locale state survives across the flow.

Audit:
`docs/audit/M12_12K_LANGUAGE_INTEGRATION_AUDIT.json`

Note:
The supplied Spanish game-content bundle provides generic Move localization but does
not include `move_card.*` card-specific fragments. The project therefore retains its
normal fallback behavior for card-specific fields that are not supplied by that pack.

## Fix 1 — stale historical regression resource paths

Godot parses historical regression scripts on project load. Six older tests still
referenced the pre-brand-normalization `PLAKOROContentStudioUI` resource name, while
the actual production files are `PlakoroContentStudioUI.tscn/.gd`.

All six stale test-only references were corrected. Production UI/runtime files are
unchanged.

Regression:
`res://scenes/tests/Milestone1212kFix1StaleTestPathRegressionTest.tscn`

## Release cleanup

After the Final Gate passed, historical `scenes/tests/` and `scripts/tests/` assets were
removed from the release-clean baseline. The test history remains documented here and
under `docs/audit/`.
