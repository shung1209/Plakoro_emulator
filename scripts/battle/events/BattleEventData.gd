extends RefCounted


var event_type: StringName = &""
var turn_number: int = 0
var source_participant_id: StringName = &""
var target_participant_id: StringName = &""
var payload: Dictionary = {}


func _init(
    type_id: StringName = &"",
    current_turn: int = 0,
    source_id: StringName = &"",
    target_id: StringName = &"",
    event_payload: Dictionary = {}
) -> void:
    event_type = type_id
    turn_number = current_turn
    source_participant_id = source_id
    target_participant_id = target_id
    payload = event_payload.duplicate(true)
