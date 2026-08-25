extends Control


signal special_move_target_selected(
	move_name_id: StringName
)
signal battle_phase_changed(phase: StringName)
signal phone_roll_confirmation_changed(
	step: StringName,
	succeeded: bool,
	detail: String,
	amount: int
)


const CHARAKORO_FEEDBACK: Script = preload(
	"res://scripts/presentation/CharakoroBattleFeedbackService.gd"
)


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


const JSON_LOADER: Script = preload(
	"res://scripts/database/JsonLoader.gd"
)
const TEAM_BUILDER_SERVICE: Script = preload(
	"res://scripts/team_builder/TeamBuilderService.gd"
)
const STRUCTURED_DICE_SERVICE: Script = preload(
	"res://scripts/team_builder/StructuredEnergyDiceService.gd"
)
const ENERGY_SETUP_LOADER: Script = preload(
	"res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const MOVE_COVERAGE_ANALYZER: Script = preload(
	"res://scripts/analysis/MoveCoverageAnalyzer.gd"
)
const BATTLE_CONTROLLER: Script = preload(
	"res://scripts/battle/BattleController.gd"
)
const BATTLE_RANDOM_SEED: Script = preload(
	"res://scripts/battle/BattleRandomSeedService.gd"
)
const DICE_ENGINE: Script = preload(
	"res://scripts/dice/DiceEngine.gd"
)
const AI_TURN_SERVICE: Script = preload(
	"res://scripts/ai/AITurnService.gd"
)
const STATUS_RESOLVER: Script = preload(
	"res://scripts/battle/status/StatusResolver.gd"
)
const SPECIAL_KYOKORO_SEQUENCE: Script = preload(
	"res://scripts/battle/special/SpecialKyokoroSequenceService.gd"
)
const SPECIAL_MOVE_SELECTION: Script = preload(
	"res://scripts/battle/special/SpecialMoveSelectionService.gd"
)
const SPECIAL_OPPONENT_ENERKORO: Script = preload(
	"res://scripts/battle/special/SpecialOpponentEnerkoroService.gd"
)
const ENERGY_RESOLVER: Script = preload(
	"res://scripts/battle/EnergyResolver.gd"
)
const TIMELINE_BUILDER: Script = preload(
	"res://scripts/presentation/timeline/BattleTimelineBuilder.gd"
)
const OUTCOME_FEEDBACK: Script = preload(
	"res://scripts/presentation/BattleOutcomeFeedback.gd"
)
const PLAYER_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const RUNTIME_LOADOUT_BUILDER: Script = preload(
	"res://scripts/loadout/RuntimePlayerLoadoutBuilder.gd"
)
const AI_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/AIBattleLoadoutProvider.gd"
)
const RUNTIME_AI_LOADOUT_BUILDER: Script = preload(
	"res://scripts/loadout/RuntimeAILoadoutBuilder.gd"
)
const LOADOUT_VERIFICATION: Script = preload(
	"res://scripts/runtime/BattleLoadoutVerificationService.gd"
)
const MOVE_EFFECT_PRESENTATION: Script = preload(
	"res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)
const RESOURCE_RECOVERY: Script = preload(
	"res://scripts/runtime/BattleResourceRecoveryService.gd"
)
const PLAKORO_MOVE_BUTTON: Script = preload(
	"res://scripts/ui/components/PlakoroMoveButton.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
	"res://scripts/ui/components/MoveEnergyCostRow.gd"
)
const DICE_ICON_SUMMARY: Script = preload(
	"res://scripts/ui/components/EnergyDiceIconSummary.gd"
)
const PLAKORO_PORTRAIT: PackedScene = preload(
	"res://scenes/ui/components/PlakoroPortrait.tscn"
)
const HP_PRESENTER: Script = preload(
	"res://scripts/ui/components/BattleHPBarPresenter.gd"
)
const MESSAGE_PRESENTER: Script = preload(
	"res://scripts/ui/components/BattleMessagePresenter.gd"
)
const FLOATING_TEXT: Script = preload(
	"res://scripts/ui/components/BattleFloatingTextPresenter.gd"
)
const ATTACK_VFX: Script = preload(
	"res://scripts/ui/components/BattleAttackVFX.gd"
)
const TURN_BANNER: Script = preload(
	"res://scripts/ui/components/BattleTurnBannerPresenter.gd"
)
const BATTLE_OUTCOME_DATA: Script = preload(
	"res://scripts/game/data/BattleOutcomeData.gd"
)
const RESOLUTION_PRESENTATION_CONFIG: Script = preload(
	"res://scripts/runtime/BattleResolutionPresentationConfig.gd"
)
const RESOLUTION_STEP_QUEUE_BUILDER: Script = preload(
	"res://scripts/presentation/BattleResolutionStepQueueBuilder.gd"
)




@onready var database: Node = $Database
@onready var page_title: Label = $Margin/Main/Header/Title
@onready var margin: MarginContainer = $Margin
@onready var main: VBoxContainer = $Margin/Main
@onready var body: HSplitContainer = $Margin/Main/Body
@onready var battle_scroll: ScrollContainer = (
	$Margin/Main/Body/BattleScroll
)
@onready var combatants: HBoxContainer = (
	$Margin/Main/Body/BattleScroll/BattleColumn/Combatants
)
@onready var timeline_panel: PanelContainer = (
	$Margin/Main/Body/TimelinePanel
)

@onready var layout_prototype: VBoxContainer = %LayoutPrototype
@onready var prototype_top_row: HBoxContainer = %PrototypeTopRow
@onready var prototype_bottom_row: HBoxContainer = %PrototypeBottomRow
@onready var prototype_center_top: VBoxContainer = %PrototypeCenterTop
@onready var prototype_player_slot: VBoxContainer = %PrototypePlayerSlot
@onready var prototype_turn_slot: Control = %PrototypeTurnSlot
@onready var prototype_roll_slot: Control = %PrototypeRollSlot
@onready var prototype_enemy_slot: VBoxContainer = %PrototypeEnemySlot
@onready var prototype_moves_slot: VBoxContainer = %PrototypeMovesSlot
@onready var prototype_message_slot: VBoxContainer = %PrototypeMessageSlot
@onready var prototype_timeline_slot: VBoxContainer = %PrototypeTimelineSlot
@onready var layout_prototype_button: Button = %LayoutPrototypeButton
@onready var prototype_battle_message_label: Label = %PrototypeBattleMessageLabel

@onready var player_panel: PanelContainer = $Margin/Main/Body/BattleScroll/BattleColumn/Combatants/PlayerPanel
@onready var enemy_panel: PanelContainer = $Margin/Main/Body/BattleScroll/BattleColumn/Combatants/EnemyPanel
@onready var message_panel: PanelContainer = $Margin/Main/Body/BattleScroll/BattleColumn/MessagePanel

@onready var player_header_label: Label = $Margin/Main/Body/BattleScroll/BattleColumn/Combatants/PlayerPanel/VBox/PlayerHeader
@onready var enemy_header_label: Label = $Margin/Main/Body/BattleScroll/BattleColumn/Combatants/EnemyPanel/VBox/EnemyHeader
@onready var player_name_label: Label = %PlayerNameLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var player_type_label: Label = %PlayerTypeLabel
@onready var enemy_type_label: Label = %EnemyTypeLabel
@onready var player_weakness_label: Label = %PlayerWeaknessLabel
@onready var enemy_weakness_label: Label = %EnemyWeaknessLabel
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var enemy_hp_bar: ProgressBar = %EnemyHpBar
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var player_hero_container: VBoxContainer = %PlayerHeroContainer
@onready var enemy_hero_container: VBoxContainer = %EnemyHeroContainer
@onready var enemy_charakoro_button: Button = %EnemyCharakoroButton
@onready var enemy_move_window: PopupPanel = %EnemyMoveWindow
@onready var enemy_move_window_title: Label = %EnemyMoveWindowTitle
@onready var enemy_move_window_hint: Label = %EnemyMoveWindowHint
@onready var enemy_move_detail_grid: GridContainer = %EnemyMoveDetailGrid
@onready var enemy_move_window_close_button: Button = %EnemyMoveWindowCloseButton
@onready var coin_toss_window: PopupPanel = %CoinTossWindow
@onready var coin_toss_title: Label = %CoinTossTitle
@onready var coin_toss_visual: Control = %CoinTossVisual
@onready var coin_flip_label: Label = %CoinFlipLabel
@onready var coin_result_label: Label = %CoinResultLabel
@onready var player_pending_effect_indicator: HBoxContainer = (
	%PlayerPendingEffectIndicator
)
@onready var enemy_pending_effect_indicator: HBoxContainer = (
	%EnemyPendingEffectIndicator
)

@onready var turn_label: Label = %TurnLabel
@onready var message_label: Label = %MessageLabel
@onready var charakoro_feedback_panel: MarginContainer = %CharakoroFeedbackPanel
@onready var charakoro_feedback_title: Label = %CharakoroFeedbackTitle
@onready var charakoro_feedback_label: Label = %CharakoroFeedbackLabel
@onready var action_row: HBoxContainer = (
	%ActionRow
)
@onready var moves_panel: PanelContainer = (
	$Margin/Main/Body/BattleScroll/BattleColumn/ActionRow/MovesPanel
)
@onready var roll_result_panel: PanelContainer = (
	$Margin/Main/Body/BattleScroll/BattleColumn/ActionRow/RollResultPanel
)
@onready var battle_dice_roll_presenter: HBoxContainer = (
	%BattleDiceRollPresenter
)
@onready var energy_state_panel: MarginContainer = %EnergyStatePanel
@onready var energy_payment_label: Label = %EnergyPaymentLabel
@onready var turn_banner_panel: PanelContainer = %TurnBannerPanel
@onready var turn_banner_label: Label = %TurnBannerLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title_label: Label = %ResultTitleLabel
@onready var result_summary_label: Label = %ResultSummaryLabel
@onready var result_hp_label: Label = %ResultHpLabel
@onready var result_restart_button: Button = %ResultRestartButton
@onready var result_preparation_button: Button = %ResultPreparationButton

@onready var move_button_container: GridContainer = (
	%MoveButtonContainer
)
@onready var move_grid_margins: MarginContainer = (
	$Margin/Main/Body/BattleScroll/BattleColumn/ActionRow/MovesPanel/MovesBox/MoveGridMargins
)
@onready var result_actions: HBoxContainer = (
	$Margin/Main/Body/BattleScroll/BattleColumn/ResultPanel/ResultBox/ResultActions
)

@onready var timeline_view: VBoxContainer = %TimelineView
@onready var timeline_scroll: ScrollContainer = %TimelineScroll
@onready var timeline_technical_toggle: CheckButton = (
	%TimelineTechnicalToggle
)
@onready var setup_source_label: Label = %SetupSourceLabel
@onready var moves_title_label: Label = $Margin/Main/Body/BattleScroll/BattleColumn/ActionRow/MovesPanel/MovesBox/MovesTitle
@onready var roll_result_title_label: Label = $Margin/Main/Body/BattleScroll/BattleColumn/ActionRow/RollResultPanel/RollResultBox/RollResultTitle
@onready var timeline_title_label: Label = $Margin/Main/Body/TimelinePanel/TimelineBox/TimelineHeader/TimelineTitle

@onready var restart_button: Button = %RestartButton
@onready var back_to_preparation_button: Button = %BackToPreparationButton
@onready var quit_confirmation: ConfirmationDialog = %QuitConfirmation


var team_rules: Dictionary = {}

var player_loadout_data: Variant = null
var ai_loadout_data: Variant = null

var player_loadout: Variant = null
var enemy_loadout: Variant = null

var player_energy_setup: Variant = null

var battle: Variant = null
var player_dice_engine: Variant = null
var ai_turn_service: Variant = null

var move_buttons: Array[Button] = []
var input_locked: bool = true
var navigation_locked: bool = false
var battle_report_transition_requested: bool = false

var player_damage_dealt: int = 0
var enemy_damage_dealt: int = 0


func _ready() -> void:

	if not layout_prototype_button.pressed.is_connected(_toggle_layout_prototype):
		layout_prototype_button.pressed.connect(_toggle_layout_prototype)
	PLAKORO_THEME.apply_to(self)
	_apply_battle_visual_style()
	LocalizationService.locale_changed.connect(
		_on_locale_changed
	)
	_apply_localized_text()
	get_viewport().size_changed.connect(
		_apply_responsive_layout
	)
	_apply_responsive_layout()
	_configure_battle_tooltip_theme()

	_apply_enerkoro_color_preferences()

	restart_button.pressed.connect(
		_start_new_battle
	)
	result_restart_button.pressed.connect(
		_on_result_primary_pressed
	)
	result_preparation_button.pressed.connect(
		_open_battle_report
	)
	back_to_preparation_button.pressed.connect(
		_on_back_to_preparation_pressed
	)
	quit_confirmation.confirmed.connect(
		_on_quit_confirmed
	)
	enemy_charakoro_button.pressed.connect(_open_enemy_move_window)
	enemy_move_window_close_button.pressed.connect(enemy_move_window.hide)

	# Prevent the OS close button from quitting immediately. The close request
	# is handled by _notification() so the player can confirm first.
	get_tree().auto_accept_quit = false

	if not database.load_all():
		message_label.text = LocalizationService.tr_key(
			"battle.database_load_failed",
			"Database load failed."
		)
		return

	team_rules = JSON_LOADER.load_dictionary(
		"res://database/rules/team_builder_rules.json"
	)

	if team_rules.is_empty():
		message_label.text = LocalizationService.tr_key(
			"battle.rules_load_failed",
			"Team Builder rules load failed."
		)
		return

	if not timeline_technical_toggle.toggled.is_connected(
		_on_timeline_technical_toggled
	):
		timeline_technical_toggle.toggled.connect(
			_on_timeline_technical_toggled
		)

	timeline_technical_toggle.button_pressed = false
	_on_timeline_technical_toggled(false)

	_start_new_battle()
	_set_layout_prototype_enabled(true)




func _on_locale_changed(
	_locale: String
) -> void:
	GameContentLocalizationService.set_locale(
		LocalizationService.get_current_locale()
	)
	_apply_localized_text()
	_rebuild_localized_move_buttons()
	_refresh_enemy_move_reveal()
	_refresh_ui()


func _rebuild_localized_move_buttons() -> void:
	if player_loadout == null:
		return
	_clear_move_buttons()
	_create_move_buttons()


func _apply_localized_text() -> void:
	page_title.text = LocalizationService.tr_key(
		"battle.title",
		"PLAKORO Battle"
	)
	back_to_preparation_button.text = (
		"<- "
		+ LocalizationService.tr_key(
			"battle.back_preparation",
			"Back to Preparation"
		)
	)
	restart_button.text = LocalizationService.tr_key(
		"battle.restart",
		"Restart"
	)
	_refresh_result_primary_button()
	result_preparation_button.text = LocalizationService.tr_key(
		"battle.view_results",
		"View Results"
	)
	moves_title_label.text = LocalizationService.tr_key(
		"battle.moves",
		"Moves"
	)
	roll_result_title_label.text = LocalizationService.tr_key(
		"battle.roll_result",
		"Roll Result"
	)
	timeline_title_label.text = LocalizationService.tr_key(
		"battle.timeline",
		"Battle Timeline"
	)
	player_header_label.text = LocalizationService.tr_key(
		"battle.you",
		"YOU"
	)
	enemy_header_label.text = LocalizationService.tr_key(
		"battle.ai",
		"AI"
	)
	enemy_charakoro_button.tooltip_text = LocalizationService.tr_key(
		"battle.opponent_moves_open",
		"View opponent Charakoro and Moves"
	)
	enemy_move_window_title.text = LocalizationService.tr_key(
		"battle.opponent_moves_title",
		"OPPONENT CHARAKORO / MOVES"
	)
	enemy_move_window_hint.text = LocalizationService.tr_key(
		"battle.opponent_moves_hint",
		"Opponent information revealed after battle begins."
	)
	enemy_move_window_close_button.text = LocalizationService.tr_key(
		"common.close",
		"Close"
	)
	timeline_technical_toggle.text = LocalizationService.tr_key(
		"battle.technical",
		"Technical"
	)
	quit_confirmation.title = LocalizationService.tr_key(
		"battle.quit_title",
		"Exit PLAKORO?"
	)
	quit_confirmation.dialog_text = LocalizationService.tr_key(
		"global_quit.message",
		"Are you sure you want to close the game?"
	)
	quit_confirmation.ok_button_text = LocalizationService.tr_key(
		"battle.quit",
		"Quit"
	)
	quit_confirmation.cancel_button_text = LocalizationService.tr_key(
		"common.cancel",
		"Cancel"
	)


func _apply_battle_visual_style() -> void:
	setup_source_label.visible = false
	turn_label.visible = false
	var warm: bool = PLAKORO_THEME.is_warm_theme()
	if warm:
		page_title.add_theme_color_override(
			"font_color",
			Color("ebe6dc")
		)

	# The center battle arena deliberately uses the exact same presentation in
	# Warm and Dark themes. Only the surrounding player/enemy/move UI follows
	# the selected application theme. This prevents the combat result text and
	# dice presentation from changing contrast when the theme is switched.
	var arena_text: Color = Color(0.95, 0.98, 1.0, 1.0)
	var arena_outline: Color = Color(0.0, 0.0, 0.0, 0.92)
	for contrast_label: Label in [
		energy_payment_label,
		charakoro_feedback_title,
		charakoro_feedback_label,
		message_label,
		prototype_battle_message_label
	]:
		contrast_label.add_theme_color_override("font_color", arena_text)
		contrast_label.add_theme_color_override("font_outline_color", arena_outline)
		contrast_label.add_theme_constant_override("outline_size", 5)
	roll_result_title_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.82, 0.40, 1.0)
	)
	roll_result_title_label.add_theme_color_override(
		"font_outline_color",
		arena_outline
	)
	roll_result_title_label.add_theme_constant_override("outline_size", 5)
	turn_banner_label.add_theme_color_override(
		"font_outline_color",
		arena_outline
	)
	turn_banner_label.add_theme_constant_override("outline_size", 4)
	var enemy_window_style: StyleBoxFlat = StyleBoxFlat.new()
	enemy_window_style.bg_color = (
		Color("e4d3d0") if warm
		else Color(0.045, 0.018, 0.032, 0.995)
	)
	enemy_window_style.border_color = Color(1.0, 0.30, 0.46, 0.95)
	enemy_window_style.set_border_width_all(2)
	enemy_window_style.corner_radius_top_left = 16
	enemy_window_style.corner_radius_top_right = 16
	enemy_window_style.corner_radius_bottom_left = 16
	enemy_window_style.corner_radius_bottom_right = 16
	enemy_window_style.shadow_color = Color(0.11, 0.15, 0.25, 0.16 if warm else 0.86)
	enemy_window_style.shadow_size = 10 if warm else 24
	enemy_move_window.add_theme_stylebox_override("panel", enemy_window_style)

	player_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(Color("d4dfe4"), 0.82) if warm else Color(0.025, 0.060, 0.105, 0.86),
			Color(0.20, 0.62, 1.0, 0.90),
			2
		)
	)
	enemy_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(Color("e4d3d0"), 0.82) if warm else Color(0.105, 0.025, 0.052, 0.86),
			Color(1.0, 0.30, 0.42, 0.88),
			2
		)
	)
	roll_result_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(0.015, 0.030, 0.025, 0.12),
			Color(0.92, 0.78, 0.36, 0.72),
			1,
			false
		)
	)
	moves_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(PLAKORO_THEME.get_color("surface"), 0.72) if warm else Color(0.025, 0.038, 0.060, 0.84),
			Color(0.25, 0.50, 0.82, 0.72),
			1
		)
	)
	timeline_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(PLAKORO_THEME.get_color("surface"), 0.72) if warm else Color(0.020, 0.028, 0.044, 0.82),
			Color(0.24, 0.30, 0.42, 0.70),
			1
		)
	)
	%PrototypeBattleMessagePanel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(0.035, 0.020, 0.045, 0.12),
			Color(0.76, 0.58, 0.92, 0.60),
			1,
			false
		)
	)
	turn_banner_panel.add_theme_stylebox_override(
		"panel",
		_battle_panel_style(
			Color(0.015, 0.025, 0.035, 0.72),
			Color(0.48, 0.74, 0.90, 0.58),
			1,
			false
		)
	)

	player_header_label.add_theme_color_override(
		"font_color",
		Color(0.38, 0.76, 1.0, 1.0)
	)
	enemy_header_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.48, 0.58, 1.0)
	)
	roll_result_title_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.82, 0.40, 1.0)
	)
	roll_result_title_label.add_theme_font_size_override("font_size", 21)
	prototype_battle_message_label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.92)
	)
	prototype_battle_message_label.add_theme_constant_override(
		"outline_size",
		5
	)

	player_hp_bar.add_theme_stylebox_override(
		"fill",
		_battle_bar_style(Color(0.18, 0.66, 1.0, 1.0))
	)
	enemy_hp_bar.add_theme_stylebox_override(
		"fill",
		_battle_bar_style(Color(1.0, 0.26, 0.38, 1.0))
	)


func _battle_panel_style(
	background: Color,
	border: Color,
	border_width: int,
	with_shadow: bool = true
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12.0)
	if with_shadow:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
		style.shadow_size = 8
	return style


func _battle_bar_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style


func _toggle_layout_prototype() -> void:
	_set_layout_prototype_enabled(
		not layout_prototype.visible
	)


func _set_layout_prototype_enabled(enabled: bool) -> void:
	if enabled:
		# Digital adaptation of the 2P Playseat: the opponent occupies the
		# far/right end, the player the near/left end, and dice resolve in the
		# shared center. Text stays upright for screen play.
		_move_control_to(timeline_panel, prototype_player_slot)
		_move_control_to(turn_banner_panel, prototype_turn_slot)
		_move_control_to(roll_result_panel, prototype_roll_slot)
		_fill_fixed_layout_slot(
			turn_banner_panel,
			prototype_turn_slot
		)
		_fill_fixed_layout_slot(
			roll_result_panel,
			prototype_roll_slot
		)
		_move_control_to(enemy_panel, prototype_enemy_slot)

		# All three top-row visual panels must occupy the same HBox row height.
		enemy_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		_move_control_to(player_panel, prototype_moves_slot)
		player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_move_control_to(moves_panel, prototype_timeline_slot)
		moves_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		moves_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_prototype_move_button_size()

		_move_control_to(result_panel, prototype_message_slot)

		prototype_battle_message_label.text = ""
		message_panel.visible = false
		turn_banner_panel.visible = true
		turn_banner_panel.custom_minimum_size = Vector2.ZERO
		roll_result_panel.custom_minimum_size = Vector2.ZERO
		roll_result_panel.visible = true
		energy_state_panel.visible = true
		charakoro_feedback_panel.visible = true
		energy_payment_label.text = ""
		charakoro_feedback_title.text = ""
		charakoro_feedback_label.text = ""
		timeline_panel.visible = true
		timeline_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		battle_scroll.visible = false
		layout_prototype.visible = true
		layout_prototype_button.text = "Original Layout"
		layout_prototype_button.visible = false
		_apply_prototype_responsive_layout()
	else:
		layout_prototype.visible = false

		_move_control_to(player_panel, combatants)
		_move_control_to(enemy_panel, combatants)
		player_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		enemy_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_move_control_to(message_panel, battle_scroll.get_node("BattleColumn"))
		_move_control_to(turn_banner_panel, battle_scroll.get_node("BattleColumn"))
		_move_control_to(result_panel, battle_scroll.get_node("BattleColumn"))
		_move_control_to(moves_panel, action_row)
		moves_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		moves_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_move_control_to(roll_result_panel, action_row)
		_move_control_to(timeline_panel, body)

		combatants.move_child(player_panel, 0)
		combatants.move_child(enemy_panel, 1)
		var battle_column: VBoxContainer = battle_scroll.get_node("BattleColumn")
		battle_column.move_child(combatants, 0)
		battle_column.move_child(message_panel, 1)
		battle_column.move_child(turn_banner_panel, 2)
		battle_column.move_child(result_panel, 3)
		battle_column.move_child(action_row, 4)
		action_row.move_child(moves_panel, 0)
		action_row.move_child(roll_result_panel, 1)
		body.move_child(battle_scroll, 0)
		body.move_child(timeline_panel, 1)

		message_panel.visible = true
		turn_banner_panel.custom_minimum_size = Vector2(0, 42)
		roll_result_panel.custom_minimum_size = Vector2(430, 285)
		energy_state_panel.visible = false
		charakoro_feedback_panel.visible = false
		roll_result_panel.visible = false
		battle_scroll.visible = true
		layout_prototype_button.text = "Test Layout"
		layout_prototype_button.visible = false
		_apply_responsive_layout()


func _apply_prototype_move_button_size() -> void:
	move_button_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	for button: Button in move_buttons:
		if button == null:
			continue
		button.custom_minimum_size = Vector2(
			0.0,
			124.0
		)
		button.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)


func _fill_fixed_layout_slot(
	control: Control,
	slot: Control
) -> void:
	if control == null or slot == null:
		return

	control.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _move_control_to(control: Control, target_parent: Node) -> void:
	if control == null or target_parent == null:
		return
	if control.get_parent() == target_parent:
		return
	control.reparent(target_parent)


func _apply_responsive_layout() -> void:
	if layout_prototype != null and layout_prototype.visible:
		_apply_prototype_responsive_layout()
		return

	var profile: StringName = (
		RESPONSIVE_UI.get_profile(
			self
		)
	)
	var viewport_width: float = (
		get_viewport_rect().size.x
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

	RESPONSIVE_UI.apply_button(
		back_to_preparation_button,
		profile,
		190
	)
	RESPONSIVE_UI.apply_button(
		restart_button,
		profile,
		120
	)

	match profile:
		RESPONSIVE_PROFILE.PROFILE_FULL:
			timeline_panel.visible = true
			timeline_panel.custom_minimum_size.x = 360
			body.split_offset = int(
				viewport_width * 0.68
			)
			move_button_container.columns = 2
			combatants.add_theme_constant_override(
				"separation",
				12
			)

		RESPONSIVE_PROFILE.PROFILE_COMPACT:
			timeline_panel.visible = true
			timeline_panel.custom_minimum_size.x = 300
			body.split_offset = int(
				viewport_width * 0.66
			)
			move_button_container.columns = 2
			combatants.add_theme_constant_override(
				"separation",
				8
			)

		_:
			# Below 1280 px the priority is playable battle controls.
			# Timeline remains available in desktop/compact layouts and is
			# hidden on handheld-sized widths to prevent horizontal squeezing.
			timeline_panel.visible = false
			body.split_offset = int(
				viewport_width - 24.0
			)
			move_button_container.columns = 1
			combatants.add_theme_constant_override(
				"separation",
				6
			)

	_apply_action_row_layout(
		profile
	)

	for button: Button in move_buttons:
		if button == null:
			continue

		_apply_move_button_responsive_size(
			button,
			profile
		)



func _apply_prototype_responsive_layout() -> void:
	var profile: StringName = (
		RESPONSIVE_UI.get_profile(
			self
		)
	)
	var viewport_size: Vector2 = (
		get_viewport_rect().size
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

	var row_spacing: int = 18
	var center_width: float = 430.0
	var center_height: float = 374.0
	var roll_height: float = 314.0
	var move_side_margin: int = 36
	var move_height: float = 124.0
	var timeline_visible: bool = true

	match profile:
		RESPONSIVE_PROFILE.PROFILE_FULL:
			row_spacing = 18
			center_width = 430.0
			center_height = (
				340.0
				if viewport_size.y < 900.0
				else 374.0
			)
			roll_height = center_height - 60.0
			move_side_margin = 36
			move_height = 124.0
			timeline_visible = true

		RESPONSIVE_PROFILE.PROFILE_COMPACT:
			row_spacing = 12
			center_width = 360.0
			center_height = (
				286.0
				if viewport_size.y <= 720.0
				else 318.0
			)
			roll_height = center_height - 60.0
			move_side_margin = 20
			move_height = 104.0
			timeline_visible = true

		_:
			row_spacing = 8
			center_width = 300.0
			center_height = (
				252.0
				if viewport_size.y <= 720.0
				else 280.0
			)
			roll_height = center_height - 60.0
			move_side_margin = 10
			move_height = 86.0
			timeline_visible = false

	prototype_top_row.add_theme_constant_override(
		"separation",
		row_spacing
	)
	prototype_bottom_row.add_theme_constant_override(
		"separation",
		row_spacing
	)

	prototype_center_top.custom_minimum_size = Vector2(
		center_width,
		center_height
	)
	prototype_roll_slot.custom_minimum_size.y = max(
		180.0,
		roll_height
	)

	move_grid_margins.add_theme_constant_override(
		"margin_left",
		move_side_margin
	)
	move_grid_margins.add_theme_constant_override(
		"margin_right",
		move_side_margin
	)

	for button: Button in move_buttons:
		if button == null:
			continue

		button.custom_minimum_size = Vector2(
			0.0,
			move_height
		)
		button.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

	timeline_panel.visible = timeline_visible
	prototype_player_slot.visible = timeline_visible
	prototype_timeline_slot.visible = true

	# If Timeline is hidden, the two useful lower panels divide the full row.
	prototype_moves_slot.size_flags_stretch_ratio = (
		1.0
	)
	prototype_message_slot.size_flags_stretch_ratio = (
		1.0
	)
	prototype_timeline_slot.size_flags_stretch_ratio = (
		1.0
	)

	RESPONSIVE_UI.apply_button(
		result_restart_button,
		profile,
		150
	)
	RESPONSIVE_UI.apply_button(
		result_preparation_button,
		profile,
		190
	)

	result_actions.add_theme_constant_override(
		"separation",
		RESPONSIVE_PROFILE.section_spacing(
			profile
		)
	)




func _apply_action_row_layout(
	profile: StringName
) -> void:
	match profile:
		RESPONSIVE_PROFILE.PROFILE_FULL:
			action_row.alignment = (
				BoxContainer.ALIGNMENT_CENTER
			)
			moves_panel.custom_minimum_size.x = 430.0
			roll_result_panel.custom_minimum_size.x = 500.0

		RESPONSIVE_PROFILE.PROFILE_COMPACT:
			action_row.alignment = (
				BoxContainer.ALIGNMENT_CENTER
			)
			moves_panel.custom_minimum_size.x = 360.0
			roll_result_panel.custom_minimum_size.x = 430.0

		_:
			# HBox still remains one row when space allows. On handheld the
			# Roll Result gets the smaller minimum so move controls stay usable.
			action_row.alignment = (
				BoxContainer.ALIGNMENT_BEGIN
			)
			moves_panel.custom_minimum_size.x = 320.0
			roll_result_panel.custom_minimum_size.x = 360.0


func _apply_move_button_responsive_size(
	button: Button,
	profile: StringName
) -> void:
	match profile:
		RESPONSIVE_PROFILE.PROFILE_FULL:
			button.custom_minimum_size = Vector2(
				240,
				145
			)
		RESPONSIVE_PROFILE.PROFILE_COMPACT:
			button.custom_minimum_size = Vector2(
				190,
				118
			)
		_:
			button.custom_minimum_size = Vector2(
				0,
				112
			)
			button.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL
			)



func _notification(
	what: int
) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_show_quit_confirmation()


func _on_back_to_preparation_pressed() -> void:
	if navigation_locked:
		return

	# Returning to Preparation is normal navigation, not quitting the game.
	GameFlow.open_preparation()


func _show_quit_confirmation() -> void:
	if quit_confirmation == null:
		return

	if quit_confirmation.visible:
		return

	quit_confirmation.popup_centered()


func _on_quit_confirmed() -> void:
	get_tree().quit()


func _configure_battle_tooltip_theme() -> void:
	# Keep the existing project theme, but override the built-in tooltip
	# presentation for this Battle UI so effect text is easy to read.
	var battle_theme: Theme = Theme.new()

	if theme != null:
		battle_theme = theme.duplicate()

	var tooltip_panel: StyleBoxFlat = StyleBoxFlat.new()
	tooltip_panel.bg_color = PLAKORO_THEME.get_color("surface")
	tooltip_panel.border_color = PLAKORO_THEME.get_color("border_hover")
	tooltip_panel.set_border_width_all(1)
	tooltip_panel.corner_radius_top_left = 6
	tooltip_panel.corner_radius_top_right = 6
	tooltip_panel.corner_radius_bottom_left = 6
	tooltip_panel.corner_radius_bottom_right = 6
	tooltip_panel.content_margin_left = 12.0
	tooltip_panel.content_margin_right = 12.0
	tooltip_panel.content_margin_top = 9.0
	tooltip_panel.content_margin_bottom = 9.0

	battle_theme.set_stylebox(
		"panel",
		"TooltipPanel",
		tooltip_panel
	)
	battle_theme.set_color(
		"font_color",
		"TooltipLabel",
		Color(0.97, 0.97, 0.98, 1.0)
	)
	battle_theme.set_font_size(
		"font_size",
		"TooltipLabel",
		16
	)

	theme = battle_theme


func _set_battle_action_state(
	phase: StringName
) -> void:
	battle_phase_changed.emit(phase)
	if turn_banner_label == null:
		return

	var turn_number: int = 1
	var actor_key: String = "battle.your_turn"

	if (
		battle != null
		and battle.state != null
	):
		turn_number = int(
			battle.state.turn_number
		)
		if (
			battle.state.current_participant_id
			== &"enemy"
		):
			actor_key = "battle.ai_turn"

	var phase_key: String = ""

	match phase:
		&"choose_move":
			actor_key = "battle.your_turn"
			phase_key = "battle.phase.choose_move"
		&"rolling":
			actor_key = "battle.your_turn"
			phase_key = "battle.phase.rolling"
		&"select_target":
			actor_key = "battle.your_turn"
			phase_key = "battle.phase.select_target"
		&"resolving":
			actor_key = "battle.your_turn"
			phase_key = "battle.phase.resolving"
		&"ai_thinking":
			actor_key = "battle.ai_turn"
			phase_key = "battle.phase.ai_thinking"
		&"ai_rolling":
			actor_key = "battle.ai_turn"
			phase_key = "battle.phase.rolling"
		&"ai_resolving":
			actor_key = "battle.ai_turn"
			phase_key = "battle.phase.resolving"
		&"battle_finished":
			actor_key = "battle.finished"
			phase_key = "battle.phase.battle_finished"

	var actor_text: String = LocalizationService.tr_key(
		actor_key,
		"YOUR TURN"
	)
	var phase_text: String = (
		LocalizationService.tr_key(
			phase_key,
			String(phase).replace(
				"_",
				" "
			).capitalize()
		)
		if not phase_key.is_empty()
		else String(phase).replace(
			"_",
			" "
		).capitalize()
	)

	turn_banner_panel.visible = true

	if phase == &"rolling":
		roll_result_title_label.text = LocalizationService.tr_key(
			"battle.roll.player",
			"YOUR ROLL"
		)
	elif phase == &"ai_rolling":
		roll_result_title_label.text = LocalizationService.tr_key(
			"battle.roll.opponent",
			"OPPONENT ROLL"
		)
	elif phase == &"choose_move":
		roll_result_title_label.text = LocalizationService.tr_key(
			"battle.roll.ready",
			"DICE READY"
		)

	var actor_color: Color = TURN_BANNER.PLAYER_COLOR
	if actor_key == "battle.ai_turn":
		actor_color = TURN_BANNER.AI_COLOR
	elif actor_key == "battle.finished":
		actor_color = Color(
			0.78,
			0.82,
			0.88,
			1.0
		)
	turn_banner_label.add_theme_color_override(
		"font_color",
		actor_color
	)
	turn_banner_label.text = LocalizationService.tr_format(
		"battle.turn_phase",
		{
			"turn": turn_number,
			"actor": actor_text,
			"phase": phase_text
		},
		"Turn {turn} - {actor}  |  {phase}"
	)



func _hold_action_state(
	phase: StringName,
	_seconds: float = 1.0
) -> void:
	_set_battle_action_state(
		phase
	)

	# 12.9g Fix 3:
	# Keep the current Turn Dialog visible until the next battle phase replaces it.
	# No timer-driven hide/fade is used.
	await get_tree().process_frame


func _apply_enerkoro_color_preferences() -> void:
	if battle_dice_roll_presenter == null:
		return
	if battle_dice_roll_presenter.has_method("set_custom_slot_color_types"):
		battle_dice_roll_presenter.set_custom_slot_color_types(
			PLAKORO_THEME.get_enerkoro_color_types()
		)


func _on_timeline_technical_toggled(
	enabled: bool
) -> void:
	if timeline_view.has_method(
		"set_technical_mode"
	):
		timeline_view.set_technical_mode(
			enabled
		)

	await get_tree().process_frame
	timeline_scroll.scroll_vertical = int(
		timeline_scroll.get_v_scroll_bar().max_value
	)


func _start_new_battle() -> void:
	if navigation_locked:
		return

	input_locked = true
	battle_report_transition_requested = false
	_set_battle_navigation_locked(false)
	roll_result_panel.visible = layout_prototype.visible
	if battle_dice_roll_presenter.has_method(
		"reset_display"
	):
		battle_dice_roll_presenter.reset_display()
	_clear_current_energy_state()
	_clear_charakoro_feedback()
	if layout_prototype.visible:
		prototype_battle_message_label.text = ""
		energy_state_panel.visible = true
		charakoro_feedback_panel.visible = true
	player_damage_dealt = 0
	enemy_damage_dealt = 0
	result_panel.visible = false
	turn_banner_panel.visible = true
	_clear_move_buttons()

	if timeline_view.has_method("clear_timeline"):
		timeline_view.clear_timeline()

	player_loadout_data = (
		PLAYER_LOADOUT_PROVIDER.load_player_loadout()
	)

	ai_loadout_data = (
		AI_LOADOUT_PROVIDER.load_ai_loadout()
	)

	if player_loadout_data == null:
		message_label.text = LocalizationService.tr_key("battle.player_loadout_failed", "Player loadout load failed.")
		return

	if ai_loadout_data == null:
		message_label.text = LocalizationService.tr_key("battle.ai_loadout_failed", "AI loadout load failed.")
		return

	var player_resource_report: Dictionary = (
		RESOURCE_RECOVERY.inspect_loadout(
			player_loadout_data,
			database,
			"Player"
		)
	)

	var ai_resource_report: Dictionary = (
		RESOURCE_RECOVERY.inspect_loadout(
			ai_loadout_data,
			database,
			"AI"
		)
	)

	RESOURCE_RECOVERY.print_report(
		"Player",
		player_resource_report
	)
	RESOURCE_RECOVERY.print_report(
		"AI",
		ai_resource_report
	)

	if not bool(player_resource_report["success"]):
		message_label.text = (
			RESOURCE_RECOVERY.format_blocking_message(
				player_resource_report
			)
		)
		return

	if not bool(ai_resource_report["success"]):
		message_label.text = (
			RESOURCE_RECOVERY.format_blocking_message(
				ai_resource_report
			)
		)
		return

	player_energy_setup = (
		player_loadout_data.energy_dice_setup
	)

	if player_energy_setup == null:
		message_label.text = (
			LocalizationService.tr_key("battle.player_enerkoro_missing", "Player Enerkoro setup is missing.")
		)
		return

	player_loadout = (
		RUNTIME_LOADOUT_BUILDER.build_runtime_loadout(
			player_loadout_data,
			database,
			team_rules,
			&"player",
			GameFlow.free_mode
			and GameFlow.free_mode_allow_repeated_fixed_energy
		)
	)

	enemy_loadout = (
		RUNTIME_AI_LOADOUT_BUILDER.build_runtime_loadout(
			ai_loadout_data,
			database,
			team_rules,
			&"ai",
			GameFlow.free_mode
			and GameFlow.free_mode_allow_repeated_fixed_energy
		)
	)

	if player_loadout == null:
		message_label.text = (
			LocalizationService.tr_key("battle.player_runtime_failed", "Player runtime loadout build failed.")
		)
		return

	if enemy_loadout == null:
		message_label.text = (
			LocalizationService.tr_key("battle.ai_runtime_failed", "AI runtime loadout build failed.")
		)
		return

	setup_source_label.text = LocalizationService.tr_format(
		"battle.setup_source",
		{
			"player": String(
				player_loadout_data.loadout_id
			),
			"ai": String(
				ai_loadout_data.loadout_id
			)
		},
		"Player: {player} | AI: {ai}"
	)

	var player_verification: Dictionary = (
		LOADOUT_VERIFICATION.build_player_report(
			player_loadout_data,
			database
		)
	)

	var ai_verification: Dictionary = (
		LOADOUT_VERIFICATION.build_ai_report(
			ai_loadout_data,
			database
		)
	)

	LOADOUT_VERIFICATION.print_report(
		"Player Battle Runtime Initialization",
		player_verification
	)

	LOADOUT_VERIFICATION.print_report(
		"AI Battle Runtime Initialization",
		ai_verification
	)

	if bool(player_verification.get("success", false)):
		setup_source_label.text += LocalizationService.tr_format(
			"battle.setup_signature",
			{
				"signature": String(
					player_verification["signature"]
				)
			},
			" | SIG {signature}"
		)

	setup_source_label.text += LocalizationService.tr_format(
		"battle.setup_resolution",
		{
			"resolution": RESOLUTION_PRESENTATION_CONFIG.display_name()
		},
		" | Resolution: {resolution}"
	)

	var live_battle_seed: int = (
		BATTLE_RANDOM_SEED.create_live_seed()
	)
	var coin_random: RandomNumberGenerator = RandomNumberGenerator.new()
	coin_random.seed = BATTLE_RANDOM_SEED.derive_seed(
		live_battle_seed,
		73129
	)
	var coin_heads: bool = coin_random.randi_range(0, 1) == 0
	var starting_participant_id: StringName = (
		&"player" if coin_heads else &"enemy"
	)

	battle = BATTLE_CONTROLLER.new(database)
	battle.start_battle(
		player_loadout,
		enemy_loadout,
		starting_participant_id
	)

	var ai_battle_seed: int = (
		BATTLE_RANDOM_SEED.derive_seed(
			live_battle_seed,
			90210
		)
	)

	player_dice_engine = DICE_ENGINE.new(
		database.reference_data,
		live_battle_seed
	)

	ai_turn_service = AI_TURN_SERVICE.new(
		battle,
		1200,
		ai_battle_seed
	)

	print(
		"Live Battle RNG seed: ",
		live_battle_seed,
		" | AI seed: ",
		ai_battle_seed
	)

	_refresh_plakoro_presentations()
	_refresh_enemy_move_reveal()
	_create_move_buttons()
	_refresh_ui()
	_set_battle_navigation_locked(true)
	await _present_coin_toss(coin_heads)

	if starting_participant_id == &"enemy":
		TURN_BANNER.show_turn(
			turn_banner_panel,
			turn_banner_label,
			int(battle.state.turn_number),
			&"enemy"
		)
		MESSAGE_PRESENTER.show_ai(
			message_label,
			LocalizationService.tr_key(
				"battle.ai_goes_first",
				"AI won the coin toss and goes first."
			)
		)
		await _hold_action_state(&"ai_thinking", 0.8)
		await _execute_ai_turn()
		return

	TURN_BANNER.show_turn(
		turn_banner_panel,
		turn_banner_label,
		int(battle.state.turn_number),
		&"player"
	)
	_set_battle_action_state(&"choose_move")

	MESSAGE_PRESENTER.show_player(
		message_label,
		LocalizationService.tr_key(
			"battle.choose_move",
			"Choose a move."
		)
	)
	_set_player_input_enabled(true)
	_set_battle_navigation_locked(false)


func _present_coin_toss(coin_heads: bool) -> void:
	coin_toss_title.text = LocalizationService.tr_key(
		"battle.coin_toss.title",
		"COIN TOSS"
	)
	coin_flip_label.text = LocalizationService.tr_key(
		"battle.coin_toss.flipping",
		"Flipping to decide who goes first..."
	)
	coin_result_label.text = ""
	coin_toss_window.popup_centered(Vector2i(500, 380))
	await get_tree().process_frame
	await coin_toss_visual.call("play_flip", coin_heads)
	coin_flip_label.text = LocalizationService.tr_key(
		"battle.coin_toss.heads"
		if coin_heads
		else "battle.coin_toss.tails",
		"HEADS" if coin_heads else "TAILS"
	)
	coin_result_label.text = LocalizationService.tr_key(
		"battle.coin_toss.player_first"
		if coin_heads
		else "battle.coin_toss.ai_first",
		"You go first!" if coin_heads else "AI goes first!"
	)
	await get_tree().create_timer(1.25).timeout
	coin_toss_window.hide()



func _refresh_plakoro_presentations() -> void:
	_refresh_single_portrait(
		player_hero_container,
		player_loadout_data
	)
	_refresh_single_portrait(
		enemy_hero_container,
		ai_loadout_data
	)


func _refresh_single_portrait(
	target: VBoxContainer,
	loadout_data: Variant
) -> void:
	for child: Node in target.get_children():
		child.queue_free()

	if loadout_data == null:
		return

	var pokemon: Variant = database.get_pokemon(
		loadout_data.pokemon_id
	)

	var portrait: Control = (
		PLAKORO_PORTRAIT.instantiate()
	)
	portrait.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)
	target.add_child(portrait)
	portrait.setup(pokemon)


func _refresh_enemy_move_reveal() -> void:
	for child: Node in enemy_move_detail_grid.get_children():
		child.queue_free()
	if enemy_loadout == null:
		return
	for move_card: Variant in enemy_loadout.selected_move_cards:
		if move_card == null:
			continue
		enemy_move_detail_grid.add_child(
			_build_enemy_move_reveal_card(move_card)
		)


func _open_enemy_move_window() -> void:
	if GameFlow.phone_mode:
		return
	if enemy_loadout == null:
		return
	_refresh_enemy_move_reveal()
	enemy_move_window.popup_centered(Vector2i(960, 720))


func _build_enemy_move_reveal_card(move_card: Variant) -> Button:
	var button := Button.new()
	button.set_script(PLAKORO_MOVE_BUTTON)
	button.custom_minimum_size = Vector2(430, 220)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var damage_text: String = "-"
	if move_card.printed_damage != null:
		damage_text = str(int(move_card.printed_damage))

	var coverage_text: String = "-"
	if (
		ai_loadout_data != null
		and ai_loadout_data.energy_dice_setup != null
	):
		var coverage: Variant = MOVE_COVERAGE_ANALYZER.analyze_move(
			ai_loadout_data.energy_dice_setup,
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
	return button


func _create_move_buttons() -> void:
	for move_card: Variant in (
		player_loadout.selected_move_cards
	):
		if move_card == null:
			push_warning(
				"BattleGameUI: skipped a null Move Card while building buttons."
			)
			continue

		var button: Button = Button.new()
		button.set_script(
			PLAKORO_MOVE_BUTTON
		)
		var profile: StringName = (
			RESPONSIVE_UI.get_profile(
				self
			)
		)
		_apply_move_button_responsive_size(
			button,
			profile
		)
		var damage_text: String = "-"
		if move_card.printed_damage != null:
			damage_text = str(
				int(
					move_card.printed_damage
				)
			)

		var coverage: Variant = (
			MOVE_COVERAGE_ANALYZER.analyze_move(
				player_energy_setup,
				move_card
			)
		)
		var coverage_text: String = "-"

		if coverage != null:
			coverage_text = LocalizationService.format_percent(
				float(
					coverage.success_probability
				),
				0
			)

		button.setup_battle_summary(
			move_card,
			damage_text,
			coverage_text
		)
		if OS.has_feature("web"):
			button.call("set_web_popup_allow_use", true)
			button.pressed.connect(
				func() -> void:
					button.call("_open_web_move_info_popup")
			)
			button.connect(
				"web_move_use_requested",
				Callable(self, "_on_move_pressed")
			)
		else:
			button.pressed.connect(
				_on_move_pressed.bind(
					StringName(move_card.id)
				)
			)

		move_button_container.add_child(button)
		move_buttons.append(button)

	if layout_prototype != null and layout_prototype.visible:
		_apply_prototype_move_button_size()


func _format_move_button_text(
	move_card: Variant
) -> String:
	var costs: Array[String] = []

	for cost: Variant in move_card.energy_costs:
		costs.append(
			_energy_icon(
				StringName(cost.energy_type)
			)
			+ " "
			+ GameContentLocalizationService.localize_type(cost.energy_type)
			+ "x"
			+ str(int(cost.count))
		)

	var damage_text: String = "-"
	if move_card.printed_damage != null:
		damage_text = str(
			int(move_card.printed_damage)
		)

	var coverage: Variant = (
		MOVE_COVERAGE_ANALYZER.analyze_move(
			player_energy_setup,
			move_card
		)
	)

	var coverage_text: String = "-"
	if coverage != null:
		coverage_text = (
			"%.0f%%"
			% (
				float(
					coverage.success_probability
				)
				* 100.0
			)
		)

	return (
		GameContentLocalizationService.localize_move(move_card)
		+ "\n"
		+ ", ".join(costs)
		+ " | DMG "
		+ damage_text
		+ " | "
		+ coverage_text
	)


func _refresh_current_energy_state(
	move_card: Variant,
	dice_result: Variant,
	actor_label: String = "USER"
) -> void:
	if GameFlow.phone_mode:
		energy_state_panel.visible = false
		return
	if move_card == null or dice_result == null:
		energy_state_panel.visible = false
		return

	var sufficient: bool = ENERGY_RESOLVER.can_pay_cost(
		move_card,
		dice_result
	)
	energy_state_panel.visible = true
	energy_payment_label.text = LocalizationService.tr_format(
		(
			"battle.energy_met"
			if sufficient
			else "battle.energy_not_met"
		),
		{
			"actor": actor_label
		},
		(
			"[OK] {actor} Energy requirement met"
			if sufficient
			else "X {actor} Energy requirement not met"
		)
	)


func _clear_current_energy_state() -> void:
	energy_payment_label.text = ""
	energy_state_panel.visible = (
		not GameFlow.phone_mode
		and layout_prototype != null
		and layout_prototype.visible
	)


func _on_move_pressed(
	move_card_id: StringName
) -> void:
	if input_locked:
		return

	if battle == null or battle.state == null:
		return

	if battle.state.is_finished:
		return

	if (
		battle.state.current_participant_id
		!= &"player"
	):
		return

	_set_player_input_enabled(false)
	_set_battle_navigation_locked(true)
	await _hold_action_state(
		&"rolling",
		1.0
	)
	MESSAGE_PRESENTER.show_normal(
		message_label,
		"Rolling Enerkoro..."
	)

	var actor: Variant = battle.state.player
	var profiles: Array = _create_profiles(
		actor.loadout
	)

	var dice_modifier_report: Dictionary = (
		STATUS_RESOLVER
		.consume_energy_dice_modifier_report(
			actor
		)
	)
	var dice_modifier: int = int(
		dice_modifier_report.get(
			"value",
			0
		)
	)

	var kyokoro_disable_report: Dictionary = (
		STATUS_RESOLVER
		.consume_kyokoro_disable_report(
			actor
		)
	)
	var kyokoro_enabled: bool = not bool(
		kyokoro_disable_report.get(
			"consumed",
			false
		)
	)

	if bool(
		dice_modifier_report.get(
			"consumed",
			false
		)
	):
		MESSAGE_PRESENTER.show_normal(
			message_label,
			"Enerkoro modifier "
			+ str(dice_modifier)
			+ " applied. Rolling..."
		)

	var forced_orientation: StringName = &""
	if kyokoro_enabled:
		forced_orientation = STATUS_RESOLVER.consume_forced_kyokoro_orientation(actor)

	var dice_result: Variant = (
		player_dice_engine.roll_battle_dice(
			profiles,
			actor.pokemon_data.kyokoro_profile,
			dice_modifier,
			kyokoro_enabled,
			forced_orientation
		)
	)

	if dice_result == null:
		message_label.text = "Dice roll failed."
		_set_battle_action_state(&"choose_move")
		_set_player_input_enabled(true)
		_set_battle_navigation_locked(false)
		return

	var move_card: Variant = (
		RESOURCE_RECOVERY.safe_get_move(
			database,
			move_card_id,
			"Player turn"
		)
	)

	if move_card == null:
		message_label.text = (
			"Move is no longer available: "
			+ String(move_card_id)
		)
		_set_battle_action_state(&"choose_move")
		_set_player_input_enabled(true)
		_set_battle_navigation_locked(false)
		return

	var roll_record: Variant = null
	var roll_history: Array = (
		player_dice_engine.get_history()
	)

	if not roll_history.is_empty():
		roll_record = roll_history.back()

	var initial_energy_sufficient: bool = (
		ENERGY_RESOLVER.can_pay_cost(
			move_card,
			dice_result
		)
	)

	var opponent_enerkoro_profiles: Array = (
		_create_profiles(
			battle.state.get_opponent_participant().loadout
		)
	)
	var opponent_enerkoro_roll: Dictionary = {
		"generated": false
	}

	if initial_energy_sufficient:
		SPECIAL_KYOKORO_SEQUENCE.populate_additional_rolls(
			move_card,
			dice_result,
			player_dice_engine,
			actor.pokemon_data.kyokoro_profile
		)

		SPECIAL_KYOKORO_SEQUENCE.populate_opponent_roll(
			move_card,
			dice_result,
			player_dice_engine,
			battle.state.get_opponent_participant().pokemon_data.kyokoro_profile
		)

		opponent_enerkoro_roll = (
			SPECIAL_OPPONENT_ENERKORO.populate_roll(
				move_card,
				dice_result,
				player_dice_engine,
				opponent_enerkoro_profiles
			)
		)

	_clear_charakoro_feedback()
	# 12.9g Fix 5:
	# This is still the PLAYER roll. Do not switch the persistent Turn Dialog
	# to AI TURN until the actual AI phase begins.
	await _hold_action_state(
		&"rolling",
		1.0
	)
	roll_result_panel.visible = true
	await battle_dice_roll_presenter.play_result(
		dice_result,
		profiles,
		roll_record
	)
	_refresh_current_energy_state(
		move_card,
		dice_result,
		"USER"
	)

	if bool(
		opponent_enerkoro_roll.get(
			"generated",
			false
		)
	):
		await battle_dice_roll_presenter.play_opponent_enerkoro_result(
			opponent_enerkoro_roll.get(
				"dice_result",
				null
			),
			opponent_enerkoro_profiles,
			opponent_enerkoro_roll.get(
				"roll_record",
				null
			)
		)

	if bool(
		dice_result.opponent_kyokoro_roll_triggered
	):
		await battle_dice_roll_presenter.play_opponent_kyokoro_roll(
			StringName(
				dice_result.opponent_kyokoro_orientation
			)
		)

	if not dice_result.additional_kyokoro_orientations.is_empty():
		await battle_dice_roll_presenter.play_kyokoro_sequence(
			dice_result.additional_kyokoro_orientations
		)

	if initial_energy_sufficient:
		_show_charakoro_feedback(
			move_card,
			dice_result,
			&"player"
		)
	else:
		_clear_charakoro_feedback()

	if (
		initial_energy_sufficient
		and SPECIAL_MOVE_SELECTION.requires_selection(
			move_card,
			dice_result
		)
	):
		_set_battle_action_state(&"select_target")
		var selected_move_name_id: StringName = (
			await _request_special_move_lock_target(
				battle.state.get_opponent_participant()
			)
		)

		if selected_move_name_id == &"":
			message_label.text = (
				LocalizationService.tr_key(
					"battle.move_selection_cancelled",
					"Move selection was cancelled."
				)
			)
			_set_battle_action_state(&"choose_move")
			_set_player_input_enabled(true)
			_set_battle_navigation_locked(false)
			return

		dice_result.selected_opponent_move_name_id = (
			selected_move_name_id
		)

	var turn_number: int = battle.state.turn_number

	var enemy_hp_before: int = int(
		battle.state.enemy.current_hp
	)
	var player_hp_before: int = int(
		battle.state.player.current_hp
	)

	if not GameFlow.phone_mode:
		await _hold_action_state(
			&"resolving",
			1.0
		)
	var turn_result: Variant = battle.execute_turn(
		move_card_id,
		dice_result
	)

	await _present_phone_roll_confirmation(
		GameContentLocalizationService.localize_pokemon(
			battle.state.player.pokemon_data
		),
		GameContentLocalizationService.localize_move(move_card),
		initial_energy_sufficient,
		turn_result
	)

	if not turn_result.success:
		message_label.text = (
			turn_result.error_message
		)
		_refresh_ui()
		_set_battle_action_state(&"choose_move")
		_set_player_input_enabled(true)
		_set_battle_navigation_locked(false)
		return

	if GameFlow.phone_mode:
		await _hold_action_state(
			&"resolving",
			1.0
		)

	_show_prototype_battle_message(
		GameContentLocalizationService.localize_pokemon(
			battle.state.player.pokemon_data
		),
		GameContentLocalizationService.localize_pokemon(
			battle.state.enemy.pokemon_data
		),
		move_card,
		turn_result,
		player_hp_before,
		int(battle.state.player.current_hp),
		enemy_hp_before,
		int(battle.state.enemy.current_hp)
	)

	_add_timeline_turn(
		TIMELINE_BUILDER.build_turn(
			turn_number,
			&"player",
			move_card,
			dice_result,
			turn_result
		)
	)

	var player_damage: int = max(
		0,
		enemy_hp_before
		- int(battle.state.enemy.current_hp)
	)

	if player_damage > 0:
		player_damage_dealt += player_damage

	await _present_turn_damage(
		turn_result,
		&"player",
		enemy_hp_before,
		player_hp_before,
		move_card,
		_turn_attack_executed(
			turn_result,
			initial_energy_sufficient
		)
	)
	_refresh_ui()

	if battle.state.is_finished:
		# _present_turn_damage() has completed all target/self HP beats before
		# the KO/result UI is revealed.
		_show_battle_result()
		return

	MESSAGE_PRESENTER.show_ai(
		message_label,
		LocalizationService.tr_key(
			"battle.ai_thinking",
			"AI is thinking..."
		)
	)
	await _hold_action_state(
		&"ai_thinking",
		1.0
	)
	await _execute_ai_turn()


func _execute_ai_turn() -> void:
	if battle.state.is_finished:
		# _present_turn_damage() has completed all target/self HP beats before
		# the KO/result UI is revealed.
		_show_battle_result()
		return

	var turn_number: int = battle.state.turn_number

	var player_hp_before: int = int(
		battle.state.player.current_hp
	)
	var enemy_hp_before: int = int(
		battle.state.enemy.current_hp
	)

	TURN_BANNER.show_turn(
		turn_banner_panel,
		turn_banner_label,
		int(turn_number),
		&"enemy"
	)

	var execution: Dictionary = (
		ai_turn_service.execute_ai_turn(
			StringName(ai_loadout_data.difficulty)
		)
	)

	var decision: Variant = execution.get(
		"decision",
		null
	)
	var dice_result: Variant = execution.get(
		"dice_result",
		null
	)
	var turn_result: Variant = execution.get(
		"turn_result",
		null
	)
	var ai_energy_profiles: Array = execution.get(
		"energy_profiles",
		[]
	)
	var ai_roll_record: Variant = execution.get(
		"roll_record",
		null
	)
	var ai_opponent_enerkoro_roll: Dictionary = execution.get(
		"opponent_enerkoro_roll",
		{}
	)
	var ai_opponent_enerkoro_profiles: Array = execution.get(
		"opponent_enerkoro_profiles",
		[]
	)

	if (
		decision == null
		or not decision.is_valid()
		or dice_result == null
		or turn_result == null
	):
		message_label.text = LocalizationService.tr_key(
			"battle.ai_turn_failed",
			"AI turn failed."
		)
		_set_battle_action_state(&"choose_move")
		_set_player_input_enabled(true)
		_set_battle_navigation_locked(false)
		return

	var feedback_move_card: Variant = (
		RESOURCE_RECOVERY.safe_get_move(
			database,
			decision.selected_move_card_id,
			"AI Charakoro feedback"
		)
	)

	_refresh_current_energy_state(
		feedback_move_card,
		dice_result,
		"AI"
	)

	# The AI dice presentation must explicitly enter the AI rolling phase.
	# battle.state.current_participant_id can already have advanced by the time
	# the visual roll is presented, so relying on state inference can leave
	# the persistent roll label showing the player's "YOUR ROLL" text.
	await _hold_action_state(
		&"ai_rolling",
		0.0
	)

	_clear_charakoro_feedback()
	roll_result_panel.visible = true
	await battle_dice_roll_presenter.play_result(
		dice_result,
		ai_energy_profiles,
		ai_roll_record
	)

	if bool(
		ai_opponent_enerkoro_roll.get(
			"generated",
			false
		)
	):
		await battle_dice_roll_presenter.play_opponent_enerkoro_result(
			ai_opponent_enerkoro_roll.get(
				"dice_result",
				null
			),
			ai_opponent_enerkoro_profiles,
			ai_opponent_enerkoro_roll.get(
				"roll_record",
				null
			)
		)

	if bool(
		dice_result.opponent_kyokoro_roll_triggered
	):
		await battle_dice_roll_presenter.play_opponent_kyokoro_roll(
			StringName(
				dice_result.opponent_kyokoro_orientation
			)
		)

	if not dice_result.additional_kyokoro_orientations.is_empty():
		await battle_dice_roll_presenter.play_kyokoro_sequence(
			dice_result.additional_kyokoro_orientations
		)

	_show_charakoro_feedback(
		feedback_move_card,
		dice_result,
		&"enemy"
	)

	var move_card: Variant = (
		RESOURCE_RECOVERY.safe_get_move(
			database,
			decision.selected_move_card_id,
			"AI turn"
		)
	)

	if move_card != null:
		if not GameFlow.phone_mode:
			await _hold_action_state(
				&"ai_resolving",
				1.0
			)
		var ai_energy_sufficient: bool = (
			ENERGY_RESOLVER.can_pay_cost(
				move_card,
				dice_result
			)
		)
		await _present_phone_roll_confirmation(
			GameContentLocalizationService.localize_pokemon(
				battle.state.enemy.pokemon_data
			),
			GameContentLocalizationService.localize_move(move_card),
			ai_energy_sufficient,
			turn_result
		)
		if GameFlow.phone_mode:
			await _hold_action_state(
				&"ai_resolving",
				1.0
			)
		_show_prototype_battle_message(
			GameContentLocalizationService.localize_pokemon(
				battle.state.enemy.pokemon_data
			),
			GameContentLocalizationService.localize_pokemon(
				battle.state.player.pokemon_data
			),
			move_card,
			turn_result,
			enemy_hp_before,
			int(battle.state.enemy.current_hp),
			player_hp_before,
			int(battle.state.player.current_hp)
		)
		_add_timeline_turn(
			TIMELINE_BUILDER.build_turn(
				turn_number,
				&"enemy",
				move_card,
				dice_result,
				turn_result,
				decision
			)
		)
	else:
		push_warning(
			"BattleGameUI: AI turn completed but its timeline row was skipped because the Move resource is missing."
		)

	var enemy_damage: int = max(
		0,
		player_hp_before
		- int(battle.state.player.current_hp)
	)

	if enemy_damage > 0:
		enemy_damage_dealt += enemy_damage

	await _present_turn_damage(
		turn_result,
		&"enemy",
		player_hp_before,
		enemy_hp_before,
		move_card,
		(
			move_card != null
			and ENERGY_RESOLVER.can_pay_cost(
				move_card,
				dice_result
			)
		)
	)
	_refresh_ui()

	if not bool(execution.get("success", false)):
		message_label.text = LocalizationService.tr_key(
			"battle.ai_turn_failed",
			"AI turn failed."
		)
		_set_battle_action_state(&"choose_move")
		_set_player_input_enabled(true)
		_set_battle_navigation_locked(false)
		return

	if battle.state.is_finished:
		_show_battle_result()
		return

	TURN_BANNER.show_turn(
		turn_banner_panel,
		turn_banner_label,
		int(battle.state.turn_number),
		&"player"
	)
	_set_battle_action_state(&"choose_move")
	MESSAGE_PRESENTER.show_player(
		message_label,
		LocalizationService.tr_key(
			"battle.choose_move",
			"Choose a move."
		)
	)
	_set_player_input_enabled(true)
	_set_battle_navigation_locked(false)


func _clear_charakoro_feedback() -> void:
	charakoro_feedback_title.text = ""
	charakoro_feedback_label.text = ""
	charakoro_feedback_panel.visible = (
		not GameFlow.phone_mode
		and layout_prototype != null
		and layout_prototype.visible
	)


func _present_phone_roll_confirmation(
	actor_name: String,
	move_name: String,
	enerkoro_succeeded: bool,
	turn_result: Variant
) -> void:
	if not GameFlow.phone_mode:
		return
	phone_roll_confirmation_changed.emit(
		&"move",
		true,
		actor_name + "\n" + move_name,
		0
	)

	var damage_context: Variant = turn_result.damage_context
	var base_damage: int = 0
	var charakoro_damage: int = 0
	var weakness_damage: int = 0
	if damage_context != null:
		base_damage = int(damage_context.base_damage)
		charakoro_damage = int(damage_context.outcome_bonus)
		weakness_damage = int(damage_context.weakness_bonus)

	phone_roll_confirmation_changed.emit(
		&"enerkoro",
		enerkoro_succeeded,
		"",
		base_damage
	)
	await get_tree().create_timer(1.0).timeout
	if not enerkoro_succeeded:
		phone_roll_confirmation_changed.emit(
			&"attack",
			false,
			"",
			0
		)
		await get_tree().create_timer(2.0).timeout
		return

	phone_roll_confirmation_changed.emit(
		&"charakoro",
		true,
		"",
		charakoro_damage
	)
	await get_tree().create_timer(1.0).timeout
	phone_roll_confirmation_changed.emit(
		&"weakness",
		true,
		"",
		weakness_damage
	)
	await get_tree().create_timer(1.0).timeout
	var attack_succeeded: bool = (
		turn_result.success
		and _turn_attack_executed(turn_result, true)
	)
	phone_roll_confirmation_changed.emit(
		&"attack",
		attack_succeeded,
		"",
		int(turn_result.applied_damage) if attack_succeeded else 0
	)
	await get_tree().create_timer(2.0).timeout


func _show_charakoro_feedback(
	move_card: Variant,
	dice_result: Variant,
	actor_side: StringName
) -> void:
	var feedback: Dictionary = (
		CHARAKORO_FEEDBACK.build_feedback(
			move_card,
			dice_result
		)
	)

	if not bool(
		feedback.get(
			"triggered",
			false
		)
	):
		_clear_charakoro_feedback()
		return

	var actor_text: String = LocalizationService.tr_key(
		(
			"battle.you"
			if actor_side == &"player"
			else "battle.ai"
		),
		(
			"USER"
			if actor_side == &"player"
			else "AI"
		)
	)
	charakoro_feedback_title.text = LocalizationService.tr_format(
		"battle.charakoro_triggered",
		{"actor": actor_text},
		"[OK] {actor} Charakoro effect triggered"
	)
	charakoro_feedback_label.text = LocalizationService.tr_format(
		"battle.charakoro_effect",
		{
			"effect": String(
				feedback.get(
					"summary",
					""
				)
			)
		},
		"Effect: {effect}"
	)
	charakoro_feedback_panel.visible = not GameFlow.phone_mode


func _request_special_move_lock_target(
	target_participant: Variant
) -> StringName:
	var targets: Array[Dictionary] = (
		SPECIAL_MOVE_SELECTION.get_available_targets(
			target_participant
		)
	)

	if targets.is_empty():
		return &""

	var popup: PopupPanel = PopupPanel.new()
	popup.name = "SpecialMoveSelectionPopup"
	popup.exclusive = true

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(
		"margin_left",
		18
	)
	margin.add_theme_constant_override(
		"margin_right",
		18
	)
	margin.add_theme_constant_override(
		"margin_top",
		16
	)
	margin.add_theme_constant_override(
		"margin_bottom",
		16
	)
	popup.add_child(
		margin
	)

	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(
		460,
		0
	)
	box.add_theme_constant_override(
		"separation",
		8
	)
	margin.add_child(
		box
	)

	var title: Label = Label.new()
	title.text = LocalizationService.tr_key(
		"battle.special_choose_title",
		"Choose an opponent Move to disable during their next turn"
	)
	title.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	title.add_theme_font_size_override(
		"font_size",
		18
	)
	box.add_child(
		title
	)

	var selected: Array[StringName] = []

	for target: Dictionary in targets:
		var button: Button = Button.new()
		var move_name_id: StringName = StringName(
			target.get(
				"move_name_id",
				""
			)
		)
		button.text = (
			String(
				target.get(
					"display_name",
					move_name_id
				)
			)
			+ "  ["
			+ String(
				move_name_id
			)
			+ "]"
		)
		button.custom_minimum_size = Vector2(
			0,
			42
		)
		button.pressed.connect(
			func() -> void:
				selected.append(
					move_name_id
				)
				special_move_target_selected.emit(
					move_name_id
				)
				popup.hide()
		)
		box.add_child(
			button
		)

	add_child(
		popup
	)
	popup.popup_centered(
		Vector2i(
			520,
			300
		)
	)

	_set_battle_navigation_locked(true)
	MESSAGE_PRESENTER.show_normal(
		message_label,
		LocalizationService.tr_key(
			"battle.special_choose_message",
			"Charakoro Effect triggered - choose an opponent Move."
		)
	)

	await special_move_target_selected

	_set_battle_navigation_locked(true)

	var result: StringName = (
		selected[0]
		if not selected.is_empty()
		else &""
	)

	if is_instance_valid(
		popup
	):
		popup.queue_free()

	return result


func _turn_attack_executed(
	turn_result: Variant,
	energy_sufficient: bool
) -> bool:
	if turn_result == null:
		return false

	if not energy_sufficient:
		return false

	# `turn_result.success` means the turn resolved without a runtime failure.
	# It does NOT necessarily mean the selected Move actually executed.
	# Energy payment is the first hard gate for ordinary attacks.
	return true


func _show_prototype_battle_message(
	actor_name: String,
	target_name: String,
	move_card: Variant,
	turn_result: Variant,
	actor_hp_before: int,
	actor_hp_after: int,
	target_hp_before: int,
	target_hp_after: int
) -> void:
	if prototype_battle_message_label == null:
		return

	var lines: Array[String] = (
		OUTCOME_FEEDBACK.build_lines(
			actor_name,
			target_name,
			move_card,
			turn_result,
			actor_hp_before,
			actor_hp_after,
			target_hp_before,
			target_hp_after
		)
	)

	prototype_battle_message_label.text = "\n".join(lines)


func _add_timeline_turn(
	turn: Variant
) -> void:
	if timeline_view.has_method("add_turn"):
		timeline_view.add_turn(turn)

	await get_tree().process_frame

	timeline_scroll.scroll_vertical = int(
		timeline_scroll.get_v_scroll_bar().max_value
	)


func _play_attack_vfx(
	move_card: Variant,
	actor_side: StringName
) -> void:
	if move_card == null:
		return

	var source_hero: Control = (
		player_hero_container
		if actor_side == &"player"
		else enemy_hero_container
	)
	var target_hero: Control = (
		enemy_hero_container
		if actor_side == &"player"
		else player_hero_container
	)
	var attack_type: StringName = StringName(move_card.attack_type)
	var effect: Control = ATTACK_VFX.new()
	effect.name = "BattleAttackVFX"
	add_child(effect)
	await effect.play(
		source_hero,
		target_hero,
		attack_type
	)


func _present_turn_damage(
	turn_result: Variant,
	actor_side: StringName,
	target_hp_before: int,
	actor_hp_before: int,
	move_card: Variant = null,
	attack_executed: bool = false
) -> void:
	if turn_result == null:
		return

	var target_bar: ProgressBar = enemy_hp_bar if actor_side == &"player" else player_hp_bar
	var target_label: Label = enemy_hp_label if actor_side == &"player" else player_hp_label
	var target_hero: Control = enemy_hero_container if actor_side == &"player" else player_hero_container
	var target_max_hp: int = int(battle.state.enemy.max_hp) if actor_side == &"player" else int(battle.state.player.max_hp)
	var final_target_hp: int = int(battle.state.enemy.current_hp) if actor_side == &"player" else int(battle.state.player.current_hp)
	var actual_damage: int = max(0, target_hp_before - final_target_hp)

	# Attack VFX is keyed from the Move's attack_type / Energy family and is
	# played only after the Move has passed its Energy gate. This keeps the
	# animation synchronized with real battle execution for both Player and AI.
	if attack_executed and move_card != null:
		await _play_attack_vfx(
			move_card,
			actor_side
		)

	if not RESOLUTION_PRESENTATION_CONFIG.is_step_by_step():
		if actual_damage > 0:
			FLOATING_TEXT.show_damage(
				self,
				target_hero,
				actual_damage
			)
		await _animate_hp_bars()
		return

	# Step-by-step must not return early just because the opponent took no
	# damage. A Move may still contain recoil/self-damage, including a
	# self-KO. Target and actor presentation phases are therefore independent.
	if actual_damage > 0:
		HP_PRESENTER.refresh(
			target_bar,
			target_label,
			target_hp_before,
			target_max_hp
		)

	var resolution_events: Array = []
	for raw_event: Variant in turn_result.resolution_events:
		if raw_event is Dictionary:
			resolution_events.append(
				raw_event
			)

	var step_queue: Array[Dictionary] = []
	if actual_damage > 0:
		step_queue = (
			RESOLUTION_STEP_QUEUE_BUILDER.build_target_damage_queue(
				resolution_events,
				target_hp_before,
				final_target_hp
			)
		)

	for step: Dictionary in step_queue:
		var kind: StringName = StringName(step.get("kind", &""))
		if kind == &"hp_update":
			var tween: Tween = HP_PRESENTER.refresh(
				target_bar,
				target_label,
				int(step.get("hp_after", final_target_hp)),
				target_max_hp,
				true,
				self
			)
			if tween != null:
				await tween.finished
			await get_tree().create_timer(0.18).timeout
			continue

		var amount: int = max(
			int(
				step.get(
					"amount",
					0
				)
			),
			0
		)
		if amount <= 0:
			continue

		var step_label: String = String(
			step.get(
				"label",
				LocalizationService.tr_key(
					"battle.damage",
					"Damage"
				)
			)
		)
		var effect_trigger_index: int = int(
			step.get(
				"effect_trigger_index",
				0
			)
		)

		if (
			kind == &"effect_damage"
			and effect_trigger_index > 0
		):
			step_label += (
				" #"
				+ str(
					effect_trigger_index
				)
			)
		elif kind == &"weakness_damage":
			step_label = LocalizationService.tr_key(
				"battle.weakness_damage",
				"Weakness Damage"
			)

		MESSAGE_PRESENTER.show_normal(
			message_label,
			LocalizationService.tr_format(
				"battle.damage_step",
				{
					"label": step_label,
					"amount": amount
				},
				"{label}: {amount}"
			)
		)
		FLOATING_TEXT.show_damage(
			self,
			target_hero,
			amount
		)

	var actor_bar: ProgressBar = (
		player_hp_bar
		if actor_side == &"player"
		else enemy_hp_bar
	)
	var actor_label: Label = (
		player_hp_label
		if actor_side == &"player"
		else enemy_hp_label
	)
	var actor_hero: Control = (
		player_hero_container
		if actor_side == &"player"
		else enemy_hero_container
	)
	var actor_max_hp: int = (
		int(battle.state.player.max_hp)
		if actor_side == &"player"
		else int(battle.state.enemy.max_hp)
	)
	var final_actor_hp: int = (
		int(battle.state.player.current_hp)
		if actor_side == &"player"
		else int(battle.state.enemy.current_hp)
	)
	var actual_self_damage: int = max(
		0,
		actor_hp_before - final_actor_hp
	)

	if actual_self_damage <= 0:
		HP_PRESENTER.refresh(
			actor_bar,
			actor_label,
			final_actor_hp,
			actor_max_hp
		)
		return

	if not RESOLUTION_PRESENTATION_CONFIG.is_step_by_step():
		# Quick mode's _animate_hp_bars() already synchronized both sides.
		return

	HP_PRESENTER.refresh(
		actor_bar,
		actor_label,
		actor_hp_before,
		actor_max_hp
	)

	var self_damage_events: Array = []
	for raw_self_event: Variant in turn_result.resolution_self_damage_events:
		if raw_self_event is Dictionary:
			self_damage_events.append(
				raw_self_event
			)

	var self_damage_queue: Array[Dictionary] = (
		RESOLUTION_STEP_QUEUE_BUILDER.build_self_damage_queue(
			self_damage_events,
			actor_hp_before,
			final_actor_hp
		)
	)

	for step: Dictionary in self_damage_queue:
		var kind: StringName = StringName(
			step.get(
				"kind",
				&""
			)
		)

		if kind == &"hp_update":
			var self_tween: Tween = HP_PRESENTER.refresh(
				actor_bar,
				actor_label,
				int(
					step.get(
						"hp_after",
						final_actor_hp
					)
				),
				actor_max_hp,
				true,
				self
			)
			if self_tween != null:
				await self_tween.finished

			await get_tree().create_timer(
				0.18
			).timeout
			continue

		var amount: int = max(
			int(
				step.get(
					"amount",
					0
				)
			),
			0
		)

		if amount <= 0:
			continue

		var step_label: String = String(
			step.get(
				"label",
				LocalizationService.tr_key(
					"battle.self_damage",
					"Self Damage"
				)
			)
		)
		var self_damage_index: int = int(
			step.get(
				"self_damage_index",
				0
			)
		)

		if self_damage_index > 1:
			step_label += (
				" #"
				+ str(
					self_damage_index
				)
			)

		MESSAGE_PRESENTER.show_failure(
			message_label,
			LocalizationService.tr_format(
				"battle.damage_step",
				{
					"label": step_label,
					"amount": amount
				},
				"{label}: {amount}"
			)
		)
		FLOATING_TEXT.show_damage(
			self,
			actor_hero,
			amount
		)
func _show_hp_delta_feedback(
	anchor: Control,
	hp_before: int,
	hp_after: int
) -> void:
	var delta: int = hp_after - hp_before
	if delta < 0:
		FLOATING_TEXT.show_damage(self, anchor, abs(delta))
	elif delta > 0:
		FLOATING_TEXT.show_heal(self, anchor, delta)


func _animate_hp_bars() -> void:
	var player_tween: Tween = (
		HP_PRESENTER.refresh(
			player_hp_bar,
			player_hp_label,
			int(battle.state.player.current_hp),
			int(battle.state.player.max_hp),
			true,
			self
		)
	)

	var enemy_tween: Tween = (
		HP_PRESENTER.refresh(
			enemy_hp_bar,
			enemy_hp_label,
			int(battle.state.enemy.current_hp),
			int(battle.state.enemy.max_hp),
			true,
			self
		)
	)

	if player_tween != null:
		await player_tween.finished
	elif enemy_tween != null:
		await enemy_tween.finished


func _format_battle_weakness(
	pokemon_data: Variant
) -> String:
	if pokemon_data == null:
		return LocalizationService.tr_format(
			"battle.weakness_value",
			{"value": "-"},
			"Weakness: {value}"
		)

	var weaknesses: Variant = pokemon_data.weaknesses
	if (
		not (weaknesses is Array)
		or (weaknesses as Array).is_empty()
	):
		return LocalizationService.tr_key(
			"battle.weakness_none",
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
						"bonus": LocalizationService.format_integer(
							bonus_damage
						)
					},
					"{type} +{bonus}"
				)
			)

	return LocalizationService.tr_format(
		"battle.weakness_value",
		{
			"value": (
				", ".join(parts)
				if not parts.is_empty()
				else LocalizationService.tr_key(
					"battle.none",
					"(none)"
				)
			)
		},
		"Weakness: {value}"
	)



func _refresh_combatant_identity() -> void:
	player_type_label.visible = not GameFlow.phone_mode
	enemy_type_label.visible = not GameFlow.phone_mode
	player_weakness_label.visible = not GameFlow.phone_mode
	enemy_weakness_label.visible = not GameFlow.phone_mode

	if battle == null or battle.state == null:
		player_type_label.text = LocalizationService.tr_format(
			"battle.type_value",
			{"type": "-"},
			"Type: {type}"
		)
		enemy_type_label.text = LocalizationService.tr_format(
			"battle.type_value",
			{"type": "-"},
			"Type: {type}"
		)
		player_weakness_label.text = LocalizationService.tr_format(
			"battle.weakness_value",
			{"value": "-"},
			"Weakness: {value}"
		)
		enemy_weakness_label.text = LocalizationService.tr_format(
			"battle.weakness_value",
			{"value": "-"},
			"Weakness: {value}"
		)
		return

	var state: Variant = battle.state
	var player_pokemon: Variant = state.player.pokemon_data
	var enemy_pokemon: Variant = state.enemy.pokemon_data

	player_type_label.text = LocalizationService.tr_format(
		"battle.type_value",
		{
			"type": GameContentLocalizationService.localize_type(
				player_pokemon.pokemon_type
			)
		},
		"Type: {type}"
	)
	enemy_type_label.text = LocalizationService.tr_format(
		"battle.type_value",
		{
			"type": GameContentLocalizationService.localize_type(
				enemy_pokemon.pokemon_type
			)
		},
		"Type: {type}"
	)
	player_weakness_label.text = _format_battle_weakness(
		player_pokemon
	)
	enemy_weakness_label.text = _format_battle_weakness(
		enemy_pokemon
	)


func _refresh_ui() -> void:
	if battle == null or battle.state == null:
		return

	var state: Variant = battle.state

	player_name_label.text = GameContentLocalizationService.localize_pokemon(
		state.player.pokemon_data
	)
	enemy_name_label.text = GameContentLocalizationService.localize_pokemon(
		state.enemy.pokemon_data
	)

	_refresh_combatant_identity()
	if GameFlow.phone_mode:
		player_name_label.text = "%s [%s]" % [
			player_name_label.text,
			player_weakness_label.text
		]
		enemy_name_label.text = "%s [%s]" % [
			enemy_name_label.text,
			enemy_weakness_label.text
		]

	HP_PRESENTER.refresh(
		player_hp_bar,
		player_hp_label,
		int(state.player.current_hp),
		int(state.player.max_hp)
	)
	HP_PRESENTER.refresh(
		enemy_hp_bar,
		enemy_hp_label,
		int(state.enemy.current_hp),
		int(state.enemy.max_hp)
	)

	turn_label.text = LocalizationService.tr_format(
		"battle.turn_header",
		{
			"turn": int(
				state.turn_number
			),
			"actor": LocalizationService.tr_key(
				(
					"battle.player"
					if state.current_participant_id == &"player"
					else "battle.ai"
				),
				(
					"Player"
					if state.current_participant_id == &"player"
					else "AI"
				)
			)
		},
		"Turn {turn} - {actor}"
	)

	_refresh_pending_effect_indicators()
	_refresh_move_button_states()


func _refresh_pending_effect_indicators() -> void:
	if battle == null or battle.state == null:
		player_pending_effect_indicator.visible = false
		enemy_pending_effect_indicator.visible = false
		return

	var state: Variant = battle.state
	var turn_number: int = int(
		state.turn_number
	)

	player_pending_effect_indicator.refresh(
		state.player,
		turn_number
	)
	enemy_pending_effect_indicator.refresh(
		state.enemy,
		turn_number
	)


func _refresh_move_button_states() -> void:
	if battle == null:
		return

	for index: int in range(
		move_buttons.size()
	):
		var button: Button = move_buttons[index]
		var move_card: Variant = (
			player_loadout.selected_move_cards[index]
		)

		var move_name_id: StringName = StringName(
			move_card.move_name_id
		)
		var usable: bool = (
			battle.state.player.can_use_move(
				move_name_id
			)
		)
		var unavailable_reason: String = ""

		if not usable:
			if STATUS_RESOLVER.is_move_locked(
				battle.state.player,
				move_name_id
			):
				unavailable_reason = LocalizationService.tr_key(
					"battle.move_unavailable.disabled",
					"Disabled by an active effect"
				)
			elif battle.state.player.last_move_name_id == move_name_id:
				unavailable_reason = LocalizationService.tr_key(
					"battle.move_unavailable.repeat",
					"Cannot repeat this move"
				)
			else:
				unavailable_reason = LocalizationService.tr_key(
					"battle.move_unavailable.generic",
					"Move is currently unavailable"
				)

		var coverage: Variant = (
			MOVE_COVERAGE_ANALYZER.analyze_move(
				player_energy_setup,
				move_card
			)
		)
		var coverage_text: String = "-"
		if coverage != null:
			coverage_text = LocalizationService.format_percent(
				float(coverage.success_probability),
				0
			)

		if button.has_method("set_battle_availability"):
			button.call(
				"set_battle_availability",
				usable,
				unavailable_reason,
				coverage_text
			)

		if OS.has_feature("web"):
			# Web users may inspect an unavailable move; the popup Use button
			# remains disabled and cannot bypass battle validation.
			button.disabled = (
				input_locked
				or battle.state.is_finished
			)
		else:
			button.disabled = (
				input_locked
				or not usable
				or battle.state.is_finished
			)


func _set_player_input_enabled(
	enabled: bool
) -> void:
	input_locked = not enabled
	_refresh_move_button_states()


func _set_battle_navigation_locked(
	locked: bool
) -> void:
	navigation_locked = locked
	back_to_preparation_button.disabled = locked
	restart_button.disabled = locked

	if result_restart_button != null:
		result_restart_button.disabled = locked

	if result_preparation_button != null:
		result_preparation_button.disabled = locked


func _show_battle_result() -> void:
	if battle_report_transition_requested:
		return
	battle_report_transition_requested = true
	_set_player_input_enabled(false)
	_set_battle_navigation_locked(true)
	_set_battle_action_state(&"battle_finished")
	# The full Battle Report is the only post-battle UI. Defer the transition
	# until the current damage/KO presentation stack has returned.
	_open_battle_report.call_deferred(false)


func _refresh_result_primary_button() -> void:
	var player_won: bool = (
		battle != null
		and battle.state != null
		and battle.state.is_finished
		and battle.state.winner_participant_id == &"player"
	)
	result_restart_button.text = LocalizationService.tr_key(
		"battle.next_opponent" if player_won else "battle.restart",
		"Next Opponent" if player_won else "Restart"
	)


func _on_result_primary_pressed() -> void:
	if (
		battle != null
		and battle.state != null
		and battle.state.is_finished
		and battle.state.winner_participant_id == &"player"
	):
		# Record rewards and unlock the next encounter before advancing.
		_open_battle_report(true)
		return
	_start_new_battle()


func _open_battle_report(advance_to_next_opponent: bool = false) -> void:
	if battle == null or battle.state == null or not battle.state.is_finished:
		return

	var outcome: Variant = BATTLE_OUTCOME_DATA.new()
	outcome.winner_participant_id = battle.state.winner_participant_id
	outcome.player_pokemon_id = player_loadout_data.pokemon_id
	outcome.encounter_id = EncounterSession.get_current_encounter_id()
	if EncounterSession.has_active_encounter():
		outcome.reward_pokemon_id = StringName(
			EncounterSession.current_encounter.get("pokemon_id", "")
		)
		outcome.reward_move_card_ids = (
			EncounterSession.current_encounter.get("reward_move_ids", []) as Array
		).duplicate()
	outcome.turn_count = int(battle.state.turn_number)
	outcome.player_name = String(battle.state.player.display_name)
	outcome.enemy_name = String(battle.state.enemy.display_name)
	outcome.player_damage_dealt = player_damage_dealt
	outcome.enemy_damage_dealt = enemy_damage_dealt
	outcome.player_hp = int(battle.state.player.current_hp)
	outcome.player_max_hp = int(battle.state.player.max_hp)
	outcome.enemy_hp = int(battle.state.enemy.current_hp)
	outcome.enemy_max_hp = int(battle.state.enemy.max_hp)
	GameFlow.finish_battle(outcome, advance_to_next_opponent)


func _create_profiles(
	loadout: Variant
) -> Array:
	var result: Array = []

	for die_config: Variant in loadout.energy_dice:
		result.append(
			die_config.create_profile()
		)

	return result


func _clear_move_buttons() -> void:
	for button: Button in move_buttons:
		if is_instance_valid(button):
			button.queue_free()

	move_buttons.clear()


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
