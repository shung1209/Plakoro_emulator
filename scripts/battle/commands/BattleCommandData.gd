extends RefCounted


var command_type: StringName = &""
var source_participant_id: StringName = &""
var target_participant_id: StringName = &""
var payload: Dictionary = {}


func _init(
    type_id: StringName = &"",
    source_id: StringName = &"",
    target_id: StringName = &"",
    command_payload: Dictionary = {}
) -> void:
    command_type = type_id
    source_participant_id = source_id
    target_participant_id = target_id
    payload = command_payload.duplicate(true)
