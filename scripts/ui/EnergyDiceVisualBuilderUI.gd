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
const DICE_ICON_SUMMARY: Script = preload(
    "res://scripts/ui/components/EnergyDiceIconSummary.gd"
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
@onready var dice_section_title: Label = $Margin/Main/ContentScroll/Content/DiceSectionHeader/DiceSectionTitle
@onready var dice_section_hint: Label = $Margin/Main/ContentScroll/Content/DiceSectionHeader/DiceSectionHint
@onready var energy_preview_title: Label = $Margin/Main/ContentScroll/Content/PreviewCoverageRow/PreviewPanel/PreviewBox/DiceIconPreviewTitle
@onready var move_readiness_title: Label = $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel/CoverageBox/AnalysisTitle
@onready var move_readiness_hint: Label = $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel/CoverageBox/CoverageDescription
@onready var margin: MarginContainer = $Margin
@onready var main: VBoxContainer = $Margin/Main
@onready var content_scroll: ScrollContainer = $Margin/Main/ContentScroll
@onready var content: VBoxContainer = $Margin/Main/ContentScroll/Content
@onready var dice_scroll: ScrollContainer = (
    $Margin/Main/ContentScroll/Content/DiceScroll
)
@onready var summary_split: HSplitContainer = (
    $Margin/Main/ContentScroll/Content/SummarySplit
)
@onready var actions: HBoxContainer = $Margin/Main/Actions
@onready var dice_container: HBoxContainer = %DiceContainer
@onready var preview_coverage_row: HBoxContainer = %PreviewCoverageRow
@onready var preview_panel: PanelContainer = (
    $Margin/Main/ContentScroll/Content/PreviewCoverageRow/PreviewPanel
)
@onready var coverage_panel: PanelContainer = (
    $Margin/Main/ContentScroll/Content/PreviewCoverageRow/CoveragePanel
)
@onready var dice_icon_preview_container: HBoxContainer = %DiceIconPreviewContainer
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
    _refresh_all_analysis()


func _apply_localized_text() -> void:
    page_title.text = LocalizationService.tr_key(
        "enerkoro_builder.title",
        "Enerkoro Builder"
    )
    back_button.text = "← " + LocalizationService.tr_key(
        "enerkoro_builder.back_preparation",
        "Back to Preparation"
    )
    context_title.text = LocalizationService.tr_key(
        "enerkoro_builder.current_setup",
        "CURRENT SETUP"
    )
    builder_hint.text = LocalizationService.tr_key(
        "enerkoro_builder.hint",
        "Select a face to change its Energy. Fixed faces must use unique Energy types across all three Enerkoro."
    )
    dice_section_title.text = LocalizationService.tr_key(
        "enerkoro_builder.faces",
        "Enerkoro Faces"
    )
    dice_section_hint.text = LocalizationService.tr_key(
        "enerkoro_builder.faces_hint",
        "3 Enerkoro • 6 faces each"
    )
    energy_preview_title.text = LocalizationService.tr_key(
        "enerkoro_builder.energy_preview",
        "Energy Preview"
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
            GameContentLocalizationService.text("pokemon", pokemon_id, "name", pokemon_id.capitalize()) + "  •  "
            if not pokemon_id.is_empty()
            else ""
        )
        + source_name
         + "\n" + LocalizationService.tr_format(
            "enerkoro_builder.save_target",
            {"path": active_setup_path},
            "Save target  •  {path}"
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
            "%s ×%d" % [
                GameContentLocalizationService.localize_type(energy_type),
                int(inventory.get(String(energy_type), 0))
            ]
        )
    return "\n" + LocalizationService.tr_format(
        "enerkoro_builder.inventory_summary",
        {"inventory": "  •  ".join(parts)},
        "Energy Pool  •  {inventory}"
    )


func _on_advanced_toggled(
    enabled: bool
) -> void:
    preview_coverage_row.visible = enabled
    summary_split.visible = enabled
    advanced_toggle.text = (
        LocalizationService.tr_key("enerkoro_builder.advanced_open", "Advanced ▾")
        if enabled
        else LocalizationService.tr_key("enerkoro_builder.advanced_closed", "Advanced ▸")
    )

    # Normal Builder mode is intentionally a single-screen workspace.
    # Page scrolling is only needed after the optional Advanced section
    # is expanded.
    content_scroll.vertical_scroll_mode = (
        ScrollContainer.SCROLL_MODE_AUTO
        if enabled
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

    RESPONSIVE_UI.apply_split(
        summary_split,
        profile,
        get_viewport_rect().size.x,
        0.50
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
    # On desktop, Preview and Coverage share one horizontal band to make use
    # of the large empty space visible to the right of the preview.
    match profile:
        RESPONSIVE_PROFILE.PROFILE_FULL:
            preview_panel.custom_minimum_size.x = 620.0
            coverage_panel.custom_minimum_size.x = 560.0
            preview_coverage_row.add_theme_constant_override(
                "separation",
                14
            )

        RESPONSIVE_PROFILE.PROFILE_COMPACT:
            preview_panel.custom_minimum_size.x = 520.0
            coverage_panel.custom_minimum_size.x = 470.0
            preview_coverage_row.add_theme_constant_override(
                "separation",
                12
            )

        _:
            preview_panel.custom_minimum_size.x = 430.0
            coverage_panel.custom_minimum_size.x = 410.0
            preview_coverage_row.add_theme_constant_override(
                "separation",
                10
            )


func _apply_dice_builder_work_area(
    profile: StringName
) -> void:
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

    # DiceScroll only owns horizontal overflow. Never create a nested
    # vertical scrollbar inside the three Enerkoro work areas.
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

        slot.add_child(editor)
        editor.initialize(
            setup,
            index,
            EDITOR_SERVICE,
            _get_player_energy_inventory()
        )

        _polish_die_editor_layout(
            editor
        )

        die_editors.append(editor)



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
    _refresh_dice_icon_preview()



func _refresh_dice_icon_preview() -> void:
    for child: Node in (
        dice_icon_preview_container.get_children()
    ):
        dice_icon_preview_container.remove_child(
            child
        )
        child.queue_free()

    if setup == null:
        return

    var summary: HBoxContainer = HBoxContainer.new()
    summary.set_script(
        DICE_ICON_SUMMARY
    )
    summary.setup(
        setup,
        false
    )
    dice_icon_preview_container.add_child(
        summary
    )


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
            valid_energy_types
        )
    )
    _merge_inventory_validation(validation)

    if bool(validation["success"]):
        top_validation_label.text = LocalizationService.tr_key("enerkoro_builder.valid", "✓ Valid")
        top_validation_label.modulate = Color(
            0.45,
            0.9,
            0.62,
            1.0
        )
        validation_label.text = (
            LocalizationService.tr_key("enerkoro_builder.valid_ready", "✓ VALID  •  Ready for battle.")
        )
        confirm_button.disabled = false
        back_button.disabled = false
    else:
        top_validation_label.text = LocalizationService.tr_key("enerkoro_builder.invalid", "✕ Invalid")
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
                "✕ INVALID\n{errors}"
            )
        )
        confirm_button.disabled = true
        back_button.disabled = false


func _refresh_energy_probability() -> void:
    var expected: Dictionary = (
        PROBABILITY
        .get_expected_energy_per_roll(
            setup
        )
    )

    var lines: Array[String] = [
        LocalizationService.tr_key("enerkoro_builder.energy_output_title", "ENERGY OUTPUT — expected per three-dice roll")
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
                "{energy}  •  expected {expected}  •  at least one {probability}%"
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
        PLAYER_LOADOUT_PROVIDER.USER_LOADOUT_PATH
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
        PLAYER_LOADOUT_PROVIDER.USER_LOADOUT_PATH
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
        AI_LOADOUT_PROVIDER.USER_LOADOUT_PATH
    )


func _validate_current_setup() -> Dictionary:
    var valid_energy_types: Array = []

    for energy_type: StringName in (
        VALID_ENERGY_TYPES
    ):
        valid_energy_types.append(energy_type)

    var result: Dictionary = VALIDATOR.validate(
        setup,
        valid_energy_types
    )
    _merge_inventory_validation(result)
    return result


func _get_player_energy_inventory() -> Dictionary:
    if not sync_player_loadout or not PlayerProgress.has_profile():
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
