extends RefCounted


const INCOMING_DAMAGE_MODIFIER: StringName = (
    &"incoming_damage_modifier"
)
const ENERGY_DICE_MODIFIER: StringName = (
    &"energy_dice_modifier"
)
const REPEAT_MOVE_PERMISSION: StringName = (
    &"repeat_move_permission"
)
const WEAKNESS_DISABLE: StringName = (
    &"weakness_disable"
)
const ATTACK_DAMAGE_IMMUNITY: StringName = (
    &"attack_damage_immunity"
)
const MOVE_LOCK: StringName = (
    &"move_lock"
)
const KYOKORO_DISABLE: StringName = (
    &"kyokoro_disable"
)
const KYOKORO_FORCED_ORIENTATION: StringName = (
    &"kyokoro_forced_orientation"
)

const TIMING_NEXT_OWNER_TURN: StringName = (
    &"next_owner_turn"
)
const TIMING_NEXT_INCOMING_ATTACK: StringName = (
    &"next_incoming_attack"
)
const TIMING_NEXT_OWNER_MOVE: StringName = (
    &"next_owner_move"
)


static func consume_incoming_damage_modifier_report(
    participant: Variant
) -> Dictionary:
    var statuses: Array = (
        participant.status_container
        .get_by_type_and_timing(
            INCOMING_DAMAGE_MODIFIER,
            TIMING_NEXT_INCOMING_ATTACK
        )
    )
    var total: int = (
        participant.status_container
        .get_additive_value_for_timing(
            INCOMING_DAMAGE_MODIFIER,
            TIMING_NEXT_INCOMING_ATTACK
        )
    )
    var consumed_ids: Array[StringName] = []

    for status: Variant in statuses:
        if int(status.remaining_uses) < 0:
            continue

        consumed_ids.append(
            StringName(
                status.id
            )
        )
        status.consume_use()

    participant.status_container.remove_expired()

    return {
        "consumed": not statuses.is_empty(),
        "status_type": INCOMING_DAMAGE_MODIFIER,
        "timing": TIMING_NEXT_INCOMING_ATTACK,
        "value": total,
        "status_ids": consumed_ids,
        "persistent": (
            statuses.size()
            > consumed_ids.size()
        )
    }


static func consume_incoming_damage_modifier(
    participant: Variant
) -> int:
    return int(
        consume_incoming_damage_modifier_report(
            participant
        ).get(
            "value",
            0
        )
    )


static func get_energy_dice_modifier(
    participant: Variant
) -> int:
    return (
        participant.status_container
        .get_additive_value_for_timing(
            ENERGY_DICE_MODIFIER,
            TIMING_NEXT_OWNER_TURN
        )
    )


static func consume_energy_dice_modifier_report(
    participant: Variant
) -> Dictionary:
    var statuses: Array = (
        participant.status_container
        .get_by_type_and_timing(
            ENERGY_DICE_MODIFIER,
            TIMING_NEXT_OWNER_TURN
        )
    )
    var total: int = (
        participant.status_container
        .get_additive_value_for_timing(
            ENERGY_DICE_MODIFIER,
            TIMING_NEXT_OWNER_TURN
        )
    )
    var consumed_ids: Array[StringName] = []

    for status: Variant in statuses:
        if int(status.remaining_uses) < 0:
            continue

        consumed_ids.append(
            StringName(
                status.id
            )
        )
        status.consume_use()

    participant.status_container.remove_expired()

    return {
        "consumed": not statuses.is_empty(),
        "status_type": ENERGY_DICE_MODIFIER,
        "timing": TIMING_NEXT_OWNER_TURN,
        "value": total,
        "status_ids": consumed_ids,
        "persistent": (
            statuses.size()
            > consumed_ids.size()
        )
    }


static func consume_energy_dice_modifier(
    participant: Variant
) -> int:
    return int(
        consume_energy_dice_modifier_report(
            participant
        ).get(
            "value",
            0
        )
    )


static func consume_kyokoro_disable_report(
    participant: Variant
) -> Dictionary:
    return (
        participant.status_container
        .consume_one_for_timing(
            KYOKORO_DISABLE,
            TIMING_NEXT_OWNER_TURN
        )
    )


static func consume_kyokoro_disable(
    participant: Variant
) -> bool:
    return bool(
        consume_kyokoro_disable_report(
            participant
        ).get(
            "consumed",
            false
        )
    )


static func consume_forced_kyokoro_orientation(
    participant: Variant
) -> StringName:
    var statuses: Array = (
        participant.status_container.get_by_type_and_timing(
            KYOKORO_FORCED_ORIENTATION,
            TIMING_NEXT_OWNER_TURN
        )
    )
    if statuses.is_empty():
        return &""

    var status: Variant = statuses[0]
    var orientation: StringName = StringName(
        status.parameters.get("orientation", "")
    )
    status.consume_use()
    participant.status_container.remove_expired()
    return orientation


static func has_repeat_permission(
    participant: Variant,
    move_name_id: StringName
) -> bool:
    for status: Variant in (
        participant.status_container
        .get_by_type_and_timing(
            REPEAT_MOVE_PERMISSION,
            TIMING_NEXT_OWNER_TURN
        )
    ):
        if status.parameters.get(
            "move_name_id",
            null
        ) == move_name_id:
            return true

    return false


static func consume_repeat_permission_report(
    participant: Variant,
    move_name_id: StringName
) -> Dictionary:
    return (
        participant.status_container
        .consume_one_for_timing(
            REPEAT_MOVE_PERMISSION,
            TIMING_NEXT_OWNER_TURN,
            "move_name_id",
            move_name_id
        )
    )


static func consume_repeat_permission(
    participant: Variant,
    move_name_id: StringName
) -> bool:
    return bool(
        consume_repeat_permission_report(
            participant,
            move_name_id
        ).get(
            "consumed",
            false
        )
    )


static func has_attack_damage_immunity(
    participant: Variant
) -> bool:
    return not (
        participant.status_container
        .get_by_type_and_timing(
            ATTACK_DAMAGE_IMMUNITY,
            TIMING_NEXT_INCOMING_ATTACK
        )
        .is_empty()
    )


static func is_move_locked(
    participant: Variant,
    move_name_id: StringName
) -> bool:
    for status: Variant in (
        participant.status_container
        .get_by_type_and_timing(
            MOVE_LOCK,
            TIMING_NEXT_OWNER_TURN
        )
    ):
        if status.parameters.get(
            "move_name_id",
            null
        ) == move_name_id:
            return true

    return false


static func consume_weakness_disable_report(
    participant: Variant
) -> Dictionary:
    return (
        participant.status_container
        .consume_one_for_timing(
            WEAKNESS_DISABLE,
            TIMING_NEXT_OWNER_MOVE
        )
    )


static func consume_weakness_disable(
    participant: Variant
) -> bool:
    return bool(
        consume_weakness_disable_report(
            participant
        ).get(
            "consumed",
            false
        )
    )
