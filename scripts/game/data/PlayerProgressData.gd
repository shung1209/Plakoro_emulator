extends RefCounted


const SCHEMA_VERSION: String = "3.3"
const FIRST_VICTORY_MILESTONE: String = "first_victory"
const ENERGY_CATALOG: Script = preload(
	"res://scripts/game/EnergyProgressionCatalog.gd"
)


var total_battles: int = 0
var wins: int = 0
var losses: int = 0
var current_win_streak: int = 0
var best_win_streak: int = 0
var unlocked_milestones: Array[String] = []
var completed_encounter_ids: Array[String] = []
var starter_pokemon_id: StringName = &""
var starter_energy_type: StringName = &""
var unlocked_pokemon_ids: Array[String] = []
var unlocked_move_card_ids: Array[String] = []
var pokemon_levels: Dictionary = {}
var energy_inventory: Dictionary = {}
var pending_energy_choices: Array[Dictionary] = []
var last_winner_participant_id: StringName = &""
var last_played_unix_time: int = 0


func record_battle(outcome: Variant) -> Array[String]:
	var newly_unlocked: Array[String] = []
	total_battles += 1
	last_winner_participant_id = outcome.winner_participant_id
	last_played_unix_time = int(Time.get_unix_time_from_system())

	if outcome.player_won():
		wins += 1
		current_win_streak += 1
		best_win_streak = max(best_win_streak, current_win_streak)

		if not unlocked_milestones.has(FIRST_VICTORY_MILESTONE):
			unlocked_milestones.append(FIRST_VICTORY_MILESTONE)
			newly_unlocked.append(FIRST_VICTORY_MILESTONE)

		var encounter_id: String = String(outcome.encounter_id)
		if not encounter_id.is_empty() and not completed_encounter_ids.has(encounter_id):
			completed_encounter_ids.append(encounter_id)

		var reward_pokemon_id: String = String(outcome.reward_pokemon_id)
		var is_new_pokemon: bool = (
			not reward_pokemon_id.is_empty()
			and not unlocked_pokemon_ids.has(reward_pokemon_id)
		)
		if (
			is_new_pokemon
		):
			unlocked_pokemon_ids.append(reward_pokemon_id)
			pokemon_levels[reward_pokemon_id] = 1
			_add_energy_pack(
				ENERGY_CATALOG.get_new_pokemon_pack(StringName(reward_pokemon_id))
			)
			_queue_level_energy_choice(StringName(reward_pokemon_id), 1)
		for raw_move_id: Variant in outcome.reward_move_card_ids:
			var move_id: String = String(raw_move_id)
			if not move_id.is_empty() and not unlocked_move_card_ids.has(move_id):
				unlocked_move_card_ids.append(move_id)

		var player_pokemon_id: String = String(outcome.player_pokemon_id)
		if not player_pokemon_id.is_empty() and pokemon_levels.has(player_pokemon_id):
			var current_level: int = max(1, int(pokemon_levels[player_pokemon_id]))
			if current_level < ENERGY_CATALOG.MAX_LEVEL:
				var next_level: int = current_level + 1
				pokemon_levels[player_pokemon_id] = next_level
				_queue_level_energy_choice(StringName(player_pokemon_id), next_level)
	else:
		losses += 1
		current_win_streak = 0

	return newly_unlocked


func to_dictionary() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"total_battles": total_battles,
		"wins": wins,
		"losses": losses,
		"current_win_streak": current_win_streak,
		"best_win_streak": best_win_streak,
		"unlocked_milestones": unlocked_milestones.duplicate(),
		"completed_encounter_ids": completed_encounter_ids.duplicate(),
		"starter_pokemon_id": String(starter_pokemon_id),
		"starter_energy_type": String(starter_energy_type),
		"unlocked_pokemon_ids": unlocked_pokemon_ids.duplicate(),
		"unlocked_move_card_ids": unlocked_move_card_ids.duplicate(),
		"pokemon_levels": pokemon_levels.duplicate(true),
		"energy_inventory": energy_inventory.duplicate(true),
		"pending_energy_choices": pending_energy_choices.duplicate(true),
		"last_winner_participant_id": String(last_winner_participant_id),
		"last_played_unix_time": last_played_unix_time
	}


static func from_dictionary(data: Dictionary) -> Variant:
	var result: Variant = new()
	var source_schema: String = String(data.get("schema_version", ""))
	result.total_battles = max(0, int(data.get("total_battles", 0)))
	result.wins = max(0, int(data.get("wins", 0)))
	result.losses = max(0, int(data.get("losses", 0)))
	result.current_win_streak = max(
		0,
		int(data.get("current_win_streak", 0))
	)
	result.best_win_streak = max(
		result.current_win_streak,
		int(data.get("best_win_streak", 0))
	)

	var raw_milestones: Variant = data.get("unlocked_milestones", [])
	if raw_milestones is Array:
		for raw_milestone: Variant in raw_milestones:
			var milestone: String = String(raw_milestone).strip_edges()
			if not milestone.is_empty() and not result.unlocked_milestones.has(milestone):
				result.unlocked_milestones.append(milestone)

	var raw_encounters: Variant = data.get("completed_encounter_ids", [])
	if raw_encounters is Array:
		for raw_encounter_id: Variant in raw_encounters:
			var encounter_id: String = String(raw_encounter_id).strip_edges()
			if not encounter_id.is_empty() and not result.completed_encounter_ids.has(encounter_id):
				result.completed_encounter_ids.append(encounter_id)

	result.starter_pokemon_id = StringName(data.get("starter_pokemon_id", ""))
	result.starter_energy_type = StringName(data.get("starter_energy_type", ""))
	_load_unique_strings(data.get("unlocked_pokemon_ids", []), result.unlocked_pokemon_ids)
	_load_unique_strings(data.get("unlocked_move_card_ids", []), result.unlocked_move_card_ids)
	_load_nonnegative_counts(data.get("pokemon_levels", {}), result.pokemon_levels)
	_load_nonnegative_counts(data.get("energy_inventory", {}), result.energy_inventory)
	var raw_choices: Variant = data.get("pending_energy_choices", [])
	if raw_choices is Array:
		for raw_choice: Variant in raw_choices:
			if raw_choice is Dictionary:
				var choice: Dictionary = (raw_choice as Dictionary).duplicate(true)
				if not String(choice.get("pokemon_id", "")).is_empty():
					result.pending_energy_choices.append(choice)
	result._migrate_energy_progression(source_schema)

	result.last_winner_participant_id = StringName(
		data.get("last_winner_participant_id", "")
	)
	result.last_played_unix_time = max(
		0,
		int(data.get("last_played_unix_time", 0))
	)
	return result


static func create_new_profile(
	starter_id: StringName,
	starter_move_ids: Array[String],
	starter_energy: StringName
) -> Variant:
	var result: Variant = new()
	result.starter_pokemon_id = starter_id
	result.starter_energy_type = starter_energy
	result.unlocked_pokemon_ids.append(String(starter_id))
	result.pokemon_levels[String(starter_id)] = 1
	result.energy_inventory = ENERGY_CATALOG.create_starter_inventory(
		starter_id,
		starter_energy
	)
	for move_id: String in starter_move_ids:
		if not move_id.is_empty() and not result.unlocked_move_card_ids.has(move_id):
			result.unlocked_move_card_ids.append(move_id)
	return result


func claim_energy_choice(
	pokemon_id: StringName,
	level: int,
	energy_type: StringName
) -> bool:
	for index: int in range(pending_energy_choices.size()):
		var choice: Dictionary = pending_energy_choices[index]
		if (
			String(choice.get("pokemon_id", "")) == String(pokemon_id)
			and int(choice.get("level", 0)) == level
			and (choice.get("options", []) as Array).has(String(energy_type))
		):
			energy_inventory[String(energy_type)] = (
				int(energy_inventory.get(String(energy_type), 0)) + 1
			)
			pending_energy_choices.remove_at(index)
			return true
	return false


func _queue_level_energy_choice(pokemon_id: StringName, level: int) -> void:
	var options: Array[String] = ENERGY_CATALOG.get_energy_options(pokemon_id)
	if options.is_empty():
		return
	pending_energy_choices.append({
		"pokemon_id": String(pokemon_id),
		"level": level,
		"options": options.duplicate()
	})


func _add_energy_pack(pack: Dictionary) -> void:
	for raw_energy: Variant in pack.keys():
		var energy: String = String(raw_energy)
		energy_inventory[energy] = (
			int(energy_inventory.get(energy, 0)) + max(0, int(pack[raw_energy]))
		)


func _migrate_energy_progression(source_schema: String) -> void:
	_infer_starter_energy_if_missing()
	if (
		starter_pokemon_id != &""
		and starter_energy_type != &""
		and source_schema != SCHEMA_VERSION
	):
		var old_start: Dictionary = (
			ENERGY_CATALOG.create_starter_inventory(
				starter_pokemon_id,
				starter_energy_type,
				0
			)
			if source_schema == "3.2"
			else ENERGY_CATALOG.BASE_ENERGY_INVENTORY.duplicate(true)
		)
		if source_schema != "3.2":
			old_start[String(starter_energy_type)] = max(
				6,
				int(old_start.get(String(starter_energy_type), 0))
			)
		var migrated: Dictionary = ENERGY_CATALOG.create_starter_inventory(
			starter_pokemon_id,
			starter_energy_type
		)
		for energy: String in ENERGY_CATALOG.ALL_ENERGY_TYPES:
			var earned_after_start: int = max(
				0,
				int(energy_inventory.get(energy, 0))
				- int(old_start.get(energy, 0))
			)
			migrated[energy] = int(migrated.get(energy, 0)) + earned_after_start
		energy_inventory = migrated
	for pokemon_id: String in unlocked_pokemon_ids:
		if not pokemon_levels.has(pokemon_id):
			pokemon_levels[pokemon_id] = 1


func _infer_starter_energy_if_missing() -> void:
	if starter_energy_type != &"" or starter_pokemon_id == &"":
		return
	var options: Array[String] = ENERGY_CATALOG.get_energy_options(starter_pokemon_id)
	if energy_inventory.is_empty():
		if not options.is_empty():
			starter_energy_type = StringName(options[0])
		return
	var best_energy: String = ""
	var best_bonus: int = -1
	for energy: String in options:
		var bonus: int = (
			int(energy_inventory.get(energy, 0))
			- int(ENERGY_CATALOG.BASE_ENERGY_INVENTORY.get(energy, 0))
		)
		if bonus > best_bonus:
			best_bonus = bonus
			best_energy = energy
	if not best_energy.is_empty():
		starter_energy_type = StringName(best_energy)


func has_profile() -> bool:
	return (
		starter_pokemon_id != &""
		and not unlocked_pokemon_ids.is_empty()
		and unlocked_move_card_ids.size() >= 4
	)


static func _load_unique_strings(raw_values: Variant, target: Array[String]) -> void:
	if not raw_values is Array:
		return
	for raw_value: Variant in raw_values:
		var value: String = String(raw_value).strip_edges()
		if not value.is_empty() and not target.has(value):
			target.append(value)


static func _load_nonnegative_counts(raw_values: Variant, target: Dictionary) -> void:
	if not raw_values is Dictionary:
		return
	for raw_key: Variant in raw_values.keys():
		var key: String = String(raw_key).strip_edges()
		if not key.is_empty():
			target[key] = max(0, int(raw_values[raw_key]))
