extends RefCounted


const STATUS_EFFECT_DATA: Script = preload(
    "res://scripts/battle/status/StatusEffectData.gd"
)
const STATUS_LIFECYCLE: Script = preload(
    "res://scripts/battle/status/StatusLifecycleService.gd"
)


var _statuses: Array = []
var _next_status_number: int = 1


func add_status_from_payload(
    source_participant_id: StringName,
    payload: Dictionary
) -> Variant:
    var validation: Dictionary = (
        STATUS_LIFECYCLE.validate_payload(
            payload
        )
    )

    if not bool(
        validation.get(
            "success",
            false
        )
    ):
        push_error(
            "StatusContainerData: invalid status payload: "
            + "; ".join(
                validation.get(
                    "errors",
                    []
                )
            )
        )
        return null

    var status: Variant = STATUS_EFFECT_DATA.new()

    status.id = StringName(
        payload.get(
            "id",
            "status_%d" % _next_status_number
        )
    )
    _next_status_number += 1

    status.status_type = StringName(
        payload.get("status_type", "")
    )
    status.source_participant_id = (
        source_participant_id
    )
    status.value = int(
        payload.get("value", 0)
    )
    status.stack_mode = StringName(
        payload.get("stack_mode", "add")
    )
    status.duration_turns = int(
        payload.get("duration_turns", 0)
    )
    status.duration_based = (
        status.duration_turns > 0
    )
    status.duration_scope = StringName(
        payload.get(
            "duration_scope",
            "owner_turn"
        )
    )
    status.created_turn_number = int(
        payload.get(
            "created_turn_number",
            0
        )
    )
    status.remaining_uses = int(
        payload.get("remaining_uses", 1)
    )
    status.timing = StringName(
        payload.get("timing", "")
    )

    var raw_parameters: Variant = payload.get(
        "parameters",
        {}
    )

    if raw_parameters is Dictionary:
        status.parameters = (
            raw_parameters as Dictionary
        ).duplicate(true)

    if status.status_type == &"":
        push_error(
            "StatusContainerData: status_type cannot be empty."
        )
        return null

    _statuses.append(status)
    return status


func get_all() -> Array:
    _remove_expired()
    return _statuses.duplicate()


func get_by_type(
    status_type: StringName
) -> Array:
    _remove_expired()

    var result: Array = []

    for status: Variant in _statuses:
        if StringName(status.status_type) == status_type:
            result.append(status)

    return result


func has_type(
    status_type: StringName
) -> bool:
    return not get_by_type(status_type).is_empty()


func get_additive_value(
    status_type: StringName
) -> int:
    var total: int = 0

    for status: Variant in get_by_type(status_type):
        if StringName(status.stack_mode) == &"add":
            total += int(status.value)
        elif StringName(status.stack_mode) == &"replace":
            total = int(status.value)
        elif StringName(status.stack_mode) == &"max":
            total = max(total, int(status.value))
        elif StringName(status.stack_mode) == &"min":
            total = min(total, int(status.value))

    return total


func find_first(
    status_type: StringName,
    parameter_key: String = "",
    parameter_value: Variant = null
) -> Variant:
    for status: Variant in get_by_type(status_type):
        if parameter_key.is_empty():
            return status

        if (
            status.parameters.get(
                parameter_key,
                null
            )
            == parameter_value
        ):
            return status

    return null


func get_by_type_and_timing(
    status_type: StringName,
    timing: StringName
) -> Array:
    var result: Array = []

    for status: Variant in get_by_type(
        status_type
    ):
        if STATUS_LIFECYCLE.timing_matches(
            status,
            timing
        ):
            result.append(
                status
            )

    return result


func get_additive_value_for_timing(
    status_type: StringName,
    timing: StringName
) -> int:
    var total: int = 0

    for status: Variant in get_by_type_and_timing(
        status_type,
        timing
    ):
        match StringName(status.stack_mode):
            &"add":
                total += int(status.value)
            &"replace":
                total = int(status.value)
            &"max":
                total = max(
                    total,
                    int(status.value)
                )
            &"min":
                total = min(
                    total,
                    int(status.value)
                )

    return total


func consume_statuses_by_type_and_timing(
    status_type: StringName,
    timing: StringName
) -> Dictionary:
    var consumed_ids: Array[StringName] = []
    var total_value: int = 0

    for status: Variant in get_by_type_and_timing(
        status_type,
        timing
    ):
        total_value += int(
            status.value
        )
        consumed_ids.append(
            StringName(
                status.id
            )
        )
        status.consume_use()

    _remove_expired()

    return {
        "consumed": not consumed_ids.is_empty(),
        "status_type": status_type,
        "timing": timing,
        "value": total_value,
        "status_ids": consumed_ids
    }


func consume_one_for_timing(
    status_type: StringName,
    timing: StringName,
    parameter_key: String = "",
    parameter_value: Variant = null
) -> Dictionary:
    for status: Variant in get_by_type_and_timing(
        status_type,
        timing
    ):
        if (
            not parameter_key.is_empty()
            and status.parameters.get(
                parameter_key,
                null
            ) != parameter_value
        ):
            continue

        var status_id: StringName = StringName(
            status.id
        )
        var value: int = int(
            status.value
        )

        status.consume_use()
        _remove_expired()

        return {
            "consumed": true,
            "status_type": status_type,
            "timing": timing,
            "value": value,
            "status_ids": [
                status_id
            ]
        }

    return {
        "consumed": false,
        "status_type": status_type,
        "timing": timing,
        "value": 0,
        "status_ids": []
    }


func consume_statuses_by_type(
    status_type: StringName
) -> void:
    for status: Variant in get_by_type(status_type):
        status.consume_use()

    _remove_expired()


func consume_one(
    status_type: StringName,
    parameter_key: String = "",
    parameter_value: Variant = null
) -> bool:
    var status: Variant = find_first(
        status_type,
        parameter_key,
        parameter_value
    )

    if status == null:
        return false

    status.consume_use()
    _remove_expired()
    return true


func tick_owner_turn(
    completed_turn_number: int
) -> Dictionary:
    var ticked_ids: Array[StringName] = []
    var expired_ids: Array[StringName] = []
    var remaining: Dictionary = {}

    for status: Variant in _statuses:
        var status_id: StringName = StringName(
            status.id
        )

        if status.tick_owner_turn(
            completed_turn_number
        ):
            ticked_ids.append(
                status_id
            )
            remaining[
                String(
                    status_id
                )
            ] = int(
                status.duration_turns
            )

        if status.is_expired():
            expired_ids.append(
                status_id
            )

    _remove_expired()

    return {
        "ticked": not ticked_ids.is_empty(),
        "ticked_ids": ticked_ids,
        "expired_ids": expired_ids,
        "remaining_turns": remaining
    }


func tick_turn() -> void:
    tick_owner_turn(-1)


func remove_expired() -> void:
    _remove_expired()


func clear() -> void:
    _statuses.clear()
    _next_status_number = 1


func size() -> int:
    _remove_expired()
    return _statuses.size()


func _remove_expired() -> void:
    for index: int in range(
        _statuses.size() - 1,
        -1,
        -1
    ):
        if _statuses[index].is_expired():
            _statuses.remove_at(index)
