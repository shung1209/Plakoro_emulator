extends RefCounted


const NORMAL: Color = Color(
    0.90,
    0.93,
    0.98,
    1.0
)

const PLAYER_TURN: Color = Color(
    0.55,
    0.82,
    1.00,
    1.0
)

const AI_TURN: Color = Color(
    0.95,
    0.72,
    0.34,
    1.0
)

const SUCCESS: Color = Color(
    0.38,
    0.90,
    0.56,
    1.0
)

const FAILURE: Color = Color(
    0.96,
    0.42,
    0.42,
    1.0
)


static func show_normal(
    label: Label,
    text: String
) -> void:
    _apply(
        label,
        text,
        NORMAL
    )


static func show_player(
    label: Label,
    text: String
) -> void:
    _apply(
        label,
        text,
        PLAYER_TURN
    )


static func show_ai(
    label: Label,
    text: String
) -> void:
    _apply(
        label,
        text,
        AI_TURN
    )


static func show_success(
    label: Label,
    text: String
) -> void:
    _apply(
        label,
        text,
        SUCCESS
    )


static func show_failure(
    label: Label,
    text: String
) -> void:
    _apply(
        label,
        text,
        FAILURE
    )


static func _apply(
    label: Label,
    text: String,
    color: Color
) -> void:
    if label == null:
        return

    label.text = text
    label.add_theme_color_override(
        "font_color",
        color
    )
