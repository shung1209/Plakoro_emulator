extends RefCounted
var id: StringName = &""
var roll_mode: StringName = &"weighted"
var orientation_weights: Dictionary = {}
var scene_path: String = ""
var physics_profile: Dictionary = {}
func get_weight(orientation: StringName) -> float: return float(orientation_weights.get(orientation, 0.0))
func get_total_weight() -> float:
	var total: float = 0.0
	for value: Variant in orientation_weights.values(): total += float(value)
	return total
func has_all_orientations(valid_orientations: Array[StringName]) -> bool:
	for orientation: StringName in valid_orientations:
		if not orientation_weights.has(orientation): return false
	return true
func roll_weighted(rng: RandomNumberGenerator, valid_orientations: Array[StringName]) -> StringName:
	if valid_orientations.is_empty(): return &""
	var total: float = get_total_weight()
	if total <= 0.0: return &""
	var value: float = rng.randf_range(0.0, total)
	var acc: float = 0.0
	for orientation: StringName in valid_orientations:
		acc += get_weight(orientation)
		if value <= acc: return orientation
	return valid_orientations.back()
