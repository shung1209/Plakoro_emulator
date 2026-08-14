extends RefCounted
const POKEMON_DATA: Script = preload("res://scripts/data/PokemonData.gd")
const WEAKNESS_DATA: Script = preload("res://scripts/data/WeaknessData.gd")
static func parse(data: Dictionary, source_path: String, reference_data: Variant) -> Variant:
	for key: String in ["id", "species_id", "display_name", "pokemon_type", "kyokoro_profile_id"]:
		if not data.has(key) or not data[key] is String or String(data[key]).strip_edges().is_empty(): return null
	var hp: int = int(data.get("max_hp", 0))
	if hp <= 0: return null
	var result: Variant = POKEMON_DATA.new(); result.id = StringName(data["id"]); result.species_id = StringName(data["species_id"]); result.display_name = String(data["display_name"]); result.pokemon_type = StringName(data["pokemon_type"]); result.max_hp = hp; result.kyokoro_profile_id = StringName(data["kyokoro_profile_id"])
	if not reference_data.has_pokemon_type(result.pokemon_type): return null
	var weaknesses: Variant = data.get("weaknesses", [])
	if not weaknesses is Array: return null
	for item_raw: Variant in weaknesses:
		if not item_raw is Dictionary: return null
		var item: Dictionary = item_raw as Dictionary; var attack_type: StringName = StringName(item.get("attack_type", "")); var bonus: int = int(item.get("bonus_damage", 20))
		if attack_type == &"" or bonus < 0 or not reference_data.has_energy_type(attack_type): return null
		var weakness: Variant = WEAKNESS_DATA.new(); weakness.attack_type = attack_type; weakness.bonus_damage = bonus; result.weaknesses.append(weakness)
	var ids: Variant = data.get("available_move_card_ids", [])
	if not ids is Array: return null
	for raw_id: Variant in ids:
		if not raw_id is String: return null
		var card_id: StringName = StringName(raw_id)
		if result.available_move_card_ids.has(card_id): return null
		result.available_move_card_ids.append(card_id)
	return result
