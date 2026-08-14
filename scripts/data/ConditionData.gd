extends RefCounted
var condition_type: StringName = &""
var parameters: Dictionary = {}
var child_conditions: Array = []
func _init(type_id: StringName = &"", condition_parameters: Dictionary = {}) -> void:
	condition_type = type_id
	parameters = condition_parameters.duplicate(true)
func get_orientations() -> Array[StringName]:
	var result: Array[StringName] = []
	if condition_type != &"kyokoro_orientation_any": return result
	var raw: Variant = parameters.get("orientations", [])
	if not raw is Array: return result
	for item: Variant in raw:
		if item is String: result.append(StringName(item))
	return result
