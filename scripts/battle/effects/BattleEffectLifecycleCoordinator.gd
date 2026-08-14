extends RefCounted


const TIMING_NEXT_OWNER_TURN: StringName = &"next_owner_turn"
const TIMING_NEXT_OWNER_MOVE: StringName = &"next_owner_move"
const TIMING_NEXT_OWNER_ROLL: StringName = &"next_owner_roll"
const TIMING_NEXT_INCOMING_ATTACK: StringName = &"next_incoming_attack"
const TIMING_WHEN_TRIGGERED: StringName = &"when_triggered"


static func begin_owner_turn(
    participant: Variant,
    turn_number: int
) -> Dictionary:
    return _consume_matching_timing(
        participant,
        TIMING_NEXT_OWNER_TURN,
        turn_number,
        false
    )


static func begin_owner_move(
    participant: Variant,
    turn_number: int
) -> Dictionary:
    return _consume_matching_timing(
        participant,
        TIMING_NEXT_OWNER_MOVE,
        turn_number,
        false
    )


static func begin_owner_roll(
    participant: Variant,
    turn_number: int
) -> Dictionary:
    return _consume_matching_timing(
        participant,
        TIMING_NEXT_OWNER_ROLL,
        turn_number,
        false
    )


static func begin_incoming_attack(
    participant: Variant,
    turn_number: int
) -> Dictionary:
    return _consume_matching_timing(
        participant,
        TIMING_NEXT_INCOMING_ATTACK,
        turn_number,
        false
    )


static func consume_when_triggered(
    participant: Variant,
    effect_type: StringName,
    turn_number: int,
    metadata_key: String = "",
    metadata_value: Variant = null
) -> Dictionary:
    if (
        participant == null
        or participant.effect_container == null
    ):
        return _empty_report(
            TIMING_WHEN_TRIGGERED,
            turn_number
        )

    var consumed_ids: Array[StringName] = []

    for effect: Variant in (
        participant.effect_container.get_by_type(
            effect_type
        )
    ):
        if StringName(
            effect.consume_timing
        ) != TIMING_WHEN_TRIGGERED:
            continue

        if (
            not metadata_key.is_empty()
            and effect.metadata.get(
                metadata_key,
                null
            ) != metadata_value
        ):
            continue

        var effect_id: StringName = StringName(
            effect.id
        )

        if effect.consume_once():
            consumed_ids.append(
                effect_id
            )

    participant.effect_container.get_all()

    return {
        "timing": TIMING_WHEN_TRIGGERED,
        "turn_number": turn_number,
        "consumed": not consumed_ids.is_empty(),
        "consumed_ids": consumed_ids
    }


static func tick_owner_turn_duration(
    participant: Variant,
    completed_turn_number: int
) -> Dictionary:
    if (
        participant == null
        or participant.effect_container == null
    ):
        return {
            "ticked": false,
            "ticked_ids": [],
            "expired_ids": []
        }

    return participant.effect_container.tick_owner_turn(
        completed_turn_number
    )


static func _consume_matching_timing(
    participant: Variant,
    timing: StringName,
    turn_number: int,
    include_empty_timing: bool
) -> Dictionary:
    if (
        participant == null
        or participant.effect_container == null
    ):
        return _empty_report(
            timing,
            turn_number
        )

    var consumed_ids: Array[StringName] = []

    for effect: Variant in (
        participant.effect_container.get_active()
    ):
        var actual_timing: StringName = StringName(
            effect.consume_timing
        )

        if (
            actual_timing != timing
            and not (
                include_empty_timing
                and actual_timing == &""
            )
        ):
            continue

        var effect_id: StringName = StringName(
            effect.id
        )

        if effect.consume_once():
            consumed_ids.append(
                effect_id
            )

    participant.effect_container.get_all()

    return {
        "timing": timing,
        "turn_number": turn_number,
        "consumed": not consumed_ids.is_empty(),
        "consumed_ids": consumed_ids
    }


static func _empty_report(
    timing: StringName,
    turn_number: int
) -> Dictionary:
    return {
        "timing": timing,
        "turn_number": turn_number,
        "consumed": false,
        "consumed_ids": []
    }
