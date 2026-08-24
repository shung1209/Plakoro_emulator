extends RefCounted


const PLAYER_COLOR: Color = Color(
    0.48,
    0.80,
    1.0,
    1.0
)

const AI_COLOR: Color = Color(
    0.96,
    0.70,
    0.28,
    1.0
)


static func show_turn(
    panel: PanelContainer,
    label: Label,
    turn_number: int,
    participant_id: StringName
) -> void:
    if panel == null or label == null:
        return

    var is_player: bool = (
        participant_id == &"player"
    )

    label.text = LocalizationService.tr_format(
        "battle.turn_banner",
        {
            "turn": turn_number,
            "actor": (
                LocalizationService.tr_key(
                    "battle.player_turn",
                    "PLAYER TURN"
                )
                if is_player
                else LocalizationService.tr_key(
                    "battle.ai_turn",
                    "AI TURN"
                )
            )
        },
        "TURN {turn}   |   {actor}"
    )

    label.add_theme_color_override(
        "font_color",
        PLAYER_COLOR if is_player else AI_COLOR
    )

    # 12.9g Fix 4:
    # Turn Dialog is a persistent state indicator. Never fade or hide it.
    panel.visible = true
    panel.modulate.a = 1.0
