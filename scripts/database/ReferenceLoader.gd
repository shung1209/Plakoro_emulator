extends RefCounted
const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")
const REFERENCE_DATA: Script = preload("res://scripts/data/ReferenceData.gd")
const DIR: String = "res://database/reference"
static func load_all() -> Variant:
	var result: Variant = REFERENCE_DATA.new()
	var energy: Dictionary = JSON_LOADER.load_dictionary(DIR.path_join("energy_types.json"))
	var pokemon: Dictionary = JSON_LOADER.load_dictionary(DIR.path_join("pokemon_types.json"))
	var opcodes: Dictionary = JSON_LOADER.load_dictionary(DIR.path_join("effect_opcodes.json"))
	var conditions: Dictionary = JSON_LOADER.load_dictionary(DIR.path_join("condition_types.json"))
	var orientations: Dictionary = JSON_LOADER.load_dictionary(DIR.path_join("kyokoro_orientations.json"))
	if energy.is_empty() or pokemon.is_empty() or opcodes.is_empty() or conditions.is_empty() or orientations.is_empty(): return null
	result.energy_types = _parse_id_array(energy.get("energy_types", []), "energy_types")
	result.pokemon_types = _parse_id_array(pokemon.get("pokemon_types", []), "pokemon_types")
	result.effect_opcodes = _parse_named(opcodes.get("opcodes", {}), "opcodes")
	result.condition_types = _parse_named(conditions.get("condition_types", {}), "condition_types")
	result.kyokoro_orientations = _parse_id_array(orientations.get("orientations", []), "orientations")
	if result.energy_types.is_empty() or result.pokemon_types.is_empty() or result.effect_opcodes.is_empty() or result.condition_types.is_empty() or result.kyokoro_orientations.is_empty(): return null
	return result
static func _parse_id_array(raw: Variant, field: String) -> Dictionary:
	if not raw is Array:
		push_error("%s must be an Array." % field)
		return {}
	var result: Dictionary = {}
	for item_raw: Variant in raw:
		if not item_raw is Dictionary: return {}
		var item: Dictionary = item_raw as Dictionary
		var id: StringName = StringName(item.get("id", ""))
		if id == &"" or result.has(id): return {}
		result[id] = item.duplicate(true)
	return result
static func _parse_named(raw: Variant, field: String) -> Dictionary:
	if not raw is Dictionary:
		push_error("%s must be an object." % field)
		return {}
	var result: Dictionary = {}
	for key_raw: Variant in (raw as Dictionary).keys():
		var key: StringName = StringName(key_raw)
		var value: Variant = (raw as Dictionary)[key_raw]
		if key == &"" or not value is Dictionary: return {}
		result[key] = (value as Dictionary).duplicate(true)
	return result
