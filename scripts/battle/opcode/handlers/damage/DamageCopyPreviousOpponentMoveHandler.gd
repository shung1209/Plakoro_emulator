extends "res://scripts/battle/opcode/OpcodeHandler.gd"


func get_opcode() -> StringName:
    return &"damage.copy_previous_opponent_move"


func compile(
    _action: Variant,
    context: Variant
) -> bool:
    if (
        context == null
        or context.battle_state == null
        or context.actor == null
        or context.damage_context == null
    ):
        return false

    var record: Variant = (
        context.battle_state
        .get_previous_opponent_record_for(
            StringName(
                context.actor.id
            )
        )
    )

    if (
        record == null
        or not bool(
            record.had_printed_damage
        )
    ):
        context.damage_context.base_damage = 0
        context.log(
            "No previous opponent printed damage is available to copy."
        )
        return true

    # Reflection copies the opponent card's printed attack damage. Charakoro
    # bonuses/effects from that old attack are intentionally not copied.
    context.damage_context.base_damage = max(
        int(
            record.printed_damage
        ),
        0
    )

    context.log(
        "Copied previous opponent printed damage: %d."
        % int(
            record.printed_damage
        )
    )
    return true
