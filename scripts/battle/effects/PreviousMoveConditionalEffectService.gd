extends RefCounted


const EFFECT_TYPE: StringName = &"previous_move_outcome_success"
const TIMING_NEXT_OWNER_MOVE: StringName = &"next_owner_move"


static func has_previous_move_success(
    participant: Variant,
    move_name_id: StringName
) -> bool:
    if (
        participant == null
        or participant.effect_container == null
    ):
        return false

    return (
        participant.effect_container.find_first(
            EFFECT_TYPE,
            "move_name_id",
            String(move_name_id)
        )
        != null
    )


static func consume_previous_move_window(
    participant: Variant
) -> Array[StringName]:
    var consumed_ids: Array[StringName] = []

    if (
        participant == null
        or participant.effect_container == null
    ):
        return consumed_ids

    for effect: Variant in participant.effect_container.get_for_timing(
        TIMING_NEXT_OWNER_MOVE
    ):
        if StringName(effect.effect_type) != EFFECT_TYPE:
            continue

        var effect_id: StringName = StringName(effect.id)

        if effect.consume_once():
            consumed_ids.append(effect_id)

    participant.effect_container.get_all()
    return consumed_ids


static func create_from_completed_move(
    participant: Variant,
    move_card: Variant,
    outcome_succeeded: bool,
    turn_number: int
) -> Variant:
    if (
        participant == null
        or participant.effect_container == null
        or move_card == null
        or not outcome_succeeded
    ):
        return null

    return participant.effect_container.add_effect_from_payload(
        StringName(participant.id),
        StringName(participant.id),
        {
            "effect_type": String(EFFECT_TYPE),
            "source_move_id": String(move_card.id),
            "consume_timing": String(TIMING_NEXT_OWNER_MOVE),
            "remaining_uses": 1,
            "created_turn_number": turn_number,
            "activate_after_turn_number": turn_number,
            "display_text": (
                "Previous Move Charakoro outcome succeeded: "
                + String(move_card.display_name)
            ),
            "metadata": {
                "move_name_id": String(move_card.move_name_id),
                "move_card_id": String(move_card.id)
            }
        }
    )


static func rotate_after_move(
    participant: Variant,
    move_card: Variant,
    outcome_succeeded: bool,
    turn_number: int
) -> Dictionary:
    # Old marker must stay active while the current Move resolves.
    # Once resolution is complete, consume the old window and then create the
    # current Move's marker for the participant's next owner Move.
    var consumed_ids: Array[StringName] = (
        consume_previous_move_window(participant)
    )
    var should_create_next_window: bool = (
        outcome_succeeded
        and _has_selected_move_dependency(
            participant,
            StringName(move_card.move_name_id)
        )
    )

    var created: Variant = null
    if should_create_next_window:
        created = create_from_completed_move(
            participant,
            move_card,
            true,
            turn_number
        )

    return {
        "consumed_ids": consumed_ids,
        "created": created != null,
        "created_id": (
            StringName(created.id)
            if created != null
            else &""
        ),
        "created_effect_type": (
            StringName(created.effect_type)
            if created != null
            else &""
        ),
        "created_display_text": (
            String(created.display_text)
            if created != null
            else ""
        )
    }


static func _has_selected_move_dependency(
    participant: Variant,
    completed_move_name_id: StringName
) -> bool:
    if (
        participant == null
        or participant.loadout == null
    ):
        return false

    var selected_moves: Variant = participant.loadout.get(
        "selected_move_cards"
    )

    if not selected_moves is Array:
        return false

    for candidate: Variant in selected_moves:
        if candidate == null:
            continue

        for outcome: Variant in candidate.outcome_rules:
            if outcome == null:
                continue

            if _actions_reference_previous_move(
                outcome.actions,
                completed_move_name_id
            ):
                return true

        if _actions_reference_previous_move(
            candidate.base_actions,
            completed_move_name_id
        ):
            return true

    return false


static func _actions_reference_previous_move(
    actions: Array,
    completed_move_name_id: StringName
) -> bool:
    for action: Variant in actions:
        if action == null:
            continue

        if StringName(action.opcode) == &"condition.if":
            var condition_value: Variant = action.args.get(
                "condition",
                {}
            )

            if condition_value is Dictionary:
                var condition: Dictionary = (
                    condition_value as Dictionary
                )
                if (
                    StringName(
                        condition.get(
                            "type",
                            ""
                        )
                    )
                    == &"previous_self_move_outcome_success"
                    and StringName(
                        condition.get(
                            "move_name_id",
                            ""
                        )
                    )
                    == completed_move_name_id
                ):
                    return true

        if _actions_reference_previous_move(
            action.then_actions,
            completed_move_name_id
        ):
            return true

        if _actions_reference_previous_move(
            action.else_actions,
            completed_move_name_id
        ):
            return true

    return false
