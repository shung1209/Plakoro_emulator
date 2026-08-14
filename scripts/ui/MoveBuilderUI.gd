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
const MOVE_SELECTION_VALIDATOR: Script = preload(
    "res://scripts/loadout/MoveSelectionValidator.gd"
)
const MOVE_BUILDER_ANALYSIS: Script = preload(
    "res://scripts/analysis/MoveBuilderAnalysisService.gd"
)
const MOVE_EFFECT_PRESENTATION: Script = preload(
    "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostRow.gd"
)
const KYOKORO_TRIGGER_ROW: Script = preload(
    "res://scripts/ui/components/KyokoroTriggerRow.gd"
)
const MOVE_DRAFT_PROVIDER: Script = preload(
    "res://scripts/draft/MoveDraftProvider.gd"
)
const MOVE_DRAFT_DIFF: Script = preload(
    "res://scripts/draft/MoveDraftDiffService.gd"
)
const MOVE_DRAFT_APPLY: Script = preload(
    "res://scripts/draft/MoveDraftApplyService.gd"
)


const PREPARATION_SCENE_PATH: String = (
    "res://scenes/ui/BattlePreparationUI.tscn"
)


@onready var database: Node = $Database
@onready var margin: MarginContainer = $Margin
@onready var main: VBoxContainer = $Margin/Main
@onready var content_scroll: ScrollContainer = $Margin/Main/ContentScroll
@onready var content: VBoxContainer = $Margin/Main/ContentScroll/Content
@onready var builder_body: HSplitContainer = (
    $Margin/Main/ContentScroll/Content/Body
)
@onready var available_scroll: ScrollContainer = (
    $Margin/Main/ContentScroll/Content/Body/AvailablePanel/AvailableBox/AvailableScroll
)
@onready var right_scroll: ScrollContainer = (
    $Margin/Main/ContentScroll/Content/Body/RightScroll
)
@onready var actions: HBoxContainer = $Margin/Main/Actions

@onready var pokemon_name_label: Label = %PokemonNameLabel
@onready var pokemon_id_label: Label = %PokemonIdLabel
@onready var draft_mode_label: Label = %DraftModeLabel

@onready var available_moves_container: VBoxContainer = (
    %AvailableMovesContainer
)
@onready var selected_moves_container: VBoxContainer = (
    %SelectedMovesContainer
)

@onready var selection_count_label: Label = %SelectionCountLabel
@onready var status_label: Label = %StatusLabel
@onready var validation_label: Label = %ValidationLabel
@onready var diff_label: Label = %DiffLabel

@onready var coverage_container: VBoxContainer = %CoverageContainer
@onready var overall_rating_label: Label = %OverallRatingLabel
@onready var overall_probability_label: Label = (
    %OverallProbabilityLabel
)
@onready var energy_usage_label: Label = %EnergyUsageLabel

@onready var discard_draft_button: Button = %DiscardDraftButton
@onready var apply_button: Button = %ApplyButton
@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton


var player_loadout_data: Variant = null
var pokemon_data: Variant = null
var move_draft: Variant = null

var available_moves: Array = []
var selected_move_ids: Array[StringName] = []

var move_buttons: Dictionary = {}


func _ready() -> void:
    PLAKORO_THEME.apply_to(self)
    get_viewport().size_changed.connect(
        _apply_responsive_layout
    )
    _apply_responsive_layout()
    content_scroll.scroll_vertical = 0

    back_button.pressed.connect(
        _back_to_preparation
    )
    discard_draft_button.pressed.connect(
        _discard_draft
    )
    apply_button.pressed.connect(
        _apply_draft
    )
    continue_button.pressed.connect(
        _on_continue_pressed
    )

    if not database.load_all():
        status_label.text = "Database load failed."
        back_button.disabled = true
        continue_button.disabled = true
        return

    _load_current_loadout()



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
        apply_button,
        profile,
        180
    )
    RESPONSIVE_UI.apply_button(
        continue_button,
        profile,
        180
    )
    RESPONSIVE_UI.apply_button(
        back_button,
        profile,
        180
    )
    RESPONSIVE_UI.apply_button(
        discard_draft_button,
        profile,
        150
    )

    RESPONSIVE_UI.apply_split(
        builder_body,
        profile,
        get_viewport_rect().size.x,
        0.54
    )

    _apply_builder_work_area(
        profile
    )



func _apply_builder_work_area(
    profile: StringName
) -> void:
    var viewport_height: float = (
        get_viewport_rect().size.y
    )

    # ContentScroll fills the area between the fixed header and fixed action
    # footer. The Body previously had no meaningful vertical minimum once it
    # was moved inside a ScrollContainer, so its nested move lists collapsed.
    var body_height: float = 520.0

    match profile:
        RESPONSIVE_PROFILE.PROFILE_FULL:
            body_height = clamp(
                viewport_height * 0.58,
                500.0,
                650.0
            )
        RESPONSIVE_PROFILE.PROFILE_COMPACT:
            body_height = clamp(
                viewport_height * 0.54,
                390.0,
                540.0
            )
        _:
            body_height = clamp(
                viewport_height * 0.50,
                320.0,
                440.0
            )

    builder_body.custom_minimum_size.y = body_height

    # Keep the database list and selected/analysis column independently
    # scrollable inside the work area.
    available_scroll.custom_minimum_size.y = max(
        240.0,
        body_height - 95.0
    )
    right_scroll.custom_minimum_size.y = body_height

    content.size_flags_vertical = (
        Control.SIZE_EXPAND_FILL
    )


func _load_current_loadout() -> void:
    player_loadout_data = (
        PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    )

    if player_loadout_data == null:
        status_label.text = (
            "Player loadout could not be loaded."
        )
        return

    pokemon_data = database.get_pokemon(
        player_loadout_data.pokemon_id
    )

    if pokemon_data == null:
        status_label.text = (
            "Current Pokémon could not be found."
        )
        return

    move_draft = MOVE_DRAFT_PROVIDER.load_or_create_draft()

    if move_draft == null:
        status_label.text = "Move draft could not be loaded."
        return

    selected_move_ids.clear()

    for move_card_id: StringName in (
        move_draft.selected_move_ids
    ):
        selected_move_ids.append(move_card_id)

    _load_available_moves()
    _refresh_all()


func _load_available_moves() -> void:
    available_moves.clear()

    for move_card: Variant in (
        pokemon_data.available_move_cards
    ):
        if move_card != null:
            available_moves.append(move_card)

    available_moves.sort_custom(
        func(a: Variant, b: Variant) -> bool:
            return (
                String(a.display_name)
                .naturalnocasecmp_to(
                    String(b.display_name)
                ) < 0
            )
    )


func _refresh_all() -> void:
    pokemon_name_label.text = String(
        pokemon_data.display_name
    )
    pokemon_id_label.text = String(
        pokemon_data.id
    )
    draft_mode_label.text = (
        "Draft Mode"
        if MOVE_DRAFT_PROVIDER.has_draft()
        else "Loadout Mode"
    )

    _refresh_available_moves()
    _refresh_selected_moves()
    _refresh_selection_status()
    _refresh_validation()
    _refresh_live_analysis()
    _refresh_diff()


func _refresh_available_moves() -> void:
    for child: Node in (
        available_moves_container.get_children()
    ):
        child.queue_free()

    move_buttons.clear()

    for move_card: Variant in available_moves:
        var move_card_id: StringName = StringName(
            move_card.id
        )
        var selected: bool = selected_move_ids.has(
            move_card_id
        )

        var row: PanelContainer = PanelContainer.new()
        row.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )

        var box: HBoxContainer = HBoxContainer.new()
        box.add_theme_constant_override(
            "separation",
            10
        )
        row.add_child(box)

        var info: VBoxContainer = VBoxContainer.new()
        info.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )
        box.add_child(info)

        var title: Label = Label.new()
        title.text = String(
            move_card.display_name
        )
        title.add_theme_font_size_override(
            "font_size",
            18
        )
        info.add_child(title)

        var stats_row: HBoxContainer = HBoxContainer.new()
        stats_row.add_theme_constant_override(
            "separation",
            12
        )
        info.add_child(stats_row)

        var energy_row: HBoxContainer = HBoxContainer.new()
        energy_row.set_script(
            MOVE_ENERGY_COST_ROW
        )
        energy_row.setup(
            move_card,
            22
        )
        stats_row.add_child(
            energy_row
        )

        var stats_label: Label = Label.new()
        stats_label.text = (
            "DMG "
            + _format_damage(move_card)
            + " | "
            + String(move_card.attack_type)
        )
        stats_label.modulate.a = 0.88
        stats_row.add_child(
            stats_label
        )

        var effect_preview: Dictionary = (
            MOVE_EFFECT_PRESENTATION.build_preview(
                move_card
            )
        )

        var trigger_groups: Array = (
            effect_preview.get(
                "trigger_groups",
                []
            )
        )

        for raw_group: Variant in trigger_groups:
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

            var trigger_line: HBoxContainer = HBoxContainer.new()
            trigger_line.add_theme_constant_override(
                "separation",
                10
            )
            info.add_child(
                trigger_line
            )

            var trigger_row: HBoxContainer = HBoxContainer.new()
            trigger_row.set_script(
                KYOKORO_TRIGGER_ROW
            )
            trigger_row.setup(
                orientations,
                26
            )
            trigger_line.add_child(
                trigger_row
            )

            var effect_text: Label = Label.new()
            effect_text.size_flags_horizontal = (
                Control.SIZE_EXPAND_FILL
            )
            effect_text.autowrap_mode = (
                TextServer.AUTOWRAP_WORD_SMART
            )
            effect_text.text = String(
                group.get(
                    "effect_text",
                    ""
                )
            )
            effect_text.tooltip_text = String(
                effect_preview["detail"]
            )
            effect_text.modulate.a = 0.90
            trigger_line.add_child(
                effect_text
            )

        if trigger_groups.is_empty():
            var effect_label: Label = Label.new()
            effect_label.autowrap_mode = (
                TextServer.AUTOWRAP_WORD_SMART
            )
            effect_label.text = String(
                effect_preview["summary"]
            )
            effect_label.tooltip_text = String(
                effect_preview["detail"]
            )
            effect_label.modulate.a = 0.70
            info.add_child(
                effect_label
            )

        var source: Label = Label.new()
        source.text = String(move_card.id)
        source.modulate.a = 0.55
        info.add_child(source)

        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(
            140,
            44
        )

        var same_name_selected: bool = (
            MOVE_SELECTION_VALIDATOR
            .has_selected_move_name(
                move_card,
                selected_move_ids,
                database
            )
        )

        if selected:
            button.text = "Selected"
            button.disabled = false
            button.tooltip_text = (
                "This exact Move Card is currently selected."
            )
        elif same_name_selected:
            button.text = "Same Move"
            button.disabled = true
            button.tooltip_text = (
                "Another Move Card named "
                + String(move_card.display_name)
                + " is already selected."
            )
            button.modulate.a = 0.45
        elif selected_move_ids.size() >= 4:
            button.text = "Add"
            button.disabled = true
            button.tooltip_text = (
                "Four moves are already selected. "
                + "Remove one before adding another."
            )
            button.modulate.a = 0.65
        else:
            button.text = "Add"
            button.disabled = false
            button.tooltip_text = ""
            button.modulate.a = 1.0

        button.pressed.connect(
            _on_move_button_pressed.bind(
                move_card_id
            )
        )

        move_buttons[move_card_id] = button
        box.add_child(button)

        available_moves_container.add_child(row)


func _refresh_selected_moves() -> void:
    for child: Node in (
        selected_moves_container.get_children()
    ):
        child.queue_free()

    for index: int in range(
        selected_move_ids.size()
    ):
        var move_card_id: StringName = (
            selected_move_ids[index]
        )
        var move_card: Variant = database.get_move_card(
            move_card_id
        )

        var row: PanelContainer = PanelContainer.new()
        row.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )
        row.modulate.a = 0.20

        var box: HBoxContainer = HBoxContainer.new()
        box.add_theme_constant_override(
            "separation",
            10
        )
        row.add_child(box)

        var slot: Label = Label.new()
        slot.custom_minimum_size = Vector2(
            34,
            0
        )
        slot.text = str(index + 1) + "."
        box.add_child(slot)

        var name_label: Label = Label.new()
        name_label.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )

        if move_card != null:
            name_label.text = String(
                move_card.display_name
            )
        else:
            name_label.text = String(
                move_card_id
            )

        box.add_child(name_label)

        if move_card != null:
            var selected_energy_row: HBoxContainer = HBoxContainer.new()
            selected_energy_row.set_script(
                MOVE_ENERGY_COST_ROW
            )
            selected_energy_row.setup(
                move_card,
                20
            )
            box.add_child(
                selected_energy_row
            )

        var remove_button: Button = Button.new()
        remove_button.text = "Remove"
        remove_button.pressed.connect(
            _remove_move.bind(
                move_card_id
            )
        )
        box.add_child(remove_button)

        selected_moves_container.add_child(row)

        var tween: Tween = create_tween()
        tween.tween_property(
            row,
            "modulate:a",
            1.0,
            0.16
        )


func _refresh_selection_status() -> void:
    selection_count_label.text = (
        "Selected "
        + str(selected_move_ids.size())
        + " / 4"
    )

    if selected_move_ids.size() > 4:
        status_label.text = (
            "Too many moves selected."
        )
    elif selected_move_ids.size() < 4:
        status_label.text = (
            "Select "
            + str(4 - selected_move_ids.size())
            + " more move(s)."
        )
    else:
        status_label.text = (
            "Four moves selected."
        )


func _refresh_validation() -> void:
    var result: Dictionary = (
        MOVE_SELECTION_VALIDATOR.validate(
            pokemon_data,
            selected_move_ids,
            database
        )
    )

    if bool(result["success"]):
        validation_label.text = (
            "READY — Move selection is valid."
        )
        continue_button.disabled = false

        var diff: Dictionary = MOVE_DRAFT_DIFF.compare(
            move_draft,
            player_loadout_data
        )
        apply_button.disabled = not bool(
            diff["changed"]
        )
        return

    validation_label.text = (
        "NOT READY\n"
        + "\n".join(result["errors"])
    )
    continue_button.disabled = true
    apply_button.disabled = true


func _refresh_live_analysis() -> void:
    for child: Node in coverage_container.get_children():
        child.queue_free()

    if (
        player_loadout_data == null
        or player_loadout_data.energy_dice_setup == null
    ):
        overall_rating_label.text = "☆☆☆☆☆  No Dice Setup"
        overall_probability_label.text = "Overall coverage: —"
        energy_usage_label.text = "Energy Usage\n—"
        return

    var analysis: Dictionary = (
        MOVE_BUILDER_ANALYSIS.analyze_selection(
            player_loadout_data.energy_dice_setup,
            selected_move_ids,
            database
        )
    )

    var move_results: Array = analysis["move_results"]

    for coverage: Variant in move_results:
        _add_coverage_row(coverage)

    var stars: int = int(
        analysis["stars"]
    )
    var rating: StringName = StringName(
        analysis["rating"]
    )
    var overall_probability: float = float(
        analysis["overall_probability"]
    )

    overall_rating_label.text = (
        _stars_text(stars)
        + "  "
        + _rating_text(rating)
    )

    overall_probability_label.text = (
        "Overall coverage: "
        + "%.1f%%"
        % (overall_probability * 100.0)
    )

    energy_usage_label.text = _format_energy_usage(
        analysis["energy_usage"]
    )


func _add_coverage_row(
    coverage: Variant
) -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override(
        "separation",
        4
    )
    panel.add_child(box)

    var header: HBoxContainer = HBoxContainer.new()
    box.add_child(header)

    var name_label: Label = Label.new()
    name_label.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    name_label.text = String(
        coverage.move_name
    )
    header.add_child(name_label)

    var percent_label: Label = Label.new()
    percent_label.text = (
        "%.1f%%"
        % (
            float(
                coverage.success_probability
            )
            * 100.0
        )
    )
    header.add_child(percent_label)

    var progress: ProgressBar = ProgressBar.new()
    progress.min_value = 0.0
    progress.max_value = 100.0
    progress.value = 0.0
    progress.show_percentage = false
    progress.custom_minimum_size = Vector2(
        0,
        14
    )
    box.add_child(progress)

    var detail: Label = Label.new()

    if coverage.most_missing_energy == &"":
        detail.text = (
            "Average shortfall: "
            + "%.2f"
            % float(coverage.average_shortfall)
        )
    else:
        detail.text = (
            "Most missing: "
            + _energy_icon(
                coverage.most_missing_energy
            )
            + " "
            + String(
                coverage.most_missing_energy
            )
            + " | Average shortfall: "
            + "%.2f"
            % float(coverage.average_shortfall)
        )

    detail.modulate.a = 0.75
    box.add_child(detail)

    coverage_container.add_child(panel)

    var tween: Tween = create_tween()
    tween.tween_property(
        progress,
        "value",
        float(coverage.success_probability) * 100.0,
        0.25
    )


func _on_continue_pressed() -> void:
    var result: Dictionary = (
        MOVE_SELECTION_VALIDATOR.validate(
            pokemon_data,
            selected_move_ids,
            database
        )
    )

    if not bool(result["success"]):
        _refresh_validation()
        return

    status_label.text = (
        "Draft is valid. Use Apply Changes to save it."
    )


func _on_move_button_pressed(
    move_card_id: StringName
) -> void:
    if selected_move_ids.has(move_card_id):
        _remove_move(move_card_id)
        return

    var move_card: Variant = database.get_move_card(
        move_card_id
    )

    if (
        move_card != null
        and MOVE_SELECTION_VALIDATOR
        .has_selected_move_name(
            move_card,
            selected_move_ids,
            database
        )
    ):
        status_label.text = (
            "A move with the same name is already selected: "
            + String(move_card.display_name)
        )
        return

    if selected_move_ids.size() >= 4:
        status_label.text = (
            "Four moves are already selected. "
            + "Remove one before adding another."
        )
        return

    selected_move_ids.append(move_card_id)
    _sync_selection_to_draft()
    _refresh_all()


func _remove_move(
    move_card_id: StringName
) -> void:
    selected_move_ids.erase(move_card_id)
    _sync_selection_to_draft()
    _refresh_all()



func _sync_selection_to_draft() -> void:
    if move_draft == null:
        return

    move_draft.selected_move_ids.clear()

    for move_id: StringName in selected_move_ids:
        move_draft.selected_move_ids.append(move_id)

    if not MOVE_DRAFT_PROVIDER.save_draft(move_draft):
        status_label.text = "Draft auto-save failed."


func _refresh_diff() -> void:
    var diff: Dictionary = MOVE_DRAFT_DIFF.compare(
        move_draft,
        player_loadout_data
    )

    if not bool(diff["changed"]):
        diff_label.text = "Draft matches saved loadout."
        apply_button.disabled = true
        return

    var lines: Array[String] = ["Draft Changes"]

    for move_id: StringName in diff["added"]:
        var move_card: Variant = database.get_move_card(move_id)
        lines.append(
            "+ "
            + (
                String(move_card.display_name)
                if move_card != null
                else String(move_id)
            )
        )

    for move_id: StringName in diff["removed"]:
        var move_card: Variant = database.get_move_card(move_id)
        lines.append(
            "- "
            + (
                String(move_card.display_name)
                if move_card != null
                else String(move_id)
            )
        )

    diff_label.text = "\n".join(lines)



func _apply_draft() -> void:
    if move_draft == null:
        status_label.text = "Move draft is missing."
        return

    var validation: Dictionary = (
        MOVE_SELECTION_VALIDATOR.validate(
            pokemon_data,
            selected_move_ids,
            database
        )
    )

    if not bool(validation["success"]):
        _refresh_validation()
        return

    var result: Dictionary = (
        MOVE_DRAFT_APPLY.apply_draft(
            move_draft,
            database
        )
    )

    if not bool(result["success"]):
        status_label.text = (
            "Apply failed.\n"
            + "\n".join(result["errors"])
        )
        return

    # Reload formal loadout after successful apply.
    player_loadout_data = (
        PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    )

    if player_loadout_data == null:
        status_label.text = (
            "Changes were saved, but the Player Loadout could not be reloaded."
        )
        return

    # No active draft now. Recreate an in-memory copy only for continued editing.
    move_draft = (
        MOVE_DRAFT_PROVIDER.create_from_loadout(
            player_loadout_data
        )
    )

    if move_draft == null:
        status_label.text = (
            "Changes were saved, but a new editor draft could not be created."
        )
        return

    selected_move_ids.clear()

    for move_id: StringName in move_draft.selected_move_ids:
        selected_move_ids.append(move_id)

    _refresh_all()

    status_label.text = (
        "Changes applied to Player Battle Loadout."
    )


func _discard_draft() -> void:
    if not MOVE_DRAFT_PROVIDER.discard_draft():
        status_label.text = "Could not discard draft."
        return

    move_draft = MOVE_DRAFT_PROVIDER.create_from_loadout(
        player_loadout_data
    )

    if move_draft == null:
        status_label.text = "Could not restore saved loadout."
        return

    selected_move_ids.clear()

    for move_id: StringName in move_draft.selected_move_ids:
        selected_move_ids.append(move_id)

    _refresh_all()
    status_label.text = (
        "Draft discarded. Restored saved loadout."
    )


func _back_to_preparation() -> void:
    get_tree().change_scene_to_file(
        PREPARATION_SCENE_PATH
    )


func _format_move_cost(
    move_card: Variant
) -> String:
    if move_card.energy_costs.is_empty():
        return "No energy cost"

    var parts: Array[String] = []

    for cost: Variant in move_card.energy_costs:
        parts.append(
            _energy_icon(
                StringName(cost.energy_type)
            )
            + " "
            + String(cost.energy_type)
            + "×"
            + str(int(cost.count))
        )

    return ", ".join(parts)


func _format_damage(
    move_card: Variant
) -> String:
    if move_card.printed_damage == null:
        return "—"

    return str(
        int(move_card.printed_damage)
    )


func _format_energy_usage(
    energy_usage: Dictionary
) -> String:
    if energy_usage.is_empty():
        return "Energy Usage\nNo selected move energy costs."

    var lines: Array[String] = [
        "Energy Usage"
    ]

    var keys: Array = energy_usage.keys()
    keys.sort()

    for raw_energy: Variant in keys:
        var energy_type: StringName = StringName(
            raw_energy
        )

        lines.append(
            _energy_icon(energy_type)
            + " "
            + String(energy_type)
            + " × "
            + str(
                int(
                    energy_usage[raw_energy]
                )
            )
        )

    return "\n".join(lines)


func _stars_text(
    filled_count: int
) -> String:
    var text: String = ""

    for index: int in range(5):
        text += (
            "★"
            if index < filled_count
            else "☆"
        )

    return text


func _rating_text(
    rating: StringName
) -> String:
    match rating:
        &"excellent":
            return "Excellent"
        &"good":
            return "Good"
        &"acceptable":
            return "Acceptable"
        &"poor":
            return "Needs Improvement"
        _:
            return "No Analysis"


func _energy_icon(
    energy_type: StringName
) -> String:
    match energy_type:
        &"normal":
            return "☆"
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
            return "•"
