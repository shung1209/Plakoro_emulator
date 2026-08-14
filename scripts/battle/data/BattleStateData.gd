extends RefCounted


var player: Variant = null
var enemy: Variant = null

var current_participant_id: StringName = &"player"
var turn_number: int = 1

var is_finished: bool = false
var winner_participant_id: StringName = &""

var battle_log: Array[String] = []
var turn_history: Array = []


func add_turn_history(
    record: Variant
) -> void:
    if record != null:
        turn_history.append(
            record
        )


func get_previous_record_for(
    participant_id: StringName
) -> Variant:
    for index: int in range(
        turn_history.size() - 1,
        -1,
        -1
    ):
        var record: Variant = (
            turn_history[index]
        )

        if (
            record != null
            and StringName(
                record.actor_participant_id
            ) == participant_id
        ):
            return record

    return null


func get_previous_opponent_record_for(
    participant_id: StringName
) -> Variant:
    var opponent_id: StringName = (
        &"enemy"
        if participant_id == &"player"
        else &"player"
    )

    return get_previous_record_for(
        opponent_id
    )


func get_current_participant() -> Variant:
    if current_participant_id == &"player":
        return player

    return enemy


func get_opponent_participant() -> Variant:
    if current_participant_id == &"player":
        return enemy

    return player


func switch_turn() -> void:
    if current_participant_id == &"player":
        current_participant_id = &"enemy"
    else:
        current_participant_id = &"player"

    turn_number += 1
