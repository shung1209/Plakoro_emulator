extends RefCounted


const EFFECT_STATE_DATA: Script = preload(
    "res://scripts/battle/effects/BattleEffectStateData.gd"
)
const LIFECYCLE: Script = preload(
    "res://scripts/battle/effects/BattleEffectLifecycleService.gd"
)


var _effects: Array = []
var _next_effect_number: int = 1


func add_effect_from_payload(
    source_participant_id: StringName,
    target_participant_id: StringName,
    payload: Dictionary
) -> Variant:
    var validation: Dictionary = (
        LIFECYCLE.validate_payload(
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
            "BattleEffectContainerData: invalid effect payload: "
            + "; ".join(
                validation.get(
                    "errors",
                    []
                )
            )
        )
        return null

    var effect: Variant = EFFECT_STATE_DATA.new()

    effect.id = StringName(
        payload.get(
            "id",
            "battle_effect_%d"
            % _next_effect_number
        )
    )
    _next_effect_number += 1

    effect.effect_type = StringName(
        payload.get(
            "effect_type",
            ""
        )
    )
    effect.source_participant_id = (
        source_participant_id
    )
    effect.target_participant_id = (
        target_participant_id
    )
    effect.source_move_id = StringName(
        payload.get(
            "source_move_id",
            ""
        )
    )
    effect.target_move_id = StringName(
        payload.get(
            "target_move_id",
            ""
        )
    )
    effect.value = int(
        payload.get(
            "value",
            0
        )
    )
    effect.remaining_uses = int(
        payload.get(
            "remaining_uses",
            1
        )
    )
    effect.duration_turns = int(
        payload.get(
            "duration_turns",
            0
        )
    )
    effect.duration_scope = StringName(
        payload.get(
            "duration_scope",
            ""
        )
    )
    effect.consume_timing = StringName(
        payload.get(
            "consume_timing",
            ""
        )
    )
    effect.created_turn_number = int(
        payload.get(
            "created_turn_number",
            0
        )
    )
    effect.activate_after_turn_number = int(
        payload.get(
            "activate_after_turn_number",
            effect.created_turn_number
        )
    )
    effect.display_text = String(
        payload.get(
            "display_text",
            ""
        )
    )

    var raw_metadata: Variant = payload.get(
        "metadata",
        {}
    )

    if raw_metadata is Dictionary:
        effect.metadata = (
            raw_metadata as Dictionary
        ).duplicate(
            true
        )

    _effects.append(
        effect
    )
    return effect


func get_all() -> Array:
    _remove_expired()
    return _effects.duplicate()


func get_active() -> Array:
    var result: Array = []

    for effect: Variant in get_all():
        if effect.is_active():
            result.append(
                effect
            )

    return result


func get_active_for_turn(
    turn_number: int
) -> Array:
    var result: Array = []

    for effect: Variant in get_active():
        if effect.can_activate_in_turn(
            turn_number
        ):
            result.append(
                effect
            )

    return result


func get_by_type(
    effect_type: StringName
) -> Array:
    var result: Array = []

    for effect: Variant in get_active():
        if StringName(
            effect.effect_type
        ) == effect_type:
            result.append(
                effect
            )

    return result


func find_first(
    effect_type: StringName,
    metadata_key: String = "",
    metadata_value: Variant = null
) -> Variant:
    for effect: Variant in get_by_type(
        effect_type
    ):
        if metadata_key.is_empty():
            return effect

        if effect.metadata.get(
            metadata_key,
            null
        ) == metadata_value:
            return effect

    return null


func get_for_timing(
    timing: StringName
) -> Array:
    var result: Array = []

    for effect: Variant in get_active():
        if LIFECYCLE.timing_matches(
            effect,
            timing
        ):
            result.append(
                effect
            )

    return result


func consume_one(
    effect_type: StringName,
    timing: StringName = &"",
    metadata_key: String = "",
    metadata_value: Variant = null
) -> Dictionary:
    for effect: Variant in get_by_type(
        effect_type
    ):
        if not LIFECYCLE.timing_matches(
            effect,
            timing
        ):
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

        if not effect.consume_once():
            continue

        _remove_expired()

        return {
            "consumed": true,
            "effect_id": effect_id,
            "effect_type": effect_type,
            "timing": timing
        }

    return {
        "consumed": false,
        "effect_id": &"",
        "effect_type": effect_type,
        "timing": timing
    }


func expire_by_id(
    effect_id: StringName
) -> bool:
    for effect: Variant in _effects:
        if StringName(
            effect.id
        ) != effect_id:
            continue

        effect.expire()
        _remove_expired()
        return true

    return false


func tick_owner_turn(
    completed_turn_number: int
) -> Dictionary:
    var ticked_ids: Array[StringName] = []
    var expired_ids: Array[StringName] = []

    for effect: Variant in _effects:
        var effect_id: StringName = StringName(
            effect.id
        )

        if effect.tick_owner_turn(
            completed_turn_number
        ):
            ticked_ids.append(
                effect_id
            )

        if effect.is_expired():
            expired_ids.append(
                effect_id
            )

    _remove_expired()

    return {
        "ticked": not ticked_ids.is_empty(),
        "ticked_ids": ticked_ids,
        "expired_ids": expired_ids
    }


func clear() -> void:
    _effects.clear()
    _next_effect_number = 1


func size() -> int:
    _remove_expired()
    return _effects.size()


func _remove_expired() -> void:
    for index: int in range(
        _effects.size() - 1,
        -1,
        -1
    ):
        if _effects[index].is_expired():
            _effects.remove_at(
                index
            )
