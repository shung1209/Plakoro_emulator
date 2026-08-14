extends RefCounted


var effect_type: StringName = &""
var parameters: Dictionary = {}


func _init(
    type_id: StringName = &"",
    effect_parameters: Dictionary = {}
) -> void:
    effect_type = type_id
    parameters = effect_parameters.duplicate(true)
