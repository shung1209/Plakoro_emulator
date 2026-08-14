extends RefCounted
var energy_types: Dictionary = {}
var pokemon_types: Dictionary = {}
var effect_opcodes: Dictionary = {}
var condition_types: Dictionary = {}
var kyokoro_orientations: Dictionary = {}
func has_energy_type(id: StringName) -> bool: return energy_types.has(id)
func has_pokemon_type(id: StringName) -> bool: return pokemon_types.has(id)
func has_opcode(id: StringName) -> bool: return effect_opcodes.has(id)
func has_condition_type(id: StringName) -> bool: return condition_types.has(id)
func has_kyokoro_orientation(id: StringName) -> bool: return kyokoro_orientations.has(id)
func get_orientation_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for key: Variant in kyokoro_orientations.keys(): result.append(StringName(key))
	result.sort()
	return result
