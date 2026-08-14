extends PanelContainer


enum BadgeKind {
    NEUTRAL,
    SUCCESS,
    WARNING,
    DANGER
}


@onready var label: Label = %Label


func setup(
    text: String,
    kind: BadgeKind = BadgeKind.NEUTRAL
) -> void:
    if not is_node_ready():
        await ready

    label.text = text

    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.set_border_width_all(1)
    style.corner_radius_top_left = 999
    style.corner_radius_top_right = 999
    style.corner_radius_bottom_left = 999
    style.corner_radius_bottom_right = 999
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 4
    style.content_margin_bottom = 4

    match kind:
        BadgeKind.SUCCESS:
            style.bg_color = Color(0.10, 0.25, 0.17, 0.95)
            style.border_color = Color(0.30, 0.75, 0.48, 1.0)
        BadgeKind.WARNING:
            style.bg_color = Color(0.28, 0.22, 0.08, 0.95)
            style.border_color = Color(0.90, 0.68, 0.22, 1.0)
        BadgeKind.DANGER:
            style.bg_color = Color(0.30, 0.10, 0.11, 0.95)
            style.border_color = Color(0.90, 0.35, 0.38, 1.0)
        _:
            style.bg_color = Color(0.09, 0.12, 0.17, 0.95)
            style.border_color = Color(0.30, 0.38, 0.50, 1.0)

    add_theme_stylebox_override(
        "panel",
        style
    )
