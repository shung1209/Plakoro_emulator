extends RefCounted


const DAMAGE_COLOR: Color = Color(
    1.0,
    0.38,
    0.34,
    1.0
)

const HEAL_COLOR: Color = Color(
    0.35,
    0.92,
    0.55,
    1.0
)

const EFFECT_COLOR: Color = Color(
    0.55,
    0.82,
    1.0,
    1.0
)


static func show_damage(
    root: Control,
    anchor: Control,
    amount: int
) -> void:
    if amount <= 0:
        return

    _show(
        root,
        anchor,
        "-" + str(amount),
        DAMAGE_COLOR,
        28
    )


static func show_heal(
    root: Control,
    anchor: Control,
    amount: int
) -> void:
    if amount <= 0:
        return

    _show(
        root,
        anchor,
        "+" + str(amount),
        HEAL_COLOR,
        26
    )


static func show_effect(
    root: Control,
    anchor: Control,
    text: String
) -> void:
    if text.is_empty():
        return

    _show(
        root,
        anchor,
        text,
        EFFECT_COLOR,
        20
    )


static func _show(
    root: Control,
    anchor: Control,
    text: String,
    color: Color,
    font_size: int
) -> void:
    if root == null or anchor == null:
        return

    var label: Label = Label.new()
    label.text = text
    label.z_index = 100
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override(
        "font_size",
        font_size
    )
    label.add_theme_color_override(
        "font_color",
        color
    )
    label.add_theme_color_override(
        "font_outline_color",
        Color(0.02, 0.02, 0.03, 1.0)
    )
    label.add_theme_constant_override(
        "outline_size",
        5
    )

    root.add_child(label)

    var anchor_rect: Rect2 = anchor.get_global_rect()
    var root_position: Vector2 = root.global_position

    label.position = (
        anchor_rect.get_center()
        - root_position
        - Vector2(26, 20)
    )

    label.modulate.a = 0.0
    label.scale = Vector2(0.82, 0.82)

    var tween: Tween = root.create_tween()
    tween.set_parallel(true)

    tween.tween_property(
        label,
        "modulate:a",
        1.0,
        0.10
    )

    tween.tween_property(
        label,
        "scale",
        Vector2.ONE,
        0.12
    ).set_trans(
        Tween.TRANS_BACK
    ).set_ease(
        Tween.EASE_OUT
    )

    tween.tween_property(
        label,
        "position:y",
        label.position.y - 46.0,
        0.70
    ).set_trans(
        Tween.TRANS_QUAD
    ).set_ease(
        Tween.EASE_OUT
    )

    tween.chain().tween_property(
        label,
        "modulate:a",
        0.0,
        0.18
    )

    tween.chain().tween_callback(
        label.queue_free
    )
