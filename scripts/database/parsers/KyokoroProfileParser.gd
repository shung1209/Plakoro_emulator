extends RefCounted
const PROFILE_DATA: Script = preload("res://scripts/data/KyokoroProfileData.gd")
static func parse(data: Dictionary, source_path: String, reference_data: Variant) -> Variant:
	var id: StringName = StringName(data.get("id", ""))
	if id == &"": return null
	var result: Variant = PROFILE_DATA.new(); result.id = id; result.roll_mode = StringName(data.get("roll_mode", "weighted")); result.scene_path = String(data.get("scene_path", ""))
	var physics: Variant = data.get("physics_profile", {}); var weights: Variant = data.get("orientation_weights", {})
	if not physics is Dictionary or not weights is Dictionary: return null
	result.physics_profile = (physics as Dictionary).duplicate(true)
	for key: Variant in (weights as Dictionary).keys():
		var orientation: StringName = StringName(key); var weight: Variant = (weights as Dictionary)[key]
		if not reference_data.has_kyokoro_orientation(orientation) or (not weight is int and not weight is float) or float(weight) < 0.0: return null
		result.orientation_weights[orientation] = float(weight)
	if not result.has_all_orientations(reference_data.get_orientation_ids()) or result.get_total_weight() <= 0.0: return null
	return result
