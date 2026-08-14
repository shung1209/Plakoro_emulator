# Milestone 12.12a — Localization & Data Source Audit

Status: **AUDIT COMPLETE / READY FOR REVIEW**

## Executive summary

- Path literals found: **567** total (`res://`: **517**, `user://`: **50**).
- Likely hardcoded visible strings found: **463** total (player/editor UI: **358**, technical/debug: **0**, review: **105**).
- This is a static source audit. A `res://` literal is not automatically wrong; scenes, bundled defaults, templates and fallback resources should remain in `res://`.

## Source-of-truth findings

### Pokémon / Move / Charakoro
Runtime `DatabaseService` loads bundled `res://database/...` first, then merges `user://user_database/...` records on top. User content is therefore the editable runtime override layer; bundled `res://` content remains the base/default layer.

### Content Studio
Authoring services target `user://user_database/...`. `res://database/...` is used for bundled source content, editable-copy bootstrap, and restore-to-built-in workflows, not as the normal writable destination.

### Localization
`LocalizationService` loads `res://language/<locale>.json` as the bundled base and merges matching `user://user_database/language/*.json` strings on top. User JSON has priority while newly added bundled keys remain available.

### Model Weight Generator
Generated Charakoro profiles write directly to `user://user_database/kyokoro_profiles`.

### Battle Preparation / Battle Runtime
Normal user-authored content is consumed through providers and `DatabaseService`, not by directly treating `res://database` as the authoritative runtime store. Direct raw database paths in UI/runtime code are audit candidates and should be reviewed individually.

## Data source map

| System | Static path pattern | Interpretation |
|---|---|---|
| Pokémon Database | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Move Database | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Charakoro Profiles | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Enerkoro / Dice Setups | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Localization | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Battle Preparation | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Battle Runtime | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Content Studio | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |
| Model Weight Output | mixed / layered | Bundled base + user override, or mixed infrastructure paths; service semantics must decide. |

## Localization coverage findings

12.11e covers primary navigation and several major workflows, but hardcoded visible text remains in Preparation setup/status strings, Battle messages/timeline/status/effect presentation, Content Studio dialogs/editor labels/validation, Enerkoro subcomponents, Model Weight dynamic status/warnings, and supporting presentation services.

### Highest-priority files by likely visible hardcoded string count

| File | Count |
|---|---:|
| `scenes/ui/PlakoroContentStudioUI.tscn` | 126 |
| `scripts/ui/PlakoroContentStudioUI.gd` | 51 |
| `scenes/ui/BattlePreparationUI.tscn` | 45 |
| `scripts/model_weight/ModelWeightGeneratorPanel.gd` | 37 |
| `scenes/ui/BattleGameUI.tscn` | 33 |
| `scenes/ui/EnergyDiceVisualBuilderUI.tscn` | 17 |
| `scripts/ui/BattlePreparationUI.gd` | 16 |
| `scripts/ui/BattleGameUI.gd` | 13 |
| `scenes/ui/PreBattleDiceSetupUI.tscn` | 8 |
| `scripts/presentation/timeline/BattleTimelineBuilder.gd` | 5 |
| `scripts/ui/EnergyDiceVisualBuilderUI.gd` | 4 |
| `scripts/ui/PreBattleDiceSetupUI.gd` | 1 |
| `scripts/ui/components/BattlePendingEffectIndicator.gd` | 1 |
| `scripts/ui/components/BattleDiceRollPresenter.gd` | 1 |

## Recommended 12.12 execution order

1. **12.12b Preparation Deep Localization** — setup dialog, loadout status, validation, difficulty/resolution, coverage/status text.
2. **12.12c Battle Deep Localization** — turn/result/status/effect/timeline/damage/heal/energy messages.
3. **12.12d Content Studio Deep Localization** — editor labels, filters, dialogs, validation, restore/delete/unsaved workflows.
4. **12.12e Enerkoro + Model Weight Deep Localization** — subcomponent labels and dynamic status/warnings.
5. **12.12f Dynamic Text Formatting** — parameterized templates rather than English-order concatenation.
6. **12.12g Game Content Localization** — Pokémon/Move/Type display strings separated from UI strings.
7. **12.12i Language Pack Validation** — missing/empty/unknown key report.
8. **12.12j/k Responsive + final cross-locale regression.**

## Generated audit files

- `docs/audit/M12_12A_PATH_USAGE.csv`
- `docs/audit/M12_12A_HARDCODED_STRINGS.csv`

## Focus service excerpts


### `scripts/database/DatabaseService.gd`

```text
2: const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")
3: const REFERENCE_LOADER: Script = preload("res://scripts/database/ReferenceLoader.gd")
4: const RULES_LOADER: Script = preload("res://scripts/database/RulesLoader.gd")
5: const MOVE_CARD_PARSER: Script = preload("res://scripts/database/parsers/MoveCardParser.gd")
6: const POKEMON_PARSER: Script = preload("res://scripts/database/parsers/PokemonParser.gd")
7: const PROFILE_PARSER: Script = preload("res://scripts/database/parsers/KyokoroProfileParser.gd")
8: const MOVE_DIR: String = "res://database/move_cards"
9: const POKEMON_DIR: String = "res://database/pokemon"
10: const PROFILE_DIR: String = "res://database/kyokoro_profiles"
11: const USER_MOVE_DIR: String = "user://user_database/move_cards"
12: const USER_POKEMON_DIR: String = "user://user_database/pokemon"
13: const USER_PROFILE_DIR: String = "user://user_database/kyokoro_profiles"
21: func load_all() -> bool:
23: 	reference_data = REFERENCE_LOADER.load_all()
240: 		# user:// is the editable authoritative override layer.
```

### `scripts/content/UserDatabasePathService.gd`

```text
4: const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")
7: const BUILTIN_ROOT: String = "res://database"
8: const ROOT: String = "user://user_database"
54:     "user://player_energy_dice_setup.json": PLAYER_ENERGY_DICE_PATH,
55:     "user://player_battle_loadout.json": PLAYER_LOADOUT_PATH,
56:     "user://ai_battle_loadout.json": AI_LOADOUT_PATH
91: # First-run/update bootstrap policy:
96: static func bootstrap_from_builtin_database(
114:     # Export-safe: do not enumerate res:// database directories at runtime.
116:     # so the same bootstrap works in Editor, native Linux and Windows/Proton PCKs.
273:     # Editable runtime content must never target res:// in an exported build.
274:     # Map built-in database paths to the matching user_database override and
```

### `scripts/content/ContentDataSourceService.gd`

```text
3: const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")
18:     var user_path: String = "user://user_database/%s/%s.json" % [directory, normalized_id]
19:     var builtin_path: String = "res://database/%s/%s.json" % [directory, normalized_id]
33:         source = "override"
36:         # First-run bootstrap intentionally mirrors built-in JSON into user://.
63:         return {"success": false, "errors": ["Could not remove the user override."]}
```

### `scripts/content/PokemonAuthoringService.gd`

```text
4: const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")
10:     "res://scripts/dice/setup/PokemonDefaultDiceGenerator.gd"
14:     "res://database/pokemon"
18:     "user://user_database/pokemon"
22:     "res://database/kyokoro_profiles"
26:     "user://user_database/kyokoro_profiles"
30:     "user://user_database/move_cards",
31:     "res://database/move_cards",
32:     "res://database/moves"
285:                 "Could not create user://user_database/pokemon."
316:             "user://user_database/dice_setups"
356: static func load_by_id(
396:     for move_id: String in _list_json_ids("user://user_database/move_cards"):
399:     # Legacy res://database/moves is development-only fallback.
400:     for move_id: String in _list_json_ids("res://database/moves"):
```

### `scripts/content/MoveCardAuthoringService.gd`

```text
4: const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")
10:     "res://database/move_cards"
14:     "user://user_database/move_cards"
38:     "res://scripts/runtime/MoveRuntimeCompatibilityService.gd"
41:     "res://scripts/runtime/KyokoroOrientationMappingService.gd"
514: static func load_by_id(
577:                 "Could not create user://user_database/move_cards."
```

### `scripts/content/KyokoroProfileAuthoringService.gd`

```text
4: const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")
10:     "res://database/kyokoro_profiles"
14:     "user://user_database/kyokoro_profiles"
229:                 "Could not create user://user_database/kyokoro_profiles."
271: static func load_by_id(
```

### `scripts/localization/LocalizationService.gd`

```text
8: 	"user://user_database/language"
14: 	"res://language"
22: var fallback_strings: Dictionary = {}
104: 			"LocalizationService: built-in fallback language is missing."
116: 	var fallback_locale: String = String(
118: 			"fallback",
124: 		fallback_locale.is_empty()
125: 		or fallback_locale == current_locale
127: 		fallback_locale = (
133: 	fallback_strings.clear()
135: 	if not fallback_locale.is_empty():
136: 		var fallback_document: Dictionary = (
138: 				fallback_locale
142: 		if not fallback_document.is_empty():
143: 			fallback_strings = (
144: 				fallback_document.get(
152: 		and fallback_locale != DEFAULT_LOCALE
168: 				if not fallback_strings.has(key):
169: 					fallback_strings[key] = (
191: 	if fallback_strings.has(key):
193: 			fallback_strings[key]
207: 		or fallback_strings.has(key)
299: 	# User files are free-form filenames and override the matching locale by
343: 	merged["fallback"] = String(
345: 			"fallback",
347: 				"fallback",
```

### `scripts/model_weight/ModelWeightGeneratorPanel.gd`

```text
3: const STLImporter = preload("res://scripts/model_weight/importers/STLRuntimeImporter.gd")
4: const OBJImporter = preload("res://scripts/model_weight/importers/OBJRuntimeImporter.gd")
5: const GLTFImporter = preload("res://scripts/model_weight/importers/GLTFRuntimeImporter.gd")
89: 	page_margin.add_theme_constant_override("margin_left", 12)
90: 	page_margin.add_theme_constant_override("margin_right", 12)
91: 	page_margin.add_theme_constant_override("margin_top", 4)
92: 	page_margin.add_theme_constant_override("margin_bottom", 4)
98: 	page.add_theme_constant_override("separation", 6)
139: 	left_margin.add_theme_constant_override("margin_left", 10)
140: 	left_margin.add_theme_constant_override("margin_right", 10)
141: 	left_margin.add_theme_constant_override("margin_top", 8)
142: 	left_margin.add_theme_constant_override("margin_bottom", 8)
148: 	preview_panel.add_theme_constant_override("separation", 6)
153: 	orient_title.add_theme_font_size_override("font_size", 18)
223: 	appearance_row.add_theme_constant_override("separation", 6)
259: 	rotate_row.add_theme_constant_override("separation", 5)
313: 	right_stack.add_theme_constant_override("separation", 6)
324: 	model_margin.add_theme_constant_override("margin_left", 10)
325: 	model_margin.add_theme_constant_override("margin_right", 10)
326: 	model_margin.add_theme_constant_override("margin_top", 8)
327: 	model_margin.add_theme_constant_override("margin_bottom", 8)
331: 	model_box.add_theme_constant_override("separation", 6)
336: 	model_title.add_theme_font_size_override("font_size", 18)
340: 	file_row.add_theme_constant_override("separation", 6)
356: 	meta_row.add_theme_constant_override("separation", 8)
422: 	right_margin.add_theme_constant_override("margin_left", 10)
423: 	right_margin.add_theme_constant_override("margin_right", 10)
424: 	right_margin.add_theme_constant_override("margin_top", 8)
425: 	right_margin.add_theme_constant_override("margin_bottom", 8)
431: 	right.add_theme_constant_override("separation", 6)
436: 	sim_title.add_theme_font_size_override("font_size", 18)
440: 	sim_options.add_theme_constant_override("separation", 8)
505: 	result_title.add_theme_font_size_override("font_size", 16)
637: func _sanitize_output_filename(raw_name: String, fallback_id: String) -> String:
641: 		filename = fallback_id + "_model_custom.json"
655: 		filename = fallback_id + "_model_custom.json"
986: 	preview_mesh_instance.material_override = preview_material
1188: 	body.physics_material_override = pm
1486: 	return "user://user_database/kyokoro_profiles"
1501: 	floor_body.physics_material_override = pm
```

### `scripts/loadout/PlayerBattleLoadoutProvider.gd`

```text
5:     "res://scripts/loadout/PlayerBattleLoadoutData.gd"
8:     "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
11:     "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
14:     "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
17:     "res://scripts/content/UserDatabasePathService.gd"
22:     "user://user_database/loadouts/player_battle_loadout.json"
26:     "user://user_database/dice_setups/player_energy_dice_setup.json"
30:     "res://database/dice_setups/pikachu_default.json"
69:     # user:// custom file is only a fallback when the database default cannot
```

### `scripts/loadout/AIBattleLoadoutProvider.gd`

```text
5:     "res://scripts/loadout/AIBattleLoadoutData.gd"
8:     "res://scripts/loadout/AIBattleLoadoutSaveService.gd"
11:     "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
14:     "res://scripts/content/UserDatabasePathService.gd"
19:     "user://user_database/loadouts/ai_battle_loadout.json"
23:     "res://database/dice_setups/squirtle_default.json"
```

### `scripts/ui/BattlePreparationUI.gd`

```text
5:     "res://scripts/ui/theme/PlakoroThemeFactory.gd"
8:     "res://scripts/ui/theme/PlakoroUIStyle.gd"
13:     "res://scripts/ui/responsive/ResponsiveUIService.gd"
16:     "res://scripts/ui/responsive/UIResponsiveProfile.gd"
21:     "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
24:     "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
27:     "res://scripts/loadout/PlayerBattleLoadoutValidator.gd"
30:     "res://scripts/analysis/MoveCoverageAnalyzer.gd"
33:     "res://scripts/analysis/MoveBuilderAnalysisService.gd"
36:     "res://scripts/runtime/BattleLoadoutVerificationService.gd"
39:     "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
42:     "res://scripts/runtime/BattleResourceRecoveryService.gd"
45:     "res://scripts/ui/components/EnergyCostChip.gd"
48:     "res://scripts/ui/components/MoveEnergyCostRow.gd"
51:     "res://scripts/ui/components/KyokoroTriggerRow.gd"
54:     "res://scripts/ui/components/EnergyDiceIconSummary.gd"
57:     "res://scenes/ui/components/PlakoroPortrait.tscn"
60:     "res://scripts/loadout/AIBattleLoadoutProvider.gd"
63:     "res://scripts/loadout/AIBattleLoadoutValidator.gd"
66:     "res://scripts/content/ContentPlaytestBridgeService.gd"
69:     "res://scripts/ui/components/MovePresentationService.gd"
72:     "res://scripts/ui/components/KyokoroEffectPopup.gd"
75:     "res://scripts/dice/setup/EnergyDiceBuilderContextService.gd"
78:     "res://scripts/content/PokemonAuthoringService.gd"
81:     "res://scripts/content/MoveCardAuthoringService.gd"
84:     "res://scripts/runtime/BattleResolutionPresentationConfig.gd"
89:     "res://scenes/ui/BattleGameUI.tscn"
93:     "res://scenes/ui/PlakoroContentStudioUI.tscn"
97:     "res://scenes/ui/EnergyDiceVisualBuilderUI.tscn"
102:     "res://scenes/ui/MoveBuilderUI.tscn"
105:     "res://scripts/draft/MoveDraftProvider.gd"
244:     if not database.load_all():
335:     main.add_theme_constant_override(
450:             POKEMON_AUTHORING.load_by_id(
597:     var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
741:         POKEMON_AUTHORING.load_by_id(
779:                 MOVE_AUTHORING.load_by_id(
1050:     var fallback_detail: String = (
1091:         fallback_detail
1456:             POKEMON_AUTHORING.load_by_id(
```

### `scripts/ui/BattleGameUI.gd`

```text
10: 	"res://scripts/presentation/CharakoroBattleFeedbackService.gd"
15: 	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
18: 	"res://scripts/ui/theme/PlakoroUIStyle.gd"
23: 	"res://scripts/ui/responsive/ResponsiveUIService.gd"
26: 	"res://scripts/ui/responsive/UIResponsiveProfile.gd"
31: 	"res://scripts/database/JsonLoader.gd"
34: 	"res://scripts/team_builder/TeamBuilderService.gd"
37: 	"res://scripts/team_builder/StructuredEnergyDiceService.gd"
40: 	"res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
43: 	"res://scripts/analysis/MoveCoverageAnalyzer.gd"
46: 	"res://scripts/battle/BattleController.gd"
49: 	"res://scripts/battle/BattleRandomSeedService.gd"
52: 	"res://scripts/dice/DiceEngine.gd"
55: 	"res://scripts/ai/AITurnService.gd"
58: 	"res://scripts/battle/status/StatusResolver.gd"
61: 	"res://scripts/battle/special/SpecialKyokoroSequenceService.gd"
64: 	"res://scripts/battle/special/SpecialMoveSelectionService.gd"
67: 	"res://scripts/battle/special/SpecialOpponentEnerkoroService.gd"
70: 	"res://scripts/battle/EnergyResolver.gd"
73: 	"res://scripts/presentation/timeline/BattleTimelineBuilder.gd"
76: 	"res://scripts/presentation/BattleOutcomeFeedback.gd"
79: 	"res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
82: 	"res://scripts/loadout/RuntimePlayerLoadoutBuilder.gd"
85: 	"res://scripts/loadout/AIBattleLoadoutProvider.gd"
88: 	"res://scripts/loadout/RuntimeAILoadoutBuilder.gd"
91: 	"res://scripts/runtime/BattleLoadoutVerificationService.gd"
94: 	"res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
97: 	"res://scripts/runtime/BattleResourceRecoveryService.gd"
100: 	"res://scripts/ui/components/PlakoroMoveButton.gd"
103: 	"res://scripts/ui/components/EnergyDiceIconSummary.gd"
106: 	"res://scenes/ui/components/PlakoroPortrait.tscn"
109: 	"res://scripts/ui/components/BattleHPBarPresenter.gd"
112: 	"res://scenes/ui/BattlePreparationUI.tscn"
116: 	"res://scripts/ui/components/BattleMessagePresenter.gd"
119: 	"res://scripts/ui/components/BattleFloatingTextPresenter.gd"
122: 	"res://scripts/ui/components/BattleTurnBannerPresenter.gd"
125: 	"res://scripts/ui/components/BattleResultPresenter.gd"
128: 	"res://scripts/runtime/BattleResolutionPresentationConfig.gd"
131: 	"res://scripts/presentation/BattleResolutionStepQueueBuilder.gd"
300: 	if not database.load_all():
```