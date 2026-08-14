extends VBoxContainer


const PLAYER_COLOR: Color = Color(
    0.34,
    0.78,
    1.0,
    1.0
)
const ENEMY_COLOR: Color = Color(
    1.0,
    0.61,
    0.33,
    1.0
)
const SYSTEM_COLOR: Color = Color(
    0.67,
    0.70,
    0.77,
    1.0
)


var technical_mode: bool = false
var _turn_history: Array = []


func set_technical_mode(
    enabled: bool
) -> void:
    technical_mode = enabled
    _rebuild()


func clear_timeline() -> void:
    _turn_history.clear()
    _clear_rendered_timeline()


func add_turn(
    turn: Variant
) -> void:
    if turn == null:
        return

    _turn_history.append(turn)
    _render_turn(turn)


func _rebuild() -> void:
    _clear_rendered_timeline()

    for turn: Variant in _turn_history:
        _render_turn(turn)


func _clear_rendered_timeline() -> void:
    for child: Node in get_children():
        remove_child(child)
        child.queue_free()


func _render_turn(
    turn: Variant
) -> void:
    var turn_panel: PanelContainer = (
        PanelContainer.new()
    )
    turn_panel.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )

    var turn_box: VBoxContainer = (
        VBoxContainer.new()
    )
    turn_box.add_theme_constant_override(
        "separation",
        8
    )
    turn_panel.add_child(turn_box)

    var header: Label = Label.new()
    header.text = _turn_header(turn)
    header.add_theme_font_size_override(
        "font_size",
        18
    )
    header.modulate = (
        PLAYER_COLOR
        if turn.actor_id == &"player"
        else ENEMY_COLOR
    )
    turn_box.add_child(header)

    for entry: Variant in turn.entries:
        if (
            not technical_mode
            and not _is_player_facing_entry(entry)
        ):
            continue

        turn_box.add_child(
            _create_entry_panel(
                entry,
                not technical_mode
            )
        )

    add_child(turn_panel)


func _is_player_facing_entry(
    entry: Variant
) -> bool:
    var entry_type: StringName = StringName(
        entry.entry_type
    )

    return entry_type in [
        &"move",
        &"damage",
        &"status",
        &"effect_lifecycle",
        &"result"
    ]


func _create_entry_panel(
    entry: Variant,
    concise: bool = false
) -> Control:
    var wrapper: PanelContainer = (
        PanelContainer.new()
    )
    wrapper.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )

    var box: VBoxContainer = (
        VBoxContainer.new()
    )
    box.add_theme_constant_override(
        "separation",
        4
    )
    wrapper.add_child(box)

    var title_label: Label = Label.new()
    title_label.text = String(entry.title)
    title_label.add_theme_font_size_override(
        "font_size",
        15
    )
    title_label.modulate = _entry_color(
        StringName(entry.emphasis),
        StringName(entry.actor_id)
    )
    box.add_child(title_label)

    var display_lines: Array[String] = (
        _display_lines(
            entry,
            concise
        )
    )

    for body_line: String in display_lines:
        var line_label: Label = Label.new()
        line_label.text = body_line
        line_label.autowrap_mode = (
            TextServer.AUTOWRAP_WORD_SMART
        )
        line_label.modulate = Color(
            0.91,
            0.92,
            0.95,
            1.0
        )
        box.add_child(line_label)

    return wrapper


func _display_lines(
    entry: Variant,
    concise: bool
) -> Array[String]:
    var lines: Array[String] = []

    for raw_line: Variant in entry.body_lines:
        lines.append(
            String(raw_line)
        )

    if not concise:
        return lines

    var entry_type: StringName = StringName(
        entry.entry_type
    )

    if entry_type == &"damage":
        for line: String in lines:
            if line.begins_with(
                "Final applied damage:"
            ):
                return [
                    line.replace(
                        "Final applied damage:",
                        "Damage:"
                    )
                ]

    return lines


func _entry_color(
    emphasis: StringName,
    actor_id: StringName
) -> Color:
    match emphasis:
        &"damage":
            return Color(
                1.0,
                0.42,
                0.42,
                1.0
            )

        &"success":
            return Color(
                0.39,
                0.85,
                0.52,
                1.0
            )

        &"failure":
            return Color(
                1.0,
                0.42,
                0.42,
                1.0
            )

        &"status":
            return Color(
                0.82,
                0.61,
                1.0,
                1.0
            )

        &"dice":
            return Color(
                1.0,
                0.85,
                0.35,
                1.0
            )

        &"ai":
            return ENEMY_COLOR

        &"actor":
            if actor_id == &"player":
                return PLAYER_COLOR

            return ENEMY_COLOR

        &"result":
            return Color.WHITE

        _:
            return SYSTEM_COLOR


func _turn_header(
    turn: Variant
) -> String:
    var actor_name: String = "AI"

    if turn.actor_id == &"player":
        actor_name = "YOU"

    return (
        "TURN "
        + str(int(turn.turn_number))
        + " — "
        + actor_name
        + " — "
        + String(turn.move_name)
    )
