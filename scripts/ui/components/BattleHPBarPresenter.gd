extends RefCounted


const HEALTHY_COLOR: Color = Color(
    0.28,
    0.82,
    0.47,
    1.0
)

const WARNING_COLOR: Color = Color(
    0.95,
    0.72,
    0.20,
    1.0
)

const DANGER_COLOR: Color = Color(
    0.93,
    0.34,
    0.34,
    1.0
)


static func refresh(
    bar: ProgressBar,
    label: Label,
    current_hp: int,
    max_hp: int,
    animate: bool = false,
    owner: Node = null
) -> Tween:
    if bar == null or label == null:
        return null

    var safe_max: int = max(
        1,
        max_hp
    )
    var safe_current: int = clamp(
        current_hp,
        0,
        safe_max
    )

    bar.max_value = safe_max

    label.text = (
        str(safe_current)
        + " / "
        + str(safe_max)
    )

    _apply_fill_color(
        bar,
        float(safe_current) / float(safe_max)
    )

    if animate and owner != null:
        var tween: Tween = owner.create_tween()
        tween.tween_property(
            bar,
            "value",
            float(safe_current),
            0.28
        ).set_trans(
            Tween.TRANS_QUAD
        ).set_ease(
            Tween.EASE_OUT
        )
        return tween

    bar.value = safe_current
    return null


static func _apply_fill_color(
    bar: ProgressBar,
    ratio: float
) -> void:
    var fill: StyleBoxFlat = StyleBoxFlat.new()

    if ratio <= 0.25:
        fill.bg_color = DANGER_COLOR
    elif ratio <= 0.50:
        fill.bg_color = WARNING_COLOR
    else:
        fill.bg_color = HEALTHY_COLOR

    fill.corner_radius_top_left = 6
    fill.corner_radius_top_right = 6
    fill.corner_radius_bottom_left = 6
    fill.corner_radius_bottom_right = 6

    bar.add_theme_stylebox_override(
        "fill",
        fill
    )
