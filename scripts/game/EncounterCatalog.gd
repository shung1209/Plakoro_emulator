extends RefCounted


const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")
const POKEMON_DIRECTORY: String = "res://database/pokemon"
const DICE_DIRECTORY: String = "res://database/dice_setups"

const POKEMON_ORDER: Array[String] = [
	"bulbasaur_standard",
	"squirtle_standard",
	"charmander_standard",
	"eevee_standard",
	"pikachu_standard",
	"mew_standard",
	"pinsir_eb01_a1",
	"pinsir_eb01_b1",
	"onix_eb01_a1",
	"onix_eb01_b1",
	"grimer_eb01_a1",
	"grimer_eb01_b1",
	"articuno_eb01_a1",
	"articuno_eb01_b1",
	"moltres_eb01_a1",
	"moltres_eb01_b1",
	"zapdos_eb01_a1",
	"zapdos_eb01_b1",
	"gengar_standard",
	"metagross_standard",
	"lucario_standard"
]


static func create_random_order(
	starter_pokemon_id: StringName,
	random_seed: int = 0
) -> Array[String]:
	var ordered_ids: Array[String] = POKEMON_ORDER.duplicate()
	var starter_id: String = String(starter_pokemon_id)
	if ordered_ids.has(starter_id):
		ordered_ids.erase(starter_id)

	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	if random_seed == 0:
		random.randomize()
	else:
		random.seed = random_seed
	for index: int in range(ordered_ids.size() - 1, 0, -1):
		var swap_index: int = random.randi_range(0, index)
		var swap_value: String = ordered_ids[index]
		ordered_ids[index] = ordered_ids[swap_index]
		ordered_ids[swap_index] = swap_value

	# A new save only owns its starter. Keeping that Plakoro away from the
	# opening stages prevents an impossible self-match before another partner
	# has been unlocked.
	if POKEMON_ORDER.has(starter_id):
		ordered_ids.insert(min(3, ordered_ids.size()), starter_id)
	return ordered_ids


static func get_all(
	starter_pokemon_id: StringName = &"",
	saved_order_ids: Array[String] = []
) -> Array[Dictionary]:
	var ordered_ids: Array[String] = (
		saved_order_ids.duplicate()
		if not saved_order_ids.is_empty()
		else POKEMON_ORDER.duplicate()
	)
	if saved_order_ids.is_empty():
		var starter_id: String = String(starter_pokemon_id)
		if ordered_ids.has(starter_id):
			ordered_ids.erase(starter_id)
			ordered_ids.insert(min(3, ordered_ids.size()), starter_id)

	var encounters: Array[Dictionary] = []
	for index: int in ordered_ids.size():
		var encounter: Dictionary = _build_encounter(ordered_ids[index], index + 1)
		if not encounter.is_empty():
			encounters.append(encounter)
	return encounters


static func get_by_id(
	encounter_id: StringName,
	starter_pokemon_id: StringName = &"",
	saved_order_ids: Array[String] = []
) -> Dictionary:
	for encounter: Dictionary in get_all(starter_pokemon_id, saved_order_ids):
		if StringName(encounter.get("id", "")) == encounter_id:
			return encounter.duplicate(true)
	return {}


static func is_unlocked(
	encounter_id: StringName,
	completed_encounter_ids: Array,
	starter_pokemon_id: StringName = &"",
	saved_order_ids: Array[String] = []
) -> bool:
	var encounters: Array[Dictionary] = get_all(
		starter_pokemon_id,
		saved_order_ids
	)
	for index: int in encounters.size():
		if StringName(encounters[index].get("id", "")) != encounter_id:
			continue
		if index == 0:
			return true
		return completed_encounter_ids.has(
			String(encounters[index - 1].get("id", ""))
		)
	return false


static func _build_encounter(pokemon_id: String, stage_number: int) -> Dictionary:
	var pokemon: Dictionary = JSON_LOADER.load_dictionary(
		POKEMON_DIRECTORY.path_join(pokemon_id + ".json")
	)
	if pokemon.is_empty():
		return {}
	var species_id: String = String(pokemon.get("species_id", ""))
	var raw_moves: Variant = pokemon.get("available_move_card_ids", [])
	var reward_move_ids: Array[String] = []
	if raw_moves is Array:
		for raw_move_id: Variant in raw_moves:
			var move_id: String = String(raw_move_id)
			if not move_id.is_empty() and not reward_move_ids.has(move_id):
				reward_move_ids.append(move_id)
	if reward_move_ids.size() < 4:
		return {}
	var selected_move_ids: Array[String] = []
	for index: int in 4:
		selected_move_ids.append(reward_move_ids[index])
	return {
		"id": pokemon_id,
		"stage_number": stage_number,
		"pokemon_id": pokemon_id,
		"species_id": species_id,
		"display_name": String(pokemon.get("display_name", pokemon_id)),
		"variant_label": _variant_label(pokemon_id),
		"difficulty": _difficulty_for_stage(stage_number),
		"dice_path": DICE_DIRECTORY.path_join(species_id + "_default.json"),
		"move_ids": selected_move_ids,
		"reward_move_ids": reward_move_ids
	}


static func _difficulty_for_stage(stage_number: int) -> String:
	if stage_number <= 5:
		return "easy"
	if stage_number <= 12:
		return "normal"
	return "hard"


static func _variant_label(pokemon_id: String) -> String:
	if pokemon_id.ends_with("_a1"):
		return "A"
	if pokemon_id.ends_with("_b1"):
		return "B"
	return ""
