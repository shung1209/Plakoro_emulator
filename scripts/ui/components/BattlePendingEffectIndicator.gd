extends HBoxContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)


func refresh(
    participant: Variant,
    turn_number: int
) -> void:
    _clear_children()

    if (
        participant == null
        or participant.effect_container == null
    ):
        visible = false
        return

    var effects: Array = (
        participant.effect_container.get_active_for_turn(
            turn_number
        )
    )

    if effects.is_empty():
        visible = false
        return

    visible = true
    add_theme_constant_override(
        "separation",
        6
    )

    var anchor_icon: TextureRect = TextureRect.new()
    anchor_icon.custom_minimum_size = Vector2(
        30,
        30
    )
    anchor_icon.expand_mode = (
        TextureRect.EXPAND_IGNORE_SIZE
    )
    anchor_icon.stretch_mode = (
        TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    )
    anchor_icon.texture = ICONS.load_kyokoro_icon(
        &"HEAD_UP"
    )
    anchor_icon.tooltip_text = LocalizationService.tr_key(
        "battle.pending.tooltip",
        "Charakoro pending effects"
    )
    add_child(
        anchor_icon
    )

    for effect: Variant in effects:
        var badge: Button = Button.new()
        badge.custom_minimum_size = Vector2(
            92,
            30
        )
        badge.focus_mode = Control.FOCUS_NONE
        badge.mouse_default_cursor_shape = (
            Control.CURSOR_POINTING_HAND
        )
        badge.text = _badge_text(
            effect
        )
        badge.tooltip_text = _tooltip_text(
            effect
        )
        add_child(
            badge
        )


func _badge_text(
    effect: Variant
) -> String:
    var timing: StringName = StringName(
        effect.consume_timing
    )

    match timing:
        &"next_owner_turn":
            return LocalizationService.tr_key("battle.pending.next_turn", "NEXT TURN")
        &"next_owner_move":
            return LocalizationService.tr_key("battle.pending.next_move", "NEXT MOVE")
        &"next_owner_roll":
            return LocalizationService.tr_key("battle.pending.next_roll", "NEXT ROLL")
        &"next_incoming_attack":
            return LocalizationService.tr_key("battle.pending.next_hit", "NEXT HIT")
        &"when_triggered":
            return LocalizationService.tr_key("battle.pending.pending", "PENDING")
        _:
            if int(effect.duration_turns) > 0:
                return LocalizationService.tr_format(
                    "battle.pending.turns",
                    {
                        "count": int(
                            effect.duration_turns
                        )
                    },
                    "TURN x{count}"
                )

    return LocalizationService.tr_key("battle.pending.active", "ACTIVE")


func _tooltip_text(
    effect: Variant
) -> String:
    var lines: Array[String] = []

    if not String(
        effect.display_text
    ).is_empty():
        lines.append(
            String(
                effect.display_text
            )
        )
    else:
        lines.append(
            String(
                effect.effect_type
            ).replace(
                "_",
                " "
            ).capitalize()
        )

    var source_move_id: String = String(
        effect.source_move_id
    )

    if not source_move_id.is_empty():
        lines.append(
            LocalizationService.tr_format(
                "battle.pending.source_move",
                {"move": source_move_id},
                "Source Move: {move}"
            )
        )

    var target_move_id: String = String(
        effect.target_move_id
    )

    if not target_move_id.is_empty():
        lines.append(
            LocalizationService.tr_format(
                "battle.pending.target_move",
                {"move": target_move_id},
                "Target Move: {move}"
            )
        )

    var timing: String = String(
        effect.consume_timing
    )

    if not timing.is_empty():
        lines.append(
            LocalizationService.tr_format(
                "battle.pending.timing",
                {
                    "timing": timing.replace(
                        "_",
                        " "
                    )
                },
                "Timing: {timing}"
            )
        )

    if int(effect.remaining_uses) >= 0:
        lines.append(
            LocalizationService.tr_format(
                "battle.pending.remaining_uses",
                {
                    "count": int(
                        effect.remaining_uses
                    )
                },
                "Remaining uses: {count}"
            )
        )

    if int(effect.duration_turns) > 0:
        lines.append(
            LocalizationService.tr_format(
                "battle.pending.remaining_turns",
                {
                    "count": int(
                        effect.duration_turns
                    )
                },
                "Remaining turns: {count}"
            )
        )

    return "\n".join(
        lines
    )


func _clear_children() -> void:
    for child: Node in get_children():
        remove_child(
            child
        )
        child.queue_free()
