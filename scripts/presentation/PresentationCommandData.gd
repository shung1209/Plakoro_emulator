extends RefCounted


var command_type: StringName = &""
var payload: Dictionary = {}
var duration: float = 0.0
var blocking: bool = true


func _init(
    type_id: StringName = &"",
    command_payload: Dictionary = {},
    command_duration: float = 0.0,
    is_blocking: bool = true
) -> void:
    command_type = type_id
    payload = command_payload.duplicate(true)
    duration = max(command_duration, 0.0)
    blocking = is_blocking
