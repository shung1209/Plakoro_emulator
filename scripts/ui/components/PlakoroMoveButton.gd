extends Button


const EFFECT_PRESENTATION: Script = preload(
    "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)
const POPUP_SCRIPT: Script = preload(
    "res://scripts/ui/components/KyokoroEffectPopup.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostRow.gd"
)


var move_card: Variant = null
var _hover_popup: Popup = null
var _hover_popup_card: PanelContainer = null
var _hover_request_serial: int = 0
var _availability_label: Label = null

const BATTLE_HOVER_DELAY_SECONDS: float = 0.35
const BATTLE_HOVER_LAYOUT_DEBUG: bool = false


func set_move_card(
    value: Variant
) -> void:
    move_card = value
    tooltip_text = ""

    if not mouse_entered.is_connected(
        _on_battle_hover_entered
    ):
        mouse_entered.connect(
            _on_battle_hover_entered
        )

    if not mouse_exited.is_connected(
        _on_battle_hover_exited
    ):
        mouse_exited.connect(
            _on_battle_hover_exited
        )


func setup_battle_summary(
    value: Variant,
    damage_text: String,
    coverage_text: String
) -> void:
    set_move_card(
        value
    )

    text = ""

    for child: Node in get_children():
        child.queue_free()

    var box: VBoxContainer = VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT,
        Control.PRESET_MODE_MINSIZE,
        8
    )
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override(
        "separation",
        4
    )
    add_child(
        box
    )

    var title: Label = Label.new()
    title.text = GameContentLocalizationService.localize_move(
        move_card
    )
    title.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )
    title.add_theme_font_size_override(
        "font_size",
        22
    )
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(
        title
    )

    var stat_row: HBoxContainer = HBoxContainer.new()
    stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
    stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_row.add_theme_constant_override(
        "separation",
        8
    )
    box.add_child(
        stat_row
    )

    var cost_row: HBoxContainer = HBoxContainer.new()
    cost_row.set_script(
        MOVE_ENERGY_COST_ROW
    )
    cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cost_row.setup(
        move_card,
        26
    )
    stat_row.add_child(
        cost_row
    )

    var damage_label: Label = Label.new()
    damage_label.text = LocalizationService.tr_format(
        "battle.move_damage_short",
        {"damage": damage_text},
        "DMG {damage}"
    )
    damage_label.add_theme_font_size_override(
        "font_size",
        17
    )
    damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stat_row.add_child(
        damage_label
    )

    _availability_label = Label.new()
    _availability_label.name = "MoveAvailabilityLabel"
    _availability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _availability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _availability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _availability_label.max_lines_visible = 2
    _availability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _availability_label.add_theme_font_size_override(
        "font_size",
        15
    )
    _availability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _availability_label.text = LocalizationService.tr_format(
        "battle.move_success",
        {"coverage": coverage_text},
        "✓ Success {coverage}"
    )
    _availability_label.modulate.a = 0.88
    box.add_child(_availability_label)



func set_battle_availability(
    usable: bool,
    reason: String,
    coverage_text: String
) -> void:
    if _availability_label == null:
        return

    if usable:
        _availability_label.text = LocalizationService.tr_format(
            "battle.move_available",
            {"coverage": coverage_text},
            "✓ Available • Success {coverage}"
        )
        _availability_label.modulate = Color(0.72, 1.0, 0.78, 0.95)
    else:
        _availability_label.text = (
            "✕"
            + (" " + reason if not reason.is_empty() else "")
        )
        _availability_label.modulate = Color(1.0, 0.68, 0.68, 0.95)


func _on_battle_hover_entered() -> void:
    if move_card == null:
        return

    _hover_request_serial += 1
    var request_serial: int = _hover_request_serial

    await get_tree().create_timer(
        BATTLE_HOVER_DELAY_SECONDS
    ).timeout

    if (
        request_serial != _hover_request_serial
        or not is_hovered()
        or move_card == null
    ):
        return

    await _show_manual_battle_hover_popup()


func _on_battle_hover_exited() -> void:
    _hover_request_serial += 1
    _hide_manual_battle_hover_popup()


func _show_manual_battle_hover_popup() -> void:
    _hide_manual_battle_hover_popup()

    var preview: Dictionary = (
        EFFECT_PRESENTATION.build_preview(
            move_card
        )
    )
    var move_data: Dictionary = (
        _build_presentation_move_data(
            move_card
        )
    )
    var move_name_id: String = String(
        move_card.move_name_id
    )
    move_data["display_name"] = GameContentLocalizationService.localize_move(
        move_card
    )
    if move_data.has("attack_type"):
        move_data["attack_type"] = GameContentLocalizationService.localize_type(
            move_data["attack_type"]
        )

    var localized_trigger_groups: Array = []
    var raw_trigger_groups: Array = preview.get(
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
            GameContentLocalizationService.localize_effect_text(
                move_card,
                index,
                String(
                    localized_group.get(
                        "effect_text",
                        ""
                    )
                )
            )
        )
        localized_trigger_groups.append(localized_group)

    var localized_detail: String = (
        GameContentLocalizationService.localize_move_description(
            move_card
        )
    )
    if localized_detail.is_empty():
        localized_detail = String(
            preview.get(
                "detail",
                ""
            )
        )

    _hover_popup = Popup.new()
    _hover_popup.name = "BattleMoveHoverPopup"
    _hover_popup.transparent_bg = true
    _hover_popup.borderless = true
    add_child(
        _hover_popup
    )

    _hover_popup_card = PanelContainer.new()
    _hover_popup_card.name = "BattleMoveHoverCard"
    _hover_popup_card.set_script(
        POPUP_SCRIPT
    )
    _hover_popup_card.set_anchors_preset(
        Control.PRESET_TOP_LEFT
    )
    _hover_popup_card.size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    _hover_popup_card.size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )

    # Keep the visible card fully transparent during the first layout frame.
    # The Control still participates in Container layout while alpha = 0.
    _hover_popup_card.modulate.a = 0.0

    _hover_popup.add_child(
        _hover_popup_card
    )

    var estimated_size: Vector2 = (
        _hover_popup_card.setup_battle_popup_move(
            String(
                move_data.get(
                    "id",
                    move_card.id
                )
            ),
            move_data,
            localized_trigger_groups,
            localized_detail
        )
    )

    if (
        _hover_popup == null
        or not is_instance_valid(
            _hover_popup
        )
        or _hover_popup_card == null
        or not is_instance_valid(
            _hover_popup_card
        )
    ):
        return

    var screen_size: Vector2i = DisplayServer.screen_get_size()
    var anchor_position: Vector2 = get_screen_position()

    # First position is based on the estimate. It is invisible, so minor
    # adjustment after exact measurement cannot flash on-screen.
    var first_position: Vector2 = _calculate_hover_position(
        anchor_position,
        estimated_size,
        screen_size
    )

    _hover_popup_card.position = Vector2.ZERO
    _hover_popup_card.size = estimated_size

    _hover_popup.popup(
        Rect2i(
            Vector2i(
                first_position
            ),
            Vector2i(
                estimated_size
            )
        )
    )

    # Critical: once the popup Window has a real width, Godot can correctly
    # calculate autowrapped Label heights. The diagnostic build showed the
    # VBox minimum falling from ~1620 px to ~190 px after this layout pass.
    await get_tree().process_frame
    await get_tree().process_frame

    if (
        _hover_popup == null
        or not is_instance_valid(
            _hover_popup
        )
        or _hover_popup_card == null
        or not is_instance_valid(
            _hover_popup_card
        )
    ):
        return

    var actual_size: Vector2 = (
        _hover_popup_card.get_content_fitted_size()
    )
    var final_position: Vector2 = _calculate_hover_position(
        anchor_position,
        actual_size,
        screen_size
    )

    _hover_popup.size = Vector2i(
        actual_size
    )
    _hover_popup.position = Vector2i(
        final_position
    )

    _hover_popup_card.position = Vector2.ZERO
    _hover_popup_card.custom_minimum_size = actual_size
    _hover_popup_card.size = actual_size

    # Reveal only after both size and position are final.
    _hover_popup_card.modulate.a = 1.0


func _calculate_hover_position(
    anchor_position: Vector2,
    hover_size: Vector2,
    screen_size: Vector2i
) -> Vector2:
    var desired_position: Vector2 = Vector2(
        anchor_position.x + size.x + 10.0,
        anchor_position.y
    )

    if (
        desired_position.x + hover_size.x
        > float(screen_size.x) - 12.0
    ):
        desired_position.x = max(
            12.0,
            anchor_position.x
            - hover_size.x
            - 10.0
        )

    if (
        desired_position.y + hover_size.y
        > float(screen_size.y) - 12.0
    ):
        desired_position.y = max(
            12.0,
            float(screen_size.y)
            - hover_size.y
            - 12.0
        )

    return desired_position


func _debug_hover_layout(
    stage: String
) -> void:
    if not BATTLE_HOVER_LAYOUT_DEBUG:
        return

    var popup_valid: bool = (
        _hover_popup != null
        and is_instance_valid(
            _hover_popup
        )
    )
    var card_valid: bool = (
        _hover_popup_card != null
        and is_instance_valid(
            _hover_popup_card
        )
    )

    var popup_size: Vector2i = Vector2i.ZERO
    var popup_position: Vector2i = Vector2i.ZERO
    var popup_visible: bool = false

    if popup_valid:
        popup_size = _hover_popup.size
        popup_position = _hover_popup.position
        popup_visible = _hover_popup.visible

    var card_snapshot: Dictionary = {}

    if card_valid:
        card_snapshot = (
            _hover_popup_card.debug_layout_snapshot(
                stage
            )
        )

    print("")
    print(
        "[HOVER_LAYOUT_DEBUG] "
        + stage
    )
    print(
        "  popup.valid="
        + str(popup_valid)
        + " visible="
        + str(popup_visible)
        + " position="
        + str(popup_position)
        + " size="
        + str(popup_size)
    )

    if card_valid:
        print(
            "  card.size="
            + str(
                card_snapshot.get(
                    "size",
                    Vector2.ZERO
                )
            )
            + " custom_min="
            + str(
                card_snapshot.get(
                    "custom_minimum_size",
                    Vector2.ZERO
                )
            )
            + " combined_min="
            + str(
                card_snapshot.get(
                    "combined_minimum_size",
                    Vector2.ZERO
                )
            )
        )
        print(
            "  card.anchors="
            + str(
                card_snapshot.get(
                    "anchors",
                    Vector4.ZERO
                )
            )
            + " offsets="
            + str(
                card_snapshot.get(
                    "offsets",
                    Vector4.ZERO
                )
            )
            + " flags="
            + str(
                card_snapshot.get(
                    "size_flags_horizontal",
                    -1
                )
            )
            + "/"
            + str(
                card_snapshot.get(
                    "size_flags_vertical",
                    -1
                )
            )
        )
        print(
            "  child.class="
            + str(
                card_snapshot.get(
                    "first_child_class",
                    "(none)"
                )
            )
            + " size="
            + str(
                card_snapshot.get(
                    "first_child_size",
                    Vector2.ZERO
                )
            )
            + " custom_min="
            + str(
                card_snapshot.get(
                    "first_child_custom_minimum",
                    Vector2.ZERO
                )
            )
            + " combined_min="
            + str(
                card_snapshot.get(
                    "first_child_combined_minimum",
                    Vector2.ZERO
                )
            )
            + " flags="
            + str(
                card_snapshot.get(
                    "first_child_flags_horizontal",
                    -1
                )
            )
            + "/"
            + str(
                card_snapshot.get(
                    "first_child_flags_vertical",
                    -1
                )
            )
        )


func _hide_manual_battle_hover_popup() -> void:
    if (
        _hover_popup != null
        and is_instance_valid(
            _hover_popup
        )
    ):
        _hover_popup.queue_free()

    _hover_popup = null
    _hover_popup_card = null


func _build_presentation_move_data(
    card: Variant
) -> Dictionary:
    var energy_cost: Array[Dictionary] = []

    for raw_cost: Variant in card.energy_costs:
        if raw_cost == null:
            continue

        energy_cost.append(
            {
                "energy_type": String(
                    raw_cost.energy_type
                ),
                "count": int(
                    raw_cost.count
                )
            }
        )

    return {
        "id": String(card.id),
        "move_name_id": String(
            card.move_name_id
        ),
        "owner_id": String(
            card.owner_id
        ),
        "display_name": String(
            card.display_name
        ),
        "move_category": String(
            card.move_category
        ),
        "attack_type": String(
            card.attack_type
        ),
        "energy_cost": energy_cost,
        "printed_damage": (
            card.printed_damage
        ),
        "base_actions": [],
        "special_effects": (
            card.special_effects
        ),
        "source": (
            card.source
        )
    }
