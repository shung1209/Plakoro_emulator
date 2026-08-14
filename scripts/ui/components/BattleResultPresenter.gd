extends RefCounted


static func show_result(
    panel: PanelContainer,
    title_label: Label,
    summary_label: Label,
    winner_id: StringName,
    turn_number: int,
    player_damage_dealt: int,
    enemy_damage_dealt: int,
    hp_label: Label = null,
    player_hp: int = 0,
    player_max_hp: int = 0,
    enemy_hp: int = 0,
    enemy_max_hp: int = 0
) -> void:
    if (
        panel == null
        or title_label == null
        or summary_label == null
    ):
        return

    if winner_id == &"player":
        title_label.text = LocalizationService.tr_key(
            "battle.victory",
            "VICTORY"
        )
        title_label.add_theme_color_override(
            "font_color",
            Color(0.36, 0.92, 0.56, 1.0)
        )
    elif winner_id == &"enemy":
        title_label.text = LocalizationService.tr_key(
            "battle.defeat",
            "DEFEAT"
        )
        title_label.add_theme_color_override(
            "font_color",
            Color(0.96, 0.40, 0.40, 1.0)
        )
    else:
        title_label.text = LocalizationService.tr_key(
            "battle.finished",
            "BATTLE FINISHED"
        )

    summary_label.text = LocalizationService.tr_format(
        "battle.result.summary",
        {
            "turn": turn_number,
            "dealt": player_damage_dealt,
            "taken": enemy_damage_dealt
        },
        "Turn Count: {turn}   •   Damage Dealt: {dealt}   •   Damage Taken: {taken}"
    )

    if hp_label != null:
        hp_label.text = LocalizationService.tr_format(
            "battle.result.hp",
            {
                "player_hp": player_hp,
                "player_max": player_max_hp,
                "enemy_hp": enemy_hp,
                "enemy_max": enemy_max_hp
            },
            "YOU  {player_hp} / {player_max} HP   •   AI  {enemy_hp} / {enemy_max} HP"
        )

    panel.visible = true
    panel.modulate.a = 0.0
    panel.scale = Vector2(0.96, 0.96)

    var tween: Tween = panel.create_tween()
    tween.set_parallel(true)
    tween.tween_property(
        panel,
        "modulate:a",
        1.0,
        0.18
    )
    tween.tween_property(
        panel,
        "scale",
        Vector2.ONE,
        0.22
    ).set_trans(
        Tween.TRANS_BACK
    ).set_ease(
        Tween.EASE_OUT
    )
