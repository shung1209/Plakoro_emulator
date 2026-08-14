extends Control

const LANGUAGE_PACK_VALIDATOR: Script = preload(
    "res://scripts/localization/LanguagePackValidator.gd"
)


const USER_DATABASE: Script = preload("res://scripts/content/UserDatabasePathService.gd")


const PLAKORO_THEME: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const RESPONSIVE_UI: Script = preload(
    "res://scripts/ui/responsive/ResponsiveUIService.gd"
)
const RESPONSIVE_PROFILE: Script = preload(
    "res://scripts/ui/responsive/UIResponsiveProfile.gd"
)
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const KYOKORO_AUTHORING: Script = preload(
    "res://scripts/content/KyokoroProfileAuthoringService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const POKEMON_MOVE_REFERENCE: Script = preload(
    "res://scripts/content/PokemonMoveReferenceService.gd"
)
const DATABASE_INTEGRITY: Script = preload(
    "res://scripts/content/ContentDatabaseIntegrityService.gd"
)
const CONTENT_PLAYTEST: Script = preload(
    "res://scripts/content/ContentPlaytestBridgeService.gd"
)
const DICE_BUILDER_CONTEXT: Script = preload(
    "res://scripts/dice/setup/EnergyDiceBuilderContextService.gd"
)
const DEFAULT_DICE_GENERATOR: Script = preload(
    "res://scripts/dice/setup/PokemonDefaultDiceGenerator.gd"
)
const CONTENT_DELETE: Script = preload(
    "res://scripts/content/ContentDeleteService.gd"
)
const CONTENT_SOURCE: Script = preload(
    "res://scripts/content/ContentDataSourceService.gd"
)
const CONTENT_CLONE: Script = preload(
    "res://scripts/content/ContentCloneService.gd"
)
const MOVE_RUNTIME_COMPATIBILITY: Script = preload(
    "res://scripts/runtime/MoveRuntimeCompatibilityService.gd"
)
const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)
const POKEMON_PRESENTATION: Script = preload(
    "res://scripts/presentation/PokemonPresentationAssetService.gd"
)
const ENERGY_COST_EDITOR_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostEditorRow.gd"
)
const ENERGY_COST_CHIP: Script = preload(
    "res://scripts/ui/components/EnergyCostChip.gd"
)
const MOVE_ACTION_EDITOR_ROW: Script = preload(
    "res://scripts/ui/components/MoveActionEditorRow.gd"
)
const MOVE_OUTCOME_RULE_EDITOR: Script = preload(
    "res://scripts/ui/components/MoveOutcomeRuleEditor.gd"
)

const PREPARATION_SCENE: String = (
    "res://scenes/ui/BattlePreparationUI.tscn"
)
const ENERGY_DICE_BUILDER_SCENE: String = (
    "res://scenes/ui/EnergyDiceVisualBuilderUI.tscn"
)
const CONTENT_STUDIO_SCENE: String = (
    "res://scenes/ui/PlakoroContentStudioUI.tscn"
)

const MODE_POKEMON: StringName = &"pokemon"
const MODE_KYOKORO: StringName = &"kyokoro"
const MODE_MOVE: StringName = &"move"
const MODE_MODEL_WEIGHT: StringName = &"model_weight"


@onready var margin: MarginContainer = $Margin
@onready var page_title: Label = $Margin/Main/Header/Title
@onready var main: VBoxContainer = $Margin/Main
@onready var body: HSplitContainer = $Margin/Main/Body

@onready var pokemon_tab: Button = %PokemonTab
@onready var kyokoro_tab: Button = %KyokoroTab
@onready var move_tab: Button = %MoveTab
@onready var model_weight_tab: Button = %ModelWeightTab
@onready var technical_details_toggle: CheckButton = %TechnicalDetailsToggle
@onready var pokemon_schema_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/PokemonEditor/SchemaPanel
@onready var kyokoro_schema_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/KyokoroEditor/ProfileSchemaPanel
@onready var kyokoro_physics_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/KyokoroEditor/PhysicsPanel
@onready var move_runtime_status: Label = %MoveRuntimeStatus
@onready var move_schema_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/MoveEditor/MoveSchemaPanel
@onready var move_advanced_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/MoveEditor/MoveAdvancedPanel
@onready var move_raw_preview_panel: PanelContainer = $Margin/Main/Body/EditorScroll/EditorRoot/MoveEditor/RawPreviewPanel
@onready var library_title: Label = %LibraryTitle
@onready var library_search_edit: LineEdit = %LibrarySearchEdit
@onready var library_search_clear_button: Button = %LibrarySearchClearButton
@onready var library_filter_status: Label = %LibraryFilterStatus
@onready var library_source_filter: OptionButton = %LibrarySourceFilter
@onready var library_type_filter: OptionButton = %LibraryTypeFilter
@onready var saved_list: ItemList = %SavedContentList
@onready var library_source_status: Label = %LibrarySourceStatus
@onready var restore_builtin_button: Button = %RestoreBuiltinButton
@onready var restore_builtin_dialog: ConfirmationDialog = %RestoreBuiltinDialog
@onready var restore_builtin_message_label: Label = %RestoreBuiltinMessageLabel

@onready var authoring_session_title: Label = %AuthoringSessionTitle
@onready var authoring_session_state: Label = %AuthoringSessionState
@onready var authoring_dependency_summary: Label = %AuthoringDependencySummary
@onready var authoring_impact_warning: Label = %AuthoringImpactWarning
@onready var new_content_guide_panel: PanelContainer = %NewContentGuidePanel
@onready var new_content_guide_title: Label = %NewContentGuideTitle
@onready var new_content_guide_hint: Label = %NewContentGuideHint
@onready var new_content_guide_checklist: Label = %NewContentGuideChecklist

@onready var pokemon_editor: VBoxContainer = %PokemonEditor
@onready var kyokoro_editor: VBoxContainer = %KyokoroEditor
@onready var move_editor: VBoxContainer = %MoveEditor
@onready var model_weight_panel: Control = %ModelWeightGeneratorPanel

@onready var id_edit: LineEdit = %IdEdit
@onready var species_id_edit: LineEdit = %SpeciesIdEdit
@onready var name_edit: LineEdit = %NameEdit
@onready var hp_spin: SpinBox = %HpSpin
@onready var pokemon_charakoro_preview: TextureRect = %PokemonCharakoroPreview
@onready var pokemon_charakoro_preview_status: Label = %PokemonCharakoroPreviewStatus
@onready var type_option: OptionButton = %TypeOption
@onready var weakness_type_option: OptionButton = %WeaknessTypeOption
@onready var weakness_bonus_spin: SpinBox = %WeaknessBonusSpin
@onready var kyokoro_profile_option: OptionButton = %KyokoroProfileOption
@onready var kyokoro_profile_status: Label = %KyokoroProfileStatus
@onready var available_move_list: ItemList = %AvailableMoveList
@onready var selected_move_list: ItemList = %SelectedMoveList
@onready var add_move_button: Button = %AddMoveButton
@onready var remove_move_button: Button = %RemoveMoveButton
@onready var open_selected_move_button: Button = %OpenSelectedMoveButton
@onready var open_kyokoro_profile_button: Button = %OpenKyokoroProfileButton
@onready var default_dice_path_label: Label = %DefaultDicePathLabel
@onready var default_dice_status_label: Label = %DefaultDiceStatusLabel
@onready var edit_default_dice_button: Button = %EditDefaultDiceButton

@onready var profile_id_edit: LineEdit = %ProfileIdEdit
@onready var profile_reference_rows: VBoxContainer = %ProfileReferenceRows
@onready var profile_reference_status: Label = %ProfileReferenceStatus
@onready var roll_mode_option: OptionButton = %RollModeOption
@onready var scene_path_edit: LineEdit = %ScenePathEdit
@onready var orientation_map: GridContainer = %KyokoroOrientationMap
@onready var total_weight_label: Label = %TotalWeightLabel

@onready var move_id_edit: LineEdit = %MoveIdEdit
@onready var move_name_id_edit: LineEdit = %MoveNameIdEdit
@onready var owner_id_edit: LineEdit = %OwnerIdEdit
@onready var move_display_name_edit: LineEdit = %MoveDisplayNameEdit
@onready var move_advanced_json_text: TextEdit = %MoveAdvancedJsonText
@onready var move_category_option: OptionButton = %MoveCategoryOption
@onready var attack_type_option: OptionButton = %AttackTypeOption
@onready var printed_damage_spin: SpinBox = %PrintedDamageSpin
@onready var printed_damage_none: CheckBox = %PrintedDamageNone
@onready var energy_cost_rows: VBoxContainer = %EnergyCostRows
@onready var add_energy_cost_button: Button = %AddEnergyCostButton
@onready var energy_cost_visual_preview: HBoxContainer = %EnergyCostVisualPreview
@onready var energy_cost_total_label: Label = %EnergyCostTotalLabel
@onready var clear_energy_cost_button: Button = %ClearEnergyCostButton
@onready var add_attack_type_cost_button: Button = %AddAttackTypeCostButton
@onready var base_actions_rows: VBoxContainer = %BaseActionsRows
@onready var add_base_action_button: Button = %AddBaseActionButton
@onready var outcome_rule_rows: VBoxContainer = %OutcomeRuleRows
@onready var add_outcome_rule_button: Button = %AddOutcomeRuleButton
@onready var base_actions_count_label: Label = %BaseActionsCountLabel
@onready var outcome_rules_count_label: Label = %OutcomeRulesCountLabel
@onready var move_preview_owner_icon: TextureRect = %MovePreviewOwnerIcon
@onready var move_preview_name: Label = %MovePreviewName
@onready var move_preview_meta: Label = %MovePreviewMeta
@onready var move_preview_damage: Label = %MovePreviewDamage
@onready var move_preview_energy: HBoxContainer = %MovePreviewEnergy
@onready var move_preview_effects: VBoxContainer = %MovePreviewEffects
@onready var pokemon_assignment_rows: VBoxContainer = %PokemonAssignmentRows
@onready var pokemon_assignment_status: Label = %PokemonAssignmentStatus
@onready var move_json_preview: TextEdit = %MoveJsonPreview

@onready var unsaved_changes_dialog: ConfirmationDialog = %UnsavedChangesDialog
@onready var unsaved_changes_message: Label = %UnsavedChangesMessage
@onready var unsaved_status_label: Label = %UnsavedStatusLabel
@onready var validation_label: Label = %ValidationLabel
@onready var save_button: Button = %SaveButton
@onready var new_button: Button = %NewButton
@onready var load_button: Button = %LoadButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var delete_button: Button = %DeleteButton
@onready var delete_dialog: ConfirmationDialog = %DeleteDialog
@onready var delete_message_label: Label = %DeleteMessageLabel
@onready var validate_database_button: Button = %ValidateDatabaseButton
@onready var database_integrity_dialog: AcceptDialog = %DatabaseIntegrityDialog
@onready var database_integrity_report: TextEdit = %DatabaseIntegrityReport
@onready var regenerate_default_dice_button: Button = %RegenerateDefaultDiceButton
@onready var regenerate_default_dice_dialog: ConfirmationDialog = %RegenerateDefaultDiceDialog
@onready var regenerate_default_dice_message: Label = %RegenerateDefaultDiceMessage
@onready var back_button: Button = %BackButton

var mode: StringName = MODE_POKEMON
var current_document: Dictionary = {}
var clean_editor_snapshot: String = ""
var pending_guard_action: String = ""
var pending_guard_payload: Dictionary = {}
var pending_after_save: bool = false
var suppress_unsaved_guard: bool = false
var weight_controls: Dictionary = {}
var probability_labels: Dictionary = {}

var language_validation_button: Button = null


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)

	LocalizationService.locale_changed.connect(
		_on_locale_changed
	)
	_apply_localized_text()

	var discard_button: Button = unsaved_changes_dialog.add_button(
		LocalizationService.tr_key(
			"content_studio.discard",
			"Discard"
		),
		true,
		"discard"
	)
	discard_button.tooltip_text = LocalizationService.tr_key(
		"content_studio.discard_tooltip",
		"Discard unsaved changes and continue."
	)

	get_viewport().size_changed.connect(
		_apply_responsive_layout
	)

	_populate_types(
		type_option,
		false
	)
	_populate_types(
		weakness_type_option,
		true
	)
	_populate_kyokoro_profiles()
	_populate_available_moves()
	_populate_roll_modes()
	_populate_move_categories()
	_populate_types(
		attack_type_option,
		false
	)
	_build_orientation_map()
	_setup_library_filters()
	_connect_actions()
	_set_technical_details_visible(false)

	_switch_mode(
		MODE_POKEMON
	)
	_apply_responsive_layout()
	_ensure_language_validation_button()


func _on_locale_changed(
	_locale: String
) -> void:
	_apply_localized_text()
	# Dynamic refresh is safe only after editor OptionButtons have been populated.
	# _ready() applies static localized text before _populate_types(), so running
	# validation during that first pass would read selected == -1.
	if weakness_type_option.item_count <= 0:
		return
	_setup_library_filters()
	if mode != MODE_MODEL_WEIGHT:
		_refresh_saved_list()
		_refresh_content_source_status()
		_refresh_validation()


func _set_text_if_present(
	node_name: String,
	key: String,
	fallback: String
) -> void:
	var node: Node = find_child(
		node_name,
		true,
		false
	)
	if node != null and "text" in node:
		node.text = LocalizationService.tr_key(
			key,
			fallback
		)


func _set_tooltip_if_present(
	node_name: String,
	key: String,
	fallback: String
) -> void:
	var node: Node = find_child(
		node_name,
		true,
		false
	)
	if node is Control:
		(node as Control).tooltip_text = LocalizationService.tr_key(
			key,
			fallback
		)


func _ensure_language_validation_button() -> void:
	if language_validation_button != null:
		return

	language_validation_button = Button.new()
	language_validation_button.name = "ValidateLanguagePacksButton"
	language_validation_button.text = LocalizationService.tr_key(
		"content_studio.validate_language_packs",
        "Validate Language Packs"
	)
	language_validation_button.tooltip_text = LocalizationService.tr_key(
		"content_studio.validate_language_packs_tooltip",
        "Validate UI and game-content language packs."
	)
	language_validation_button.pressed.connect(
		_on_validate_language_packs_pressed
	)

	var parent_node: Node = validate_database_button.get_parent()
	parent_node.add_child(
		language_validation_button
	)
	parent_node.move_child(
		language_validation_button,
		validate_database_button.get_index() + 1
	)


func _on_validate_language_packs_pressed() -> void:
	var report: Dictionary = LANGUAGE_PACK_VALIDATOR.validate_all()
	database_integrity_dialog.title = LocalizationService.tr_format(
		"content_studio.language_validation_title",
		{
			"result": (
                "PASS"
				if bool(report.get("success", false))
				else "FAIL"
			)
		},
        "Language Pack Validation — {result}"
	)
	database_integrity_dialog.ok_button_text = LocalizationService.tr_key(
		"content_studio.close",
        "Close"
	)
	database_integrity_report.text = LANGUAGE_PACK_VALIDATOR.format_report(
		report
	)
	database_integrity_dialog.popup_centered_ratio(
		0.82
	)


func _apply_localized_text() -> void:
	page_title.text = LocalizationService.tr_key("content_studio.title", "PLAKORO Content Studio")
	validate_database_button.text = LocalizationService.tr_key("content_studio.validate_database", "Validate Database")
	back_button.text = "← " + LocalizationService.tr_key("content_studio.back_preparation", "Back to Preparation")
	pokemon_tab.text = LocalizationService.tr_key("content_studio.pokemon_editor", "Pokémon Editor")
	kyokoro_tab.text = LocalizationService.tr_key("content_studio.kyokoro_editor", "Charakoro Profile Editor")
	move_tab.text = LocalizationService.tr_key("content_studio.move_editor", "Move Editor")
	model_weight_tab.text = LocalizationService.tr_key("content_studio.model_weight", "Model Weight Generator")
	technical_details_toggle.text = LocalizationService.tr_key("content_studio.technical_details", "Advanced / Technical Details")

	var static_nodes: Array[Array] = [
		["LibraryTitle", "content_studio.library", "Library"],
		["LibrarySearchClearButton", "content_studio.clear", "Clear"],
		["RestoreBuiltinButton", "content_studio.restore_builtin", "Restore Built-in"],
		["NewButton", "content_studio.new", "New"],
		["LoadButton", "content_studio.load", "Load"],
		["DuplicateButton", "content_studio.duplicate", "Duplicate"],
		["DeleteButton", "content_studio.delete", "Delete"],
		["BasicTitle", "content_studio.basic_information", "Basic Information"],
		["WeaknessTitle", "content_studio.battle_weakness", "Battle Weakness"],
		["KyokoroTitle", "content_studio.charakoro_profile", "Charakoro Profile"],
		["OpenKyokoroProfileButton", "content_studio.open_charakoro", "Open Charakoro Profile"],
		["DefaultDiceTitle", "content_studio.default_enerkoro", "Default Enerkoro"],
		["EditDefaultDiceButton", "content_studio.edit_default_enerkoro", "Edit Default Dice"],
		["RegenerateDefaultDiceButton", "content_studio.regenerate_default_enerkoro", "Regenerate Default Dice"],
		["MovesTitle", "content_studio.move_loadout", "Move Loadout"],
		["AddMoveButton", "content_studio.add", "Add →"],
		["RemoveMoveButton", "content_studio.remove", "← Remove"],
		["OpenSelectedMoveButton", "content_studio.open_selected_move", "Open Selected Move"],
		["WeightsTitle", "content_studio.weights", "Landing Orientation Weights"],
		["ProfileReferencesTitle", "content_studio.used_by_pokemon", "Used by Pokémon"],
		["MoveBasicTitle", "content_studio.basic_information", "Basic Information"],
		["ComplexTitle", "content_studio.gameplay_effects", "Gameplay & Effects"],
		["AddAttackTypeCostButton", "content_studio.add_attack_type", "+ Attack Type"],
		["ClearEnergyCostButton", "content_studio.clear", "Clear"],
		["AddEnergyCostButton", "content_studio.add_energy", "+ Add Energy"],
		["EnergyCostPreviewTitle", "content_studio.visual_cost_preview", "Visual Cost Preview"],
		["AddBaseActionButton", "content_studio.add_action", "+ Add Action"],
		["AddOutcomeRuleButton", "content_studio.add_outcome_rule", "+ Add Outcome Rule"],
		["MoveAdvancedTitle", "content_studio.advanced_data", "Advanced Data"],
		["PokemonReferenceTitle", "content_studio.pokemon_assignment", "Pokémon Assignment"],
		["MovePresentationTitle", "content_studio.preview", "Preview"],
		["EnergyLabel", "content_studio.energy_cost", "Energy Cost"],
		["EffectsLabel", "content_studio.effects", "Effects"],
		["RawPreviewTitle", "content_studio.technical_json_preview", "Technical JSON Preview"],
		["NewContentGuideTitle", "content_studio.create_new_content", "Create New Content"],
		["NewContentGuideHint", "content_studio.complete_required_info", "Complete the required information, then create the content."],
		["ProfileInstructions", "content_studio.profile_instructions", "Profile settings control how this Charakoro behaves when rolled."],
		["WeightsHint", "content_studio.weights_hint", "Edit the six Charakoro orientation weights. Probability is normalized automatically."],
		["ProfileReferencesHint", "content_studio.used_by_hint", "Pokémon currently using this Charakoro Profile."],
		["PhysicsProfileHint", "content_studio.physics_preserved", "Physics profile is preserved automatically when this profile is saved."],
		["MoveRuntimeStatus", "content_studio.runtime_supported", "Runtime Effects: Supported"],
		["MoveSchemaHint", "content_studio.move_schema_hint", "Move Card schema and technical fields."],
		["MoveAdvancedHint", "content_studio.advanced_data_hint", "Advanced technical Move data."],
		["PokemonReferenceHint", "content_studio.pokemon_assignment_hint", "Assign this Move only to compatible Pokémon."],
		["MovePresentationHint", "content_studio.preview_hint", "Live presentation preview. This does not change the Move Card JSON schema."]
	]
	for row: Array in static_nodes:
		_set_text_if_present(
			String(row[0]),
			String(row[1]),
			String(row[2])
		)

	var default_dice_hint: Label = get_node_or_null(
		"Margin/Main/Body/EditorScroll/EditorRoot/PokemonEditor/DefaultDicePanel/DefaultDiceBox/DefaultDiceHint"
	) as Label
	if default_dice_hint != null:
		default_dice_hint.text = LocalizationService.tr_key(
			"content_studio.default_enerkoro_hint",
			"Species default used when Battle Preparation selects Pokémon Default. If missing, Save Pokémon automatically generates a valid default from the Pokémon type."
		)

	library_search_edit.placeholder_text = LocalizationService.tr_key(
		"content_studio.search_placeholder",
		"Search ID or display name..."
	)

	unsaved_changes_dialog.title = LocalizationService.tr_key("content_studio.unsaved_title", "Unsaved Changes")
	unsaved_changes_dialog.ok_button_text = LocalizationService.tr_key("content_studio.save_changes", "Save Changes")
	unsaved_changes_dialog.cancel_button_text = LocalizationService.tr_key("common.cancel", "Cancel")
	restore_builtin_dialog.title = LocalizationService.tr_key("content_studio.restore_title", "Restore Built-in Content?")
	restore_builtin_dialog.ok_button_text = LocalizationService.tr_key("content_studio.restore_builtin", "Restore Built-in")
	restore_builtin_dialog.cancel_button_text = LocalizationService.tr_key("common.cancel", "Cancel")
	delete_dialog.title = LocalizationService.tr_key("content_studio.delete_title", "Delete Content?")
	delete_dialog.ok_button_text = LocalizationService.tr_key("content_studio.delete", "Delete")
	delete_dialog.cancel_button_text = LocalizationService.tr_key("common.cancel", "Cancel")
	regenerate_default_dice_dialog.title = LocalizationService.tr_key("content_studio.regenerate_title", "Regenerate Default Enerkoro?")
	regenerate_default_dice_dialog.ok_button_text = LocalizationService.tr_key("content_studio.regenerate", "Regenerate")
	regenerate_default_dice_dialog.cancel_button_text = LocalizationService.tr_key("common.cancel", "Cancel")
	regenerate_default_dice_message.text = LocalizationService.tr_key("content_studio.regenerate_message", "This will replace the Pokémon Default Dice file.")
	database_integrity_dialog.title = LocalizationService.tr_key("content_studio.database_integrity", "Database Integrity")
	database_integrity_dialog.ok_button_text = LocalizationService.tr_key("content_studio.close", "Close")

	_set_tooltip_if_present("OpenKyokoroProfileButton", "content_studio.open_charakoro", "Open this profile in Charakoro Profile Editor.")
	_set_tooltip_if_present("OpenSelectedMoveButton", "content_studio.open_selected_move", "Open the selected Move in Move Editor.")

	# Do not refresh editor data here. During the first _ready() pass the
	# OptionButtons have not been populated yet. Dynamic text is refreshed by
	# _on_locale_changed() after initialization.
	if language_validation_button != null:
		language_validation_button.text = LocalizationService.tr_key(
			"content_studio.validate_language_packs",
            "Validate Language Packs"
		)
		language_validation_button.tooltip_text = LocalizationService.tr_key(
			"content_studio.validate_language_packs_tooltip",
			"Validate UI and game-content language packs."
		)



func _setup_library_filters() -> void:
	library_source_filter.clear()
	var source_labels: Array[String] = [
		LocalizationService.tr_key("content_studio.all_sources", "All Sources"),
		LocalizationService.tr_key("content_studio.source.builtin", "Built-in"),
		LocalizationService.tr_key("content_studio.source.modified", "Modified"),
		LocalizationService.tr_key("content_studio.source.user_created", "User Created")
	]
	for label: String in source_labels:
		library_source_filter.add_item(label)
	library_source_filter.select(0)
	_refresh_library_type_filter()


func _refresh_library_type_filter() -> void:
	library_type_filter.clear()
	library_type_filter.add_item(
		LocalizationService.tr_key(
			"content_studio.all_types",
			"All Types"
		)
	)
	library_type_filter.set_item_metadata(0, "")
	if (
		mode == MODE_KYOKORO
		or mode == MODE_MODEL_WEIGHT
	):
		library_type_filter.visible = false
		return
	library_type_filter.visible = true
	var types: Array[String] = POKEMON_AUTHORING.VALID_TYPES
	for type_name: String in types:
		library_type_filter.add_item(GameContentLocalizationService.localize_type(type_name))
		library_type_filter.set_item_metadata(library_type_filter.item_count - 1, type_name)
	library_type_filter.select(0)


func _connect_actions() -> void:
	pokemon_tab.pressed.connect(
		func() -> void:
			_request_guarded_action(
				"switch_mode",
				{"mode": MODE_POKEMON}
			)
	)
	kyokoro_tab.pressed.connect(
		func() -> void:
			_request_guarded_action(
				"switch_mode",
				{"mode": MODE_KYOKORO}
			)
	)
	move_tab.pressed.connect(
		func() -> void:
			_request_guarded_action(
				"switch_mode",
				{"mode": MODE_MOVE}
			)
	)
	model_weight_tab.pressed.connect(
		func() -> void:
			_request_guarded_action(
				"switch_mode",
				{"mode": MODE_MODEL_WEIGHT}
			)
	)
	technical_details_toggle.toggled.connect(
		_set_technical_details_visible
	)

	new_button.pressed.connect(
		func() -> void:
			_request_guarded_action("new")
	)
	save_button.pressed.connect(
		_save_content
	)
	load_button.pressed.connect(
		func() -> void:
			_request_guarded_action("load_selected")
	)
	duplicate_button.pressed.connect(
		func() -> void:
			_request_guarded_action("duplicate")
	)
	delete_button.pressed.connect(
		func() -> void:
			_request_guarded_action("delete")
	)
	restore_builtin_button.pressed.connect(
		func() -> void:
			_request_guarded_action("restore_builtin")
	)
	unsaved_changes_dialog.confirmed.connect(
		_on_unsaved_save_confirmed
	)
	unsaved_changes_dialog.custom_action.connect(
		_on_unsaved_custom_action
	)
	unsaved_changes_dialog.canceled.connect(
		_on_unsaved_cancelled
	)
	restore_builtin_dialog.confirmed.connect(
		_confirm_restore_selected_builtin
	)
	delete_dialog.confirmed.connect(
		_confirm_delete_selected
	)
	back_button.pressed.connect(
		func() -> void:
			_request_guarded_action("back")
	)
	regenerate_default_dice_button.pressed.connect(
		_request_regenerate_default_dice
	)
	regenerate_default_dice_dialog.confirmed.connect(
		_confirm_regenerate_default_dice
	)
	validate_database_button.pressed.connect(
		_validate_database_integrity
	)

	library_search_edit.text_changed.connect(
		func(_text: String) -> void:
			_refresh_saved_list()
	)
	library_search_clear_button.pressed.connect(
		func() -> void:
			library_search_edit.clear()
			library_search_edit.grab_focus()
	)
	library_source_filter.item_selected.connect(
		func(_index: int) -> void:
			_refresh_saved_list()
	)
	library_type_filter.item_selected.connect(
		func(_index: int) -> void:
			_refresh_saved_list()
	)
	saved_list.item_activated.connect(
		func(_index: int) -> void:
			_request_guarded_action("load_selected")
	)
	selected_move_list.item_activated.connect(
		func(_index: int) -> void:
			_open_selected_move()
	)

	add_move_button.pressed.connect(
		_add_selected_move
	)
	add_energy_cost_button.pressed.connect(
		_add_energy_cost_row
	)
	clear_energy_cost_button.pressed.connect(
		_clear_energy_cost
	)
	add_attack_type_cost_button.pressed.connect(
		_add_attack_type_energy_cost
	)
	add_base_action_button.pressed.connect(
		_add_base_action
	)
	add_outcome_rule_button.pressed.connect(
		_add_outcome_rule
	)
	remove_move_button.pressed.connect(
		_remove_selected_move
	)
	open_selected_move_button.pressed.connect(
		_open_selected_move
	)
	open_kyokoro_profile_button.pressed.connect(
		_open_selected_kyokoro_profile
	)
	edit_default_dice_button.pressed.connect(
		_edit_default_pokemon_dice
	)

	for edit: LineEdit in [
		id_edit,
		species_id_edit,
		name_edit,
		profile_id_edit,
		scene_path_edit
	]:
		edit.text_changed.connect(
			func(_text: String) -> void:
				if edit == species_id_edit:
					_refresh_default_dice_status()
				_refresh_validation()
		)

	hp_spin.value_changed.connect(
		func(_value: float) -> void:
			_refresh_validation()
	)

	type_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_default_dice_status()
			_refresh_validation()
	)
	weakness_type_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_validation()
	)
	weakness_bonus_spin.value_changed.connect(
		func(_value: float) -> void:
			_refresh_validation()
	)
	kyokoro_profile_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_kyokoro_profile_status()
			_refresh_validation()
	)
	roll_mode_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_validation()
	)


	for edit: LineEdit in [
		move_id_edit,
		move_name_id_edit,
		owner_id_edit,
		move_display_name_edit
	]:
		edit.text_changed.connect(
			func(_text: String) -> void:
				if edit == owner_id_edit:
					_refresh_move_assignments(
						move_id_edit.text
					)

				_refresh_move_preview()
				_refresh_validation()
		)


	move_category_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_move_preview()
			_refresh_validation()
	)
	attack_type_option.item_selected.connect(
		func(_index: int) -> void:
			_refresh_move_preview()
			_refresh_validation()
	)
	printed_damage_spin.value_changed.connect(
		func(_value: float) -> void:
			_refresh_move_preview()
			_refresh_validation()
	)
	printed_damage_none.toggled.connect(
		func(pressed: bool) -> void:
			printed_damage_spin.editable = not pressed
			_refresh_move_preview()
			_refresh_validation()
	)


func _default_dice_path_for_current_pokemon() -> String:
	var species_id: String = (
		species_id_edit.text.strip_edges().to_lower()
	)
	if species_id.is_empty():
		return ""
	return (
		USER_DATABASE.DICE_SETUPS
		+ "/"
		+ species_id
		+ "_default.json"
	)


func _refresh_default_dice_status() -> void:
	var path: String = _default_dice_path_for_current_pokemon()
	default_dice_path_label.text = (
		path if not path.is_empty() else LocalizationService.tr_key("content_studio.set_species_first", "Set species_id first.")
	)
	var exists: bool = (
		not path.is_empty()
		and FileAccess.file_exists(path)
	)

	var status_text: String = (
		LocalizationService.tr_key("content_studio.default_dice_ready", "Default Dice: Ready")
		if exists
		else LocalizationService.tr_key("content_studio.default_dice_missing", "Default Dice: Missing")
	)

	if exists and not current_document.is_empty():
		var saved_type: String = String(
			current_document.get(
				"pokemon_type",
				""
			)
		)
		var selected_type: String = String(
			type_option.get_item_metadata(
				type_option.selected
			)
		)
		if (
			not saved_type.is_empty()
			and saved_type != selected_type
		):
			status_text += LocalizationService.tr_format(
				"content_studio.default_dice_type_changed",
				{
					"old_type": GameContentLocalizationService.localize_type(saved_type),
					"new_type": GameContentLocalizationService.localize_type(selected_type)
				},
				" — Pokémon type changed from {old_type} to {new_type}. Existing Dice is preserved until Regenerate."
			)

	default_dice_status_label.text = status_text
	edit_default_dice_button.disabled = (
		path.is_empty() or not exists
	)
	regenerate_default_dice_button.disabled = (
		path.is_empty()
	)


func _request_regenerate_default_dice() -> void:
	var path: String = _default_dice_path_for_current_pokemon()
	if path.is_empty():
		validation_label.text = (
			"Set species_id before generating Default Dice."
		)
		return

	var pokemon_data: Dictionary = _collect_data()
	var selected_type: String = String(
		pokemon_data.get(
			"pokemon_type",
			"normal"
		)
	)

	regenerate_default_dice_message.text = (
		"Generate a fresh deterministic Default Dice setup for "
		+ String(
			pokemon_data.get(
				"display_name",
				pokemon_data.get(
					"species_id",
					"Pokémon"
				)
			)
		)
		+ " using type "
		+ selected_type.capitalize()
		+ "?\n\n"
		+ (
			"This will REPLACE the existing file:\n"
			if FileAccess.file_exists(path)
			else "This will CREATE:\n"
		)
		+ path
		+ "\n\nManual edits in that Default Dice file cannot be restored automatically."
	)

	regenerate_default_dice_dialog.popup_centered(
		Vector2i(
			720,
			360
		)
	)


func _confirm_regenerate_default_dice() -> void:
	var result: Dictionary = (
		DEFAULT_DICE_GENERATOR
		.regenerate_default_for_pokemon(
			_collect_data(),
			"user://user_database/dice_setups"
		)
	)

	if not bool(
		result.get(
			"success",
			false
		)
	):
		_show_action_error(
			"Cannot Regenerate Default Enerkoro",
			result.get("errors", [])
		)
		return

	_refresh_default_dice_status()
	_show_action_success(
		"Default Enerkoro regenerated successfully."
	)


func _edit_default_pokemon_dice() -> void:
	var path: String = _default_dice_path_for_current_pokemon()
	if path.is_empty() or not FileAccess.file_exists(path):
		validation_label.text = (
			"Default Dice is missing. "
			+ "Milestone 10.4b will generate it automatically."
		)
		return

	if not DICE_BUILDER_CONTEXT.set_context(
		"pokemon_default",
		path,
		CONTENT_STUDIO_SCENE,
		id_edit.text.strip_edges(),
		species_id_edit.text.strip_edges()
	):
		validation_label.text = LocalizationService.tr_key(
			"content_studio.default_dice_editor_failed",
            "Could not prepare Default Dice editor."
		)
		return

	get_tree().change_scene_to_file(ENERGY_DICE_BUILDER_SCENE)


func _validate_database_integrity() -> void:
	var report: Dictionary = (
		DATABASE_INTEGRITY.validate_all()
	)

	database_integrity_report.text = (
		DATABASE_INTEGRITY.format_report(
			report
		)
	)

	database_integrity_dialog.title = LocalizationService.tr_format(
		"content_studio.database_scan_title",
		{
			"result": (
				"PASS"
				if bool(report.get("success", false))
				else "FAIL"
			)
		},
		"Database Integrity Deep Scan — {result}"
	)

	database_integrity_dialog.popup_centered(
		Vector2i(
			980,
			700
		)
	)


func _set_technical_details_visible(show_details: bool) -> void:
	pokemon_schema_panel.visible = show_details
	kyokoro_schema_panel.visible = show_details
	kyokoro_physics_panel.visible = show_details
	move_runtime_status.visible = show_details
	move_schema_panel.visible = show_details
	move_advanced_panel.visible = show_details
	move_raw_preview_panel.visible = show_details


func _current_editor_state() -> Dictionary:
	var document: Dictionary = {}
	match mode:
		MODE_POKEMON:
			document = _collect_data()
		MODE_KYOKORO:
			document = _collect_profile_data()
		MODE_MOVE:
			document = _collect_move_data()

	var state: Dictionary = {
		"mode": String(mode),
		"document": document
	}
	if mode == MODE_MOVE:
		state["pokemon_assignments"] = _collect_selected_pokemon_assignments()
	return state


func _snapshot_current_editor() -> String:
	return JSON.stringify(_current_editor_state())


func _mark_editor_clean() -> void:
	clean_editor_snapshot = _snapshot_current_editor()
	_refresh_unsaved_status()
	_refresh_authoring_session()


func _has_unsaved_changes() -> bool:
	if suppress_unsaved_guard:
		return false
	if clean_editor_snapshot.is_empty():
		return false
	return _snapshot_current_editor() != clean_editor_snapshot


func _refresh_unsaved_status() -> void:
	if clean_editor_snapshot.is_empty():
		unsaved_status_label.text = LocalizationService.tr_key(
			"content_studio.saved_plain",
            "Saved"
		)
		return
	unsaved_status_label.text = (
		"● Unsaved Changes"
		if _has_unsaved_changes()
		else "✓ Saved"
	)


func _request_guarded_action(
	action: String,
	payload: Dictionary = {}
) -> void:
	# Model Weight Generator is an independent utility, not a Content Studio
	# authoring document. Never allow the Pokémon / Charakoro / Move dirty
	# state to block entering it, and never carry a stale authoring dirty state
	# out of it when returning to an editor.
	var target_mode: StringName = StringName(
		payload.get(
			"mode",
			mode
		)
	)
	var bypass_for_model_weight: bool = (
		mode == MODE_MODEL_WEIGHT
		or (
			action == "switch_mode"
			and target_mode == MODE_MODEL_WEIGHT
		)
	)

	if bypass_for_model_weight:
		_execute_guarded_action(
			action,
			payload
		)
		return

	if not _has_unsaved_changes():
		_execute_guarded_action(action, payload)
		return

	pending_guard_action = action
	pending_guard_payload = payload.duplicate(true)
	pending_after_save = false
	unsaved_changes_message.text = LocalizationService.tr_format(
		"content_studio.unsaved_message",
		{"kind": _content_kind_label()},
		"You have unsaved changes in the current {kind}.\n\nSave changes before continuing?"
	)
	unsaved_changes_dialog.popup_centered(Vector2i(680, 300))


func _on_unsaved_save_confirmed() -> void:
	pending_after_save = true
	_save_content()


func _on_unsaved_custom_action(action: StringName) -> void:
	if action != &"discard":
		return
	unsaved_changes_dialog.hide()
	pending_after_save = false
	var next_action: String = pending_guard_action
	var next_payload: Dictionary = pending_guard_payload.duplicate(true)
	pending_guard_action = ""
	pending_guard_payload.clear()
	suppress_unsaved_guard = true
	_execute_guarded_action(next_action, next_payload)
	suppress_unsaved_guard = false


func _on_unsaved_cancelled() -> void:
	pending_after_save = false
	pending_guard_action = ""
	pending_guard_payload.clear()


func _continue_pending_after_save() -> void:
	if not pending_after_save:
		return
	pending_after_save = false
	var next_action: String = pending_guard_action
	var next_payload: Dictionary = pending_guard_payload.duplicate(true)
	pending_guard_action = ""
	pending_guard_payload.clear()
	if next_action.is_empty():
		return
	suppress_unsaved_guard = true
	_execute_guarded_action(next_action, next_payload)
	suppress_unsaved_guard = false


func _execute_guarded_action(
	action: String,
	payload: Dictionary
) -> void:
	match action:
		"switch_mode":
			_switch_mode(StringName(payload.get("mode", mode)))
		"new":
			_new_content()
		"load_selected":
			_load_selected()
		"duplicate":
			_duplicate_selected_content()
		"navigate":
			_navigate_to_content_now(
				StringName(payload.get("mode", mode)),
				String(payload.get("id", ""))
			)
		"restore_builtin":
			_request_restore_selected_builtin()
		"delete":
			_request_delete_selected()
		"back":
			_back_to_preparation()


func _switch_mode(
	new_mode: StringName
) -> void:
	if mode != new_mode:
		library_search_edit.clear()

	mode = new_mode
	_refresh_library_type_filter()

	pokemon_editor.visible = (
		mode == MODE_POKEMON
	)
	kyokoro_editor.visible = (
		mode == MODE_KYOKORO
	)
	move_editor.visible = (
		mode == MODE_MOVE
	)
	model_weight_panel.visible = (
		mode == MODE_MODEL_WEIGHT
	)

	pokemon_tab.disabled = (
		mode == MODE_POKEMON
	)
	kyokoro_tab.disabled = (
		mode == MODE_KYOKORO
	)
	move_tab.disabled = (
		mode == MODE_MOVE
	)
	model_weight_tab.disabled = (
		mode == MODE_MODEL_WEIGHT
	)

	var model_weight_mode: bool = (
		mode == MODE_MODEL_WEIGHT
	)
	$Margin/Main/Body/LibraryPanel.visible = (
		not model_weight_mode
	)
	$Margin/Main/Body/EditorScroll/EditorRoot/AuthoringSessionPanel.visible = (
		not model_weight_mode
	)
	new_content_guide_panel.visible = (
		not model_weight_mode
	)
	$Margin/Main/Body/EditorScroll/EditorRoot/ValidationPanel.visible = (
		not model_weight_mode
	)
	$Margin/Main/Actions.visible = (
		not model_weight_mode
	)
	technical_details_toggle.visible = (
		not model_weight_mode
	)
	var editor_scroll: ScrollContainer = $Margin/Main/Body/EditorScroll
	editor_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if model_weight_mode
		else ScrollContainer.SCROLL_MODE_AUTO
	)
	if model_weight_mode:
		editor_scroll.scroll_vertical = 0

	match mode:
		MODE_POKEMON:
			library_title.text = (
				LocalizationService.tr_key("content_studio.library.pokemon", "Pokémon Library")
			)
			save_button.text = (
				LocalizationService.tr_key("content_studio.save_pokemon", "Save Pokémon")
			)
			_refresh_saved_list()
			_load_data(
				POKEMON_AUTHORING.create_default()
			)

		MODE_KYOKORO:
			library_title.text = (
				LocalizationService.tr_key("content_studio.library.charakoro", "Charakoro Profile Library")
			)
			save_button.text = (
				LocalizationService.tr_key("content_studio.save_charakoro", "Save Charakoro Profile")
			)
			_refresh_saved_list()
			_load_profile_data(
				KYOKORO_AUTHORING.create_default()
			)

		MODE_MOVE:
			library_title.text = (
				LocalizationService.tr_key("content_studio.library.move", "Move Library")
			)
			save_button.text = (
				LocalizationService.tr_key("content_studio.save_move", "Save Move Card")
			)
			_refresh_saved_list()
			_load_move_data(
				MOVE_AUTHORING.create_default()
			)

		MODE_MODEL_WEIGHT:
			# The integrated generator writes a complete Charakoro profile
			# directly to user://user_database/kyokoro_profiles/.
			return

	_refresh_content_source_status()


func _populate_types(
	target: OptionButton,
	include_none: bool
) -> void:
	target.clear()

	if include_none:
		target.add_item(
            "None"
		)
		target.set_item_metadata(
			0,
            "none"
		)

	for type_name: String in (
		POKEMON_AUTHORING.VALID_TYPES
	):
		target.add_item(
			GameContentLocalizationService.localize_type(type_name)
		)
		target.set_item_metadata(
			target.item_count - 1,
			type_name
		)


func _populate_kyokoro_profiles() -> void:
	kyokoro_profile_option.clear()

	var profile_ids: Array[String] = (
		POKEMON_AUTHORING.list_kyokoro_profiles()
	)

	if profile_ids.is_empty():
		profile_ids.append(
            "standard_equal"
		)

	for profile_id: String in profile_ids:
		kyokoro_profile_option.add_item(
			profile_id
		)
		kyokoro_profile_option.set_item_metadata(
			kyokoro_profile_option.item_count - 1,
			profile_id
		)


func _populate_available_moves() -> void:
	available_move_list.clear()

	for move_id: String in (
		POKEMON_AUTHORING.list_move_card_ids()
	):
		available_move_list.add_item(
			move_id
		)


func _populate_roll_modes() -> void:
	roll_mode_option.clear()
	roll_mode_option.add_item(
        "Weighted"
	)
	roll_mode_option.set_item_metadata(
		0,
        "weighted"
	)



func _populate_move_categories() -> void:
	move_category_option.clear()

	for category: String in (
		MOVE_AUTHORING.VALID_CATEGORIES
	):
		move_category_option.add_item(
			category.capitalize()
		)
		move_category_option.set_item_metadata(
			move_category_option.item_count - 1,
			category
		)


func _build_orientation_map() -> void:
	for child: Node in orientation_map.get_children():
		child.queue_free()

	weight_controls.clear()
	probability_labels.clear()

	# 3-column visual net:
	#       FACE_UP
	# HEAD_LEFT HEAD_UP HEAD_RIGHT
	#       FACE_DOWN
	#       HEAD_DOWN
	var layout: Array = [
		null, &"FACE_UP", null,
		&"HEAD_LEFT", &"HEAD_UP", &"HEAD_RIGHT",
		null, &"FACE_DOWN", null,
		null, &"HEAD_DOWN", null
	]

	for entry: Variant in layout:
		if entry == null:
			var spacer: Control = Control.new()
			spacer.custom_minimum_size = Vector2(
				210,
				150
			)
			orientation_map.add_child(
				spacer
			)
			continue

		var orientation: StringName = (
			entry as StringName
		)

		var panel: PanelContainer = (
			PanelContainer.new()
		)
		panel.custom_minimum_size = Vector2(
			210,
			150
		)
		orientation_map.add_child(
			panel
		)

		var box: VBoxContainer = (
			VBoxContainer.new()
		)
		box.alignment = (
			BoxContainer.ALIGNMENT_CENTER
		)
		box.add_theme_constant_override(
			"separation",
			5
		)
		panel.add_child(
			box
		)

		var icon: TextureRect = (
			TextureRect.new()
		)
		icon.custom_minimum_size = Vector2(
			52,
			52
		)
		icon.size_flags_horizontal = (
			Control.SIZE_SHRINK_CENTER
		)
		icon.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)
		icon.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		icon.texture = ICONS.load_kyokoro_icon(
			orientation
		)
		box.add_child(
			icon
		)

		var name_label: Label = Label.new()
		name_label.text = LocalizationService.tr_key(
			"orientation." + String(orientation),
			String(orientation).replace("_", " ").capitalize()
		)
		name_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		box.add_child(
			name_label
		)

		var control_row: HBoxContainer = (
			HBoxContainer.new()
		)
		control_row.alignment = (
			BoxContainer.ALIGNMENT_CENTER
		)
		box.add_child(
			control_row
		)

		var weight_label: Label = Label.new()
		weight_label.text = LocalizationService.tr_key(
			"content_studio.weight",
            "Weight"
		)
		control_row.add_child(
			weight_label
		)

		var weight_spin: SpinBox = (
			SpinBox.new()
		)
		weight_spin.custom_minimum_size.x = 90
		weight_spin.min_value = 0.0
		weight_spin.max_value = 1000.0
		weight_spin.step = 0.1
		weight_spin.value = 1.0
		control_row.add_child(
			weight_spin
		)

		var probability: Label = Label.new()
		probability.text = "16.7%"
		probability.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		box.add_child(
			probability
		)

		weight_controls[orientation] = (
			weight_spin
		)
		probability_labels[orientation] = (
			probability
		)

		weight_spin.value_changed.connect(
			func(_value: float) -> void:
				_refresh_weight_probability()
				_refresh_validation()
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

	RESPONSIVE_UI.apply_split(
		body,
		profile,
		get_viewport_rect().size.x,
		0.27
	)

	for button: Button in [
		back_button,
		new_button,
		load_button,
		duplicate_button,
		delete_button,
		save_button
	]:
		RESPONSIVE_UI.apply_button(
			button,
			profile,
			150
		)


func _new_content() -> void:
	saved_list.deselect_all()

	match mode:
		MODE_POKEMON:
			_load_data(
				POKEMON_AUTHORING.create_default()
			)
		MODE_KYOKORO:
			_load_profile_data(
				KYOKORO_AUTHORING.create_default()
			)
		MODE_MOVE:
			_load_move_data(
				MOVE_AUTHORING.create_default()
			)

	validation_label.text = LocalizationService.tr_format(
		"content_studio.new_content_message",
		{"kind": _content_kind_label()},
		"New {kind}\n\nComplete the required fields, then choose Create Content."
	)
	_refresh_content_source_status()
	_refresh_new_content_guide()


func _duplicate_selected_content() -> void:
	var source_id: String = _get_selected_library_id()
	if source_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.select_duplicate", "Select content to duplicate first.")
		return

	var result: Dictionary = CONTENT_CLONE.duplicate_content(mode, source_id)
	if not bool(result.get("success", false)):
		_show_action_error(
			"Cannot Duplicate " + _content_kind_label(),
			result.get("errors", [])
		)
		return

	var new_id: String = String(result.get("id", "")).strip_edges()
	var data: Dictionary = result.get("document", {}) as Dictionary
	if new_id.is_empty() or data.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.duplicate_failed", "Duplicate was created, but could not be loaded.")
		return

	match mode:
		MODE_POKEMON:
			_load_data(data)
		MODE_KYOKORO:
			_load_profile_data(data)
		MODE_MOVE:
			_load_move_data(data)

	_refresh_saved_list()
	_select_saved_id(new_id)
	_refresh_content_source_status(new_id)
	_refresh_new_content_guide()
	validation_label.text = LocalizationService.tr_format(
		"content_studio.copy_created",
		{"id": new_id},
		"Created User Content copy: {id}\n\nThe original content was preserved."
	)


func _load_selected() -> void:
	var selected: PackedInt32Array = (
		saved_list.get_selected_items()
	)

	if selected.is_empty():
		validation_label.text = (
            "Select a database entry first."
		)
		return

	var content_id: String = String(
		saved_list.get_item_metadata(
			selected[0]
		)
	).strip_edges()

	if content_id.is_empty():
		content_id = (
			saved_list.get_item_text(
				selected[0]
			)
		)

	match mode:
		MODE_POKEMON:
			var data: Dictionary = (
				POKEMON_AUTHORING.load_by_id(
					content_id
				)
			)
			if not data.is_empty():
				_load_data(
					data
				)
				_refresh_content_source_status(content_id)
				_refresh_new_content_guide()

		MODE_KYOKORO:
			var profile: Dictionary = (
				KYOKORO_AUTHORING.load_by_id(
					content_id
				)
			)
			if not profile.is_empty():
				_load_profile_data(
					profile
				)
				_refresh_content_source_status(content_id)
				_refresh_new_content_guide()

		MODE_MOVE:
			var move_data: Dictionary = (
				MOVE_AUTHORING.load_by_id(
					content_id
				)
			)
			if not move_data.is_empty():
				_load_move_data(
					move_data
				)
				_refresh_content_source_status(content_id)
				_refresh_new_content_guide()


func _refresh_content_source_status(content_id: String = "") -> void:
	var resolved_id: String = content_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = String(current_document.get("id", "")).strip_edges()

	var info: Dictionary = CONTENT_SOURCE.describe(mode, resolved_id)
	var source: String = String(info.get("source", "new"))
	var source_key: String = "content_studio.source.new"
	match source:
		"builtin":
			source_key = "content_studio.source.builtin"
		"override":
			source_key = "content_studio.source.modified"
		"user":
			source_key = "content_studio.source.user_created"

	var source_label: String = LocalizationService.tr_key(
		source_key,
		String(info.get("label", "New Content"))
	)
	library_source_status.text = LocalizationService.tr_format(
		"content_studio.source_label",
		{"source": source_label},
		"Source: {source}"
	)
	restore_builtin_button.visible = source == "override"
	restore_builtin_button.disabled = source != "override"

	match source:
		"builtin":
			save_button.text = LocalizationService.tr_key("content_studio.save_override", "Save as User Override")
			delete_button.text = LocalizationService.tr_key("content_studio.builtin", "Built-in")
			delete_button.disabled = true
			delete_button.tooltip_text = LocalizationService.tr_key("content_studio.delete_builtin_tooltip", "Built-in content cannot be deleted. Save changes to create a user override.")
		"override":
			save_button.text = LocalizationService.tr_key("content_studio.save_changes", "Save Changes")
			delete_button.text = LocalizationService.tr_key("content_studio.remove_override", "Remove Override")
			delete_button.disabled = false
			delete_button.tooltip_text = LocalizationService.tr_key("content_studio.remove_override_tooltip", "Remove your customized version and return to the built-in version.")
		"user":
			save_button.text = LocalizationService.tr_key("content_studio.save_changes", "Save Changes")
			delete_button.text = LocalizationService.tr_key("content_studio.delete", "Delete")
			delete_button.disabled = false
			delete_button.tooltip_text = LocalizationService.tr_key("content_studio.delete_user_tooltip", "Delete this user-created content.")
		_:
			save_button.text = LocalizationService.tr_key("content_studio.create_content", "Create Content")
			delete_button.text = LocalizationService.tr_key("content_studio.delete", "Delete")
			delete_button.disabled = true
			delete_button.tooltip_text = LocalizationService.tr_key("content_studio.delete_new_tooltip", "Save this new content before it can be deleted.")



func _request_restore_selected_builtin() -> void:
	var content_id: String = _get_selected_library_id()
	if content_id.is_empty():
		content_id = String(current_document.get("id", "")).strip_edges()

	if content_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.select_restore", "Select a modified built-in entry first.")
		return

	var info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
	if String(info.get("source", "")) != "override":
		validation_label.text = LocalizationService.tr_key("content_studio.no_override", "This entry does not have a user override to restore.")
		return

	var document: Dictionary = _load_library_document(content_id)
	var display_name: String = String(
		document.get("display_name", content_id)
	).strip_edges()
	if display_name.is_empty():
		display_name = content_id

	restore_builtin_message_label.text = LocalizationService.tr_format(
		"content_studio.restore_message",
		{"name": display_name},
		"Restore {name} to its built-in version?\n\nYour customized version will be removed. The built-in content shipped with PLAKORO will not be changed."
	)
	restore_builtin_dialog.set_meta("content_id", content_id)
	restore_builtin_dialog.popup_centered(Vector2i(680, 300))


func _confirm_restore_selected_builtin() -> void:
	var content_id: String = String(
		restore_builtin_dialog.get_meta("content_id", "")
	).strip_edges()
	if content_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.restore_unavailable", "Restore target is unavailable.")
		return

	var result: Dictionary = CONTENT_SOURCE.restore_builtin(mode, content_id)
	if not bool(result.get("success", false)):
		_show_action_error(
			"Cannot Restore Built-in Content",
			result.get("errors", [])
		)
		return

	var data: Dictionary = _load_library_document(content_id)
	match mode:
		MODE_POKEMON:
			_load_data(data)
		MODE_KYOKORO:
			_load_profile_data(data)
		MODE_MOVE:
			_load_move_data(data)

	_refresh_saved_list()
	_select_saved_id(content_id)
	_refresh_content_source_status(content_id)
	validation_label.text = LocalizationService.tr_key("content_studio.restored", "Restored built-in content. Your user override was removed.")


func _request_delete_selected() -> void:
	var content_id: String = _get_selected_library_id()
	if content_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.select_delete", "Select a content entry first.")
		return

	var source_info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
	var source: String = String(source_info.get("source", ""))

	if source == "builtin":
		validation_label.text = LocalizationService.tr_key(
			"content_studio.builtin_cannot_delete",
			"Built-in content cannot be deleted. Save changes first if you want to create a user override."
		)
		return

	var document: Dictionary = _load_library_document(content_id)
	var display_name: String = String(
		document.get("display_name", content_id)
	).strip_edges()
	if display_name.is_empty():
		display_name = content_id

	delete_dialog.set_meta("content_id", content_id)
	delete_dialog.set_meta("delete_action", source)

	var confirm_button: Button = delete_dialog.get_ok_button()
	if source == "override":
		delete_dialog.title = LocalizationService.tr_key("content_studio.remove_override_title", "Remove User Override?")
		delete_dialog.ok_button_text = LocalizationService.tr_key("content_studio.remove_override", "Remove Override")
		delete_message_label.text = LocalizationService.tr_format(
			"content_studio.remove_override_message",
			{"name": display_name},
			"Remove your customized version of {name}?\n\nThe built-in version will remain available and will become active again."
		)
		if confirm_button != null:
			confirm_button.disabled = false
		delete_dialog.popup_centered(Vector2i(680, 300))
		return

	var preview: Dictionary = CONTENT_DELETE.preview_delete(mode, content_id)
	if not bool(preview.get("success", false)):
		_show_action_error(
			"Cannot Prepare Delete",
			preview.get("errors", [])
		)
		return

	var message_lines: Array[String] = [
		LocalizationService.tr_key("content_studio.delete_user_question", "Delete this user-created content?"),
		"",
		String(preview.get("kind", "Content"))
		+ ": "
		+ String(preview.get("display_name", display_name)),
		"ID: " + content_id
	]

	var references: Array = preview.get("references", [])
	if not references.is_empty():
		message_lines.append("")
		message_lines.append(LocalizationService.tr_format(
			"content_studio.used_by_label",
			{"items": ", ".join(references)},
			"Used by: {items}"
		))

	var warnings: Array = preview.get("warnings", [])
	if not warnings.is_empty():
		message_lines.append("")
		message_lines.append(LocalizationService.tr_key("content_studio.what_happens", "What will happen:"))
		for warning: Variant in warnings:
			message_lines.append("• " + String(warning))

	var blocked: bool = bool(preview.get("blocked", false))
	if blocked:
		message_lines.append("")
		message_lines.append(LocalizationService.tr_key("content_studio.cannot_delete", "This content cannot be deleted:"))
		for error_text: Variant in preview.get("errors", []):
			message_lines.append("• " + String(error_text))

	delete_dialog.title = LocalizationService.tr_key("content_studio.delete_user_title", "Delete User Content?")
	delete_dialog.ok_button_text = LocalizationService.tr_key("content_studio.delete", "Delete")
	delete_message_label.text = "\n".join(message_lines)

	if confirm_button != null:
		confirm_button.disabled = blocked

	delete_dialog.popup_centered(Vector2i(760, 460))


func _confirm_delete_selected() -> void:
	var content_id: String = String(
		delete_dialog.get_meta("content_id", "")
	).strip_edges()
	var delete_action: String = String(
		delete_dialog.get_meta("delete_action", "")
	)

	if content_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.delete_unavailable", "Delete target is unavailable.")
		return

	if delete_action == "override":
		var restore_result: Dictionary = CONTENT_SOURCE.restore_builtin(mode, content_id)
		if not bool(restore_result.get("success", false)):
			_show_action_error(
				"Cannot Remove User Override",
				restore_result.get("errors", [])
			)
			return

		var restored_data: Dictionary = _load_library_document(content_id)
		match mode:
			MODE_POKEMON:
				_load_data(restored_data)
			MODE_KYOKORO:
				_load_profile_data(restored_data)
			MODE_MOVE:
				_load_move_data(restored_data)
		_refresh_saved_list()
		_select_saved_id(content_id)
		_refresh_content_source_status(content_id)
		validation_label.text = (
			LocalizationService.tr_key("content_studio.override_removed", "User override removed. The built-in version is active again.")
		)
		return

	var result: Dictionary = CONTENT_DELETE.delete(mode, content_id)
	if not bool(result.get("success", false)):
		_show_action_error(
			"Cannot Delete User Content",
			result.get("errors", [])
		)
		return

	validation_label.text = LocalizationService.tr_key("content_studio.user_deleted", "User-created content deleted.")

	var removed_loadouts: Array = result.get("stale_loadouts_removed", [])
	if not removed_loadouts.is_empty():
		validation_label.text += (
			("\n" + LocalizationService.tr_key("content_studio.loadouts_cleaned", "Battle loadout references were cleaned up automatically."))
		)

	_refresh_saved_list()
	_new_content()


func _save_content() -> void:
	match mode:
		MODE_POKEMON:
			_save_pokemon()
		MODE_KYOKORO:
			_save_profile()
		MODE_MOVE:
			_save_move()


func _save_pokemon() -> void:
	var data: Dictionary = (
		_collect_data()
	)

	var result: Dictionary = (
		POKEMON_AUTHORING.save(
			data
		)
	)

	_show_save_result(
		result,
		String(
			data.get(
				"id",
                ""
			)
		)
	)

	if bool(
		result.get(
			"success",
			false
		)
	):
		_refresh_default_dice_status()

		if bool(
			result.get(
				"default_dice_created",
				false
			)
		):
			validation_label.text += (
				"\nDefault Enerkoro was created for this Pokémon."
			)


func _save_profile() -> void:
	var data: Dictionary = (
		_collect_profile_data()
	)

	var result: Dictionary = (
		KYOKORO_AUTHORING.save(
			data
		)
	)

	if bool(
		result.get(
			"success",
			false
		)
	):
		# Refresh Pokémon dropdown immediately because Pokémon JSON references
		# profile IDs from this directory.
		_populate_kyokoro_profiles()

	_show_save_result(
		result,
		String(
			data.get(
				"id",
                ""
			)
		)
	)



func _save_move() -> void:
	var data: Dictionary = _collect_move_data()
	var previous_move_id: String = String(
		current_document.get("id", "")
	)

	var result: Dictionary = (
		MOVE_AUTHORING.save_basic_preserving_complex(data)
	)

	if not bool(result.get("success", false)):
		_show_save_result(
			result,
			String(data.get("id", ""))
		)
		return

	var assignment_result: Dictionary = (
		POKEMON_MOVE_REFERENCE.apply_assignments(
			String(data.get("id", "")),
			String(data.get("owner_id", "")),
			_collect_selected_pokemon_assignments(),
			previous_move_id
		)
	)

	if not bool(
		assignment_result.get(
			"success",
			false
		)
	):
		pending_after_save = false
		_show_action_warning(
			"Move Saved with Warning",
			(
				"The Move was saved, but its Pokémon assignments could not be updated.\n\n"
				+ "\n".join(assignment_result.get("errors", []))
			)
		)
		return

	var saved_as_new_id: bool = (
		not previous_move_id.is_empty()
		and previous_move_id
		!= String(
			data.get(
				"id",
				""
			)
		)
	)

	current_document = data.duplicate(
		true
	)

	_show_save_result(
		result,
		String(data.get("id", ""))
	)

	if saved_as_new_id:
		validation_label.text += (
			"\n" + LocalizationService.tr_format(
				"content_studio.saved_new_move",
				{"id": previous_move_id},
				"Saved as a new Move. Original Move {id} was preserved."
			)
		)

	_refresh_move_assignments(
		String(data.get("id", ""))
	)


func _content_kind_label() -> String:
	match mode:
		MODE_POKEMON:
			return LocalizationService.tr_key("content_studio.kind.pokemon", "Pokémon")
		MODE_KYOKORO:
			return LocalizationService.tr_key("content_studio.kind.charakoro", "Charakoro Profile")
		MODE_MOVE:
			return LocalizationService.tr_key("content_studio.kind.move", "Move")
	return LocalizationService.tr_key("content_studio.kind.content", "Content")



func _friendly_validation_error(raw_error: String) -> String:
	var message: String = raw_error.strip_edges()
	var replacements: Dictionary = {
		"schema_version": "Content format version",
		"species_id": "Species ID",
		"pokemon_type": "Pokémon type",
		"max_hp": "Max HP",
		"weaknesses": "Weaknesses",
		"attack_type": "Attack type",
		"bonus_damage": "Bonus damage",
		"available_move_card_ids": "Move loadout",
		"kyokoro_profile_id": "Charakoro Profile",
		"move_name_id": "Move name ID",
		"owner_id": "Pokémon owner ID",
		"move_category": "Move category",
		"printed_damage": "Printed damage",
		"energy_cost": "Energy cost",
		"base_actions": "Base actions",
		"outcome_rules": "Outcome rules",
		"special_effects": "Special effects",
		"roll_mode": "Roll mode",
		"orientation_weights": "Landing orientation weights",
		"physics_profile": "Physics profile"
	}
	for technical_name: String in replacements:
		message = message.replace(
			technical_name,
			String(replacements[technical_name])
		)

	if message.begins_with("10.0c supports Roll mode"):
		message = "Roll mode must be Weighted."

	return message


func _format_validation_errors(
	raw_errors: Array,
	action_title: String
) -> String:
	var lines: Array[String] = []
	lines.append(action_title)
	lines.append("")

	var count: int = raw_errors.size()
	lines.append(
		LocalizationService.tr_format(
			"content_studio.validation_fix",
			{
				"count": count,
				"noun": LocalizationService.tr_key(
					(
						"content_studio.issue_one"
						if count == 1
						else "content_studio.issue_many"
					),
					("issue" if count == 1 else "issues")
				)
			},
			"Please fix {count} {noun}:"
		)
	)
	lines.append("")

	for raw_error: Variant in raw_errors:
		lines.append("• " + _friendly_validation_error(String(raw_error)))

	return "\n".join(lines)


func _show_action_error(
	action_title: String,
	raw_errors: Array
) -> void:
	validation_label.text = _format_validation_errors(
		raw_errors,
		action_title
	)


func _show_action_warning(
	title: String,
	details: String
) -> void:
	validation_label.text = (
		title
		+ "\n\n"
		+ details
	)


func _show_action_success(message: String) -> void:
	validation_label.text = message


func _show_save_result(
	result: Dictionary,
	saved_id: String
) -> void:
	if bool(result.get("success", false)):
		_refresh_saved_list()
		_select_saved_id(saved_id)
		_refresh_content_source_status(saved_id)

		var source_info: Dictionary = CONTENT_SOURCE.describe(mode, saved_id)
		var source: String = String(source_info.get("source", "user"))
		if source == "override":
			validation_label.text = (
				LocalizationService.tr_key("content_studio.saved_override", "Saved as User Override. The built-in content remains unchanged.")
			)
		else:
			validation_label.text = LocalizationService.tr_key("content_studio.saved_user", "Saved as User Content.")
		_mark_editor_clean()
		call_deferred("_continue_pending_after_save")
	else:
		pending_after_save = false
		_show_action_error(
			"Cannot Save " + _content_kind_label(),
			result.get("errors", [])
		)


func _load_data(
	data: Dictionary
) -> void:
	current_document = data.duplicate(
		true
	)

	id_edit.text = String(
		data.get(
			"id",
            ""
		)
	)
	species_id_edit.text = String(
		data.get(
			"species_id",
            ""
		)
	)
	name_edit.text = String(
		data.get(
			"display_name",
            ""
		)
	)
	hp_spin.value = float(
		data.get(
			"max_hp",
			100
		)
	)

	_select_option_metadata(
		type_option,
		String(
			data.get(
				"pokemon_type",
                "normal"
			)
		)
	)

	var weakness_type: String = "none"
	var weakness_bonus: int = 20
	var weaknesses: Variant = data.get(
		"weaknesses",
		[]
	)

	if (
		weaknesses is Array
		and not (
			weaknesses as Array
		).is_empty()
		and (
			weaknesses as Array
		)[0] is Dictionary
	):
		var first: Dictionary = (
			weaknesses as Array
		)[0]

		weakness_type = String(
			first.get(
				"attack_type",
                "none"
			)
		)
		weakness_bonus = int(
			first.get(
				"bonus_damage",
				20
			)
		)

	_select_option_metadata(
		weakness_type_option,
		weakness_type
	)
	weakness_bonus_spin.value = (
		weakness_bonus
	)

	_select_option_metadata(
		kyokoro_profile_option,
		String(
			data.get(
				"kyokoro_profile_id",
                "standard_equal"
			)
		),
		true
	)

	selected_move_list.clear()

	var move_ids: Variant = data.get(
		"available_move_card_ids",
		[]
	)

	if move_ids is Array:
		for raw_move_id: Variant in move_ids:
			selected_move_list.add_item(
				String(
					raw_move_id
				)
			)

	_refresh_kyokoro_profile_status()
	_refresh_pokemon_charakoro_preview()
	_refresh_default_dice_status()
	_refresh_validation()
	_mark_editor_clean()


func _load_profile_data(
	data: Dictionary
) -> void:
	current_document = data.duplicate(
		true
	)

	profile_id_edit.text = String(
		data.get(
			"id",
            ""
		)
	)

	_select_option_metadata(
		roll_mode_option,
		String(
			data.get(
				"roll_mode",
                "weighted"
			)
		)
	)

	scene_path_edit.text = String(
		data.get(
			"scene_path",
            ""
		)
	)

	var weights: Dictionary = data.get(
		"orientation_weights",
		{}
	)

	for orientation: StringName in (
		KYOKORO_AUTHORING.ORIENTATIONS
	):
		weight_controls[
			orientation
		].value = float(
			weights.get(
				String(orientation),
				1.0
			)
		)

	_refresh_weight_probability()
	_refresh_profile_references()
	_refresh_validation()
	_mark_editor_clean()



func _load_move_data(
	data: Dictionary
) -> void:
	current_document = data.duplicate(
		true
	)

	move_id_edit.text = String(
		data.get(
			"id",
            ""
		)
	)
	move_name_id_edit.text = String(
		data.get(
			"move_name_id",
            ""
		)
	)
	owner_id_edit.text = String(
		data.get(
			"owner_id",
            ""
		)
	)
	move_display_name_edit.text = String(
		data.get(
			"display_name",
            ""
		)
	)

	_select_option_metadata(
		move_category_option,
		String(
			data.get(
				"move_category",
                "attack"
			)
		),
		true
	)

	_select_option_metadata(
		attack_type_option,
		String(
			data.get(
				"attack_type",
                "normal"
			)
		),
		true
	)

	var printed_damage: Variant = data.get(
		"printed_damage",
		null
	)

	printed_damage_none.button_pressed = (
		printed_damage == null
	)
	printed_damage_spin.editable = (
		printed_damage != null
	)

	if printed_damage != null:
		printed_damage_spin.value = float(
			printed_damage
		)
	else:
		printed_damage_spin.value = 0.0

	_load_energy_cost_rows(
		data.get(
			"energy_cost",
			[]
		)
	)

	_load_base_actions(
		data.get(
			"base_actions",
			[]
		)
	)
	_load_outcome_rules(
		data.get(
			"outcome_rules",
			[]
		)
	)

	_refresh_move_advanced_json(
		data
	)
	_refresh_effect_counts()
	_refresh_move_assignments(
		String(data.get("id", ""))
	)
	_refresh_move_preview()
	_refresh_move_runtime_status()
	_refresh_validation()
	_mark_editor_clean()


func _refresh_move_advanced_json(
	data: Dictionary
) -> void:
	if move_advanced_json_text == null:
		return

	var advanced: Dictionary = {
		"special_effects": data.get(
			"special_effects",
			[]
		),
		"resolution": data.get(
			"resolution",
			{}
		),
		"source": data.get(
			"source",
			{}
		),
		"review": data.get(
			"review",
			{}
		)
	}

	move_advanced_json_text.text = JSON.stringify(
		advanced,
		"  "
	)




func _collect_move_data() -> Dictionary:
	var result: Dictionary = (
		current_document.duplicate(
			true
		)
		if not current_document.is_empty()
		else MOVE_AUTHORING.create_default()
	)

	result["schema_version"] = (
		MOVE_AUTHORING.SCHEMA_VERSION
	)
	result["id"] = (
		move_id_edit.text
		.strip_edges()
		.to_lower()
	)
	result["move_name_id"] = (
		move_name_id_edit.text
		.strip_edges()
		.to_lower()
	)
	result["owner_id"] = (
		owner_id_edit.text
		.strip_edges()
		.to_lower()
	)
	result["display_name"] = (
		move_display_name_edit.text
		.strip_edges()
	)
	result["move_category"] = String(
		move_category_option.get_item_metadata(
			move_category_option.selected
		)
	)
	result["attack_type"] = String(
		attack_type_option.get_item_metadata(
			attack_type_option.selected
		)
	)

	result["printed_damage"] = (
		null
		if printed_damage_none.button_pressed
		else int(
			printed_damage_spin.value
		)
	)

	result["energy_cost"] = (
		_collect_energy_cost()
	)
	result["base_actions"] = (
		_collect_base_actions()
	)
	result["outcome_rules"] = (
		_collect_outcome_rules()
	)

	return result



func _load_energy_cost_rows(
	raw_energy_cost: Variant
) -> void:
	for child: Node in (
		energy_cost_rows.get_children()
	):
		energy_cost_rows.remove_child(
			child
		)
		child.queue_free()

	if raw_energy_cost is Array:
		for raw_cost: Variant in (
			raw_energy_cost as Array
		):
			if not raw_cost is Dictionary:
				continue

			var cost: Dictionary = (
				raw_cost as Dictionary
			)

			_create_energy_cost_row(
				String(
					cost.get(
						"energy_type",
                        "grass"
					)
				),
				int(
					cost.get(
						"count",
						1
					)
				)
			)

	_refresh_energy_cost_row_options()
	_refresh_energy_cost_preview()


func _add_energy_cost_row() -> void:
	var used: Array[String] = []

	for child: Node in (
		energy_cost_rows.get_children()
	):
		if child.has_method(
            "get_energy_type"
		):
			used.append(
				String(
					child.get_energy_type()
				)
			)

	var candidate: String = "grass"

	for type_name: String in (
		MOVE_AUTHORING.VALID_ENERGY_TYPES
	):
		if not used.has(
			type_name
		):
			candidate = type_name
			break

	_create_energy_cost_row(
		candidate,
		1
	)

	_on_energy_cost_changed()


func _create_energy_cost_row(
	energy_type: String,
	count: int
) -> void:
	var row: HBoxContainer = (
		ENERGY_COST_EDITOR_ROW.new()
	)

	energy_cost_rows.add_child(
		row
	)

	row.initialize(
		energy_type,
		count
	)

	row.changed.connect(
		_on_energy_cost_changed
	)

	row.remove_requested.connect(
		_remove_energy_cost_row
	)
	row.move_up_requested.connect(
		_move_energy_cost_up
	)
	row.move_down_requested.connect(
		_move_energy_cost_down
	)

	_refresh_energy_cost_row_options()


func _remove_energy_cost_row(
	row: Node
) -> void:
	if row == null:
		return

	energy_cost_rows.remove_child(
		row
	)
	row.queue_free()

	_on_energy_cost_changed()



func _clear_energy_cost() -> void:
	_clear_container(
		energy_cost_rows
	)
	_on_energy_cost_changed()


func _add_attack_type_energy_cost() -> void:
	var attack_type: String = String(
		attack_type_option.get_item_metadata(
			attack_type_option.selected
		)
	)

	if not MOVE_AUTHORING.VALID_ENERGY_TYPES.has(
		attack_type
	):
		return

	for child: Node in energy_cost_rows.get_children():
		if (
			child.has_method(
                "get_energy_type"
			)
			and String(
				child.get_energy_type()
			) == attack_type
		):
			return

	_create_energy_cost_row(
		attack_type,
		1
	)
	_on_energy_cost_changed()


func _move_energy_cost_up(
	row: Node
) -> void:
	var index: int = row.get_index()

	if index <= 0:
		return

	energy_cost_rows.move_child(
		row,
		index - 1
	)
	_on_energy_cost_changed()


func _move_energy_cost_down(
	row: Node
) -> void:
	var index: int = row.get_index()

	if index < 0 or index >= (
		energy_cost_rows.get_child_count() - 1
	):
		return

	energy_cost_rows.move_child(
		row,
		index + 1
	)
	_on_energy_cost_changed()


func _refresh_energy_cost_row_options() -> void:
	var used: Array[String] = []

	for child: Node in energy_cost_rows.get_children():
		if child.has_method(
            "get_energy_type"
		):
			used.append(
				String(
					child.get_energy_type()
				)
			)

	var count: int = energy_cost_rows.get_child_count()

	for index: int in range(count):
		var child: Node = energy_cost_rows.get_child(
			index
		)

		if child.has_method(
            "set_unavailable_types"
		):
			child.set_unavailable_types(
				used
			)

		if child.has_method(
            "set_order_buttons"
		):
			child.set_order_buttons(
				index > 0,
				index < count - 1
			)

	add_energy_cost_button.disabled = (
		used.size()
		>= MOVE_AUTHORING.VALID_ENERGY_TYPES.size()
	)


func _collect_energy_cost() -> Array:
	var result: Array = []

	for child: Node in (
		energy_cost_rows.get_children()
	):
		if child.has_method(
            "to_dictionary"
		):
			result.append(
				child.to_dictionary()
			)

	return result


func _on_energy_cost_changed() -> void:
	_refresh_energy_cost_row_options()
	_refresh_energy_cost_preview()
	_refresh_move_preview()
	_refresh_validation()


func _refresh_energy_cost_preview() -> void:
	for child: Node in (
		energy_cost_visual_preview.get_children()
	):
		energy_cost_visual_preview.remove_child(
			child
		)
		child.queue_free()

	var energy_cost: Array = (
		_collect_energy_cost()
	)

	var total: int = 0

	if energy_cost.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = LocalizationService.tr_key("content_studio.no_energy_cost", "No Energy Cost")
		empty_label.modulate.a = 0.70
		energy_cost_visual_preview.add_child(
			empty_label
		)

	for raw_cost: Variant in energy_cost:
		if not raw_cost is Dictionary:
			continue

		var cost: Dictionary = (
			raw_cost as Dictionary
		)

		var count: int = int(
			cost.get(
				"count",
				0
			)
		)

		total += max(
			0,
			count
		)

		var chip: HBoxContainer = (
			HBoxContainer.new()
		)
		chip.set_script(
			ENERGY_COST_CHIP
		)

		energy_cost_visual_preview.add_child(
			chip
		)

		chip.setup(
			StringName(
				cost.get(
					"energy_type",
                    ""
				)
			),
			count,
			30
		)

	energy_cost_total_label.text = LocalizationService.tr_format(
		"content_studio.total_energy",
		{"total": total},
		"Total Energy Required: {total}"
	)



func _load_base_actions(
	raw_actions: Variant
) -> void:
	_clear_container(
		base_actions_rows
	)

	if raw_actions is Array:
		for raw_action: Variant in (
			raw_actions as Array
		):
			if raw_action is Dictionary:
				_create_base_action_row(
					raw_action as Dictionary
				)

	_refresh_effect_counts()


func _load_outcome_rules(
	raw_rules: Variant
) -> void:
	_clear_container(
		outcome_rule_rows
	)

	if raw_rules is Array:
		for raw_rule: Variant in (
			raw_rules as Array
		):
			if raw_rule is Dictionary:
				_create_outcome_rule_row(
					raw_rule as Dictionary
				)

	_refresh_effect_counts()


func _add_base_action() -> void:
	_create_base_action_row(
		{
			"opcode": "damage.create",
			"args": {
				"target": "opponent",
				"amount": 0
			}
		}
	)
	_on_effect_changed()


func _create_base_action_row(
	action: Dictionary
) -> void:
	var row: VBoxContainer = (
		MOVE_ACTION_EDITOR_ROW.new()
	)
	base_actions_rows.add_child(
		row
	)
	row.initialize(
		action
	)
	row.changed.connect(
		_on_effect_changed
	)
	row.remove_requested.connect(
		_remove_base_action_row
	)


func _remove_base_action_row(
	row: Node
) -> void:
	base_actions_rows.remove_child(
		row
	)
	row.queue_free()
	_on_effect_changed()


func _add_outcome_rule() -> void:
	_create_outcome_rule_row(
		{
			"condition": {
				"type": "kyokoro_orientation_any",
				"orientations": [
                    "FACE_UP"
				]
			},
			"actions": [],
			"raw_text": ""
		}
	)
	_on_effect_changed()


func _create_outcome_rule_row(
	rule: Dictionary
) -> void:
	var editor: VBoxContainer = (
		MOVE_OUTCOME_RULE_EDITOR.new()
	)
	outcome_rule_rows.add_child(
		editor
	)
	editor.initialize(
		rule
	)
	editor.changed.connect(
		_on_effect_changed
	)
	editor.remove_requested.connect(
		_remove_outcome_rule
	)


func _remove_outcome_rule(
	rule: Node
) -> void:
	outcome_rule_rows.remove_child(
		rule
	)
	rule.queue_free()
	_on_effect_changed()


func _collect_base_actions() -> Array:
	var result: Array = []

	for child: Node in (
		base_actions_rows.get_children()
	):
		if not child.has_method(
            "to_dictionary"
		):
			continue

		var action: Dictionary = (
			child.to_dictionary()
		)

		if not action.is_empty():
			result.append(
				action
			)

	return result


func _collect_outcome_rules() -> Array:
	var result: Array = []

	for child: Node in (
		outcome_rule_rows.get_children()
	):
		if not child.has_method(
            "to_dictionary"
		):
			continue

		result.append(
			child.to_dictionary()
		)

	return result


func _on_effect_changed() -> void:
	_refresh_effect_counts()
	_refresh_move_preview()
	_refresh_validation()


func _refresh_effect_counts() -> void:
	base_actions_count_label.text = (
        "base_actions: "
		+ str(
			base_actions_rows.get_child_count()
		)
	)
	outcome_rules_count_label.text = (
        "outcome_rules: "
		+ str(
			outcome_rule_rows.get_child_count()
		)
	)


func _clear_container(
	container: Node
) -> void:
	for child: Node in container.get_children():
		container.remove_child(
			child
		)
		child.queue_free()


func _refresh_profile_references() -> void:
	_clear_container(profile_reference_rows)

	var profile_id: String = profile_id_edit.text.strip_edges().to_lower()
	if profile_id.is_empty():
		profile_reference_status.text = LocalizationService.tr_key("content_studio.profile_reference_empty", "Save or load a Charakoro Profile to see references.")
		return

	var count: int = 0
	for pokemon_id: String in POKEMON_AUTHORING.list_saved():
		var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
		if pokemon.is_empty():
			continue
		if String(pokemon.get("kyokoro_profile_id", "")).strip_edges().to_lower() != profile_id:
			continue

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = (
			String(pokemon.get("display_name", pokemon_id))
			+ "  ["
			+ pokemon_id
			+ "]"
		)

		var open_button: Button = Button.new()
		open_button.text = LocalizationService.tr_key("content_studio.open", "Open")
		open_button.tooltip_text = LocalizationService.tr_key("content_studio.open_pokemon_tooltip", "Open this Pokémon in Pokémon Editor.")
		open_button.pressed.connect(
			_open_pokemon_reference.bind(pokemon_id)
		)

		row.add_child(label)
		row.add_child(open_button)
		profile_reference_rows.add_child(row)
		count += 1

	profile_reference_status.text = LocalizationService.tr_format(
		"content_studio.used_by_count",
		{"count": count},
		"Used by {count} Pokémon."
	)


func _refresh_move_assignments(
	move_id: String
) -> void:
	_clear_container(pokemon_assignment_rows)

	var usage: Array[Dictionary] = (
		POKEMON_MOVE_REFERENCE.list_pokemon_usage(
			move_id,
			owner_id_edit.text
		)
	)

	var count: int = 0

	for entry: Dictionary in usage:
		var pokemon_id: String = String(
			entry.get("pokemon_id", "")
		)
		var referenced: bool = bool(
			entry.get("referenced", false)
		)

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var check: CheckBox = CheckBox.new()
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.text = (
			String(entry.get("display_name", pokemon_id))
			+ "  ["
			+ pokemon_id
			+ "]"
		)
		check.button_pressed = referenced
		check.set_meta("pokemon_id", pokemon_id)
		check.toggled.connect(
			func(_pressed: bool) -> void:
				_refresh_unsaved_status()
				_refresh_authoring_session()
		)

		var open_button: Button = Button.new()
		open_button.text = LocalizationService.tr_key(
			"content_studio.open",
            "Open"
		)
		open_button.tooltip_text = LocalizationService.tr_key(
			"content_studio.open_pokemon_tooltip",
            "Open this Pokémon in Pokémon Editor."
		)
		open_button.pressed.connect(
			_open_pokemon_reference.bind(pokemon_id)
		)

		row.add_child(check)
		row.add_child(open_button)
		pokemon_assignment_rows.add_child(row)

		if referenced:
			count += 1

	pokemon_assignment_status.text = LocalizationService.tr_format(
		"content_studio.assignment_status",
		{
			"owner": owner_id_edit.text.strip_edges().to_lower(),
			"count": count
		},
		"Owner species: {owner} | Referenced by {count} compatible Pokémon. Changes are applied when Save Move Card is pressed."
	)


func _collect_selected_pokemon_assignments() -> Array[String]:
	var result: Array[String] = []

	for row_node: Node in pokemon_assignment_rows.get_children():
		var check: CheckBox = null
		if row_node is CheckBox:
			check = row_node as CheckBox
		else:
			for child: Node in row_node.get_children():
				if child is CheckBox:
					check = child as CheckBox
					break

		if check == null or not check.button_pressed:
			continue

		result.append(
			String(check.get_meta("pokemon_id", ""))
		)

	return result


func _refresh_move_preview() -> void:
	if mode != MODE_MOVE:
		return

	var data: Dictionary = (
		_collect_move_data()
	)

	_refresh_move_card_preview(
		data
	)

	move_json_preview.text = JSON.stringify(
		MOVE_AUTHORING._ordered_document(
			data
		),
        "  "
	)


func _refresh_move_card_preview(
	data: Dictionary
) -> void:
	var display_name: String = String(
		data.get(
			"display_name",
            ""
		)
	).strip_edges()

	move_preview_name.text = (
		display_name
		if not display_name.is_empty()
		else LocalizationService.tr_key("content_studio.unnamed_move", "Unnamed Move")
	)

	var attack_type: String = String(
		data.get(
			"attack_type",
            "normal"
		)
	)
	var move_category: String = String(
		data.get(
			"move_category",
            "attack"
		)
	)

	move_preview_meta.text = (
		attack_type.capitalize()
		+ "  •  "
		+ move_category.capitalize()
	)

	var printed_damage: Variant = data.get(
		"printed_damage",
		null
	)

	move_preview_damage.text = LocalizationService.tr_format(
		"content_studio.damage",
		{
			"damage": (
				"—"
				if printed_damage == null
				else str(int(printed_damage))
			)
		},
		"Damage: {damage}"
	)

	_refresh_move_preview_owner(
		String(
			data.get(
				"owner_id",
                ""
			)
		)
	)
	_refresh_move_preview_energy(
		data.get(
			"energy_cost",
			[]
		)
	)
	_refresh_move_preview_effects(
		data
	)


func _refresh_move_preview_owner(
	owner_id: String
) -> void:
	move_preview_owner_icon.texture = null
	move_preview_owner_icon.tooltip_text = owner_id

	if owner_id.is_empty():
		return

	var texture: Texture2D = (
		POKEMON_PRESENTATION.load_species_texture(owner_id)
	)
	if texture != null:
		move_preview_owner_icon.texture = texture
		move_preview_owner_icon.tooltip_text = (
			owner_id.capitalize()
			+ "\n"
			+ POKEMON_PRESENTATION.resolve_species_image_path(owner_id)
		)


func _refresh_move_preview_energy(
	raw_energy_cost: Variant
) -> void:
	_clear_container(
		move_preview_energy
	)

	if (
		not raw_energy_cost is Array
		or (
			raw_energy_cost as Array
		).is_empty()
	):
		var free_label: Label = Label.new()
		free_label.text = LocalizationService.tr_key("content_studio.no_energy_cost", "No Energy Cost")
		move_preview_energy.add_child(
			free_label
		)
		return

	for raw_cost: Variant in (
		raw_energy_cost as Array
	):
		if not raw_cost is Dictionary:
			continue

		var cost: Dictionary = (
			raw_cost as Dictionary
		)
		var energy_type: StringName = StringName(
			cost.get(
				"energy_type",
                ""
			)
		)
		var count: int = max(
			int(
				cost.get(
					"count",
					0
				)
			),
			0
		)

		var chip: HBoxContainer = HBoxContainer.new()
		chip.set_script(
			ENERGY_COST_CHIP
		)
		move_preview_energy.add_child(
			chip
		)
		chip.setup(
			energy_type,
			count,
			34
		)


func _refresh_move_preview_effects(
	data: Dictionary
) -> void:
	_clear_container(
		move_preview_effects
	)

	var base_actions: Variant = data.get(
		"base_actions",
		[]
	)
	var outcome_rules: Variant = data.get(
		"outcome_rules",
		[]
	)

	var has_effects: bool = false

	if base_actions is Array:
		for raw_action: Variant in (
			base_actions as Array
		):
			if not raw_action is Dictionary:
				continue

			_add_move_preview_effect_line(
				_action_preview_text(
					raw_action as Dictionary
				)
			)
			has_effects = true

	if outcome_rules is Array:
		for raw_rule: Variant in (
			outcome_rules as Array
		):
			if not raw_rule is Dictionary:
				continue

			var rule: Dictionary = (
				raw_rule as Dictionary
			)
			var condition: Dictionary = {}

			if rule.get(
				"condition",
				{}
			) is Dictionary:
				condition = (
					rule.get(
						"condition",
						{}
					)
					as Dictionary
				)

			var orientation_text: String = ""

			var raw_orientations: Variant = condition.get(
				"orientations",
				[]
			)

			if raw_orientations is Array:
				var names: PackedStringArray = []

				for raw_orientation: Variant in (
					raw_orientations as Array
				):
					names.append(
						String(
							raw_orientation
						)
					)

				orientation_text = ", ".join(
					names
				)

			var raw_text: String = String(
				rule.get(
					"raw_text",
                    ""
				)
			).strip_edges()

			var line: String = (
				orientation_text
				if not orientation_text.is_empty()
				else "Outcome"
			)

			if not raw_text.is_empty():
				line += " → " + raw_text
			else:
				var actions: Variant = rule.get(
					"actions",
					[]
				)

				if (
					actions is Array
					and not (
						actions as Array
					).is_empty()
					and (
						actions as Array
					)[0] is Dictionary
				):
					line += " → " + _action_preview_text(
						(
							actions as Array
						)[0] as Dictionary
					)

			_add_move_preview_effect_line(
				line
			)
			has_effects = true

	if not has_effects:
		_add_move_preview_effect_line(
			LocalizationService.tr_key("content_studio.no_effects", "No additional effects.")
		)


func _add_move_preview_effect_line(
	text: String
) -> void:
	var label: Label = Label.new()
	label.text = LocalizationService.tr_format(
		"content_studio.preview_bullet",
		{"text": text},
        "• {text}"
	)
	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	move_preview_effects.add_child(
		label
	)


func _action_preview_text(
	action: Dictionary
) -> String:
	var opcode: String = String(action.get("opcode", "effect"))
	var args: Dictionary = {}
	if action.get("args", {}) is Dictionary:
		args = (action.get("args", {}) as Dictionary)

	match opcode:
		"damage.create":
			return LocalizationService.tr_format(
				"content_studio.action.damage",
				{
					"amount": int(args.get("amount", 0)),
					"target": String(args.get("target", "opponent"))
				},
                "Deal {amount} damage to {target}."
			)
		"incoming_damage.modify":
			var incoming_amount: int = int(args.get("amount", 0))
			return LocalizationService.tr_format(
				"content_studio.action.incoming_damage",
				{
					"amount": (
						("+" if incoming_amount >= 0 else "")
						+ str(incoming_amount)
					),
					"timing": String(args.get("timing", "immediate"))
				},
                "Incoming damage {amount} ({timing})."
			)
		"energy_dice.modify":
			var dice_amount: int = int(args.get("amount", 0))
			return LocalizationService.tr_format(
				"content_studio.action.enerkoro",
				{
					"target": String(args.get("target", "self")).capitalize(),
					"amount": (
						("+" if dice_amount >= 0 else "")
						+ str(dice_amount)
					)
				},
                "{target} next turn Enerkoro {amount}."
			)

		_:
			return opcode



func _collect_data() -> Dictionary:
	var result: Dictionary = (
		current_document.duplicate(
			true
		)
		if not current_document.is_empty()
		else POKEMON_AUTHORING.create_default()
	)

	var weakness_type: String = "none"
	if (
		weakness_type_option.item_count > 0
		and weakness_type_option.selected >= 0
	):
		weakness_type = str(
			weakness_type_option.get_item_metadata(
				weakness_type_option.selected
			)
		)

	var weaknesses: Array = []

	if weakness_type != "none":
		weaknesses.append(
			{
				"attack_type": weakness_type,
				"bonus_damage": int(
					weakness_bonus_spin.value
				)
			}
		)

	var move_ids: Array[String] = []

	for index: int in range(
		selected_move_list.item_count
	):
		move_ids.append(
			selected_move_list.get_item_text(
				index
			)
		)

	result["schema_version"] = (
		POKEMON_AUTHORING.SCHEMA_VERSION
	)
	result["id"] = (
		id_edit.text.strip_edges().to_lower()
	)
	result["species_id"] = (
		species_id_edit.text.strip_edges().to_lower()
	)
	result["display_name"] = (
		name_edit.text.strip_edges()
	)
	result["pokemon_type"] = String(
		type_option.get_item_metadata(
			type_option.selected
		)
	)
	result["max_hp"] = int(
		hp_spin.value
	)
	result["weaknesses"] = weaknesses
	result["available_move_card_ids"] = (
		move_ids
	)
	result["kyokoro_profile_id"] = String(
		kyokoro_profile_option.get_item_metadata(
			kyokoro_profile_option.selected
		)
	)

	return result


func _collect_profile_data() -> Dictionary:
	var weights: Dictionary = {}

	for orientation: StringName in (
		KYOKORO_AUTHORING.ORIENTATIONS
	):
		weights[String(orientation)] = (
			weight_controls[
				orientation
			].value
		)

	var physics_profile: Dictionary = {}

	if (
		not current_document.is_empty()
		and current_document.get(
			"physics_profile",
			{}
		) is Dictionary
	):
		physics_profile = (
			current_document.get(
				"physics_profile",
				{}
			)
			as Dictionary
		).duplicate(
			true
		)

	return {
		"schema_version": (
			KYOKORO_AUTHORING.SCHEMA_VERSION
		),
		"id": (
			profile_id_edit.text
			.strip_edges()
			.to_lower()
		),
		"roll_mode": String(
			roll_mode_option.get_item_metadata(
				roll_mode_option.selected
			)
		),
		"orientation_weights": weights,
		"scene_path": (
			scene_path_edit.text.strip_edges()
		),
		"physics_profile": physics_profile
	}


func _refresh_weight_probability() -> void:
	var weights: Dictionary = {}

	for orientation: StringName in (
		KYOKORO_AUTHORING.ORIENTATIONS
	):
		weights[String(orientation)] = (
			weight_controls[
				orientation
			].value
		)

	var probabilities: Dictionary = (
		KYOKORO_AUTHORING.probabilities(
			weights
		)
	)

	var total: float = 0.0

	for orientation: StringName in (
		KYOKORO_AUTHORING.ORIENTATIONS
	):
		total += float(
			weights[String(orientation)]
		)

		probability_labels[
			orientation
		].text = (
            "%.1f%%"
			% (
				float(
					probabilities[
						String(orientation)
					]
				)
				* 100.0
			)
		)

	total_weight_label.text = LocalizationService.tr_format(
		"content_studio.total_weight",
		{"weight": "%.1f" % total},
		"Total Weight: {weight}"
	)


func _navigate_to_content(target_mode: StringName, content_id: String) -> void:
	_request_guarded_action(
		"navigate",
		{
			"mode": target_mode,
			"id": content_id
		}
	)


func _navigate_to_content_now(target_mode: StringName, content_id: String) -> void:
	var safe_id: String = content_id.strip_edges()
	if safe_id.is_empty():
		validation_label.text = LocalizationService.tr_key("content_studio.navigation_unavailable", "Navigation target is unavailable.")
		return

	_switch_mode(target_mode)
	_refresh_saved_list()
	_select_saved_id(safe_id)

	match target_mode:
		MODE_POKEMON:
			var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(safe_id)
			if pokemon.is_empty():
				validation_label.text = LocalizationService.tr_format(
				"content_studio.load_failed_pokemon",
				{"id": safe_id},
                "Pokémon could not be loaded: {id}"
			)
				return
			_load_data(pokemon)
		MODE_KYOKORO:
			var profile: Dictionary = KYOKORO_AUTHORING.load_by_id(safe_id)
			if profile.is_empty():
				validation_label.text = LocalizationService.tr_format(
				"content_studio.load_failed_charakoro",
				{"id": safe_id},
                "Charakoro Profile could not be loaded: {id}"
			)
				return
			_load_profile_data(profile)
		MODE_MOVE:
			var move_data: Dictionary = MOVE_AUTHORING.load_by_id(safe_id)
			if move_data.is_empty():
				validation_label.text = LocalizationService.tr_format(
				"content_studio.load_failed_move",
				{"id": safe_id},
                "Move could not be loaded: {id}"
			)
				return
			_load_move_data(move_data)

	_refresh_content_source_status(safe_id)
	_refresh_new_content_guide()
	validation_label.text = LocalizationService.tr_format(
		"content_studio.opened",
		{"kind": _content_kind_label(), "id": safe_id},
        "Opened {kind}: {id}"
	)


func _open_selected_move() -> void:
	var selected: PackedInt32Array = selected_move_list.get_selected_items()
	if selected.is_empty():
		validation_label.text = LocalizationService.tr_key(
			"content_studio.select_move_first",
            "Select a Move from the Pokémon Move Loadout first."
		)
		return
	var move_id: String = selected_move_list.get_item_text(selected[0]).strip_edges()
	_navigate_to_content(MODE_MOVE, move_id)


func _open_selected_kyokoro_profile() -> void:
	if kyokoro_profile_option.item_count <= 0:
		validation_label.text = LocalizationService.tr_key(
			"content_studio.no_charakoro_selected",
            "No Charakoro Profile is selected."
		)
		return
	var profile_id: String = String(
		kyokoro_profile_option.get_item_metadata(kyokoro_profile_option.selected)
	).strip_edges()
	_navigate_to_content(MODE_KYOKORO, profile_id)


func _open_pokemon_reference(pokemon_id: String) -> void:
	_navigate_to_content(MODE_POKEMON, pokemon_id)


func _add_selected_move() -> void:
	var selected: PackedInt32Array = (
		available_move_list.get_selected_items()
	)

	if selected.is_empty():
		return

	var move_id: String = (
		available_move_list.get_item_text(
			selected[0]
		)
	)

	for index: int in range(
		selected_move_list.item_count
	):
		if (
			selected_move_list.get_item_text(
				index
			)
			== move_id
		):
			return

	selected_move_list.add_item(
		move_id
	)
	_refresh_validation()


func _remove_selected_move() -> void:
	var selected: PackedInt32Array = (
		selected_move_list.get_selected_items()
	)

	if selected.is_empty():
		return

	selected_move_list.remove_item(
		selected[0]
	)
	_refresh_validation()


func _refresh_pokemon_charakoro_preview() -> void:
	var pokemon_id: String = id_edit.text.strip_edges().to_lower()
	var species_id: String = species_id_edit.text.strip_edges().to_lower()
	pokemon_charakoro_preview.texture = null

	if pokemon_id.is_empty() and species_id.is_empty():
		pokemon_charakoro_preview_status.text = LocalizationService.tr_key("content_studio.no_pokemon_selected", "No Pokémon ID selected.")
		return

	var texture: Texture2D = POKEMON_PRESENTATION.load_pokemon_texture(
		pokemon_id,
		species_id
	)
	if texture == null:
		pokemon_charakoro_preview_status.text = LocalizationService.tr_format(
			"content_studio.png_missing",
			{
				"file": (
					pokemon_id + ".png"
					if not pokemon_id.is_empty()
					else species_id + "_standard.png"
				)
			},
			"PNG missing: {file}"
		)
		return

	pokemon_charakoro_preview.texture = texture
	var path: String = POKEMON_PRESENTATION.resolve_pokemon_image_path(
		pokemon_id,
		species_id
	)
	pokemon_charakoro_preview_status.text = (
		path.get_file()
		+ " · "
		+ LocalizationService.tr_key(
			(
				"content_studio.user_asset"
				if path.begins_with("user://")
				else "content_studio.ready_asset"
			),
			(
				"User Asset"
				if path.begins_with("user://")
				else "Built-in"
			)
		)
	)


func _refresh_kyokoro_profile_status() -> void:
	if kyokoro_profile_option.item_count <= 0:
		kyokoro_profile_status.text = LocalizationService.tr_key(
			"content_studio.no_profiles",
			"No Charakoro profiles found."
		)
		return

	var profile_id: String = String(
		kyokoro_profile_option.get_item_metadata(
			kyokoro_profile_option.selected
		)
	)

	var profile_info: Dictionary = CONTENT_SOURCE.describe(MODE_KYOKORO, profile_id)
	kyokoro_profile_status.text = LocalizationService.tr_format(
		"content_studio.profile_source",
		{
			"source": String(
				profile_info.get(
					"label",
					LocalizationService.tr_key(
						"content_studio.builtin_content",
						"Built-in Content"
					)
				)
			)
		},
		"Profile source: {source}"
	)


func _refresh_move_runtime_status() -> void:
	if mode != MODE_MOVE:
		return

	var report: Dictionary = MOVE_RUNTIME_COMPATIBILITY.inspect_move_document(
		_collect_move_data()
	)
	var used: Array = report.get("used_opcodes", [])

	if bool(report.get("success", false)):
		var details: String = (
			LocalizationService.tr_format(
				"content_studio.runtime_details",
				{"opcodes": ", ".join(used)},
                " — {opcodes}"
			)
			if not used.is_empty()
			else LocalizationService.tr_key(
				"content_studio.runtime_no_opcodes",
                " — No effect opcodes"
			)
		)
		move_runtime_status.text = LocalizationService.tr_format(
			"content_studio.runtime_supported",
			{"details": details},
            "Runtime Effects: Supported{details}"
		)
	else:
		move_runtime_status.text = LocalizationService.tr_format(
			"content_studio.runtime_blocked",
			{"opcodes": ", ".join(report.get("unsupported_opcodes", []))},
            "Runtime Effects: BLOCKED — {opcodes}"
		)



func _is_creating_new_content() -> bool:
	return (
		_get_selected_library_id().is_empty()
		and String(current_document.get("id", "")).strip_edges().is_empty()
	)


func _checkmark(done: bool) -> String:
	return "✓" if done else "○"


func _check_item(
	done: bool,
	key: String,
	fallback: String
) -> String:
	return LocalizationService.tr_format(
		"content_studio.check_item",
		{
			"mark": _checkmark(done),
			"label": LocalizationService.tr_key(key, fallback)
		},
        "{mark} {label}"
	)


func _refresh_new_content_guide() -> void:
	var creating: bool = _is_creating_new_content()
	new_content_guide_panel.visible = creating
	if not creating:
		return

	var lines: Array[String] = []
	match mode:
		MODE_POKEMON:
			var data: Dictionary = _collect_data()
			new_content_guide_title.text = LocalizationService.tr_key("content_studio.create_new_pokemon", "Create New Pokémon")
			new_content_guide_hint.text = LocalizationService.tr_key(
				"content_studio.guide_pokemon",
				"Start with the required identity and battle fields. Charakoro, Default Enerkoro, and Moves can be refined before or after creation."
			)
			lines = [
				_check_item(not String(data.get("id", "")).strip_edges().is_empty(), "content_studio.pokemon_id", "Pokémon ID"),
				_check_item(not String(data.get("species_id", "")).strip_edges().is_empty(), "content_studio.species_id", "Species ID"),
				_check_item(not String(data.get("display_name", "")).strip_edges().is_empty(), "content_studio.display_name", "Display Name"),
				_check_item(int(data.get("max_hp", 0)) > 0, "content_studio.max_hp", "Max HP"),
				_check_item(not String(data.get("pokemon_type", "")).strip_edges().is_empty(), "content_studio.pokemon_type", "Pokémon Type"),
				"",
				LocalizationService.tr_key("content_studio.gameplay_setup", "Gameplay Setup"),
				_check_item(not String(data.get("kyokoro_profile_id", "")).strip_edges().is_empty(), "content_studio.charakoro_profile", "Charakoro Profile"),
				_check_item((data.get("available_move_card_ids", []) as Array).size() > 0, "content_studio.at_least_one_move", "At least one Move")
			]
		MODE_KYOKORO:
			var profile: Dictionary = _collect_profile_data()
			new_content_guide_title.text = LocalizationService.tr_key("content_studio.create_new_charakoro", "Create New Charakoro Profile")
			new_content_guide_hint.text = LocalizationService.tr_key(
				"content_studio.guide_charakoro",
				"Give the profile a unique ID and configure its landing orientation weights."
			)
			var weights: Dictionary = profile.get("orientation_weights", {}) as Dictionary
			var total_weight: float = 0.0
			for value: Variant in weights.values():
				total_weight += max(float(value), 0.0)
			lines = [
				_check_item(not String(profile.get("id", "")).strip_edges().is_empty(), "content_studio.profile_id", "Profile ID"),
				_check_item(String(profile.get("roll_mode", "")) == "weighted", "content_studio.weighted_roll", "Weighted roll mode"),
				_check_item(total_weight > 0.0, "content_studio.weights_configured", "Landing weights configured")
			]
		MODE_MOVE:
			var move_data: Dictionary = _collect_move_data()
			new_content_guide_title.text = LocalizationService.tr_key("content_studio.create_new_move", "Create New Move")
			new_content_guide_hint.text = LocalizationService.tr_key(
				"content_studio.guide_move",
				"Define the Move identity first, then add Energy Cost and Effects as needed."
			)
			lines = [
				_check_item(not String(move_data.get("id", "")).strip_edges().is_empty(), "content_studio.move_id", "Move ID"),
				_check_item(not String(move_data.get("move_name_id", "")).strip_edges().is_empty(), "content_studio.move_name_id", "Move Name ID"),
				_check_item(not String(move_data.get("owner_id", "")).strip_edges().is_empty(), "content_studio.pokemon_owner", "Pokémon Owner"),
				_check_item(not String(move_data.get("display_name", "")).strip_edges().is_empty(), "content_studio.display_name", "Display Name"),
				_check_item(not String(move_data.get("move_category", "")).strip_edges().is_empty(), "content_studio.category", "Category"),
				_check_item(not String(move_data.get("attack_type", "")).strip_edges().is_empty(), "content_studio.attack_type", "Attack Type"),
				"",
				LocalizationService.tr_key("content_studio.gameplay_setup", "Gameplay Setup"),
				_check_item((move_data.get("energy_cost", []) as Array).size() > 0, "content_studio.energy_configured", "Energy Cost configured"),
				_check_item(
					(move_data.get("base_actions", []) as Array).size() > 0
					or (move_data.get("outcome_rules", []) as Array).size() > 0,
					"content_studio.at_least_one_effect",
					"At least one Effect"
				)
			]

	new_content_guide_checklist.text = "\n".join(lines)


func _pokemon_ids_referencing_move(move_id: String) -> Array[String]:
	var result: Array[String] = []
	var safe_id: String = move_id.strip_edges().to_lower()
	if safe_id.is_empty():
		return result

	for pokemon_id: String in POKEMON_AUTHORING.list_saved():
		var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
		if pokemon.is_empty():
			continue
		var raw_moves: Variant = pokemon.get("available_move_card_ids", [])
		if raw_moves is Array and (raw_moves as Array).has(safe_id):
			result.append(pokemon_id)
	return result


func _pokemon_ids_referencing_profile(profile_id: String) -> Array[String]:
	var result: Array[String] = []
	var safe_id: String = profile_id.strip_edges().to_lower()
	if safe_id.is_empty():
		return result

	for pokemon_id: String in POKEMON_AUTHORING.list_saved():
		var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(pokemon_id)
		if pokemon.is_empty():
			continue
		if String(
			pokemon.get("kyokoro_profile_id", "")
		).strip_edges().to_lower() == safe_id:
			result.append(pokemon_id)
	return result


func _authoring_source_label(content_id: String) -> String:
	var safe_id: String = content_id.strip_edges()
	if safe_id.is_empty():
		return "New Content"
	var info: Dictionary = CONTENT_SOURCE.describe(mode, safe_id)
	return String(info.get("label", "New Content"))


func _refresh_authoring_session() -> void:
	var data: Dictionary = {}
	match mode:
		MODE_POKEMON:
			data = _collect_data()
		MODE_KYOKORO:
			data = _collect_profile_data()
		MODE_MOVE:
			data = _collect_move_data()

	var content_id: String = String(data.get("id", "")).strip_edges()
	var original_id: String = String(
		current_document.get("id", "")
	).strip_edges()
	var display_name: String = String(
		data.get("display_name", content_id)
	).strip_edges()
	if display_name.is_empty():
		display_name = (
			LocalizationService.tr_format(
				"content_studio.new_kind",
				{"kind": _content_kind_label()},
				"New {kind}"
			)
			if content_id.is_empty()
			else content_id
		)

	authoring_session_title.text = display_name
	authoring_session_state.text = LocalizationService.tr_format(
		"content_studio.authoring_state",
		{
			"source": _authoring_source_label(
				original_id if not original_id.is_empty() else content_id
			),
			"state": LocalizationService.tr_key(
				"content_studio.unsaved"
				if _has_unsaved_changes()
				else "content_studio.saved",
				"● Unsaved"
				if _has_unsaved_changes()
				else "✓ Saved"
			)
		},
		"{source} · {state}"
	)

	var summary_lines: Array[String] = []
	match mode:
		MODE_POKEMON:
			var profile_id: String = String(
				data.get("kyokoro_profile_id", "")
			).strip_edges()
			var moves: Array = data.get("available_move_card_ids", []) as Array
			summary_lines.append(
				LocalizationService.tr_format(
					"content_studio.dependencies_locale",
					{
						"profile": (
							profile_id
							if not profile_id.is_empty()
							else LocalizationService.tr_key("content_studio.none", "None")
						),
						"moves": LocalizationService.format_count(
							"format.count.move.one",
							"format.count.move.other",
							moves.size(),
							"{count} Move",
							"{count} Moves"
						)
					},
					"Dependencies: Charakoro {profile} · {moves}"
				)
			)
			var missing: Array[String] = []
			if not profile_id.is_empty() and KYOKORO_AUTHORING.load_by_id(profile_id).is_empty():
				missing.append(LocalizationService.tr_format("content_studio.missing_charakoro", {"id": profile_id}, "Charakoro {id}"))
			for raw_move_id: Variant in moves:
				var move_id: String = String(raw_move_id).strip_edges()
				if not move_id.is_empty() and MOVE_AUTHORING.load_by_id(move_id).is_empty():
					missing.append(LocalizationService.tr_format("content_studio.missing_move", {"id": move_id}, "Move {id}"))
			if not missing.is_empty():
				summary_lines.append(
					LocalizationService.tr_format(
						"content_studio.missing_references",
						{"items": ", ".join(missing)},
                        "Missing references: {items}"
					)
				)
		MODE_MOVE:
			var reference_id: String = original_id if not original_id.is_empty() else content_id
			var pokemon_refs: Array[String] = _pokemon_ids_referencing_move(reference_id)
			summary_lines.append(
				LocalizationService.tr_format(
					"content_studio.referenced_by_locale",
					{
						"pokemon_count": LocalizationService.format_count(
							"format.count.pokemon.one",
							"format.count.pokemon.other",
							pokemon_refs.size(),
							"{count} Pokémon",
							"{count} Pokémon"
						),
						"items": (
							LocalizationService.tr_format(
								"content_studio.reference_items",
								{"items": ", ".join(pokemon_refs)},
								": {items}"
							)
							if not pokemon_refs.is_empty()
							else ""
						)
					},
					"Referenced by {pokemon_count}{items}"
				)
			)
		MODE_KYOKORO:
			var reference_id: String = original_id if not original_id.is_empty() else content_id
			var pokemon_refs: Array[String] = _pokemon_ids_referencing_profile(reference_id)
			summary_lines.append(
				LocalizationService.tr_format(
					"content_studio.used_by_locale",
					{
						"pokemon_count": LocalizationService.format_count(
							"format.count.pokemon.one",
							"format.count.pokemon.other",
							pokemon_refs.size(),
							"{count} Pokémon",
							"{count} Pokémon"
						),
						"items": (
							LocalizationService.tr_format(
								"content_studio.reference_items",
								{"items": ", ".join(pokemon_refs)},
								": {items}"
							)
							if not pokemon_refs.is_empty()
							else ""
						)
					},
					"Used by {pokemon_count}{items}"
				)
			)

	authoring_dependency_summary.text = "\n".join(summary_lines)

	var id_changed: bool = (
		not original_id.is_empty()
		and not content_id.is_empty()
		and original_id != content_id
	)
	authoring_impact_warning.visible = id_changed
	if id_changed:
		match mode:
			MODE_MOVE:
				authoring_impact_warning.text = LocalizationService.tr_format(
					"content_studio.id_change_move",
					{"new_id": content_id, "old_id": original_id},
                    "ID change: Save will create a new Move '{new_id}'. The original Move '{old_id}' and its existing Pokémon references remain."
				)
			MODE_KYOKORO:
				authoring_impact_warning.text = LocalizationService.tr_format(
					"content_studio.id_change_charakoro",
					{"new_id": content_id, "old_id": original_id},
                    "ID change: Save will create a new Charakoro Profile '{new_id}'. Pokémon using '{old_id}' will continue using the original profile."
				)
			MODE_POKEMON:
				authoring_impact_warning.text = LocalizationService.tr_format(
					"content_studio.id_change_pokemon",
					{"new_id": content_id, "old_id": original_id},
                    "ID change: Save will create a new Pokémon '{new_id}'. The original Pokémon '{old_id}' remains available."
				)
	else:
		authoring_impact_warning.text = ""


func _localize_validation_error(
	error_text: String
) -> String:
	var exact: Dictionary = {
		"Pokémon ID is required.": "content_studio.validation.pokemon_id_required",
		"species_id is required.": "content_studio.validation.species_id_required",
		"Display name is required.": "content_studio.validation.display_name_required",
		"kyokoro_profile_id is required.": "content_studio.validation.charakoro_required",
		"Profile ID is required.": "content_studio.validation.profile_id_required",
		"10.0c supports roll_mode = weighted.": "content_studio.validation.weighted_only",
		"Total orientation weight must be greater than 0.": "content_studio.validation.total_weight_positive",
		"move_category is invalid.": "content_studio.validation.move_category_invalid",
		"attack_type is invalid.": "content_studio.validation.attack_type_invalid",
		"printed_damage cannot be negative.": "content_studio.validation.damage_nonnegative"
	}
	if exact.has(error_text):
		return LocalizationService.tr_key(
			String(exact[error_text]),
			error_text
		)

	if error_text.ends_with(" is required."):
		var field_name: String = error_text.trim_suffix(
			" is required."
		)
		return LocalizationService.tr_format(
			"content_studio.validation.field_required",
			{"field": field_name},
			"{field} is required."
		)

	return error_text


func _localized_validation_errors(
	errors: Array
) -> Array[String]:
	var result: Array[String] = []
	for raw_error: Variant in errors:
		result.append(
			_localize_validation_error(
				String(raw_error)
			)
		)
	return result


func _refresh_validation() -> void:
	_refresh_new_content_guide()
	if mode == MODE_MOVE:
		_refresh_move_runtime_status()

	var validation: Dictionary

	match mode:
		MODE_POKEMON:
			validation = POKEMON_AUTHORING.validate(
				_collect_data()
			)
		MODE_KYOKORO:
			validation = KYOKORO_AUTHORING.validate(
				_collect_profile_data()
			)
		MODE_MOVE:
			validation = MOVE_AUTHORING.validate_basic(
				_collect_move_data()
			)

	if bool(
		validation["success"]
	):
		validation_label.text = (
			LocalizationService.tr_key("content_studio.valid", "VALID — Ready to save.")
		)
		save_button.disabled = false
	else:
		validation_label.text = LocalizationService.tr_format(
			"content_studio.invalid",
			{
				"errors": "\n".join(
					_localized_validation_errors(
						validation["errors"]
					)
				)
			},
			"INVALID\n{errors}"
		)
		save_button.disabled = true

	_refresh_unsaved_status()
	_refresh_authoring_session()


func _refresh_saved_list() -> void:
	var previously_selected_id: String = (
		_get_selected_library_id()
	)

	saved_list.clear()

	var ids: Array[String] = []

	match mode:
		MODE_POKEMON:
			ids = POKEMON_AUTHORING.list_saved()
		MODE_KYOKORO:
			ids = KYOKORO_AUTHORING.list_saved()
		MODE_MOVE:
			ids = MOVE_AUTHORING.list_saved()

	ids.sort()

	var query: String = (
		library_search_edit.text.strip_edges().to_lower()
	)
	var visible_count: int = 0

	for content_id: String in ids:
		var document: Dictionary = (
			_load_library_document(
				content_id
			)
		)

		if not _library_document_matches(
			content_id,
			document,
			query
		):
			continue
		if not _library_document_passes_filters(content_id, document):
			continue

		var index: int = saved_list.item_count
		saved_list.add_item(
			_library_display_text(
				content_id,
				document
			)
		)
		saved_list.set_item_metadata(
			index,
			content_id
		)
		saved_list.set_item_tooltip(
			index,
			_library_tooltip_text(
				content_id,
				document
			)
		)
		visible_count += 1

	library_filter_status.text = LocalizationService.tr_format(
		"content_studio.filter_count",
		{
			"visible": visible_count,
			"total": ids.size()
		},
		"{visible} / {total} shown"
	)

	if (
		not previously_selected_id.is_empty()
		and _select_saved_id(
			previously_selected_id
		)
	):
		return

	var current_id: String = String(
		current_document.get(
			"id",
			""
		)
	).strip_edges()

	if not current_id.is_empty():
		_select_saved_id(
			current_id
		)


func _load_library_document(
	content_id: String
) -> Dictionary:
	match mode:
		MODE_POKEMON:
			return POKEMON_AUTHORING.load_by_id(
				content_id
			)
		MODE_KYOKORO:
			return KYOKORO_AUTHORING.load_by_id(
				content_id
			)
		MODE_MOVE:
			return MOVE_AUTHORING.load_by_id(
				content_id
			)

	return {}


func _library_document_passes_filters(
	content_id: String,
	document: Dictionary
) -> bool:
	var source_index: int = library_source_filter.selected
	var source_info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
	var source: String = String(source_info.get("source", ""))
	match source_index:
		1:
			if source != "builtin":
				return false
		2:
			if source != "override":
				return false
		3:
			if source != "user":
				return false

	if mode != MODE_KYOKORO and library_type_filter.selected > 0:
		var wanted_type: String = String(
			library_type_filter.get_item_metadata(library_type_filter.selected)
		)
		var document_type: String = String(
			document.get(
				"pokemon_type" if mode == MODE_POKEMON else "attack_type",
				""
			)
		).to_lower()
		if document_type != wanted_type:
			return false

	return true


func _library_document_matches(
	content_id: String,
	document: Dictionary,
	query: String
) -> bool:
	if query.is_empty():
		return true

	var searchable_parts: Array[String] = [
		content_id
	]

	match mode:
		MODE_POKEMON:
			for key: String in [
				"display_name",
				"species_id",
				"pokemon_type"
			]:
				searchable_parts.append(
					String(
						document.get(
							key,
							""
						)
					)
				)

		MODE_KYOKORO:
			for key: String in [
				"profile_id",
				"roll_mode"
			]:
				searchable_parts.append(
					String(
						document.get(
							key,
							""
						)
					)
				)

		MODE_MOVE:
			for key: String in [
				"display_name",
				"move_name_id",
				"owner_id",
				"move_category",
				"attack_type"
			]:
				searchable_parts.append(
					String(
						document.get(
							key,
							""
						)
					)
				)

	for raw_part: String in searchable_parts:
		if raw_part.to_lower().contains(
			query
		):
			return true

	return false


func _library_display_text(
	content_id: String,
	document: Dictionary
) -> String:
	if mode == MODE_POKEMON or mode == MODE_MOVE:
		var display_name: String = String(
			document.get(
				"display_name",
				""
			)
		).strip_edges()

		if not display_name.is_empty():
			if mode == MODE_POKEMON:
				display_name = GameContentLocalizationService.text(
					"pokemon",
					String(document.get("species_id", content_id)),
					"name",
					display_name
				)
			elif mode == MODE_MOVE:
				display_name = GameContentLocalizationService.text(
					"move",
					String(document.get("move_name_id", content_id)),
					"name",
					display_name
				)
			var source_info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
			var source_mark: String = (
				LocalizationService.tr_key("content_studio.source_modified", " • Modified")
				if String(source_info.get("source", "")) == "override"
				else LocalizationService.tr_key("content_studio.source_user", " • User")
				if String(source_info.get("source", "")) == "user"
				else ""
			)
			return (
				display_name
				+ "  ["
				+ content_id
				+ "]"
				+ source_mark
			)

	var source_info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
	var source_mark: String = (
		LocalizationService.tr_key("content_studio.source_modified", " • Modified")
		if String(source_info.get("source", "")) == "override"
		else LocalizationService.tr_key("content_studio.source_user", " • User")
		if String(source_info.get("source", "")) == "user"
		else ""
	)
	return content_id + source_mark


func _library_tooltip_text(
	content_id: String,
	document: Dictionary
) -> String:
	var source_info: Dictionary = CONTENT_SOURCE.describe(mode, content_id)
	var source_line: String = LocalizationService.tr_format(
		"content_studio.tooltip_source",
		{"source": String(source_info.get("label", LocalizationService.tr_key("common.unknown", "Unknown")))},
        "Source: {source}"
	)
	match mode:
		MODE_POKEMON:
			return LocalizationService.tr_format(
				"content_studio.tooltip_pokemon",
				{
					"source": source_line,
					"name": GameContentLocalizationService.text(
						"pokemon",
						String(document.get("species_id", content_id)),
						"name",
						String(document.get("display_name", content_id))
					),
					"id": content_id,
					"species": String(document.get("species_id", "")),
					"type": GameContentLocalizationService.localize_type(document.get("pokemon_type", ""))
				},
                "{source}\n{name}\nID: {id}\nSpecies: {species}\nType: {type}"
			)

		MODE_MOVE:
			return LocalizationService.tr_format(
				"content_studio.tooltip_move",
				{
					"source": source_line,
					"name": GameContentLocalizationService.text(
						"move",
						String(document.get("move_name_id", content_id)),
						"name",
						String(document.get("display_name", content_id))
					),
					"id": content_id,
					"owner": String(document.get("owner_id", "")),
					"category": String(document.get("move_category", "")).capitalize(),
					"type": GameContentLocalizationService.localize_type(document.get("attack_type", ""))
				},
                "{source}\n{name}\nID: {id}\nOwner: {owner}\nCategory: {category}\nType: {type}"
			)

		MODE_KYOKORO:
			return LocalizationService.tr_format(
				"content_studio.tooltip_charakoro",
				{
					"id": content_id,
					"mode": String(document.get("roll_mode", ""))
				},
                "{id}\nRoll mode: {mode}"
			)

	return content_id



func _get_selected_library_id() -> String:
	var selected: PackedInt32Array = (
		saved_list.get_selected_items()
	)

	if selected.is_empty():
		return ""

	return String(
		saved_list.get_item_metadata(
			selected[0]
		)
	).strip_edges()


func _select_saved_id(
	content_id: String
) -> bool:
	for index: int in range(
		saved_list.item_count
	):
		if String(
			saved_list.get_item_metadata(
				index
			)
		) == content_id:
			saved_list.select(
				index
			)
			return true

	return false


func _select_option_metadata(
	option: OptionButton,
	value: String,
	add_if_missing: bool = false
) -> void:
	for index: int in range(
		option.item_count
	):
		if String(
			option.get_item_metadata(
				index
			)
		) == value:
			option.select(
				index
			)
			return

	if add_if_missing:
		option.add_item(
			value
		)
		option.set_item_metadata(
			option.item_count - 1,
			value
		)
		option.select(
			option.item_count - 1
		)


func _back_to_preparation() -> void:
	get_tree().change_scene_to_file(
		PREPARATION_SCENE
	)
