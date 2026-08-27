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


const SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const EDITOR_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupEditorService.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)
const VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)
const PROBABILITY: Script = preload(
    "res://scripts/dice/setup/EnergyDiceProbabilityCalculator.gd"
)
const NET_EDITOR: Script = preload(
    "res://scripts/ui/components/EnergyDieNetEditor.gd"
)
const MOVE_COVERAGE_ANALYZER: Script = preload(
    "res://scripts/analysis/MoveCoverageAnalyzer.gd"
)
const MOVE_COVERAGE_CARD: Script = preload(
    "res://scripts/ui/components/MoveCoverageCard.gd"
)
const PLAYER_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const PLAYER_LOADOUT_SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)
const AI_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutProvider.gd"
)
const AI_LOADOUT_SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutSaveService.gd"
)
const BUILDER_CONTEXT: Script = preload(
    "res://scripts/dice/setup/EnergyDiceBuilderContextService.gd"
)
const USER_DATABASE: Script = preload(
    "res://scripts/content/UserDatabasePathService.gd"
)
const ENERGY_CATALOG: Script = preload(
    "res://scripts/game/EnergyProgressionCatalog.gd"
)


const VALID_ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]

const FACE_ENERGY_FIELDS: Dictionary = {
    &"fixed_a": [&"fixed_a"],
    &"fixed_b": [&"fixed_b"],
    &"double_a": [&"double_a_first", &"double_a_second"],
    &"double_b": [&"double_b_first", &"double_b_second"],
    &"single_a": [&"single_a"],
    &"single_b": [&"single_b"]
}


const DEFAULT_SETUP_PATH: String = (
    "res://database/dice_setups/pikachu_default.json"
)

const DATABASE_SETUP_PATH: String = (
    "user://user_database/dice_setups/player_energy_dice_setup.json"
)

# Milestone 12.6a: exported builds cannot write into res:// (PCK).
# Keep the old database copy as a one-time migration source only.
const LEGACY_DATABASE_SETUP_PATH: String = (
    "res://database/dice_setups/player_energy_dice_setup.json"
)

const PREPARATION_SCENE_PATH: String = (
    "res://scenes/ui/BattlePreparationUI.tscn"
)


@onready var database: Node = $Database
@onready var page_title: Label = $Margin/Main/Header/Title
@onready var context_title: Label = $Margin/Main/ContentScroll/Content/ContextPanel/ContextRow/ContextBox/ContextTitle
@onready var builder_hint: Label = $Margin/Main/ContentScroll/Content/BuilderHint
@onready var repeat_fixed_energy_toggle: CheckButton = %RepeatFixedEnergyToggle
@onready var dice_section_title: Label = $Margin/Main/ContentScroll/Content/DiceSectionHeader/DiceSectionTitle
@onready var dice_section_hint: Label = $Margin/Main/ContentScroll/Content/DiceSectionHeader/DiceSectionHint
@onready var move_readiness_title: Label = $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel/CoverageBox/AnalysisTitle
@onready var move_readiness_hint: Label = $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel/CoverageBox/CoverageDescription
@onready var margin: MarginContainer = $Margin
@onready var main: VBoxContainer = $Margin/Main
@onready var content_scroll: ScrollContainer = $Margin/Main/ContentScroll
@onready var content: VBoxContainer = $Margin/Main/ContentScroll/Content
@onready var dice_scroll: ScrollContainer = (
    $Margin/Main/ContentScroll/Content/DiceScroll
)
@onready var actions: HBoxContainer = $Margin/Main/Actions
@onready var dice_container: HBoxContainer = %DiceContainer
@onready var preview_coverage_row: BoxContainer = %PreviewCoverageRow
@onready var coverage_panel: PanelContainer = (
    $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel
)
@onready var probability_panel: PanelContainer = (
    $Margin/Main/ContentScroll/Content/PreviewCoverageRow/ProbabilityPanel
)
@onready var validation_label: Label = %ValidationLabel
@onready var probability_label: Label = %ProbabilityLabel
@onready var top_validation_label: Label = %TopValidationLabel
@onready var advanced_toggle: Button = %AdvancedToggle
@onready var coverage_container: GridContainer = %CoverageContainer
@onready var save_path_edit: LineEdit = %SavePathEdit
@onready var editing_context_label: Label = %EditingContextLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton


var setup: Variant = null
var die_editors: Array = []
var enerkoro_color_options: Array[OptionButton] = []
var enerkoro_color_labels: Array[Label] = []
var move_cards: Array = []

var current_player_loadout: Variant = null
var builder_context: Dictionary = {}
var active_setup_path: String = DATABASE_SETUP_PATH
var return_scene_path: String = PREPARATION_SCENE_PATH
var sync_player_loadout: bool = true


func _ready() -> void:
    USER_DATABASE.migrate_legacy_user_files()
    PLAKORO_THEME.apply_to(self)

    LocalizationService.locale_changed.connect(
        _on_locale_changed
    )
    _apply_localized_text()
    get_viewport().size_changed.connect(
        _apply_responsive_layout
    )
    _apply_responsive_layout()
    content_scroll.scroll_vertical = 0

    confirm_button.pressed.connect(
        _confirm_setup
    )
    back_button.pressed.connect(
        _back_to_preparation
    )
    advanced_toggle.toggled.connect(
        _on_advanced_toggled
    )
    advanced_toggle.visible = not GameFlow.local_battle_mode
    repeat_fixed_energy_toggle.visible = (
        GameFlow.free_mode
        and not GameFlow.online_battle_mode
    )
    repeat_fixed_energy_toggle.button_pressed = (
        GameFlow.free_mode
        and GameFlow.free_mode_allow_repeated_fixed_energy
    )
    repeat_fixed_energy_toggle.toggled.connect(
        _on_repeat_fixed_energy_toggled
    )
    _on_advanced_toggled(
        false
    )

    _load_builder_context()
    save_path_edit.text = active_setup_path
    _refresh_editing_context_label()

    if not database.load_all():
        validation_label.text = (
            LocalizationService.tr_key(
                "enerkoro_builder.database_load_failed",
                "Database load failed."
            )
        )
        confirm_button.disabled = true
        back_button.disabled = true
        return

    _load_current_player_context()
    _load_startup_setup()



func _on_locale_changed(
    _locale: String
) -> void:
    _apply_localized_text()
    for editor: Variant in die_editors:
        if editor != null and editor.has_method("relocalize"):
            editor.relocalize()
    _refresh_enerkoro_color_option_texts()
    _refresh_all_analysis()


func _apply_localized_text() -> void:
    page_title.text = LocalizationService.tr_key(
        "enerkoro_builder.title",
        "Enerkoro Builder"
    )
    back_button.text = "<- " + LocalizationService.tr_key(
        "enerkoro_builder.back_preparation",
        "Back to Preparation"
    )
    context_title.text = LocalizationService.tr_key(
        "enerkoro_builder.current_setup",
        "CURRENT SETUP"
    )
    builder_hint.text = LocalizationService.tr_key(
        "enerkoro_builder.hint_repeat"
        if GameFlow.free_mode_allow_repeated_fixed_energy
        else "enerkoro_builder.hint",
        "Select a face to change its Energy. Fixed Energy may repeat across Enerkoro in Free Mode."
        if GameFlow.free_mode_allow_repeated_fixed_energy
        else "Select a face to change its Energy. Fixed faces must use unique Energy types across all three Enerkoro."
    )
    repeat_fixed_energy_toggle.text = LocalizationService.tr_key(
        "enerkoro_builder.allow_repeated_fixed_energy",
        "Allow repeated Fixed Energy (Free Mode only)"
    )
    dice_section_title.text = LocalizationService.tr_key(
        "enerkoro_builder.faces",
        "Enerkoro Faces"
    )
    dice_section_hint.text = LocalizationService.tr_key(
        "enerkoro_builder.faces_hint",
        "3 Enerkoro  |  6 faces each"
    )
    move_readiness_title.text = LocalizationService.tr_key(
        "enerkoro_builder.move_readiness",
        "Move Readiness"
    )
    move_readiness_hint.text = LocalizationService.tr_key(
        "enerkoro_builder.move_readiness_hint",
        "Availability based on the four Moves in the current Player Loadout."
    )
    confirm_button.text = LocalizationService.tr_key(
        "enerkoro_builder.save_use",
        "Save & Use"
    )
    _on_advanced_toggled(
        advanced_toggle.button_pressed
    )


func _load_builder_context() -> void:
    builder_context = BUILDER_CONTEXT.load_context()
    if builder_context.is_empty():
        return

    var target_path: String = String(
        builder_context.get("target_path", "")
    )
    var requested_return_scene: String = String(
        builder_context.get("return_scene", PREPARATION_SCENE_PATH)
    )
    var mode: String = String(
        builder_context.get("mode", "")
    )

    if not target_path.is_empty():
        # 12.6b Fix 4: old contexts may still point to res://database.
        # Always redirect editable database content to the matching user copy.
        var writable_target: String = USER_DATABASE.ensure_user_editable_copy(target_path)
        if writable_target.is_empty():
            validation_label.text = LocalizationService.tr_key("enerkoro_builder.writable_path_failed", "Could not prepare writable Enerkoro path.")
        else:
            active_setup_path = writable_target
            builder_context["target_path"] = writable_target
    if not requested_return_scene.is_empty():
        return_scene_path = requested_return_scene

    sync_player_loadout = mode != "pokemon_default"


func _refresh_editing_context_label() -> void:
    var mode: String = String(
        builder_context.get(
            "mode",
            "player_custom"
        )
    )
    var pokemon_id: String = String(
        builder_context.get(
            "pokemon_id",
            ""
        )
    )

    var source_name: String = (
        LocalizationService.tr_key("enerkoro_builder.editing_default", "Pokémon Default")
        if mode == "pokemon_default"
        else LocalizationService.tr_key("enerkoro_builder.editing_custom", "Player Custom")
    )

    editing_context_label.text = (
        (
            GameContentLocalizationService.text("pokemon", pokemon_id, "name", pokemon_id.capitalize()) + "   |   "
            if not pokemon_id.is_empty()
            else ""
        )
        + source_name
         + "\n" + LocalizationService.tr_format(
            "enerkoro_builder.save_target",
            {"path": active_setup_path},
            "Save target   |   {path}"
        )
        + _format_inventory_summary()
    )


func _format_inventory_summary() -> String:
    var inventory: Dictionary = _get_player_energy_inventory()
    if inventory.is_empty():
        return ""
    var parts: Array[String] = []
    for energy_type: StringName in VALID_ENERGY_TYPES:
        parts.append(
            "%s x%d" % [
                GameContentLocalizationService.localize_type(energy_type),
                int(inventory.get(String(energy_type), 0))
            ]
        )
    return "\n" + LocalizationService.tr_format(
        "enerkoro_builder.inventory_summary",
        {"inventory": "   |   ".join(parts)},
        "Energy Pool   |   {inventory}"
    )


func _on_advanced_toggled(
    enabled: bool
) -> void:
    if GameFlow.phone_mode or GameFlow.local_battle_mode:
        enabled = false
    preview_coverage_row.visible = enabled
    advanced_toggle.text = (
        LocalizationService.tr_key("enerkoro_builder.advanced_open", "Advanced -")
        if enabled
        else LocalizationService.tr_key("enerkoro_builder.advanced_closed", "Advanced +")
    )

    # Normal Builder mode is intentionally a single-screen workspace.
    # Page scrolling is only needed after the optional Advanced section
    # is expanded.
    content_scroll.vertical_scroll_mode = (
        ScrollContainer.SCROLL_MODE_AUTO
        if enabled or GameFlow.phone_mode
        else ScrollContainer.SCROLL_MODE_DISABLED
    )
    content_scroll.scroll_vertical = 0

    _apply_dice_builder_work_area(
        RESPONSIVE_UI.get_profile(
            self
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
        confirm_button,
        profile,
        150
    )
    RESPONSIVE_UI.apply_button(
        back_button,
        profile,
        180
    )

    RESPONSIVE_UI.apply_grid_columns(
        coverage_container,
        profile,
        2,
        1
    )

    _apply_dice_builder_work_area(
        profile
    )
    _apply_preview_coverage_layout(
        profile
    )




func _apply_preview_coverage_layout(
    profile: StringName
) -> void:
    preview_coverage_row.vertical = (
        profile == RESPONSIVE_PROFILE.PROFILE_HANDHELD
    )
    coverage_panel.custom_minimum_size.x = 0.0
    probability_panel.custom_minimum_size.x = 0.0
    match profile:
        RESPONSIVE_PROFILE.PROFILE_FULL:
            preview_coverage_row.add_theme_constant_override(
                "separation",
                14
            )

        RESPONSIVE_PROFILE.PROFILE_COMPACT:
            preview_coverage_row.add_theme_constant_override(
                "separation",
                12
            )

        _:
            preview_coverage_row.add_theme_constant_override(
                "separation",
                10
            )


func _apply_dice_builder_work_area(
    profile: StringName
) -> void:
    if GameFlow.phone_mode:
        dice_scroll.custom_minimum_size.y = 0.0
        dice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        content.size_flags_vertical = Control.SIZE_EXPAND_FILL
        for editor: Variant in die_editors:
            if editor is Control:
                (editor as Control).custom_minimum_size.x = 0.0
                (editor as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
        return

    var viewport_height: float = (
        get_viewport_rect().size.y
    )

    # Collapsed/default mode must fit on one 16:9 or 16:10 desktop
    # screen without page scrolling. Advanced mode may use the page
    # ScrollContainer because it intentionally adds analysis panels.
    var editor_height: float = 560.0

    if advanced_toggle.button_pressed:
        match profile:
            RESPONSIVE_PROFILE.PROFILE_FULL:
                editor_height = clamp(
                    viewport_height * 0.60,
                    620.0,
                    720.0
                )
            RESPONSIVE_PROFILE.PROFILE_COMPACT:
                editor_height = clamp(
                    viewport_height * 0.62,
                    570.0,
                    650.0
                )
            _:
                editor_height = clamp(
                    viewport_height * 0.66,
                    530.0,
                    610.0
                )
    else:
        match profile:
            RESPONSIVE_PROFILE.PROFILE_FULL:
                editor_height = clamp(
                    viewport_height * 0.52,
                    540.0,
                    580.0
                )
            RESPONSIVE_PROFILE.PROFILE_COMPACT:
                editor_height = clamp(
                    viewport_height * 0.54,
                    520.0,
                    560.0
                )
            _:
                editor_height = clamp(
                    viewport_height * 0.56,
                    500.0,
                    540.0
                )

    dice_scroll.custom_minimum_size.y = (
        editor_height
    )

    # DiceScroll owns horizontal overflow for the three left-to-right desktop
    # Enerkoro work areas. Phone Mode moves them into a vertical stack.
    dice_scroll.vertical_scroll_mode = (
        ScrollContainer.SCROLL_MODE_DISABLED
    )

    content.size_flags_vertical = (
        Control.SIZE_EXPAND_FILL
    )

    var editor_width: float = (
        _get_die_editor_width()
    )

    for editor: Variant in die_editors:
        if editor is Control:
            (editor as Control).custom_minimum_size.x = (
                editor_width
            )

func _load_current_player_context() -> void:
    current_player_loadout = (
        PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    )

    move_cards.clear()

    if current_player_loadout == null:
        return

    for move_card_id: StringName in (
        current_player_loadout.move_card_ids
    ):
        var move_card: Variant = database.get_move_card(
            move_card_id
        )

        if move_card != null:
            move_cards.append(move_card)


func _load_startup_setup() -> void:
    # Milestone 10.0b1 makes the project database the canonical authoring
    # source for player Enerkoro. The embedded loadout copy remains a
    # compatibility/runtime snapshot and is synchronized on Save/Confirm.
    if FileAccess.file_exists(
        active_setup_path
    ):
        setup = SAVE_SERVICE.load_setup(
            active_setup_path
        )

        if setup != null:
            validation_label.text = (
                LocalizationService.tr_format("enerkoro_builder.loaded_path", {"path": active_setup_path}, "Loaded Enerkoro from {path}")
            )
            _build_die_editors()
            _refresh_all_analysis()
            return

    # Compatibility fallback for projects that already have the setup
    # embedded in PlayerBattleLoadoutData.
    if (
        current_player_loadout != null
        and current_player_loadout.energy_dice_setup != null
    ):
        setup = EDITOR_SERVICE.clone_setup(
            current_player_loadout.energy_dice_setup
        )

        validation_label.text = (
            LocalizationService.tr_key("enerkoro_builder.loaded_loadout", "Loaded Enerkoro from current player loadout. Save once to create the database copy.")
        )
        _build_die_editors()
        _refresh_all_analysis()
        return

    # Pre-12.6 project data may contain a player custom setup under res://.
    # Read it as a migration source, then persist the editable copy under
    # user:// so the same flow works in Windows/Linux exported builds.
    if FileAccess.file_exists(
        LEGACY_DATABASE_SETUP_PATH
    ):
        setup = SAVE_SERVICE.load_setup(
            LEGACY_DATABASE_SETUP_PATH
        )

        if setup != null:
            SAVE_SERVICE.save_setup(
                setup,
                DATABASE_SETUP_PATH
            )
            validation_label.text = (
                LocalizationService.tr_format("enerkoro_builder.migrated", {"path": DATABASE_SETUP_PATH}, "Migrated legacy Enerkoro setup to {path}")
            )
            _build_die_editors()
            _refresh_all_analysis()
            return

    _load_factory_default()


func _load_factory_default() -> void:
    var inventory_mode: bool = not _get_player_energy_inventory().is_empty()
    setup = (
        ENERGY_CATALOG.create_balanced_setup(_get_player_energy_inventory())
        if inventory_mode
        else SETUP_LOADER.load_setup(DEFAULT_SETUP_PATH)
    )

    if setup == null:
        setup = (
            EDITOR_SERVICE.create_empty_setup()
        )

    _build_die_editors()
    _refresh_all_analysis()

    validation_label.text = (
        LocalizationService.tr_key(
            "enerkoro_builder.loaded_balanced_default"
            if inventory_mode
            else "enerkoro_builder.loaded_default",
            "Loaded balanced starting setup."
            if inventory_mode
            else "Loaded Pikachu default setup."
        )
    )


func _build_die_editors() -> void:
    die_editors.clear()
    enerkoro_color_options.clear()
    enerkoro_color_labels.clear()

    for child: Node in (
        dice_container.get_children()
    ):
        child.queue_free()

    for index: int in range(3):
        var slot: CenterContainer = CenterContainer.new()
        slot.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )
        slot.size_flags_vertical = (
            Control.SIZE_EXPAND_FILL
        )
        dice_container.add_child(slot)

        var column: VBoxContainer = VBoxContainer.new()
        column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        column.add_theme_constant_override("separation", 8)
        slot.add_child(column)

        var color_row: HBoxContainer = HBoxContainer.new()
        color_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        color_row.alignment = BoxContainer.ALIGNMENT_CENTER
        color_row.add_theme_constant_override("separation", 8)
        column.add_child(color_row)

        var color_label: Label = Label.new()
        color_label.text = LocalizationService.tr_key(
            "enerkoro_builder.dice_color",
            "Color"
        )
        color_row.add_child(color_label)
        enerkoro_color_labels.append(color_label)

        var color_option: OptionButton = OptionButton.new()
        color_option.custom_minimum_size = Vector2(150.0, 42.0)
        color_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        color_row.add_child(color_option)
        enerkoro_color_options.append(color_option)
        _populate_enerkoro_color_option(color_option, index)
        color_option.item_selected.connect(
            _on_enerkoro_color_selected.bind(index)
        )

        var editor: PanelContainer = (
            NET_EDITOR.new()
        )
        editor.size_flags_horizontal = (
            Control.SIZE_SHRINK_CENTER
        )
        editor.size_flags_vertical = (
            Control.SIZE_SHRINK_CENTER
        )
        editor.custom_minimum_size.x = (
            _get_die_editor_width()
        )
        editor.setup_changed.connect(
            _on_setup_changed.bind(editor)
        )

        column.add_child(editor)
        editor.initialize(
            setup,
            index,
            EDITOR_SERVICE,
            _get_player_energy_inventory(),
            GameFlow.free_mode
            and GameFlow.free_mode_allow_repeated_fixed_energy
        )

        _polish_die_editor_layout(
            editor
        )

        die_editors.append(editor)
        _apply_enerkoro_editor_color(index)



func _populate_enerkoro_color_option(
    option: OptionButton,
    slot_index: int
) -> void:
    var saved_type: String = PLAKORO_THEME.get_enerkoro_color_type(slot_index)
    option.clear()
    for color_type: String in PLAKORO_THEME.ENERKORO_COLOR_TYPES:
        option.add_item(
            LocalizationService.tr_key(
                "energy.%s" % color_type,
                color_type.capitalize()
            )
        )
        option.set_item_metadata(option.item_count - 1, color_type)
        if color_type == saved_type:
            option.select(option.item_count - 1)
    option.tooltip_text = LocalizationService.tr_format(
        "enerkoro_builder.dice_color_hint",
        {"index": slot_index + 1},
        "Choose the Battle GUI color for Enerkoro {index}."
    )


func _refresh_enerkoro_color_option_texts() -> void:
    for color_label: Label in enerkoro_color_labels:
        color_label.text = LocalizationService.tr_key(
            "enerkoro_builder.dice_color",
            "Color"
        )
    for slot_index: int in range(enerkoro_color_options.size()):
        _populate_enerkoro_color_option(
            enerkoro_color_options[slot_index],
            slot_index
        )


func _on_enerkoro_color_selected(
    item_index: int,
    slot_index: int
) -> void:
    if slot_index < 0 or slot_index >= enerkoro_color_options.size():
        return
    var option: OptionButton = enerkoro_color_options[slot_index]
    if item_index < 0 or item_index >= option.item_count:
        return
    var color_type: String = str(option.get_item_metadata(item_index))
    PLAKORO_THEME.set_enerkoro_color_type(slot_index, color_type)
    _apply_enerkoro_editor_color(slot_index)


func _apply_enerkoro_editor_color(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= die_editors.size():
        return
    var editor: PanelContainer = die_editors[slot_index] as PanelContainer
    if editor == null:
        return
    var color_type: StringName = StringName(
        PLAKORO_THEME.get_enerkoro_color_type(slot_index)
    )
    var base_color: Color = (
        PLAKORO_THEME.get_enerkoro_background_color(color_type)
    )
    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color(base_color, 0.92)
    panel_style.border_color = base_color.lightened(0.38)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(12)
    panel_style.content_margin_left = 12.0
    panel_style.content_margin_top = 12.0
    panel_style.content_margin_right = 12.0
    panel_style.content_margin_bottom = 12.0
    editor.add_theme_stylebox_override("panel", panel_style)



func _get_die_editor_width() -> float:
    var profile: StringName = (
        RESPONSIVE_UI.get_profile(
            self
        )
    )

    match profile:
        RESPONSIVE_PROFILE.PROFILE_FULL:
            return 520.0
        RESPONSIVE_PROFILE.PROFILE_COMPACT:
            return 455.0
        _:
            return 390.0


func _polish_die_editor_layout(
    editor: Control
) -> void:
    # The Enerkoro editor is generated by the existing NET_EDITOR script.
    # Keep all energy/face logic untouched and only normalize presentation.
    #
    # Hide the repeated helper line inside each die panel because the page
    # already explains the interaction once above all three dice.
    _hide_repeated_die_help(
        editor
    )

    # Center container-based children where possible. This does not change
    # the six-face energy mapping or button callbacks.
    _center_editor_containers(
        editor
    )


func _hide_repeated_die_help(
    node: Node
) -> void:
    if node is Label:
        var label: Label = node as Label

        if label.text.strip_edges() == (
            "Click a dice face to edit its energy."
        ):
            label.visible = false
            label.custom_minimum_size.y = 0.0

    for child: Node in node.get_children():
        _hide_repeated_die_help(
            child
        )


func _center_editor_containers(
    node: Node
) -> void:
    if node is BoxContainer:
        var box: BoxContainer = (
            node as BoxContainer
        )

        # Only alter alignment. Existing separation, face buttons and
        # orientation-to-energy logic remain owned by EnergyDieNetEditor.
        box.alignment = (
            BoxContainer.ALIGNMENT_CENTER
        )

    if node is Control:
        var control: Control = node as Control

        # Face rows and generated containers should use their available width
        # rather than remaining pinned to the left edge.
        if (
            control is HBoxContainer
            or control is VBoxContainer
            or control is GridContainer
        ):
            control.size_flags_horizontal = (
                Control.SIZE_EXPAND_FILL
            )

    for child: Node in node.get_children():
        _center_editor_containers(
            child
        )


func _on_setup_changed(
    source_editor: Variant
) -> void:
    for editor: Variant in die_editors:
        if (
            editor != source_editor
            and editor.has_method(
                "close_palette"
            )
        ):
            editor.close_palette()

    _refresh_all_analysis()


func _refresh_all_analysis() -> void:
    _refresh_validation()
    _refresh_energy_probability()
    _refresh_move_coverage()


func _on_repeat_fixed_energy_toggled(enabled: bool) -> void:
    if not GameFlow.free_mode:
        repeat_fixed_energy_toggle.set_pressed_no_signal(false)
        return
    GameFlow.free_mode_allow_repeated_fixed_energy = enabled
    PLAKORO_THEME.set_free_mode_allow_repeated_fixed_energy(enabled)
    for editor: Variant in die_editors:
        if editor != null and editor.has_method("set_allow_repeated_fixed_energy"):
            editor.set_allow_repeated_fixed_energy(enabled)
    _apply_localized_text()
    _refresh_all_analysis()


func _refresh_validation() -> void:
    var valid_energy_types: Array = []

    for energy_type: StringName in (
        VALID_ENERGY_TYPES
    ):
        valid_energy_types.append(
            energy_type
        )

    var validation: Dictionary = (
        VALIDATOR.validate(
            setup,
            valid_energy_types,
            GameFlow.free_mode
            and GameFlow.free_mode_allow_repeated_fixed_energy
        )
    )
    _merge_inventory_validation(validation)
    _refresh_invalid_face_highlights()

    if bool(validation["success"]):
        top_validation_label.text = LocalizationService.tr_key("enerkoro_builder.valid", "[OK] Valid")
        top_validation_label.modulate = Color(
            0.45,
            0.9,
            0.62,
            1.0
        )
        validation_label.text = (
            LocalizationService.tr_key("enerkoro_builder.valid_ready", "[OK] VALID   |   Ready for battle.")
        )
        confirm_button.disabled = false
        back_button.disabled = false
    else:
        top_validation_label.text = LocalizationService.tr_key("enerkoro_builder.invalid", "X Invalid")
        top_validation_label.modulate = Color(
            0.95,
            0.5,
            0.5,
            1.0
        )
        validation_label.text = (
            LocalizationService.tr_format(
                "enerkoro_builder.invalid_details",
                {"errors": "\n".join(validation["errors"])},
                "X INVALID\n{errors}"
            )
        )
        confirm_button.disabled = true
        back_button.disabled = false


func _refresh_invalid_face_highlights() -> void:
    var invalid_faces: Dictionary = _collect_invalid_faces()
    for die_index: int in range(die_editors.size()):
        var editor: Variant = die_editors[die_index]
        if editor == null or not editor.has_method("set_invalid_fields"):
            continue
        var fields: Array[StringName] = []
        for raw_field: Variant in invalid_faces.get(die_index, []):
            fields.append(StringName(raw_field))
        editor.set_invalid_fields(fields)


func _collect_invalid_faces() -> Dictionary:
    var result: Dictionary = {}
    var fixed_occurrences: Dictionary = {}
    var energy_occurrences: Dictionary = {}
    if setup == null:
        return result

    for die_index: int in range(setup.dice.size()):
        for raw_face_id: Variant in FACE_ENERGY_FIELDS.keys():
            var face_id: StringName = StringName(raw_face_id)
            var component_fields: Array = FACE_ENERGY_FIELDS[raw_face_id]
            for raw_component: Variant in component_fields:
                var component: StringName = StringName(raw_component)
                var energy: StringName = EDITOR_SERVICE.get_energy(
                    setup,
                    die_index,
                    component
                )
                if energy == &"" or not VALID_ENERGY_TYPES.has(energy):
                    _mark_invalid_face(result, die_index, face_id)
                if energy != &"":
                    var occurrences: Array = energy_occurrences.get(energy, [])
                    occurrences.append({
                        "die_index": die_index,
                        "face_id": face_id
                    })
                    energy_occurrences[energy] = occurrences

                if component in [&"fixed_a", &"fixed_b"] and energy != &"":
                    var fixed_entries: Array = fixed_occurrences.get(energy, [])
                    fixed_entries.append({
                        "die_index": die_index,
                        "face_id": face_id
                    })
                    fixed_occurrences[energy] = fixed_entries

        var die_data: Variant = setup.dice[die_index]
        if StringName(die_data.fixed_a) == StringName(die_data.fixed_b):
            _mark_invalid_face(result, die_index, &"fixed_a")
            _mark_invalid_face(result, die_index, &"fixed_b")

    var allow_repeated_fixed: bool = (
        GameFlow.free_mode
        and GameFlow.free_mode_allow_repeated_fixed_energy
    )
    if not allow_repeated_fixed:
        for raw_energy: Variant in fixed_occurrences.keys():
            var fixed_entries: Array = fixed_occurrences[raw_energy]
            if fixed_entries.size() <= 1:
                continue
            for entry: Dictionary in fixed_entries:
                _mark_invalid_face(
                    result,
                    int(entry.get("die_index", -1)),
                    StringName(entry.get("face_id", &""))
                )

    var inventory: Dictionary = _get_player_energy_inventory()
    if not inventory.is_empty():
        for raw_energy: Variant in energy_occurrences.keys():
            var entries: Array = energy_occurrences[raw_energy]
            var owned: int = max(0, int(inventory.get(String(raw_energy), 0)))
            if entries.size() <= owned:
                continue
            for entry: Dictionary in entries:
                _mark_invalid_face(
                    result,
                    int(entry.get("die_index", -1)),
                    StringName(entry.get("face_id", &""))
                )

    return result


func _mark_invalid_face(
    result: Dictionary,
    die_index: int,
    face_id: StringName
) -> void:
    if die_index < 0 or face_id == &"":
        return
    var fields: Array = result.get(die_index, [])
    if not fields.has(face_id):
        fields.append(face_id)
    result[die_index] = fields


func _refresh_energy_probability() -> void:
    var expected: Dictionary = (
        PROBABILITY
        .get_expected_energy_per_roll(
            setup
        )
    )

    var lines: Array[String] = [
        LocalizationService.tr_key("enerkoro_builder.energy_output_title", "ENERGY OUTPUT - expected per three-dice roll")
    ]

    var keys: Array = expected.keys()
    keys.sort()

    for raw_energy: Variant in keys:
        var energy_type: StringName = (
            StringName(raw_energy)
        )
        var expected_value: float = float(
            expected[raw_energy]
        )
        var probability: float = (
            PROBABILITY
            .get_at_least_one_probability(
                setup,
                energy_type
            )
        )

        lines.append(
            LocalizationService.tr_format(
                "enerkoro_builder.energy_output_line",
                {
                    "energy": GameContentLocalizationService.localize_type(energy_type),
                    "expected": LocalizationService.format_decimal(expected_value, 3),
                    "probability": LocalizationService.format_decimal(probability * 100.0, 1)
                },
                "{energy}   |   expected {expected}   |   at least one {probability}%"
            )
        )

    probability_label.text = "\n".join(
        lines
    )


func _refresh_move_coverage() -> void:
    for child: Node in (
        coverage_container.get_children()
    ):
        child.queue_free()

    if move_cards.is_empty():
        var label: Label = Label.new()
        label.text = (
            LocalizationService.tr_key("enerkoro_builder.no_moves", "No move cards are available from the current loadout.")
        )
        coverage_container.add_child(label)
        return

    var results: Array = (
        MOVE_COVERAGE_ANALYZER.analyze_moves(
            setup,
            move_cards
        )
    )

    for result: Variant in results:
        var card: PanelContainer = (
            MOVE_COVERAGE_CARD.new()
        )
        coverage_container.add_child(card)
        card.display_result(result)


func _confirm_setup() -> void:
    if confirm_button.disabled:
        return

    if _save_setup_and_sync_loadout():
        save_path_edit.text = active_setup_path
        var error: Error = get_tree().change_scene_to_file(
            return_scene_path
        )
        if error != OK:
            validation_label.text = LocalizationService.tr_key(
                "enerkoro_builder.return_failed",
                "Enerkoro was saved, but Battle Preparation could not be opened."
            )
            return
        BUILDER_CONTEXT.clear_context()
    else:
        validation_label.text = (
            LocalizationService.tr_key("enerkoro_builder.confirm_save_failed", "Valid setup, but save failed.")
        )


func _back_to_preparation() -> void:
    if setup == null:
        BUILDER_CONTEXT.clear_context()
        get_tree().change_scene_to_file(
            return_scene_path
        )
        return

    var validation: Dictionary = _validate_current_setup()

    if not bool(validation["success"]):
        validation_label.text = (
            LocalizationService.tr_format("enerkoro_builder.return_invalid", {"errors": "\n".join(validation["errors"])}, "Cannot return with an invalid Dice setup.\n{errors}")
        )
        return

    if not _save_setup_and_sync_loadout():
        validation_label.text = (
            LocalizationService.tr_key("enerkoro_builder.return_save_failed", "Could not save Dice changes before returning.")
        )
        return

    BUILDER_CONTEXT.clear_context()
    get_tree().change_scene_to_file(
        return_scene_path
    )


func _save_setup_and_sync_loadout() -> bool:
    if setup == null:
        return false

    var validation: Dictionary = _validate_current_setup()

    if not bool(validation["success"]):
        return false

    if not SAVE_SERVICE.save_setup(
        setup,
        active_setup_path
    ):
        return false

    if not sync_player_loadout:
        return _sync_active_pokemon_default_loadouts()

    var loadout: Variant = PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    if loadout == null:
        return true

    loadout.energy_dice_setup = EDITOR_SERVICE.clone_setup(setup)

    if not PLAYER_LOADOUT_SAVE_SERVICE.save_loadout(
        loadout,
        PLAYER_LOADOUT_PROVIDER.get_user_loadout_path()
    ):
        return false

    current_player_loadout = loadout
    return true


func _sync_active_pokemon_default_loadouts() -> bool:
    var mode: String = String(
        builder_context.get(
            "mode",
            ""
        )
    )

    if mode != "pokemon_default":
        return true

    var edited_species_id: String = String(
        builder_context.get(
            "species_id",
            ""
        )
    ).strip_edges().to_lower()

    if edited_species_id.is_empty():
        return true

    var player_sync_ok: bool = (
        _sync_player_default_if_matching(
            edited_species_id
        )
    )
    var ai_sync_ok: bool = (
        _sync_ai_default_if_matching(
            edited_species_id
        )
    )

    return player_sync_ok and ai_sync_ok


func _sync_player_default_if_matching(
    edited_species_id: String
) -> bool:
    var loadout: Variant = (
        PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    )

    if loadout == null:
        return true

    if String(
        loadout.energy_dice_source
    ) != "pokemon_default":
        return true

    var pokemon: Variant = database.get_pokemon(
        loadout.pokemon_id
    )

    if pokemon == null:
        return true

    if String(
        pokemon.species_id
    ).strip_edges().to_lower() != edited_species_id:
        return true

    loadout.energy_dice_setup = (
        EDITOR_SERVICE.clone_setup(
            setup
        )
    )

    if not PLAYER_LOADOUT_SAVE_SERVICE.save_loadout(
        loadout,
        PLAYER_LOADOUT_PROVIDER.get_user_loadout_path()
    ):
        return false

    current_player_loadout = loadout
    return true


func _sync_ai_default_if_matching(
    edited_species_id: String
) -> bool:
    var loadout: Variant = (
        AI_LOADOUT_PROVIDER.load_ai_loadout()
    )

    if loadout == null:
        return true

    var pokemon: Variant = database.get_pokemon(
        loadout.pokemon_id
    )

    if pokemon == null:
        return true

    if String(
        pokemon.species_id
    ).strip_edges().to_lower() != edited_species_id:
        return true

    loadout.energy_dice_setup = (
        EDITOR_SERVICE.clone_setup(
            setup
        )
    )

    return AI_LOADOUT_SAVE_SERVICE.save_loadout(
        loadout,
        AI_LOADOUT_PROVIDER.get_user_loadout_path()
    )


func _validate_current_setup() -> Dictionary:
    var valid_energy_types: Array = []

    for energy_type: StringName in (
        VALID_ENERGY_TYPES
    ):
        valid_energy_types.append(energy_type)

    var result: Dictionary = VALIDATOR.validate(
        setup,
        valid_energy_types,
        GameFlow.free_mode
        and GameFlow.free_mode_allow_repeated_fixed_energy
    )
    _merge_inventory_validation(result)
    return result


func _get_player_energy_inventory() -> Dictionary:
    if (
        not sync_player_loadout
        or not PlayerProgress.has_profile()
        or GameFlow.free_mode
    ):
        return {}
    return PlayerProgress.get_progress().energy_inventory.duplicate(true)


func _merge_inventory_validation(validation: Dictionary) -> void:
    var inventory: Dictionary = _get_player_energy_inventory()
    if inventory.is_empty():
        return
    var inventory_result: Dictionary = ENERGY_CATALOG.validate_inventory(
        setup,
        inventory
    )
    if not bool(inventory_result.get("success", false)):
        validation["success"] = false
        var errors: Array = validation.get("errors", [])
        errors.append_array(inventory_result.get("errors", []))
        validation["errors"] = errors
