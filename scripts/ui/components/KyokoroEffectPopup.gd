extends PanelContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)
const MOVE_ENERGY_COST_ROW: Script = preload(
    "res://scripts/ui/components/MoveEnergyCostRow.gd"
)
const THEME_FACTORY: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


func get_content_fitted_size() -> Vector2:
    var content: Control = null

    if (
        get_child_count() > 0
        and get_child(0) is Control
    ):
        content = get_child(0) as Control

    var content_size: Vector2 = Vector2(
        360.0,
        96.0
    )

    if content != null:
        content_size = (
            content.get_combined_minimum_size()
        )

    # Panel style uses 14 px left/right and 12 px top/bottom margins.
    # Add 2 px extra vertical safety to avoid clipping the last text baseline.
    return Vector2(
        max(
            content_size.x + 28.0,
            390.0
        ),
        max(
            content_size.y + 26.0,
            120.0
        )
    )




func debug_layout_snapshot(
    stage: String
) -> Dictionary:
    var first_child: Variant = (
        get_child(0)
        if get_child_count() > 0
        else null
    )

    var child_size: Vector2 = Vector2.ZERO
    var child_minimum: Vector2 = Vector2.ZERO
    var child_combined_minimum: Vector2 = Vector2.ZERO
    var child_flags_h: int = -1
    var child_flags_v: int = -1

    if first_child is Control:
        var control: Control = first_child as Control
        child_size = control.size
        child_minimum = control.custom_minimum_size
        child_combined_minimum = (
            control.get_combined_minimum_size()
        )
        child_flags_h = control.size_flags_horizontal
        child_flags_v = control.size_flags_vertical

    return {
        "stage": stage,
        "inside_tree": is_inside_tree(),
        "visible": visible,
        "size": size,
        "custom_minimum_size": custom_minimum_size,
        "combined_minimum_size": get_combined_minimum_size(),
        "anchors": Vector4(
            anchor_left,
            anchor_top,
            anchor_right,
            anchor_bottom
        ),
        "offsets": Vector4(
            offset_left,
            offset_top,
            offset_right,
            offset_bottom
        ),
        "size_flags_horizontal": size_flags_horizontal,
        "size_flags_vertical": size_flags_vertical,
        "first_child_class": (
            first_child.get_class()
            if first_child != null
            else "(none)"
        ),
        "first_child_size": child_size,
        "first_child_custom_minimum": child_minimum,
        "first_child_combined_minimum": child_combined_minimum,
        "first_child_flags_horizontal": child_flags_h,
        "first_child_flags_vertical": child_flags_v
    }




func setup_move(
    move_id: String,
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    _build_panel_style()

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(
        0,
        140
    )
    scroll.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    scroll.vertical_scroll_mode = (
        ScrollContainer.SCROLL_MODE_AUTO
    )
    scroll.horizontal_scroll_mode = (
        ScrollContainer.SCROLL_MODE_DISABLED
    )
    add_child(
        scroll
    )

    var box: VBoxContainer = _create_move_content_box()
    scroll.add_child(
        box
    )

    _populate_move_content(
        box,
        move_id,
        move_data,
        trigger_groups,
        fallback_detail
    )


func setup_battle_popup_move(
    move_id: String,
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> Vector2:
    _build_panel_style()

    custom_minimum_size = Vector2(
        390,
        0
    )
    size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )

    var box: VBoxContainer = _create_move_content_box()
    box.custom_minimum_size.x = 360.0
    box.size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    box.size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )
    add_child(
        box
    )

    _populate_battle_tooltip_content(
        box,
        move_data,
        trigger_groups,
        fallback_detail
    )

    # This is only a first-frame estimate. Exact fitting happens after the
    # hidden/invisible popup receives a real width and Godot resolves autowrap.
    var estimated_size: Vector2 = Vector2(
        390.0,
        _estimate_battle_tooltip_height(
            move_data,
            trigger_groups,
            fallback_detail
        )
    )

    custom_minimum_size = estimated_size
    size = estimated_size
    return estimated_size


func setup_tooltip_move(
    move_id: String,
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    _build_panel_style()

    custom_minimum_size = Vector2(
        390,
        0
    )
    size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )

    var box: VBoxContainer = _create_move_content_box()
    box.size_flags_horizontal = (
        Control.SIZE_SHRINK_BEGIN
    )
    box.size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )
    add_child(
        box
    )

    _populate_battle_tooltip_content(
        box,
        move_data,
        trigger_groups,
        fallback_detail
    )

    var measured_size: Vector2 = Vector2(
        390.0,
        _estimate_battle_tooltip_height(
            move_data,
            trigger_groups,
            fallback_detail
        )
    )

    custom_minimum_size = measured_size
    size = measured_size


func _estimate_battle_tooltip_height(
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> float:
    # This calculation intentionally does not depend on SceneTree/theme layout.
    # _make_custom_tooltip() is called before Godot inserts the returned Control
    # into the tooltip Window, so get_tree() is null at this stage.
    var height: float = 28.0
    var move_effects: Array[String] = (
        _collect_move_effect_texts(
            move_data
        )
    )

    if not move_effects.is_empty():
        height += 24.0

        for effect_text: String in move_effects:
            height += _estimate_wrapped_text_height(
                effect_text,
                345.0,
                16
            )

        height += 9.0

    if trigger_groups.is_empty():
        if not fallback_detail.is_empty():
            height += 24.0
            height += _estimate_wrapped_text_height(
                fallback_detail,
                345.0,
                16
            )

        return max(
            height,
            120.0
        )

    for index: int in range(
        trigger_groups.size()
    ):
        var raw_group: Variant = trigger_groups[index]

        if not raw_group is Dictionary:
            continue

        var group: Dictionary = raw_group
        var orientations: Array = group.get(
            "orientations",
            []
        )
        var effect_text: String = String(
            group.get(
                "effect_text",
                ""
            )
        )

        if index > 0:
            height += 10.0

        # Trigger title.
        height += 24.0

        # Orientation icon row (48 px icon + 11 px label + spacing).
        if not orientations.is_empty():
            height += 68.0

        # Charakoro Effect title.
        height += 24.0

        # Effect body.
        height += _estimate_wrapped_text_height(
            effect_text,
            345.0,
            16
        )

        height += 9.0

    return max(
        height,
        120.0
    )


func _estimate_wrapped_text_height(
    text_value: String,
    available_width: float,
    font_size: int
) -> float:
    if text_value.is_empty():
        return 22.0

    # Conservative character-width estimate for the default Godot UI font.
    # A little extra vertical padding is deliberate so the last line is never
    # clipped even before the tooltip inherits its final theme.
    var approximate_character_width: float = (
        float(font_size)
        * 0.56
    )
    var characters_per_line: int = max(
        1,
        int(
            floor(
                available_width
                / approximate_character_width
            )
        )
    )
    var line_count: int = max(
        1,
        int(
            ceil(
                float(
                    text_value.length()
                )
                / float(
                    characters_per_line
                )
            )
        )
    )

    return (
        float(line_count)
        * float(font_size + 7)
        + 4.0
    )


func _populate_battle_tooltip_content(
    box: VBoxContainer,
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    var move_effects: Array[String] = (
        _collect_move_effect_texts(
            move_data
        )
    )

    if not move_effects.is_empty():
        var move_effect_title: Label = Label.new()
        move_effect_title.text = LocalizationService.tr_key(
            "move_popup.move_effect",
            "Move Effect"
        )
        move_effect_title.modulate.a = 0.78
        box.add_child(
            move_effect_title
        )

        for effect_text: String in move_effects:
            var effect_label: Label = Label.new()
            effect_label.text = effect_text
            effect_label.autowrap_mode = (
                TextServer.AUTOWRAP_WORD_SMART
            )
            effect_label.add_theme_font_size_override(
                "font_size",
                16
            )
            box.add_child(
                effect_label
            )

    _append_charakoro_groups(
        box,
        trigger_groups,
        fallback_detail
    )


func _create_move_content_box() -> VBoxContainer:
    var box: VBoxContainer = VBoxContainer.new()
    box.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )
    box.add_theme_constant_override(
        "separation",
        9
    )
    return box


func _populate_move_content(
    box: VBoxContainer,
    move_id: String,
    move_data: Dictionary,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    var move_name: String = String(
        move_data.get(
            "display_name",
            move_id
        )
    )
    var attack_type: String = String(
        move_data.get(
            "attack_type",
            ""
        )
    )
    var pokemon_type: String = String(
        move_data.get(
            "pokemon_type",
            move_data.get(
                "move_type",
                ""
            )
        )
    )

    _add_title(
        box,
        move_name
    )

    var type_line: String = (
        GameContentLocalizationService.localize_type(
            attack_type
        )
        if not attack_type.is_empty()
        else ""
    )

    if not pokemon_type.is_empty():
        type_line += (
            " | "
            + GameContentLocalizationService.localize_type(
                pokemon_type
            )
        )

    if not type_line.is_empty():
        _add_detail_line(
            box,
            type_line,
            0.88
        )

    var printed_damage: Variant = move_data.get(
        "printed_damage",
        null
    )
    _add_detail_line(
        box,
        LocalizationService.tr_format(
            "move_popup.damage",
            {
                "damage": (
                    str(int(printed_damage))
                    if printed_damage != null
                    else "—"
                )
            },
            "Damage: {damage}"
        ),
        1.0
    )

    var energy_cost_line: HBoxContainer = HBoxContainer.new()
    energy_cost_line.add_theme_constant_override(
        "separation",
        8
    )
    box.add_child(
        energy_cost_line
    )

    var energy_cost_title: Label = Label.new()
    energy_cost_title.text = LocalizationService.tr_key(
        "move_popup.energy_cost",
        "Energy Cost:"
    )
    energy_cost_line.add_child(
        energy_cost_title
    )

    var energy_cost_row: HBoxContainer = HBoxContainer.new()
    energy_cost_row.set_script(
        MOVE_ENERGY_COST_ROW
    )
    energy_cost_row.setup_cost_entries(
        move_data.get(
            "energy_cost",
            []
        ),
        22
    )
    energy_cost_line.add_child(
        energy_cost_row
    )

    _add_detail_line(
        box,
        LocalizationService.tr_format(
            "move_popup.move_id",
            {"id": move_id},
            "Move ID: {id}"
        ),
        0.82
    )

    var move_effects: Array[String] = (
        _collect_move_effect_texts(
            move_data
        )
    )

    if not move_effects.is_empty():
        var separator: HSeparator = HSeparator.new()
        box.add_child(
            separator
        )

        var move_effect_title: Label = Label.new()
        move_effect_title.text = LocalizationService.tr_key(
            "move_popup.move_effect",
            "Move Effect"
        )
        move_effect_title.modulate.a = 0.78
        box.add_child(
            move_effect_title
        )

        for effect_text: String in move_effects:
            var effect_label: Label = Label.new()
            effect_label.text = effect_text
            effect_label.autowrap_mode = (
                TextServer.AUTOWRAP_WORD_SMART
            )
            effect_label.add_theme_font_size_override(
                "font_size",
                16
            )
            box.add_child(
                effect_label
            )

    _append_charakoro_groups(
        box,
        trigger_groups,
        fallback_detail
    )


func _build_panel_style() -> void:
    custom_minimum_size = Vector2(
        420,
        180
    )
    size_flags_vertical = (
        Control.SIZE_SHRINK_BEGIN
    )

    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = THEME_FACTORY.get_color("surface")
    panel_style.border_color = THEME_FACTORY.get_color("border_hover")
    panel_style.set_border_width_all(1)
    panel_style.corner_radius_top_left = 8
    panel_style.corner_radius_top_right = 8
    panel_style.corner_radius_bottom_left = 8
    panel_style.corner_radius_bottom_right = 8
    panel_style.content_margin_left = 14
    panel_style.content_margin_right = 14
    panel_style.content_margin_top = 12
    panel_style.content_margin_bottom = 12

    add_theme_stylebox_override(
        "panel",
        panel_style
    )


func _add_title(
    box: VBoxContainer,
    text_value: String
) -> void:
    var title: Label = Label.new()
    title.text = text_value
    title.add_theme_font_size_override(
        "font_size",
        19
    )
    box.add_child(
        title
    )


func _add_detail_line(
    box: VBoxContainer,
    text_value: String,
    alpha: float
) -> void:
    var label: Label = Label.new()
    label.text = text_value
    label.modulate.a = alpha
    box.add_child(
        label
    )


func _format_energy_cost(
    move_data: Dictionary
) -> String:
    var raw_cost: Variant = move_data.get(
        "energy_cost",
        []
    )

    if (
        not raw_cost is Array
        or (
            raw_cost as Array
        ).is_empty()
    ):
        return LocalizationService.tr_key(
            "move_popup.none",
            "None"
        )

    var parts: Array[String] = []

    for raw_entry: Variant in raw_cost as Array:
        if not raw_entry is Dictionary:
            continue

        var entry: Dictionary = raw_entry
        var energy_type: String = String(
            entry.get(
                "energy_type",
                "normal"
            )
        )
        var count: int = int(
            entry.get(
                "count",
                0
            )
        )

        if count <= 0:
            continue

        parts.append(
            energy_type.capitalize()
            + " ×"
            + str(
                count
            )
        )

    return (
        ", ".join(
            parts
        )
        if not parts.is_empty()
        else "None"
    )


func _collect_move_effect_texts(
    move_data: Dictionary
) -> Array[String]:
    var result: Array[String] = []
    var seen: Dictionary = {}

    for raw_action: Variant in move_data.get(
        "base_actions",
        []
    ):
        if not raw_action is Dictionary:
            continue

        var action: Dictionary = raw_action
        var text_value: String = String(
            action.get(
                "text",
                action.get(
                    "source_text",
                    ""
                )
            )
        ).strip_edges()

        if (
            not text_value.is_empty()
            and not seen.has(
                text_value
            )
        ):
            seen[text_value] = true
            result.append(
                text_value
            )

    var source_data: Variant = move_data.get(
        "source",
        {}
    )

    if source_data is Dictionary:
        var raw_move_effect_text: Variant = (
            (source_data as Dictionary).get(
                "move_effect_text",
                []
            )
        )

        if raw_move_effect_text is Array:
            for raw_text: Variant in (
                raw_move_effect_text as Array
            ):
                var source_text: String = String(
                    raw_text
                ).strip_edges()

                if (
                    not source_text.is_empty()
                    and not seen.has(
                        source_text
                    )
                ):
                    seen[source_text] = true
                    result.append(
                        source_text
                    )

    for raw_effect: Variant in move_data.get(
        "special_effects",
        []
    ):
        if not raw_effect is Dictionary:
            continue

        var effect: Dictionary = raw_effect
        var trigger: String = String(
            effect.get(
                "trigger",
                ""
            )
        )
        var effect_type: String = String(
            effect.get(
                "effect_type",
                ""
            )
        )

        if (
            trigger == "kyokoro_outcome"
            or effect_type.begins_with(
                "kyokoro."
            )
        ):
            continue

        var text_value: String = String(
            effect.get(
                "source_text",
                effect.get(
                    "text",
                    ""
                )
            )
        ).strip_edges()

        if (
            not text_value.is_empty()
            and not seen.has(
                text_value
            )
        ):
            seen[text_value] = true
            result.append(
                text_value
            )

    return result


func _append_charakoro_groups(
    box: VBoxContainer,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    if trigger_groups.is_empty():
        if not fallback_detail.is_empty():
            if box.get_child_count() > 0:
                var separator: HSeparator = HSeparator.new()
                box.add_child(
                    separator
                )

            var detail_title: Label = Label.new()
            detail_title.text = "Details"
            detail_title.modulate.a = 0.78
            box.add_child(
                detail_title
            )

            var detail_label: Label = Label.new()
            detail_label.text = fallback_detail
            detail_label.autowrap_mode = (
                TextServer.AUTOWRAP_WORD_SMART
            )
            detail_label.add_theme_font_size_override(
                "font_size",
                16
            )
            box.add_child(
                detail_label
            )
        return

    if box.get_child_count() > 0:
        var separator: HSeparator = HSeparator.new()
        box.add_child(
            separator
        )

    for index: int in range(
        trigger_groups.size()
    ):
        var raw_group: Variant = (
            trigger_groups[index]
        )

        if not raw_group is Dictionary:
            continue

        var group: Dictionary = raw_group
        var orientations: Array = group.get(
            "orientations",
            []
        )
        var effect_text: String = String(
            group.get(
                "effect_text",
                ""
            )
        )

        if index > 0:
            var group_separator: HSeparator = HSeparator.new()
            box.add_child(
                group_separator
            )

        var trigger_title: Label = Label.new()
        trigger_title.text = (
            LocalizationService.tr_key(
                "move_popup.charakoro_trigger",
                "Charakoro Trigger"
            )
            if trigger_groups.size() == 1
            else LocalizationService.tr_format(
                "move_popup.charakoro_trigger_index",
                {"index": index + 1},
                "Charakoro Trigger {index}"
            )
        )
        trigger_title.modulate.a = 0.78
        box.add_child(
            trigger_title
        )

        if not orientations.is_empty():
            var icon_row: HBoxContainer = HBoxContainer.new()
            icon_row.add_theme_constant_override(
                "separation",
                8
            )
            box.add_child(
                icon_row
            )

            for raw_orientation: Variant in orientations:
                var orientation: StringName = StringName(
                    raw_orientation
                )
                var texture: Texture2D = (
                    ICONS.load_kyokoro_icon(
                        orientation
                    )
                )

                if texture == null:
                    continue

                var icon_box: VBoxContainer = VBoxContainer.new()
                icon_box.custom_minimum_size = Vector2(
                    58,
                    0
                )

                var icon: TextureRect = TextureRect.new()
                icon.texture = texture
                icon.custom_minimum_size = Vector2(
                    48,
                    48
                )
                icon.expand_mode = (
                    TextureRect.EXPAND_IGNORE_SIZE
                )
                icon.stretch_mode = (
                    TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                )
                icon_box.add_child(
                    icon
                )

                var orientation_label: Label = Label.new()
                orientation_label.text = LocalizationService.tr_key(
                    "orientation." + String(orientation),
                    String(orientation).replace("_", " ")
                )
                orientation_label.horizontal_alignment = (
                    HORIZONTAL_ALIGNMENT_CENTER
                )
                orientation_label.add_theme_font_size_override(
                    "font_size",
                    11
                )
                orientation_label.modulate.a = 0.72
                icon_box.add_child(
                    orientation_label
                )

                icon_row.add_child(
                    icon_box
                )

        var effect_title: Label = Label.new()
        effect_title.text = LocalizationService.tr_key(
            "move_popup.charakoro_effect",
            "Charakoro Effect"
        )
        effect_title.modulate.a = 0.78
        box.add_child(
            effect_title
        )

        var effect_label: Label = Label.new()
        effect_label.text = (
            effect_text
            if not effect_text.is_empty()
            else LocalizationService.tr_key(
                "move_popup.effect_unavailable",
                "Effect data unavailable."
            )
        )
        effect_label.autowrap_mode = (
            TextServer.AUTOWRAP_WORD_SMART
        )
        effect_label.add_theme_font_size_override(
            "font_size",
            16
        )
        box.add_child(
            effect_label
        )


func setup(
    move_name: String,
    trigger_groups: Array,
    fallback_detail: String
) -> void:
    _build_panel_style()

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override(
        "separation",
        9
    )
    add_child(
        box
    )

    _add_title(
        box,
        move_name
    )
    _append_charakoro_groups(
        box,
        trigger_groups,
        fallback_detail
    )


func clamp_to_dialog_height(
    maximum_height: float
) -> void:
    if maximum_height <= 0.0:
        return

    var scroll: ScrollContainer = null
    var content: Control = null

    if (
        get_child_count() > 0
        and get_child(0) is ScrollContainer
    ):
        scroll = get_child(0) as ScrollContainer

    if (
        scroll != null
        and scroll.get_child_count() > 0
        and scroll.get_child(0) is Control
    ):
        content = scroll.get_child(0) as Control

    var natural_content_height: float = 180.0

    if content != null:
        natural_content_height = max(
            1.0,
            content.get_combined_minimum_size().y
        )

    # Panel top/bottom content margins are 12px each. Add a little extra
    # breathing room so the last line is never clipped against the border.
    var panel_padding: float = 32.0
    var desired_height: float = min(
        natural_content_height + panel_padding,
        maximum_height
    )
    desired_height = max(
        desired_height,
        180.0
    )

    custom_minimum_size.y = desired_height

    if scroll != null:
        scroll.custom_minimum_size.y = max(
            120.0,
            desired_height - panel_padding
        )
