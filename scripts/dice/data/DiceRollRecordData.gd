extends RefCounted


var random_seed: int = 0
var roll_index: int = 0

var energy_die_ids: Array = []
var energy_die_face_ids: Array = []
var energy_counts: Dictionary = {}

var kyokoro_profile_id: StringName = &""
var kyokoro_orientation: StringName = &""
