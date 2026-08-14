extends RefCounted
var condition: Variant = null
var actions: Array = []
var raw_text: String = ""
func contains_orientation(orientation: StringName) -> bool:
	if condition == null: return false
	return _contains(condition, orientation)
func get_all_orientations() -> Array[StringName]:
	var result: Array[StringName] = []
	if condition != null: _collect(condition, result)
	return result
func _contains(current: Variant, orientation: StringName) -> bool:
	if current == null: return false
	if StringName(current.condition_type) == &"kyokoro_orientation_any":
		return current.get_orientations().has(orientation)
	for child: Variant in current.child_conditions:
		if _contains(child, orientation): return true
	return false
func _collect(current: Variant, result: Array[StringName]) -> void:
	if current == null: return
	if StringName(current.condition_type) == &"kyokoro_orientation_any":
		for orientation: StringName in current.get_orientations():
			if not result.has(orientation): result.append(orientation)
	for child: Variant in current.child_conditions: _collect(child, result)
