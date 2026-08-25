extends Control


const PLAKORO_THEME: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const PLAKORO_UI_STYLE: Script = preload(
    "res://scripts/ui/theme/PlakoroUIStyle.gd"
)


const RESPONSIVE_UI: Script = preload(
    "res://scripts/ui/responsive/ResponsiveUIService.gd"
)
const RESPONSIVE_PROFILE: Script = preload(
    "res://scripts/ui/responsive/UIResponsiveProfile.gd"
)


const PLAYER_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const PLAYER_LOADOUT_SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)
const PLAYER_LOADOUT_VALIDATOR: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutValidator.gd"
)
const MOVE_COVERAGE_ANALYZER: Script = preload(
    "res://scripts/analysis/MoveCoverageAnalyzer.gd"
)
const MOVE_BUILDER_ANALYSIS: Script = preload(
    "res://scripts/analysis/MoveBuilderAnalysisService.gd"
)
const LOADOUT_VERIFICATION: Script = preload(
    "res://scripts/runtime/BattleLoadoutVerificationService.gd"
)
const MOVE_EFFECT_PRESENTATION: Script = preload(
    "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)
const PLAKORO_MOVE_BUTTON: Script = preload(
    "res://scripts/ui/components/PlakoroMoveButton.gd"
)
const RESOURCE_RECOVERY: Script = preload(
    "res://scripts/runtime/BattleResourceRecoveryService.gd"
)
const ENERGY_COST_CHIP: Script = preload(
    "res://scripts/ui/components/EnergyCostChip.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostRow.gd"
)
const KYOKORO_TRIGGER_ROW: Script = preload(
    "res://scripts/ui/components/KyokoroTriggerRow.gd"
)
const DICE_ICON_SUMMARY: Script = preload(
    "res://scripts/ui/components/EnergyDiceIconSummary.gd"
)
const PLAKORO_PORTRAIT: PackedScene = preload(
    "res://scenes/ui/components/PlakoroPortrait.tscn"
)
const POKEMON_ATTRIBUTE_ICONS: Script = preload(
	"res://scripts/ui/components/PokemonAttributeIconDisplay.gd"
)
const AI_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutProvider.gd"
)
const AI_LOADOUT_VALIDATOR: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutValidator.gd"
)
const CONTENT_PLAYTEST: Script = preload(
    "res://scripts/content/ContentPlaytestBridgeService.gd"
)
const MOVE_PRESENTATION: Script = preload(
    "res://scripts/ui/components/MovePresentationService.gd"
)
const KYOKORO_EFFECT_POPUP: Script = preload(
    "res://scripts/ui/components/KyokoroEffectPopup.gd"
)
const DICE_BUILDER_CONTEXT: Script = preload(
    "res://scripts/dice/setup/EnergyDiceBuilderContextService.gd"
)
const ENERGY_DICE_SETUP_SAVE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const RESOLUTION_PRESENTATION_CONFIG: Script = preload(
    "res://scripts/runtime/BattleResolutionPresentationConfig.gd"
)


const ENERGY_DICE_BUILDER_SCENE_PATH: String = (
    "res://scenes/ui/EnergyDiceVisualBuilderUI.tscn"
)


const MOVE_BUILDER_SCENE_PATH: String = (
    "res://scenes/ui/MoveBuilderUI.tscn"
)
const MOVE_DRAFT_PROVIDER: Script = preload(
    "res://scripts/draft/MoveDraftProvider.gd"
)


@onready var database: Node = $Database
@onready var margin: MarginContainer = $Margin
@onready var main: VBoxContainer = $Margin/Main
@onready var content_scroll: ScrollContainer = $Margin/Main/ContentScroll
@onready var preparation_body: HSplitContainer = (
	$Margin/Main/ContentScroll/Content/Body
)
@onready var actions: HBoxContainer = $Margin/Main/Actions
@onready var pokemon_title: Label = $Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/PokemonPanel/PokemonBox/PokemonTitle
@onready var battle_ready_title: Label = $Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/BattleReadyPanel/BattleReadyBox/BattleReadyTitle
@onready var opponent_title: Label = $Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/BattleReadyPanel/BattleReadyBox/OpponentBox/OpponentInfoBox/OpponentTitle
@onready var resolution_mode_label: Label = $Margin/Main/ContentScroll/Content/Body/LeftColumn/TopSummaryRow/BattleReadyPanel/BattleReadyBox/ResolutionModeBox/ResolutionModeLabel
@onready var moves_title: Label = $Margin/Main/ContentScroll/Content/Body/LeftColumn/MovesPanel/MovesBox/MovesTitle
@onready var dice_title: Label = $Margin/Main/ContentScroll/Content/Body/RightColumn/DicePanel/DiceBox/DiceTitle
@onready var coverage_title: Label = $Margin/Main/ContentScroll/Content/Body/RightColumn/CoveragePanel/CoverageBox/CoverageTitle
@onready var move_coverage_title: Label = $Margin/Main/ContentScroll/Content/Body/RightColumn/CoveragePanel/CoverageBox/MoveCoverageTitle
@onready var setup_hint: Label = $BattleSetupDialog/SetupRoot/SetupHint
@onready var player_setup_title: Label = $BattleSetupDialog/SetupRoot/SetupColumns/PlayerSetupPanel/PlayerSetupBox/PlayerSetupTitle
@onready var player_move_hint: Label = $BattleSetupDialog/SetupRoot/SetupColumns/PlayerSetupPanel/PlayerSetupBox/PlayerMoveHeader/PlayerMoveHint
@onready var ai_setup_panel: PanelContainer = $BattleSetupDialog/SetupRoot/SetupColumns/AISetupPanel
@onready var ai_setup_title: Label = $BattleSetupDialog/SetupRoot/SetupColumns/AISetupPanel/AISetupBox/AISetupTitle
@onready var ai_move_hint: Label = $BattleSetupDialog/SetupRoot/SetupColumns/AISetupPanel/AISetupBox/AIMoveHeader/AIMoveHint
@onready var page_title: Label = $Margin/Main/Header/Title

@onready var loadout_id_label: Label = %LoadoutIdLabel
@onready var pokemon_name_label: Label = %PokemonNameLabel
@onready var pokemon_id_label: Label = %PokemonIdLabel
@onready var pokemon_type_label: HBoxContainer = %PokemonTypeLabel
@onready var pokemon_hp_label: Label = %PokemonHpLabel
@onready var pokemon_weakness_label: HBoxContainer = %PokemonWeaknessLabel
@onready var hero_plakoro_container: VBoxContainer = %HeroPlakoroContainer

@onready var move_container: GridContainer = %MoveContainer
@onready var dice_icon_summary_container: HBoxContainer = %DiceIconSummaryContainer
@onready var repeat_fixed_energy_toggle: CheckButton = %RepeatFixedEnergyToggle
@onready var coverage_summary_label: Label = %CoverageSummaryLabel
@onready var overall_rating_label: Label = %OverallRatingLabel
@onready var overall_probability_label: Label = %OverallProbabilityLabel
@onready var energy_usage_label: Label = %EnergyUsageLabel
@onready var energy_icon_container: HBoxContainer = %EnergyIconContainer
@onready var loadout_status_label: Label = %LoadoutStatusLabel
@onready var loadout_signature_label: Label = %LoadoutSignatureLabel
@onready var validation_label: Label = %ValidationLabel
@onready var resolution_mode_option: OptionButton = %ResolutionModeOption
@onready var move_draft_status_label: Label = %MoveDraftStatusLabel

@onready var opponent_name_label: Label = %OpponentNameLabel
@onready var opponent_loadout_label: Label = %OpponentLoadoutLabel
@onready var opponent_difficulty_label: Label = %OpponentDifficultyLabel
@onready var opponent_weakness_label: HBoxContainer = %OpponentWeaknessLabel
@onready var opponent_portrait_container: VBoxContainer = %OpponentPortraitContainer

@onready var refresh_button: Button = %RefreshButton
@onready var edit_dice_button: Button = %EditDiceButton
@onready var start_battle_button: Button = %StartBattleButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var content_studio_button: Button = %ContentStudioButton
@onready var configure_battle_button: Button = %ConfigureBattleButton
@onready var battle_setup_dialog: ConfirmationDialog = %BattleSetupDialog
@onready var setup_player_pokemon_option: OptionButton = %SetupPlayerPokemonOption
@onready var setup_ai_pokemon_option: OptionButton = %SetupAIPokemonOption
@onready var setup_ai_difficulty_option: OptionButton = %SetupAIDifficultyOption
@onready var setup_player_move_rows: VBoxContainer = %SetupPlayerMoveRows
@onready var setup_ai_move_rows: VBoxContainer = %SetupAIMoveRows
@onready var setup_player_move_count_label: Label = %SetupPlayerMoveCountLabel
@onready var setup_ai_move_count_label: Label = %SetupAIMoveCountLabel
@onready var setup_player_move_scroll: ScrollContainer = %SetupPlayerMoveScroll
@onready var setup_ai_move_scroll: ScrollContainer = %SetupAIMoveScroll
@onready var setup_status_label: Label = %SetupStatusLabel


var player_loadout_data: Variant = null
var ai_loadout_data: Variant = null

var setup_player_move_checks: Array[CheckBox] = []
var setup_ai_move_checks: Array[CheckBox] = []
var setup_move_hover_preview: PopupPanel = null
var setup_move_hover_panel: PanelContainer = null
var setup_move_hover_owner: Control = null
var setup_move_hover_candidate: Control = null
var setup_move_hover_request_serial: int = 0
var setup_move_hover_anchor_mouse_position: Vector2i = Vector2i.ZERO

const SETUP_MOVE_HOVER_DELAY_SECONDS: float = 1.0
const SETUP_MOVE_HOVER_DISMISS_DISTANCE: float = 72.0


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)

	LocalizationService.locale_changed.connect(
		_on_locale_changed
	)
	ContentStudioAccess.content_studio_unsealed.connect(
		_refresh_content_studio_access
	)
	_apply_localized_text()
	_refresh_content_studio_access()
	get_viewport().size_changed.connect(
		_apply_responsive_layout
	)
	_apply_responsive_layout()

	# The preparation content may be taller than the viewport after adding
	# Move effects and Dice previews. Keep navigation buttons in a fixed footer
	# and start the scrollable content at the top.
	content_scroll.scroll_vertical = 0

	refresh_button.pressed.connect(
		_reload_database_and_loadout
	)
	edit_dice_button.pressed.connect(
		_open_energy_dice_builder
	)
	start_battle_button.pressed.connect(
		_start_battle
	)
	main_menu_button.pressed.connect(
		GameFlow.open_main_menu
	)
	content_studio_button.pressed.connect(
		_open_content_studio
	)
	configure_battle_button.pressed.connect(
		_open_battle_setup
	)
	repeat_fixed_energy_toggle.visible = GameFlow.free_mode
	repeat_fixed_energy_toggle.button_pressed = (
		GameFlow.free_mode
		and GameFlow.free_mode_allow_repeated_fixed_energy
	)
	repeat_fixed_energy_toggle.toggled.connect(
		_on_repeat_fixed_energy_toggled
	)
	resolution_mode_option.item_selected.connect(
		_on_resolution_mode_selected
	)
	_populate_resolution_modes()
	battle_setup_dialog.confirmed.connect(
		_apply_battle_setup
	)
	setup_player_pokemon_option.item_selected.connect(
		func(_index: int) -> void:
			_rebuild_setup_moves(false)
	)
	setup_ai_pokemon_option.item_selected.connect(
		func(_index: int) -> void:
			_rebuild_setup_moves(
				true
			)
	)
	setup_player_move_scroll.gui_input.connect(
		_on_setup_move_scroll_input
	)
	setup_ai_move_scroll.gui_input.connect(
		_on_setup_move_scroll_input
	)

	if not database.load_all():
		validation_label.text = LocalizationService.tr_key(
			"preparation.database_load_failed",
            "Database load failed."
		)
		start_battle_button.disabled = true
		return

	_reload_loadout()



func _on_locale_changed(
	_locale: String
) -> void:
	_apply_localized_text()
	_populate_resolution_modes()

	if battle_setup_dialog.visible:
		var current_difficulty: String = ""
		if setup_ai_difficulty_option.item_count > 0:
			current_difficulty = String(
				setup_ai_difficulty_option.get_item_metadata(
					setup_ai_difficulty_option.selected
				)
			)

		_populate_setup_difficulties()
		_select_setup_difficulty(
			current_difficulty
		)
		_refresh_battle_setup_state()

	if player_loadout_data != null:
		_refresh_loadout_summary()
		_refresh_opponent_summary()
		_refresh_move_draft_status()
		_refresh_validation()


func _refresh_content_studio_access() -> void:
	content_studio_button.visible = ContentStudioAccess.is_unsealed()


func _apply_localized_text() -> void:
	page_title.text = LocalizationService.tr_key(
		"preparation.title",
        "Battle Preparation"
	)
	main_menu_button.text = LocalizationService.tr_key(
		"common.main_menu",
		"Main Menu"
	)
	content_studio_button.text = LocalizationService.tr_key(
		"preparation.content_studio",
        "Content Studio"
	)
	refresh_button.text = LocalizationService.tr_key(
		"preparation.refresh",
        "Refresh"
	)
	edit_dice_button.text = LocalizationService.tr_key(
		"preparation.edit_enerkoro",
        "Edit Enerkoro"
	)
	configure_battle_button.text = LocalizationService.tr_key(
		"preparation.configure_battle",
        "Configure Battle / Moves"
	)
	start_battle_button.text = LocalizationService.tr_key(
		"encounter_select.return"
		if GameFlow.collection_mode
		else "preparation.start_battle",
		"Return to Encounters"
		if GameFlow.collection_mode
		else "Start Battle"
	)

	pokemon_title.text = LocalizationService.tr_key(
		"preparation.pokemon",
        "Pokémon"
	)
	battle_ready_title.text = LocalizationService.tr_key(
		"preparation.battle_setup",
        "Battle Setup"
	)
	opponent_title.text = LocalizationService.tr_key(
		"preparation.opponent",
        "Opponent"
	)
	resolution_mode_label.text = LocalizationService.tr_key(
		"preparation.resolution",
        "Resolution"
	)
	moves_title.text = LocalizationService.tr_key(
		"preparation.selected_moves",
        "Selected Moves"
	)
	dice_title.text = LocalizationService.tr_key(
		"preparation.enerkoro",
        "Enerkoro"
	)
	repeat_fixed_energy_toggle.text = LocalizationService.tr_key(
		"preparation.allow_repeated_fixed_energy",
		"Allow repeated Fixed Energy"
	)
	coverage_title.text = LocalizationService.tr_key(
		"preparation.loadout_analysis",
        "Loadout Analysis"
	)
	move_coverage_title.text = LocalizationService.tr_key(
		"preparation.move_coverage",
        "Move Coverage"
	)

	battle_setup_dialog.title = LocalizationService.tr_key(
		"preparation.setup_dialog_title",
        "Battle Loadout Setup"
	)
	battle_setup_dialog.ok_button_text = LocalizationService.tr_key(
		"preparation.setup_apply",
        "Apply Battle Setup"
	)
	battle_setup_dialog.cancel_button_text = LocalizationService.tr_key(
		"common.cancel",
        "Cancel"
	)
	setup_hint.text = LocalizationService.tr_key(
		"preparation.setup_hint",
		"Choose your Pokémon and four Moves. Your current Enerkoro setup is used automatically. Opponent Loadout stays hidden until battle."
	)
	player_setup_title.text = LocalizationService.tr_key(
		"preparation.player",
        "Player"
	)
	player_move_hint.text = LocalizationService.tr_key(
		"preparation.select_four_moves",
        "Select 4 Moves"
	)
	ai_setup_title.text = LocalizationService.tr_key(
		"preparation.ai",
        "AI"
	)
	ai_move_hint.text = LocalizationService.tr_key(
		"preparation.select_four_moves",
        "Select 4 Moves"
	)



func _populate_resolution_modes() -> void:
	var selected_mode: String = ""
	if resolution_mode_option.item_count > 0:
		selected_mode = String(
			resolution_mode_option.get_item_metadata(
				resolution_mode_option.selected
			)
		)

	resolution_mode_option.clear()
	resolution_mode_option.add_item(
		LocalizationService.tr_key(
			"preparation.resolution.quick",
            "Quick - show final result"
		)
	)
	resolution_mode_option.set_item_metadata(
		0,
        "quick"
	)
	resolution_mode_option.add_item(
		LocalizationService.tr_key(
			"preparation.resolution.step",
            "Step-by-step - Move -> Effect -> Weakness"
		)
	)
	resolution_mode_option.set_item_metadata(
		1,
        "step_by_step"
	)
	if EncounterSession.has_active_encounter():
		resolution_mode_option.select(1)
		resolution_mode_option.disabled = true
		RESOLUTION_PRESENTATION_CONFIG.set_mode(&"step_by_step")
		return
	resolution_mode_option.disabled = false
	if selected_mode == "quick":
		resolution_mode_option.select(0)
	elif selected_mode == "step_by_step":
		resolution_mode_option.select(1)
	else:
		resolution_mode_option.select(
			1
			if RESOLUTION_PRESENTATION_CONFIG.is_step_by_step()
			else 0
		)


func _on_resolution_mode_selected(
	index: int
) -> void:
	RESOLUTION_PRESENTATION_CONFIG.set_mode(
		StringName(
			resolution_mode_option.get_item_metadata(
				index
			)
		)
	)


func _apply_responsive_layout() -> void:
	var profile: StringName = (
		RESPONSIVE_UI.get_profile(
			self
		)
	)

	RESPONSIVE_UI.apply_margin(
		margin,
		profile
	)

	main.add_theme_constant_override(
		"separation",
		RESPONSIVE_PROFILE.section_spacing(
			profile
		)
	)

	RESPONSIVE_UI.apply_action_row(
		actions,
		profile
	)

	RESPONSIVE_UI.apply_button(
		refresh_button,
		profile,
		132
	)
	RESPONSIVE_UI.apply_button(
		edit_dice_button,
		profile,
		165
	)
	RESPONSIVE_UI.apply_button(
		start_battle_button,
		profile,
		210
	)
	RESPONSIVE_UI.apply_button(
		content_studio_button,
		profile,
		150
	)
	RESPONSIVE_UI.apply_button(
		configure_battle_button,
		profile,
		160
	)

	RESPONSIVE_UI.apply_split(
		preparation_body,
		profile,
		get_viewport_rect().size.x,
		0.50
	)


func _open_battle_setup() -> void:
	if GameFlow.phone_mode:
		GameFlow.open_phone_battle_loadout()
		return
	_prepare_battle_setup_controls()

	var setup_dialog_size: Vector2i = Vector2i(1180, 720)
	if OS.has_feature("web"):
		# Give the Web loadout editor more room for a permanently visible
		# scrollbar and a taller Move viewport. itch.io fullscreen is the
		# primary target, so this intentionally stays desktop-oriented.
		setup_dialog_size = Vector2i(1380, 840)
		battle_setup_dialog.min_size = setup_dialog_size
		battle_setup_dialog.max_size = setup_dialog_size
	battle_setup_dialog.popup_centered(setup_dialog_size)


func _prepare_battle_setup_controls() -> void:
	_clear_setup_move_hover_preview()
	_configure_setup_dialog_for_mode()
	_populate_setup_pokemon_options()
	_populate_setup_difficulties()

	_select_setup_pokemon(
		setup_player_pokemon_option,
		String(
			player_loadout_data.pokemon_id
		)
		if player_loadout_data != null
		else ""
	)
	_select_setup_pokemon(
		setup_ai_pokemon_option,
		String(
			ai_loadout_data.pokemon_id
		)
		if ai_loadout_data != null
		else ""
	)

	_rebuild_setup_moves(
		false
	)
	_rebuild_setup_moves(
		true
	)

	setup_player_move_scroll.scroll_vertical = 0
	setup_ai_move_scroll.scroll_vertical = 0

	if ai_loadout_data != null:
		_select_setup_difficulty(
			String(
				ai_loadout_data.difficulty
			)
		)

	_refresh_battle_setup_state()
	_apply_encounter_setup_lock()

func _configure_setup_dialog_for_mode() -> void:
	var configure_opponent: bool = GameFlow.free_mode
	ai_setup_panel.visible = configure_opponent
	# Let the dialog columns determine width. Keep a bounded vertical viewport
	# so the Move list scrolls instead of expanding the dialog content.
	setup_player_move_scroll.custom_minimum_size.x = 0.0
	setup_ai_move_scroll.custom_minimum_size.x = 0.0
	var move_viewport_height: float = 300.0
	if OS.has_feature("web"):
		move_viewport_height = 390.0
		setup_player_move_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		setup_ai_move_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	setup_player_move_scroll.custom_minimum_size.y = move_viewport_height
	setup_ai_move_scroll.custom_minimum_size.y = move_viewport_height
	setup_hint.text = LocalizationService.tr_key(
		"preparation.setup_hint_free"
		if configure_opponent
		else "preparation.setup_hint",
		"Choose both Pokémon, their four Moves, and AI difficulty. "
		+ "Each Pokémon automatically uses its own Default Enerkoro."
		if configure_opponent
		else "Choose your Pokémon and four Moves. Your current "
		+ "Enerkoro setup is used automatically. Opponent Loadout "
		+ "stays hidden until battle."
	)


func _apply_encounter_setup_lock() -> void:
	var locked: bool = (
		EncounterSession.has_active_encounter()
		or GameFlow.collection_mode
	)
	setup_ai_pokemon_option.disabled = locked
	setup_ai_difficulty_option.disabled = locked
	for check: CheckBox in setup_ai_move_checks:
		check.disabled = locked


func _populate_setup_pokemon_options() -> void:
	setup_player_pokemon_option.clear()
	setup_ai_pokemon_option.clear()
	var progress: Variant = PlayerProgress.get_progress()
	var collection_active: bool = (
		progress.has_profile()
		and not GameFlow.free_mode
	)

	for pokemon_id: String in (
		POKEMON_AUTHORING.list_saved()
	):
		var pokemon: Dictionary = (
			POKEMON_AUTHORING.load_by_id(
				pokemon_id
			)
		)

		if pokemon.is_empty():
			continue

		var candidate_info: Array[Dictionary] = (
			CONTENT_PLAYTEST.list_playtest_opponents()
		)
		var playable: bool = false
		var reason: String = ""

		for candidate: Dictionary in candidate_info:
			if String(
				candidate.get(
					"pokemon_id",
                    ""
				)
			) == pokemon_id:
				playable = bool(
					candidate.get(
						"playable",
						false
					)
				)
				reason = String(
					candidate.get(
						"reason",
                        ""
					)
				)
				break

		var species_id: String = String(
			pokemon.get(
				"species_id",
				pokemon_id
			)
		)
		var localized_pokemon_name: String = (
			GameContentLocalizationService.text(
				"pokemon",
				species_id,
				"name",
				String(
					pokemon.get(
						"display_name",
						pokemon_id
					)
				)
			)
		)
		var display_text: String = LocalizationService.tr_format(
			"preparation.pokemon_option",
			{
				"name": localized_pokemon_name,
				"id": pokemon_id
			},
            "{name}  [{id}]"
		)

		for option: OptionButton in [
			setup_player_pokemon_option,
			setup_ai_pokemon_option
		]:
			var collection_locked: bool = (
				option == setup_player_pokemon_option
				and collection_active
				and not progress.unlocked_pokemon_ids.has(pokemon_id)
			)
			var index: int = option.item_count
			var option_text: String = display_text
			if option == setup_player_pokemon_option and collection_active:
				option_text += LocalizationService.tr_format(
					"preparation.pokemon_level",
					{"level": int(progress.pokemon_levels.get(pokemon_id, 1))},
					"   |   LV{level}"
				)
			option.add_item(option_text)
			option.set_item_metadata(
				index,
				pokemon_id
			)
			option.set_item_disabled(
				index,
				not playable or collection_locked
			)
			option.set_item_tooltip(
				index,
				(
					LocalizationService.tr_key(
						"preparation.ready_for_battle",
                        "Ready for battle."
					)
					if playable and not collection_locked
					else (
						LocalizationService.tr_key(
							"preparation.collection_locked",
							"Defeat this Plakoro to unlock it."
						)
						if collection_locked
						else reason
					)
				)
			)

	_select_first_enabled(
		setup_player_pokemon_option
	)
	_select_first_enabled(
		setup_ai_pokemon_option
	)


func _populate_setup_difficulties() -> void:
	setup_ai_difficulty_option.clear()

	for difficulty: String in [
		"easy",
		"normal",
        "hard"
	]:
		setup_ai_difficulty_option.add_item(
			LocalizationService.tr_key(
				"preparation.difficulty." + difficulty,
				difficulty.capitalize()
			)
		)
		setup_ai_difficulty_option.set_item_metadata(
			setup_ai_difficulty_option.item_count - 1,
			difficulty
		)

	setup_ai_difficulty_option.select(
		2
	)


func _select_first_enabled(
	option: OptionButton
) -> void:
	for index: int in range(
		option.item_count
	):
		if not option.is_item_disabled(
			index
		):
			option.select(
				index
			)
			return


func _select_setup_pokemon(
	option: OptionButton,
	pokemon_id: String
) -> void:
	for index: int in range(
		option.item_count
	):
		if (
			String(
				option.get_item_metadata(
					index
				)
			)
			== pokemon_id
			and not option.is_item_disabled(
				index
			)
		):
			option.select(
				index
			)
			return


func _select_setup_difficulty(
	difficulty: String
) -> void:
	for index: int in range(
		setup_ai_difficulty_option.item_count
	):
		if String(
			setup_ai_difficulty_option.get_item_metadata(
				index
			)
		) == difficulty:
			setup_ai_difficulty_option.select(
				index
			)
			return


func _selected_setup_pokemon_id(
	option: OptionButton
) -> String:
	if option.item_count == 0:
		return ""

	var index: int = option.selected

	if (
		index < 0
		or option.is_item_disabled(
			index
		)
	):
		return ""

	return String(
		option.get_item_metadata(
			index
		)
	)


func _rebuild_setup_moves(
	for_ai: bool
) -> void:
	_clear_setup_move_hover_preview()

	var option: OptionButton = (
		setup_ai_pokemon_option
		if for_ai
		else setup_player_pokemon_option
	)
	var rows: VBoxContainer = (
		setup_ai_move_rows
		if for_ai
		else setup_player_move_rows
	)
	var checks: Array[CheckBox] = (
		setup_ai_move_checks
		if for_ai
		else setup_player_move_checks
	)

	for child: Node in rows.get_children():
		child.queue_free()

	checks.clear()

	var pokemon_id: String = (
		_selected_setup_pokemon_id(
			option
		)
	)

	if pokemon_id.is_empty():
		_refresh_battle_setup_state()
		return

	var pokemon: Dictionary = (
		POKEMON_AUTHORING.load_by_id(
			pokemon_id
		)
	)
	var raw_moves: Variant = pokemon.get(
		"available_move_card_ids",
		[]
	)

	var current_ids: Array[StringName] = []

	if for_ai and ai_loadout_data != null:
		current_ids = (
			ai_loadout_data.move_card_ids
		)
	elif (
		not for_ai
		and player_loadout_data != null
	):
		current_ids = (
			player_loadout_data.move_card_ids
		)

	var default_names: Dictionary = {}
	var default_count: int = 0

	if raw_moves is Array:
		for raw_move_id: Variant in (
			raw_moves as Array
		):
			var move_id: String = String(
				raw_move_id
			).strip_edges()

			if move_id.is_empty():
				continue
			if (
				not for_ai
				and PlayerProgress.has_profile()
				and not GameFlow.free_mode
				and not PlayerProgress.get_progress().unlocked_move_card_ids.has(move_id)
			):
				continue

			var move_data: Dictionary = (
				MOVE_AUTHORING.load_by_id(
					move_id
				)
			)

			if move_data.is_empty():
				continue

			var display_name: String = String(
				move_data.get(
					"display_name",
					move_id
				)
			)
			var move_name_id: String = String(
				move_data.get(
					"move_name_id",
					move_id
				)
			).strip_edges()

			var check: CheckBox = CheckBox.new()
			var localized_move_name: String = (
				GameContentLocalizationService.text(
					"move",
					move_name_id,
					"name",
					display_name
				)
			)
			check.text = (
				localized_move_name
				if GameFlow.phone_mode
				else LocalizationService.tr_format(
					"preparation.move_option",
					{
						"name": localized_move_name,
						"id": move_id
					},
					"{name}  [{id}]"
				)
			)
			check.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			check.set_meta(
				"move_id",
				move_id
			)
			check.set_meta(
				"move_name_id",
				move_name_id
			)
			check.tooltip_text = ""

			var should_select: bool = false

			if current_ids.has(
				StringName(
					move_id
				)
			):
				should_select = true
			elif (
				current_ids.is_empty()
				and default_count < 4
				and not default_names.has(
					move_name_id
				)
			):
				should_select = true

			if (
				should_select
				and not default_names.has(
					move_name_id
				)
				and default_count < 4
			):
				check.button_pressed = true
				default_names[
					move_name_id
				] = true
				default_count += 1

			check.toggled.connect(
				func(_pressed: bool) -> void:
					_refresh_battle_setup_state()
			)
			check.mouse_filter = (
				Control.MOUSE_FILTER_PASS
			)

			rows.add_child(
				_build_inline_setup_move_card(check, move_id, move_data)
			)
			checks.append(
				check
			)

	_refresh_battle_setup_state()


func _build_inline_setup_move_card(
	check: CheckBox,
	move_id: String,
	_move_data: Dictionary
) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Non-interactive card chrome must not swallow wheel/touch scrolling.
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(check)

	var move_card: Variant = database.get_move_card(StringName(move_id))
	if move_card == null:
		return panel

	var stats: HBoxContainer = HBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_constant_override("separation", 12)
	box.add_child(stats)
	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.set_script(MOVE_ENERGY_COST_ROW)
	cost_row.setup(move_card, 20)
	stats.add_child(cost_row)
	var damage: Label = Label.new()
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.text = "DMG " + _format_damage(move_card)
	damage.modulate.a = 0.88
	stats.add_child(damage)

	var details_box: VBoxContainer = VBoxContainer.new()
	details_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_box.add_theme_constant_override("separation", 5)
	box.add_child(details_box)
	var has_details: bool = false
	var preview: Dictionary = MOVE_EFFECT_PRESENTATION.build_preview(move_card)
	var move_effect_lines: Array = preview.get("move_effect_lines", [])
	for move_effect_index: int in range(move_effect_lines.size()):
		var move_effect_text: String = (
			GameContentLocalizationService.localize_move_effect_text(
				move_card,
				move_effect_index,
				String(move_effect_lines[move_effect_index])
			)
		).strip_edges()
		if not move_effect_text.is_empty():
			var move_effect_label: Label = Label.new()
			move_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			move_effect_label.text = move_effect_text
			move_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			move_effect_label.modulate.a = 0.78
			details_box.add_child(move_effect_label)
			has_details = true
	var groups: Array = preview.get("trigger_groups", [])
	for group_index: int in range(groups.size()):
		var raw_group: Variant = groups[group_index]
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		var orientations: Array[StringName] = []
		for raw_orientation: Variant in group.get("orientations", []):
			orientations.append(StringName(raw_orientation))
		var effect_text: String = (
			GameContentLocalizationService.localize_effect_text(
				move_card,
				group_index,
				String(group.get("effect_text", ""))
			)
			)
		var effect_row: HBoxContainer = HBoxContainer.new()
		effect_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_row.add_theme_constant_override("separation", 8)
		details_box.add_child(effect_row)
		if not orientations.is_empty():
			var trigger_row: HBoxContainer = HBoxContainer.new()
			trigger_row.set_script(KYOKORO_TRIGGER_ROW)
			trigger_row.setup(orientations, 24)
			effect_row.add_child(trigger_row)
		var effect_label: Label = Label.new()
		effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effect_label.text = effect_text
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.modulate.a = 0.78
		effect_row.add_child(effect_label)
		has_details = true
	if not has_details:
		var description: String = (
			GameContentLocalizationService.localize_move_description(move_card)
		).strip_edges()
		var fallback_label: Label = Label.new()
		fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback_label.text = (
			description
			if not description.is_empty()
			else String(preview.get("summary", "-"))
		)
		fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback_label.modulate.a = 0.78
		details_box.add_child(fallback_label)
	return panel


func _process(
	_delta: float
) -> void:
	if (
		setup_move_hover_preview == null
		or not is_instance_valid(
			setup_move_hover_preview
		)
		or not setup_move_hover_preview.visible
	):
		return

	var current_mouse_position: Vector2i = (
		DisplayServer.mouse_get_position()
	)

	if (
		Vector2(
			current_mouse_position
			- setup_move_hover_anchor_mouse_position
		).length()
		>= SETUP_MOVE_HOVER_DISMISS_DISTANCE
	):
		_clear_setup_move_hover_preview()


func _input(
	event: InputEvent
) -> void:
	# Web browsers can deliver wheel/touch events to CheckBox/Label children
	# instead of the ScrollContainer. Forward them explicitly while the
	# Configure Battle dialog is open.
	if OS.has_feature("web") and battle_setup_dialog.visible:
		if _forward_web_setup_move_scroll(event):
			get_viewport().set_input_as_handled()
			return

	if (
		setup_move_hover_preview == null
		or not is_instance_valid(
			setup_move_hover_preview
		)
		or not setup_move_hover_preview.visible
	):
		return

	if (
		event is InputEventMouseButton
		and (
			event as InputEventMouseButton
		).pressed
	):
		_clear_setup_move_hover_preview()


func _forward_web_setup_move_scroll(event: InputEvent) -> bool:
	var pointer_position: Vector2 = Vector2.ZERO
	var delta_y: float = 0.0

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return false
		pointer_position = mouse_event.position
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			delta_y = -72.0 * max(mouse_event.factor, 1.0)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			delta_y = 72.0 * max(mouse_event.factor, 1.0)
		else:
			return false
	elif event is InputEventPanGesture:
		# Let Godot's ScrollContainer handle touch/trackpad panning natively.
		# Manual forwarding here caused the same gesture to be applied twice on Web
		# (and the old 48x multiplier made it extremely sensitive).
		return false
	elif event is InputEventScreenDrag:
		# Native ScrollContainer drag already tracks the finger 1:1.
		# Do not manually change scroll_vertical as that doubles movement.
		return false
	else:
		return false

	var target_scroll: ScrollContainer = null
	if (
		setup_player_move_scroll.visible
		and setup_player_move_scroll.get_global_rect().has_point(pointer_position)
	):
		target_scroll = setup_player_move_scroll
	elif (
		setup_ai_move_scroll.visible
		and setup_ai_move_scroll.get_global_rect().has_point(pointer_position)
	):
		target_scroll = setup_ai_move_scroll

	if target_scroll == null:
		return false

	var bar: VScrollBar = target_scroll.get_v_scroll_bar()
	if bar == null or bar.max_value <= bar.page:
		return false

	target_scroll.scroll_vertical = int(clamp(
		float(target_scroll.scroll_vertical) + delta_y,
		0.0,
		max(0.0, bar.max_value - bar.page)
	))
	return true


func _on_setup_move_scroll_input(
	event: InputEvent
) -> void:
	if (
		setup_move_hover_preview == null
		or not is_instance_valid(
			setup_move_hover_preview
		)
		or not setup_move_hover_preview.visible
	):
		return

	if event is InputEventPanGesture:
		_clear_setup_move_hover_preview()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)

		if (
			mouse_event.pressed
			and (
				mouse_event.button_index
				== MOUSE_BUTTON_WHEEL_UP
				or mouse_event.button_index
				== MOUSE_BUTTON_WHEEL_DOWN
				or mouse_event.button_index
				== MOUSE_BUTTON_WHEEL_LEFT
				or mouse_event.button_index
				== MOUSE_BUTTON_WHEEL_RIGHT
			)
		):
			_clear_setup_move_hover_preview()




func _request_setup_move_hover_preview(
	owner: Control,
	move_id: String,
	move_data: Dictionary
) -> void:
	if OS.has_feature("web"):
		_clear_setup_move_hover_preview()
		return
	setup_move_hover_request_serial += 1
	var request_serial: int = (
		setup_move_hover_request_serial
	)
	setup_move_hover_candidate = owner

	await get_tree().create_timer(
		SETUP_MOVE_HOVER_DELAY_SECONDS
	).timeout

	if (
		request_serial
		!= setup_move_hover_request_serial
		or setup_move_hover_candidate != owner
		or owner == null
		or not is_instance_valid(
			owner
		)
	):
		return

	setup_move_hover_candidate = null

	_show_setup_move_hover_preview(
		owner,
		move_id,
		move_data
	)


func _cancel_setup_move_hover_request(
	owner: Control
) -> void:
	if setup_move_hover_candidate != owner:
		return

	setup_move_hover_candidate = null
	setup_move_hover_request_serial += 1


func _show_setup_move_hover_preview(
	owner: Control,
	move_id: String,
	move_data: Dictionary
) -> void:
	_clear_setup_move_hover_preview()
	if OS.has_feature("web"):
		return

	if owner == null or move_data.is_empty():
		return

	var effect_preview: Dictionary = (
		MOVE_EFFECT_PRESENTATION.build_preview(
			move_data
		)
	)
	var move_name_id: String = String(
		move_data.get(
			"move_name_id",
			move_id
		)
	)
	var localized_move_data: Dictionary = move_data.duplicate(
		true
	)
	localized_move_data["display_name"] = (
		GameContentLocalizationService.text(
			"move",
			move_name_id,
			"name",
			String(
				move_data.get(
					"display_name",
					move_id
				)
			)
		)
	)
	if localized_move_data.has("attack_type"):
		localized_move_data["attack_type"] = (
			GameContentLocalizationService.localize_type(
				localized_move_data["attack_type"]
			)
		)

	var localized_description: String = (
		GameContentLocalizationService.text(
			"move_card",
			move_id,
			"description",
			GameContentLocalizationService.text(
				"move",
				move_name_id,
				"description",
                ""
			)
		)
	)

	var trigger_groups: Array = []
	var raw_trigger_groups: Array = effect_preview.get(
		"trigger_groups",
		[]
	)
	for index: int in range(raw_trigger_groups.size()):
		var raw_group: Variant = raw_trigger_groups[index]
		if not raw_group is Dictionary:
			continue
		var localized_group: Dictionary = (
			raw_group as Dictionary
		).duplicate(true)
		localized_group["effect_text"] = (
			GameContentLocalizationService.text(
				"move_card",
				move_id,
				"effect_" + str(index),
				GameContentLocalizationService.text(
					"move",
					move_name_id,
					"effect_" + str(index),
					String(localized_group.get("effect_text", ""))
				)
			)
		)
		trigger_groups.append(
			localized_group
		)

	if not localized_description.is_empty():
		var localized_source: Dictionary = (
			localized_move_data.get(
				"source",
				{}
			) as Dictionary
		).duplicate(true)
		localized_source["move_effect_text"] = [
			localized_description
		]
		localized_move_data["source"] = localized_source

	var fallback_detail: String = localized_description
	if fallback_detail.is_empty():
		fallback_detail = MOVE_PRESENTATION.build_tooltip(
			move_id,
			move_data
		)

	var popup_window: PopupPanel = PopupPanel.new()
	popup_window.name = "BattleMoveHoverPopup"
	popup_window.exclusive = false
	popup_window.transient = true
	popup_window.transparent_bg = true
	popup_window.unresizable = true
	popup_window.borderless = true
	popup_window.size = Vector2i(
		440,
		360
	)

	var preview: PanelContainer = PanelContainer.new()
	preview.set_script(
		KYOKORO_EFFECT_POPUP
	)
	preview.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	preview.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	popup_window.add_child(
		preview
	)
	battle_setup_dialog.add_child(
		popup_window
	)

	preview.setup_move(
		move_id,
		localized_move_data,
		trigger_groups,
		fallback_detail
	)

	setup_move_hover_preview = popup_window
	setup_move_hover_panel = preview
	setup_move_hover_owner = owner

	# The hidden subwindow is already in the scene tree, so its content can
	# resolve minimum sizes without calling popup() first.
	await get_tree().process_frame
	await get_tree().process_frame

	if (
		setup_move_hover_preview != popup_window
		or not is_instance_valid(
			popup_window
		)
		or not is_instance_valid(
			preview
		)
		or not is_instance_valid(
			owner
		)
	):
		return

	var maximum_preview_height: float = clamp(
		get_viewport_rect().size.y * 0.62,
		300.0,
		560.0
	)

	if preview.has_method(
        "clamp_to_dialog_height"
	):
		preview.clamp_to_dialog_height(
			maximum_preview_height
		)

	# Apply the measured size and final position BEFORE making the native
	# PopupPanel visible. No await is allowed between popup visibility and
	# this positioning call, preventing a freed-instance race.
	var measured_size: Vector2 = (
		preview.get_combined_minimum_size()
	)
	measured_size.x = clamp(
		measured_size.x,
		400.0,
		500.0
	)
	measured_size.y = clamp(
		measured_size.y,
		180.0,
		maximum_preview_height
	)

	popup_window.size = Vector2i(
		int(
			ceil(
				measured_size.x
			)
		),
		int(
			ceil(
				measured_size.y
			)
		)
	)
	preview.custom_minimum_size = measured_size

	_position_setup_move_hover_preview(
		owner,
		popup_window,
		preview
	)

	if not is_instance_valid(
		popup_window
	):
		return

	setup_move_hover_anchor_mouse_position = (
		DisplayServer.mouse_get_position()
	)
	popup_window.show()


func _position_setup_move_hover_preview(
	owner: Control,
	popup_window: Variant,
	preview: Control
) -> void:
	if (
		owner == null
		or preview == null
		or popup_window == null
		or not is_instance_valid(
			owner
		)
		or not is_instance_valid(
			preview
		)
		or not is_instance_valid(
			popup_window
		)
		or not popup_window is PopupPanel
	):
		return

	var popup: PopupPanel = (
		popup_window as PopupPanel
	)

	var owner_rect: Rect2 = (
		owner.get_global_rect()
	)
	var preview_size: Vector2 = Vector2(
		popup.size
	)
	var viewport_rect: Rect2 = (
		get_viewport_rect()
	)

	preview_size.x = clamp(
		preview_size.x,
		400.0,
		500.0
	)
	preview_size.y = max(
		preview_size.y,
		180.0
	)

	var margin_value: float = 16.0
	var left_bound: float = (
		viewport_rect.position.x
		+ margin_value
	)
	var right_bound: float = (
		viewport_rect.end.x
		- margin_value
	)
	var top_bound: float = (
		viewport_rect.position.y
		+ margin_value
	)
	var bottom_bound: float = (
		viewport_rect.end.y
		- margin_value
	)

	var desired: Vector2 = Vector2(
		owner_rect.end.x + 12.0,
		owner_rect.position.y
	)

	if (
		desired.x + preview_size.x
		> right_bound
	):
		desired.x = (
			owner_rect.position.x
			- preview_size.x
			- 12.0
		)

	desired.x = clamp(
		desired.x,
		left_bound,
		max(
			left_bound,
			right_bound - preview_size.x
		)
	)

	if (
		desired.y + preview_size.y
		> bottom_bound
	):
		desired.y = (
			bottom_bound
			- preview_size.y
		)

	desired.y = clamp(
		desired.y,
		top_bound,
		max(
			top_bound,
			bottom_bound - preview_size.y
		)
	)

	popup.position = Vector2i(
		int(
			round(
				desired.x
			)
		),
		int(
			round(
				desired.y
			)
		)
	)
	popup.size = Vector2i(
		int(
			ceil(
				preview_size.x
			)
		),
		int(
			ceil(
				preview_size.y
			)
		)
	)


func _hide_setup_move_hover_preview(
	owner: Control
) -> void:
	if owner != setup_move_hover_owner:
		return

	_clear_setup_move_hover_preview()


func _clear_setup_move_hover_preview() -> void:
	setup_move_hover_request_serial += 1
	setup_move_hover_candidate = null
	setup_move_hover_owner = null
	setup_move_hover_panel = null
	setup_move_hover_anchor_mouse_position = Vector2i.ZERO

	if (
		setup_move_hover_preview != null
		and is_instance_valid(
			setup_move_hover_preview
		)
	):
		setup_move_hover_preview.hide()
		setup_move_hover_preview.queue_free()

	setup_move_hover_preview = null


func _refresh_setup_side(
	checks: Array[CheckBox]
) -> int:
	var selected_count: int = 0
	var selected_names: Dictionary = {}

	for check: CheckBox in checks:
		if check.button_pressed:
			selected_count += 1
			selected_names[
				String(
					check.get_meta(
						"move_name_id",
                        ""
					)
				)
			] = true

	for check: CheckBox in checks:
		var move_name_id: String = String(
			check.get_meta(
				"move_name_id",
                ""
			)
		)

		if check.button_pressed:
			check.disabled = false
			check.modulate.a = 1.0
			check.set_meta(
				"availability_note",
                ""
			)
			check.tooltip_text = ""
			continue

		var same_name_selected: bool = (
			selected_names.has(
				move_name_id
			)
		)
		var selection_full: bool = (
			selected_count >= 4
		)

		check.disabled = (
			selection_full
			or same_name_selected
		)

		if same_name_selected:
			check.set_meta(
				"availability_note",
				LocalizationService.tr_key(
					"preparation.move_unavailable_same_name",
                    "Unavailable: another Move with the same move_name_id is already selected."
				)
			)
			check.modulate.a = 0.45
		elif selection_full:
			check.set_meta(
				"availability_note",
				LocalizationService.tr_key(
					"preparation.move_unavailable_full",
                    "Unavailable: four Moves are already selected."
				)
			)
			check.modulate.a = 0.60
		else:
			check.set_meta(
				"availability_note",
                ""
			)
			check.modulate.a = 1.0

		check.tooltip_text = ""

	return selected_count


func _refresh_battle_setup_state() -> void:
	var player_count: int = (
		_refresh_setup_side(
			setup_player_move_checks
		)
	)
	var ai_count: int = (
		_refresh_setup_side(
			setup_ai_move_checks
		)
	)

	var player_id: String = (
		_selected_setup_pokemon_id(
			setup_player_pokemon_option
		)
	)
	var ai_id: String = (
		_selected_setup_pokemon_id(
			setup_ai_pokemon_option
		)
	)

	setup_player_move_count_label.text = LocalizationService.tr_format(
		"preparation.move_count",
		{"count": player_count},
        "{count} / 4"
	)
	setup_ai_move_count_label.text = LocalizationService.tr_format(
		"preparation.move_count",
		{"count": ai_count},
        "{count} / 4"
	)

	var dice_ready: bool = CONTENT_PLAYTEST.has_player_custom_dice()
	if GameFlow.free_mode and not player_id.is_empty():
		var selected_player_pokemon: Dictionary = (
			POKEMON_AUTHORING.load_by_id(player_id)
		)
		dice_ready = CONTENT_PLAYTEST.has_pokemon_default_dice(
			selected_player_pokemon
		)

	var ready: bool = (
		not player_id.is_empty()
		and not ai_id.is_empty()
		and player_count == 4
		and ai_count == 4
		and dice_ready
	)

	if ready:
		setup_status_label.text = (
			LocalizationService.tr_key(
				"preparation.ready_free_setup"
				if GameFlow.free_mode
				else "preparation.ready_player_setup",
				"READY - Player and opponent Loadouts are valid."
				if GameFlow.free_mode
				else "READY - Player Loadout is valid. Opponent Loadout is hidden."
			)
			+ (
				LocalizationService.tr_key(
					"preparation.same_pokemon_allowed",
                    " Same Pokémon battle allowed."
				)
				if player_id == ai_id
				else ""
			)
		)
	elif not dice_ready:
		setup_status_label.text = (
			LocalizationService.tr_key(
				"preparation.not_ready_dice",
                "NOT READY - Selected Player Enerkoro source is unavailable."
			)
		)
	else:
		setup_status_label.text = (
			LocalizationService.tr_format(
				"preparation.not_ready_player_count",
				{"player": player_count},
				"NOT READY - Player {player}/4 Moves"
			)
			if player_count != 4
			else LocalizationService.tr_key(
				"preparation.opponent_setup_unavailable",
				"Opponent setup is unavailable."
			)
		)

	var ok_button: Button = (
		battle_setup_dialog.get_ok_button()
	)

	if ok_button != null:
		ok_button.disabled = not ready

	_apply_encounter_setup_lock()


func _collect_setup_move_ids(
	checks: Array[CheckBox]
) -> Array[String]:
	var result: Array[String] = []

	for check: CheckBox in checks:
		if check.button_pressed:
			result.append(
				String(
					check.get_meta(
						"move_id",
                        ""
					)
				)
			)

	return result


func _apply_battle_setup() -> bool:
	_clear_setup_move_hover_preview()

	var player_id: String = (
		_selected_setup_pokemon_id(
			setup_player_pokemon_option
		)
	)
	var ai_id: String = (
		_selected_setup_pokemon_id(
			setup_ai_pokemon_option
		)
	)
	var player_moves: Array[String] = (
		_collect_setup_move_ids(
			setup_player_move_checks
		)
	)
	var ai_moves: Array[String] = (
		_collect_setup_move_ids(
			setup_ai_move_checks
		)
	)

	if (
		player_id.is_empty()
		or ai_id.is_empty()
		or player_moves.size() != 4
		or ai_moves.size() != 4
	):
		validation_label.text = (
			LocalizationService.tr_key("preparation.setup_incomplete", "Battle Setup is incomplete.")
		)
		return false

	var player_pokemon: Dictionary = (
		POKEMON_AUTHORING.load_by_id(
			player_id
		)
	)

	var player_dice_source: String = (
		"pokemon_default"
		if GameFlow.free_mode
		else "player_custom"
	)
	var player_result: Dictionary = (
		CONTENT_PLAYTEST.create_playtest_loadout(
			player_pokemon,
			player_moves,
			player_dice_source
		)
	)

	if not bool(
		player_result.get(
			"success",
			false
		)
	):
		validation_label.text = LocalizationService.tr_format(
			"preparation.player_setup_failed",
			{
				"errors": "\n".join(
					player_result.get(
						"errors",
						[]
					)
				)
			},
            "Player setup failed:\n{errors}"
		)
		return false

	var difficulty: StringName = StringName(
		setup_ai_difficulty_option.get_item_metadata(
			setup_ai_difficulty_option.selected
		)
	)

	var ai_result: Dictionary = {"success": true}
	if (
		not EncounterSession.has_active_encounter()
		and not GameFlow.collection_mode
	):
		ai_result = CONTENT_PLAYTEST.create_playtest_opponent_loadout(
			ai_id,
			difficulty,
			ai_moves
		)

	if not bool(
		ai_result.get(
			"success",
			false
		)
	):
		validation_label.text = LocalizationService.tr_format(
			"preparation.ai_setup_failed",
			{
				"errors": "\n".join(
					ai_result.get(
						"errors",
						[]
					)
				)
			},
            "AI setup failed:\n{errors}"
		)
		return false

	_reload_loadout()

	validation_label.text = LocalizationService.tr_key(
		"preparation.setup_applied",
        "Battle setup applied successfully. Review the summary or start the battle."
	)
	return true


func _reload_database_and_loadout() -> void:
	if database == null:
		validation_label.text = (
			LocalizationService.tr_key("preparation.database_unavailable", "Database service is unavailable.")
		)
		start_battle_button.disabled = true
		return

	if not database.load_all():
		validation_label.text = LocalizationService.tr_key(
			"preparation.database_reload_failed",
            "Database reload failed. Check recently edited JSON files."
		)
		start_battle_button.disabled = true
		return

	_reload_loadout()


func _reload_loadout() -> void:
	player_loadout_data = (
		PLAYER_LOADOUT_PROVIDER.load_player_loadout()
	)
	ai_loadout_data = (
		AI_LOADOUT_PROVIDER.load_ai_loadout()
	)

	if player_loadout_data == null:
		validation_label.text = (
			LocalizationService.tr_key("preparation.player_loadout_failed", "Player loadout could not be loaded.")
		)
		start_battle_button.disabled = true
		return

	if ai_loadout_data == null:
		validation_label.text = (
			LocalizationService.tr_key("preparation.ai_loadout_failed", "AI loadout could not be loaded.")
		)
		start_battle_button.disabled = true
		return

	if GameFlow.free_mode and not _ensure_free_mode_custom_dice():
		validation_label.text = LocalizationService.tr_key(
			"preparation.free_dice_init_failed",
			"Free Mode could not prepare an editable Enerkoro setup."
		)
		start_battle_button.disabled = true
		return

	_refresh_loadout_summary()
	_refresh_opponent_summary()
	_refresh_move_draft_status()
	_refresh_validation()


func _refresh_loadout_summary() -> void:
	loadout_id_label.text = ""
	loadout_id_label.tooltip_text = ""
	loadout_id_label.visible = false

	var pokemon: Variant = database.get_pokemon(
		player_loadout_data.pokemon_id
	)

	if pokemon != null:
		pokemon_name_label.text = GameContentLocalizationService.localize_pokemon(
			pokemon
		)
	else:
		pokemon_name_label.text = (
			LocalizationService.tr_key("preparation.unknown_pokemon", "Unknown Pokémon")
		)

	pokemon_id_label.text = (
		String(player_loadout_data.pokemon_id)
	)

	if pokemon != null:
		POKEMON_ATTRIBUTE_ICONS.show_type(
			pokemon_type_label,
			StringName(pokemon.pokemon_type)
		)
		pokemon_hp_label.text = LocalizationService.tr_format(
			"preparation.hp_value",
			{
				"hp": pokemon.max_hp
			},
            "HP: {hp}"
		)
		POKEMON_ATTRIBUTE_ICONS.show_weaknesses(
			pokemon_weakness_label,
			pokemon
		)
	else:
		POKEMON_ATTRIBUTE_ICONS.show_type(pokemon_type_label, &"")
		pokemon_hp_label.text = LocalizationService.tr_format(
			"preparation.hp_value",
			{"hp": "-"},
            "HP: {hp}"
		)
		POKEMON_ATTRIBUTE_ICONS.show_weaknesses(
			pokemon_weakness_label,
			null
		)

	_refresh_hero_plakoro(
		pokemon
	)
	_refresh_moves()
	_refresh_dice_icon_summary()
	_refresh_coverage_summary()
	_refresh_overall_loadout_summary()



func _format_pokemon_weakness(
	pokemon: Variant
) -> String:
	if pokemon == null:
		return LocalizationService.tr_format(
			"preparation.weakness_value",
			{"value": "-"},
            "Weakness: {value}"
		)

	var weaknesses: Variant = pokemon.weaknesses
	if (
		not (weaknesses is Array)
		or (weaknesses as Array).is_empty()
	):
		return LocalizationService.tr_key(
			"preparation.weakness_none",
            "Weakness: None"
		)

	var parts: Array[String] = []
	for raw_weakness: Variant in weaknesses:
		var attack_type: String = ""
		var bonus_damage: int = 0

		if raw_weakness is Dictionary:
			var weakness_dict: Dictionary = raw_weakness
			attack_type = GameContentLocalizationService.localize_type(
				weakness_dict.get(
					"attack_type",
                    ""
				)
			)
			bonus_damage = int(
				weakness_dict.get(
					"bonus_damage",
					0
				)
			)
		elif raw_weakness is Object:
			attack_type = GameContentLocalizationService.localize_type(
				raw_weakness.get(
                    "attack_type"
				)
			)
			bonus_damage = int(
				raw_weakness.get(
                    "bonus_damage"
				)
			)

		if not attack_type.is_empty():
			parts.append(
				LocalizationService.tr_format(
					"preparation.weakness_part",
					{
						"type": attack_type,
						"bonus": bonus_damage
					},
                    "{type} +{bonus}"
				)
			)

	if parts.is_empty():
		return LocalizationService.tr_key(
			"preparation.weakness_none",
            "Weakness: None"
		)

	return LocalizationService.tr_format(
		"preparation.weakness_value",
		{
			"value": ", ".join(parts)
		},
        "Weakness: {value}"
	)

func _short_pokemon_label(pokemon_id: StringName) -> String:
	var raw: String = String(pokemon_id).strip_edges().to_lower()
	if raw.is_empty():
		return "Unknown"

	var parts: PackedStringArray = raw.split("_")
	if parts.is_empty():
		return raw.capitalize()

	var result: String = parts[0].capitalize()
	if parts.size() >= 3 and parts[parts.size() - 1].match("?[0-9]"):
		result += " " + parts[parts.size() - 1].to_upper()
	return result


func _short_loadout_name(
	pokemon_id: StringName,
	is_ai: bool = false
) -> String:
	var pokemon_label: String = _short_pokemon_label(pokemon_id)
	return (
		LocalizationService.tr_format(
			"preparation.ai_loadout_name",
			{"pokemon": pokemon_label},
            "AI {pokemon}"
		)
		if is_ai
		else pokemon_label
	)


func _refresh_hero_plakoro(
	pokemon: Variant
) -> void:
	for child: Node in (
		hero_plakoro_container.get_children()
	):
		child.queue_free()

	var portrait: Control = (
		PLAKORO_PORTRAIT.instantiate()
	)

	portrait.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)

	hero_plakoro_container.add_child(
		portrait
	)

	portrait.setup(
		pokemon
	)


func _refresh_moves() -> void:
	for child: Node in move_container.get_children():
		child.queue_free()

	if player_loadout_data == null:
		return

	for move_card_id: StringName in player_loadout_data.move_card_ids:
		var move_card: Variant = RESOURCE_RECOVERY.safe_get_move(
			database,
			move_card_id,
			"Battle Preparation"
		)
		if move_card == null:
			continue

		var button := Button.new()
		button.set_script(PLAKORO_MOVE_BUTTON)
		button.custom_minimum_size = Vector2(360, 220)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var damage_text: String = _format_damage(move_card)
		var coverage_text: String = "-"
		if player_loadout_data.energy_dice_setup != null:
			var coverage: Variant = MOVE_COVERAGE_ANALYZER.analyze_move(
				player_loadout_data.energy_dice_setup,
				move_card
			)
			if coverage != null:
				coverage_text = LocalizationService.format_percent(
					float(coverage.success_probability),
					0
				)

		button.setup_battle_summary(
			move_card,
			damage_text,
			coverage_text
		)
		button.set_battle_availability(true, "", coverage_text)
		if OS.has_feature("web"):
			button.pressed.connect(
				func() -> void:
					button.call("_open_web_move_info_popup")
			)
		move_container.add_child(button)


func _refresh_moves_legacy() -> void:
	for child: Node in move_container.get_children():
		child.queue_free()

	for index: int in range(
		player_loadout_data.move_card_ids.size()
	):
		var move_card_id: StringName = (
			player_loadout_data.move_card_ids[index]
		)
		var move_card: Variant = (
			RESOURCE_RECOVERY.safe_get_move(
				database,
				move_card_id,
                "Battle Preparation"
			)
		)

		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 190)
		panel.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(
			"separation",
			10
		)
		panel.add_child(row)

		var slot_label: Label = Label.new()
		slot_label.custom_minimum_size = Vector2(
			42,
			0
		)
		slot_label.text = str(index + 1) + "."
		slot_label.add_theme_font_size_override(
			"font_size",
			18
		)
		row.add_child(slot_label)

		if move_card == null:
			var missing_label: Label = Label.new()
			missing_label.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			missing_label.text = (
				String(move_card_id)
				+ "\n"
				+ LocalizationService.tr_key(
					"preparation.missing_move_data",
                    "Missing move data"
				)
			)
			row.add_child(
				missing_label
			)
		else:
			var move_box: VBoxContainer = VBoxContainer.new()
			move_box.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)
			move_box.add_theme_constant_override(
				"separation",
				5
			)
			row.add_child(
				move_box
			)

			var move_name: Label = Label.new()
			move_name.text = GameContentLocalizationService.localize_move(
				move_card
			)
			move_name.add_theme_font_size_override(
				"font_size",
				17
			)
			move_box.add_child(
				move_name
			)

			var stat_row: HBoxContainer = HBoxContainer.new()
			stat_row.add_theme_constant_override(
				"separation",
				12
			)
			move_box.add_child(
				stat_row
			)

			var move_energy_row: HBoxContainer = HBoxContainer.new()
			move_energy_row.set_script(
				MOVE_ENERGY_COST_ROW
			)
			move_energy_row.setup(
				move_card,
				22
			)
			stat_row.add_child(
				move_energy_row
			)

			var damage_label: Label = Label.new()
			damage_label.text = (
                "DMG "
				+ _format_damage(move_card)
			)
			damage_label.modulate.a = 0.88
			stat_row.add_child(
				damage_label
			)

			var effect_preview: Dictionary = (
				MOVE_EFFECT_PRESENTATION.build_preview(
					move_card
				)
			)
			var localized_move_description: String = (
				GameContentLocalizationService.localize_move_description(
					move_card
				)
			)

			var trigger_groups: Array = (
				effect_preview.get(
					"trigger_groups",
					[]
				)
			)

			for group_index: int in range(trigger_groups.size()):
				var raw_group: Variant = trigger_groups[group_index]
				if not raw_group is Dictionary:
					continue

				var group: Dictionary = raw_group
				var orientations: Array[StringName] = []

				for raw_orientation: Variant in group.get(
					"orientations",
					[]
				):
					orientations.append(
						StringName(
							raw_orientation
						)
					)

				var effect_row: HBoxContainer = HBoxContainer.new()
				effect_row.add_theme_constant_override(
					"separation",
					10
				)
				move_box.add_child(
					effect_row
				)

				var trigger_row: HBoxContainer = HBoxContainer.new()
				trigger_row.set_script(
					KYOKORO_TRIGGER_ROW
				)
				trigger_row.setup(
					orientations,
					26
				)
				effect_row.add_child(
					trigger_row
				)

				var effect_label: Label = Label.new()
				effect_label.size_flags_horizontal = (
					Control.SIZE_EXPAND_FILL
				)
				effect_label.autowrap_mode = (
					TextServer.AUTOWRAP_WORD_SMART
				)
				var fallback_effect_text: String = String(
					group.get(
						"effect_text",
                        ""
					)
				)
				var localized_effect_text: String = (
					GameContentLocalizationService.localize_effect_text(
						move_card,
						group_index,
						fallback_effect_text
					)
				)
				effect_label.text = (
					localized_effect_text
					if not localized_effect_text.is_empty()
					else fallback_effect_text
				)
				effect_label.tooltip_text = String(
					effect_preview["detail"]
				)
				effect_label.modulate.a = 0.88
				effect_row.add_child(
					effect_label
				)

			if trigger_groups.is_empty():
				var fallback_effect: Label = Label.new()
				fallback_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				var fallback_summary: String = String(
					effect_preview["summary"]
				)
				fallback_effect.text = (
					localized_move_description
					if not localized_move_description.is_empty()
					else fallback_summary
				)
				fallback_effect.tooltip_text = String(
					effect_preview["detail"]
				)
				fallback_effect.modulate.a = 0.70
				move_box.add_child(
					fallback_effect
				)

		move_container.add_child(panel)


func _refresh_dice_icon_summary() -> void:
	for child: Node in (
		dice_icon_summary_container.get_children()
	):
		dice_icon_summary_container.remove_child(
			child
		)
		child.queue_free()

	if (
		player_loadout_data == null
		or player_loadout_data.energy_dice_setup == null
	):
		var missing: Label = Label.new()
		missing.text = LocalizationService.tr_key("preparation.no_enerkoro_setup", "No Enerkoro setup.")
		missing.modulate.a = 0.70
		dice_icon_summary_container.add_child(
			missing
		)
		return

	var summary: HBoxContainer = HBoxContainer.new()
	summary.set_script(
		DICE_ICON_SUMMARY
	)
	summary.setup(
		player_loadout_data.energy_dice_setup,
		true
	)
	dice_icon_summary_container.add_child(
		summary
	)


func _refresh_coverage_summary() -> void:
	var setup: Variant = (
		player_loadout_data.energy_dice_setup
	)

	if setup == null:
		coverage_summary_label.text = (
			LocalizationService.tr_key("preparation.coverage_unavailable", "Move Coverage unavailable.")
		)
		return

	var lines: Array[String] = []

	for move_card_id: StringName in (
		player_loadout_data.move_card_ids
	):
		var move_card: Variant = (
			database.get_move_card(
				move_card_id
			)
		)

		if move_card == null:
			continue

		var result: Variant = (
			MOVE_COVERAGE_ANALYZER.analyze_move(
				setup,
				move_card
			)
		)

		if result == null:
			continue

		lines.append(
			LocalizationService.tr_format(
				"preparation.coverage_line",
				{
					"move": GameContentLocalizationService.localize_move(move_card),
					"probability": "%.1f" % (
						float(
							result.success_probability
						)
						* 100.0
					),
					"rating": _coverage_suffix(
						result.get_rating_id()
					)
				},
                "{move}: {probability}%{rating}"
			)
		)

	coverage_summary_label.text = (
		"\n".join(lines)
		if not lines.is_empty()
		else LocalizationService.tr_key("preparation.no_coverage", "No Move Coverage data.")
	)




func _refresh_overall_loadout_summary() -> void:
	if player_loadout_data == null:
		overall_rating_label.text = LocalizationService.tr_key(
			"preparation.no_analysis",
            "-----  No Analysis"
		)
		overall_probability_label.text = LocalizationService.tr_key(
			"preparation.overall_coverage_empty",
            "Overall coverage: -"
		)
		energy_usage_label.text = LocalizationService.tr_key(
			"preparation.energy_usage_empty",
            "Energy Usage\n-"
		)
		loadout_status_label.text = LocalizationService.tr_key(
			"preparation.loadout_status_unavailable",
            "Loadout Status: Unavailable"
		)
		return

	var setup: Variant = (
		player_loadout_data.energy_dice_setup
	)

	if setup == null:
		overall_rating_label.text = LocalizationService.tr_key(
			"preparation.no_dice_setup",
            "-----  No Dice Setup"
		)
		overall_probability_label.text = LocalizationService.tr_key(
			"preparation.overall_coverage_empty",
            "Overall coverage: -"
		)
		energy_usage_label.text = LocalizationService.tr_key(
			"preparation.energy_usage_empty",
            "Energy Usage\n-"
		)
		loadout_status_label.text = LocalizationService.tr_key(
			"preparation.loadout_status_saved",
            "Loadout Status: Saved"
		)
		return

	var selected_ids: Array[StringName] = []

	for move_id: StringName in (
		player_loadout_data.move_card_ids
	):
		selected_ids.append(move_id)

	var analysis: Dictionary = (
		MOVE_BUILDER_ANALYSIS.analyze_selection(
			setup,
			selected_ids,
			database
		)
	)

	var stars: int = int(
		analysis.get("stars", 0)
	)
	var rating: StringName = StringName(
		analysis.get("rating", &"none")
	)
	var probability: float = float(
		analysis.get(
			"overall_probability",
			0.0
		)
	)
	var energy_usage: Dictionary = analysis.get(
		"energy_usage",
		{}
	)

	overall_rating_label.text = LocalizationService.tr_format(
		"preparation.rating_summary",
		{
			"stars": _stars_text(stars),
			"rating": _rating_text(rating)
		},
        "{stars}  {rating}"
	)

	overall_probability_label.text = LocalizationService.tr_format(
		"preparation.overall_coverage",
		{
			"probability": LocalizationService.format_decimal(
				probability * 100.0,
				1
			)
		},
        "Overall coverage: {probability}%"
	)

	energy_usage_label.text = (
		_format_energy_usage_summary(
			energy_usage
		)
	)
	_refresh_energy_icon_summary(
		energy_usage
	)

	loadout_status_label.text = (
		LocalizationService.tr_key(
			"preparation.loadout_status_saved",
            "Loadout Status: Saved"
		)
		if not MOVE_DRAFT_PROVIDER.has_draft()
		else LocalizationService.tr_key(
			"preparation.loadout_status_draft",
            "Loadout Status: Saved  |  Move Draft Active"
		)
	)

	var verification: Dictionary = (
		LOADOUT_VERIFICATION.build_player_report(
			player_loadout_data,
			database
		)
	)

	if bool(verification.get("success", false)):
		loadout_signature_label.text = LocalizationService.tr_format(
			"preparation.loadout_signature",
			{
				"signature": String(
					verification["signature"]
				)
			},
            "Loadout Signature: {signature}"
		)
	else:
		loadout_signature_label.text = LocalizationService.tr_key(
			"preparation.loadout_signature_unavailable",
            "Loadout Signature: Unavailable"
		)



func _refresh_energy_icon_summary(
	energy_usage: Dictionary
) -> void:
	for child: Node in energy_icon_container.get_children():
		child.queue_free()

	var keys: Array = energy_usage.keys()
	keys.sort()

	for raw_energy: Variant in keys:
		var energy_type: StringName = StringName(
			raw_energy
		)
		var chip: HBoxContainer = HBoxContainer.new()
		chip.set_script(ENERGY_COST_CHIP)
		chip.setup(
			energy_type,
			int(energy_usage[raw_energy]),
			24
		)
		energy_icon_container.add_child(chip)


func _format_energy_usage_summary(
	energy_usage: Dictionary
) -> String:
	if energy_usage.is_empty():
		return LocalizationService.tr_key(
			"preparation.energy_no_costs",
            "Energy Usage\nNo printed Energy costs."
		)

	var lines: Array[String] = [
		LocalizationService.tr_key(
			"preparation.energy_usage",
            "Energy Usage"
		)
	]

	var keys: Array = energy_usage.keys()
	keys.sort()

	for raw_energy: Variant in keys:
		var energy_type: StringName = StringName(
			raw_energy
		)

		lines.append(
			LocalizationService.tr_format(
				"preparation.energy_usage_line",
				{
					"icon": _energy_icon(energy_type),
					"energy": GameContentLocalizationService.localize_type(energy_type),
					"count": int(energy_usage[raw_energy])
				},
                "{icon} {energy} x {count}"
			)
		)

	return "\n".join(lines)

func _stars_text(
	filled_count: int
) -> String:
	var result: String = ""

	for index: int in range(5):
		result += (
            "*"
			if index < filled_count
			else "-"
		)

	return result


func _rating_text(
	rating: StringName
) -> String:
	match rating:
		&"excellent":
			return LocalizationService.tr_key(
				"preparation.rating.excellent",
                "Excellent"
			)
		&"good":
			return LocalizationService.tr_key(
				"preparation.rating.good",
                "Good"
			)
		&"acceptable":
			return LocalizationService.tr_key(
				"preparation.rating.acceptable",
                "Acceptable"
			)
		&"poor":
			return LocalizationService.tr_key(
				"preparation.rating.poor",
                "Needs Improvement"
			)
		_:
			return LocalizationService.tr_key(
				"preparation.rating.none",
                "No Analysis"
			)

func _refresh_opponent_summary() -> void:
	if ai_loadout_data == null:
		opponent_name_label.text = LocalizationService.tr_key("preparation.unknown_opponent", "Unknown Opponent")
		opponent_loadout_label.text = LocalizationService.tr_key("preparation.no_ai_loadout", "No AI loadout.")
		opponent_difficulty_label.text = ""
		POKEMON_ATTRIBUTE_ICONS.show_weaknesses(
			opponent_weakness_label,
			null
		)
		_refresh_opponent_portrait(null)
		return

	var pokemon: Variant = database.get_pokemon(
		ai_loadout_data.pokemon_id
	)

	opponent_name_label.text = (
		GameContentLocalizationService.localize_pokemon(pokemon)
		if pokemon != null
		else String(ai_loadout_data.pokemon_id)
	)

	opponent_loadout_label.text = ""
	opponent_loadout_label.tooltip_text = ""
	opponent_loadout_label.visible = false

	var difficulty_id: String = String(
		ai_loadout_data.difficulty
	)
	opponent_difficulty_label.text = LocalizationService.tr_format(
		"preparation.difficulty_value",
		{
			"difficulty": LocalizationService.tr_key(
				"preparation.difficulty." + difficulty_id,
				difficulty_id.capitalize()
			)
		},
        "Difficulty: {difficulty}"
	)

	POKEMON_ATTRIBUTE_ICONS.show_weaknesses(
		opponent_weakness_label,
		pokemon
	)

	_refresh_opponent_portrait(pokemon)


func _refresh_opponent_portrait(pokemon: Variant) -> void:
	for child: Node in opponent_portrait_container.get_children():
		child.queue_free()

	if pokemon == null:
		return

	var portrait: Control = PLAKORO_PORTRAIT.instantiate()
	portrait.custom_minimum_size = Vector2(100, 100)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	opponent_portrait_container.add_child(portrait)
	portrait.setup(pokemon)


func _refresh_move_draft_status() -> void:
	if MOVE_DRAFT_PROVIDER.has_draft():
		move_draft_status_label.text = (
			LocalizationService.tr_key("preparation.move_config_draft", "Move Configuration:  |  Draft Active")
		)
	else:
		move_draft_status_label.text = (
			LocalizationService.tr_key("preparation.move_config_saved", "Move Configuration: [OK] Saved Loadout")
		)


func _on_repeat_fixed_energy_toggled(enabled: bool) -> void:
	if not GameFlow.free_mode:
		repeat_fixed_energy_toggle.set_pressed_no_signal(false)
		return
	GameFlow.free_mode_allow_repeated_fixed_energy = enabled
	PLAKORO_THEME.set_free_mode_allow_repeated_fixed_energy(enabled)
	_refresh_validation()


func _refresh_validation() -> void:
	var player_resources: Dictionary = (
		RESOURCE_RECOVERY.inspect_loadout(
			player_loadout_data,
			database,
            "Player"
		)
	)

	var ai_resources: Dictionary = (
		RESOURCE_RECOVERY.inspect_loadout(
			ai_loadout_data,
			database,
            "AI"
		)
	)

	RESOURCE_RECOVERY.print_report(
		"Battle Preparation Player",
		player_resources
	)
	RESOURCE_RECOVERY.print_report(
		"Battle Preparation AI",
		ai_resources
	)

	if not bool(player_resources["success"]):
		validation_label.text = (
			RESOURCE_RECOVERY.format_blocking_message(
				player_resources
			)
		)
		start_battle_button.disabled = true
		return

	if not bool(ai_resources["success"]):
		validation_label.text = (
			RESOURCE_RECOVERY.format_blocking_message(
				ai_resources
			)
		)
		start_battle_button.disabled = true
		return

	var result: Dictionary = (
		PLAYER_LOADOUT_VALIDATOR.validate(
			player_loadout_data,
			database,
			GameFlow.free_mode
			and GameFlow.free_mode_allow_repeated_fixed_energy
		)
	)

	var ai_result: Dictionary = (
		AI_LOADOUT_VALIDATOR.validate(
			ai_loadout_data,
			database,
			GameFlow.free_mode
			and GameFlow.free_mode_allow_repeated_fixed_energy
		)
	)

	if (
		bool(result["success"])
		and bool(ai_result["success"])
	):
		validation_label.text = (
			LocalizationService.tr_key("preparation.validation_ready", "[OK] READY - Player and AI loadouts are valid.")
		)
		start_battle_button.disabled = false
		return

	var errors: Array[String] = []

	for raw_error: Variant in result["errors"]:
		errors.append(
			LocalizationService.tr_format(
				"preparation.validation_player_error",
				{"error": String(raw_error)},
                "Player: {error}"
			)
		)

	for raw_error: Variant in ai_result["errors"]:
		errors.append(
			LocalizationService.tr_format(
				"preparation.validation_ai_error",
				{"error": String(raw_error)},
                "AI: {error}"
			)
		)

	validation_label.text = LocalizationService.tr_format(
		"preparation.validation_not_ready",
		{
			"errors": "\n".join(
				errors
			)
		},
        "NOT READY\n{errors}"
	)
	start_battle_button.disabled = true


func _start_battle() -> void:
	if player_loadout_data == null:
		return

	var validation: Dictionary = (
		PLAYER_LOADOUT_VALIDATOR.validate(
			player_loadout_data,
			database,
			GameFlow.free_mode
			and GameFlow.free_mode_allow_repeated_fixed_energy
		)
	)

	if not bool(validation["success"]):
		_refresh_validation()
		return

	if not PLAYER_LOADOUT_SAVE_SERVICE.save_loadout(
		player_loadout_data,
		PLAYER_LOADOUT_PROVIDER.get_user_loadout_path()
	):
		validation_label.text = (
			LocalizationService.tr_key("preparation.loadout_save_failed", "Loadout is valid, but could not be saved.")
		)
		return

	if GameFlow.collection_mode:
		GameFlow.open_encounter_select()
	else:
		GameFlow.open_battle()



func _open_content_studio() -> void:
	GameFlow.open_content_studio()


func _open_move_builder() -> void:
	# Legacy direct route retained for compatibility.
	# Battle-specific Move selection now lives in Configure Battle.
	get_tree().change_scene_to_file(
		MOVE_BUILDER_SCENE_PATH
	)


func _open_energy_dice_builder() -> void:
	if player_loadout_data == null:
		validation_label.text = (
            "Player loadout is unavailable."
		)
		return

	var mode: String = "player_custom"
	var pokemon_id: String = String(
		player_loadout_data.pokemon_id
	)
	var species_id: String = ""

	var pokemon: Dictionary = (
		POKEMON_AUTHORING.load_by_id(
			pokemon_id
		)
	)

	if not pokemon.is_empty():
		species_id = String(
			pokemon.get(
				"species_id",
                ""
			)
		).strip_edges().to_lower()

	var target_path: String = CONTENT_PLAYTEST.get_player_custom_dice_path()

	# Free Mode edits the selected Pokémon's own default Enerkoro directly.
	# Story Mode keeps the independent player-custom Enerkoro workflow.
	if GameFlow.free_mode:
		mode = "pokemon_default"
		if pokemon.is_empty():
			validation_label.text = (
				"Selected Free Mode Pokémon is unavailable."
			)
			return
		target_path = CONTENT_PLAYTEST.get_pokemon_default_dice_path(
			pokemon
		)

	if target_path.is_empty() or not FileAccess.file_exists(target_path):
		validation_label.text = (
            "Selected Enerkoro file is missing: "
			+ target_path
		)
		return

	if not DICE_BUILDER_CONTEXT.set_context(
		mode,
		target_path,
		(
			GameFlow.PHONE_PREPARATION_SCENE
			if GameFlow.phone_mode
			else "res://scenes/ui/BattlePreparationUI.tscn"
		),
		pokemon_id,
		species_id
	):
		validation_label.text = (
            "Could not prepare Enerkoro editor context."
		)
		return

	get_tree().change_scene_to_file(
		(
			GameFlow.PHONE_ENERKORO_BUILDER_SCENE
			if GameFlow.phone_mode
			else ENERGY_DICE_BUILDER_SCENE_PATH
		)
	)


func _ensure_free_mode_custom_dice() -> bool:
	var target_path: String = CONTENT_PLAYTEST.get_player_custom_dice_path()
	if FileAccess.file_exists(target_path):
		return true
	if (
		player_loadout_data == null
		or player_loadout_data.energy_dice_setup == null
	):
		return false
	return ENERGY_DICE_SETUP_SAVE.save_setup(
		player_loadout_data.energy_dice_setup,
		target_path
	)


func _format_move_cost(
	move_card: Variant
) -> String:
	if move_card.energy_costs.is_empty():
		return LocalizationService.tr_key("preparation.no_energy_cost", "No energy cost")

	var parts: Array[String] = []

	for cost: Variant in move_card.energy_costs:
		var energy_type: StringName = StringName(
			cost.energy_type
		)

		parts.append(
			_energy_icon(energy_type)
			+ " "
			+ GameContentLocalizationService.localize_type(
				energy_type
			)
			+ "x"
			+ str(int(cost.count))
		)

	return ", ".join(parts)


func _format_damage(
	move_card: Variant
) -> String:
	if move_card.printed_damage == null:
		return "-"

	return str(int(move_card.printed_damage))


func _coverage_suffix(
	rating: StringName
) -> String:
	match rating:
		&"excellent":
			return LocalizationService.tr_key(
				"preparation.coverage.excellent",
                "  [Excellent]"
			)
		&"acceptable":
			return LocalizationService.tr_key(
				"preparation.coverage.acceptable",
                "  [Acceptable]"
			)
		_:
			return LocalizationService.tr_key(
				"preparation.coverage.poor",
                "  [Poor]"
			)

func _energy_icon(
	energy_type: StringName
) -> String:
	match energy_type:
		&"normal":
			return "-"
		&"grass":
			return "Grass"
		&"fire":
			return "Fire"
		&"water":
			return "Water"
		&"electric":
			return "Electric"
		&"psychic":
			return "Psychic"
		&"fighting":
			return "Fighting"
		&"dark":
			return "Dark"
		&"steel":
			return "Steel"
		&"flying":
			return "Flying"
		_:
			return " | "
