extends RefCounted


const SETUP_DATA: Script = preload("res://scripts/dice/setup/EnergyDiceSetupData.gd")
const DIE_DATA: Script = preload("res://scripts/dice/setup/EnergyDieSetupData.gd")
const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")

const BUILTIN_MOVE_DIRECTORY: String = "res://database/move_cards"
const USER_MOVE_DIRECTORY: String = "user://user_database/move_cards"

const VALID_ENERGIES: Array[StringName] = [
	&"grass", &"fire", &"water", &"electric", &"psychic",
	&"fighting", &"dark", &"steel", &"flying"
]
const MAIN_FACE_TARGETS: Dictionary = {&"easy": 3, &"normal": 4, &"hard": 5}
const MOVE_COUNT: int = 4
const GREEN_THRESHOLD: float = 0.60


static func build(
	pokemon: Dictionary,
	difficulty: StringName,
	requested_move_ids: Array = []
) -> Dictionary:
	var level: StringName = difficulty if MAIN_FACE_TARGETS.has(difficulty) else &"normal"
	var candidates: Array[Dictionary] = _load_moves(pokemon, requested_move_ids)
	if candidates.size() < MOVE_COUNT:
		return {"success": false, "errors": ["AI requires four unique Moves."]}

	var combinations: Array = []
	if requested_move_ids.is_empty():
		_collect_combinations(candidates, 0, [], combinations)
	elif candidates.size() == MOVE_COUNT:
		combinations.append(candidates)
	else:
		return {"success": false, "errors": ["AI requires exactly four requested Moves."]}

	var best: Dictionary = {}
	for raw_combination: Variant in combinations:
		var moves: Array = raw_combination
		var main_energy: StringName = _choose_main_energy(pokemon, moves)
		var setup: Variant = _build_dice(pokemon, moves, main_energy, level)
		var evaluation: Dictionary = _evaluate(moves, setup, level)
		evaluation["moves"] = moves
		evaluation["main_energy"] = main_energy
		evaluation["setup"] = setup
		if best.is_empty() or _is_better(evaluation, best):
			best = evaluation

	if best.is_empty():
		return {"success": false, "errors": ["AI strategy generation failed."]}

	var move_ids: Array[StringName] = []
	for raw_move: Variant in best["moves"]:
		move_ids.append(StringName((raw_move as Dictionary).get("id", "")))
	return {
		"success": true,
		"difficulty": level,
		"main_energy": best["main_energy"],
		"main_energy_faces_per_die": MAIN_FACE_TARGETS[level],
		"move_ids": move_ids,
		"energy_dice_setup": best["setup"],
		"move_success_probabilities": best["probabilities"],
		"average_success_probability": best["average_probability"],
		"green_move_count": best["green_count"],
		"errors": []
	}


static func _load_moves(pokemon: Dictionary, requested: Array) -> Array[Dictionary]:
	var allowed: Array[String] = []
	for raw_id: Variant in pokemon.get("available_move_card_ids", []):
		var move_id: String = String(raw_id).strip_edges()
		if not move_id.is_empty() and not allowed.has(move_id):
			allowed.append(move_id)
	var source: Array[String] = allowed
	if not requested.is_empty():
		source = []
		for raw_id: Variant in requested:
			var move_id: String = String(raw_id).strip_edges()
			if allowed.has(move_id) and not source.has(move_id):
				source.append(move_id)

	var result: Array[Dictionary] = []
	var names: Dictionary = {}
	for move_id: String in source:
		var move: Dictionary = _load_move(move_id)
		if move.is_empty():
			continue
		var name_id: String = String(move.get("move_name_id", move_id)).to_lower()
		if names.has(name_id):
			continue
		names[name_id] = true
		result.append(move)
	return result


static func _load_move(move_id: String) -> Dictionary:
	var user_path: String = USER_MOVE_DIRECTORY.path_join(move_id + ".json")
	if FileAccess.file_exists(user_path):
		var user_move: Dictionary = JSON_LOADER.load_dictionary(user_path)
		if not user_move.is_empty():
			return user_move
	return JSON_LOADER.load_dictionary(
		BUILTIN_MOVE_DIRECTORY.path_join(move_id + ".json")
	)


static func _collect_combinations(
	candidates: Array[Dictionary], start: int, current: Array, result: Array
) -> void:
	if current.size() == MOVE_COUNT:
		result.append(current.duplicate())
		return
	var last_start: int = candidates.size() - (MOVE_COUNT - current.size())
	for index: int in range(start, last_start + 1):
		current.append(candidates[index])
		_collect_combinations(candidates, index + 1, current, result)
		current.pop_back()


static func _choose_main_energy(pokemon: Dictionary, moves: Array) -> StringName:
	var usage: Dictionary = _energy_usage(moves)
	var pokemon_type: StringName = StringName(String(pokemon.get("pokemon_type", "")).to_lower())
	var best: StringName = pokemon_type if VALID_ENERGIES.has(pokemon_type) else VALID_ENERGIES[0]
	var best_count: int = int(usage.get(best, 0))
	for energy: StringName in VALID_ENERGIES:
		var count: int = int(usage.get(energy, 0))
		if count > best_count:
			best = energy
			best_count = count
	return best


static func _energy_usage(moves: Array) -> Dictionary:
	var usage: Dictionary = {}
	for raw_move: Variant in moves:
		for raw_cost: Variant in (raw_move as Dictionary).get("energy_cost", []):
			if not raw_cost is Dictionary:
				continue
			var cost: Dictionary = raw_cost
			var energy: StringName = StringName(String(cost.get("energy_type", "")).to_lower())
			if energy == &"normal" or not VALID_ENERGIES.has(energy):
				continue
			usage[energy] = int(usage.get(energy, 0)) + max(int(cost.get("count", 0)), 0)
	return usage


static func _support_priority(moves: Array, main_energy: StringName) -> Array[StringName]:
	var usage: Dictionary = _energy_usage(moves)
	usage.erase(main_energy)
	var result: Array[StringName] = []
	while not usage.is_empty():
		var best: StringName = &""
		var best_count: int = -1
		for raw_energy: Variant in usage:
			var energy: StringName = StringName(raw_energy)
			var count: int = int(usage[raw_energy])
			if count > best_count or (count == best_count and String(energy) < String(best)):
				best = energy
				best_count = count
		result.append(best)
		usage.erase(best)
	for energy: StringName in VALID_ENERGIES:
		if energy != main_energy and not result.has(energy):
			result.append(energy)
	return result


static func _build_dice(
	pokemon: Dictionary, moves: Array, main_energy: StringName, difficulty: StringName
) -> Variant:
	var setup: Variant = SETUP_DATA.new()
	var support: Array[StringName] = _support_priority(moves, main_energy)
	var dynamic_main_count: int = int(MAIN_FACE_TARGETS[difficulty]) - 1
	var species: String = String(pokemon.get("species_id", "ai")).to_lower()
	for die_index: int in 3:
		var die: Variant = DIE_DATA.new()
		die.die_id = StringName(
			"ai_%s_%s_die_%d" % [species, String(difficulty), die_index + 1]
		)
		die.fixed_a = main_energy
		die.fixed_b = support[die_index % support.size()]
		var support_a: StringName = support[(die_index * 2 + 1) % support.size()]
		var support_b: StringName = support[(die_index * 2 + 2) % support.size()]
		var main_faces: Array = [
			[main_energy, main_energy], [main_energy, main_energy],
			[main_energy], [main_energy]
		]
		var other_faces: Array = [
			[support_a, support_b], [support_b, support_a],
			[support_a], [support_b]
		]
		for face_index: int in 4:
			if face_index >= dynamic_main_count:
				main_faces[face_index] = other_faces[face_index]
		die.double_a_first = main_faces[0][0]
		die.double_a_second = main_faces[0][1]
		die.double_b_first = main_faces[1][0]
		die.double_b_second = main_faces[1][1]
		die.single_a = main_faces[2][0]
		die.single_b = main_faces[3][0]
		setup.add_die(die)
	return setup


static func _evaluate(moves: Array, setup: Variant, difficulty: StringName) -> Dictionary:
	var rolls: Array[Dictionary] = _enumerate_rolls(setup)
	var probabilities: Dictionary = {}
	var total: float = 0.0
	var minimum: float = 1.0
	var green_count: int = 0
	var power: float = 0.0
	for raw_move: Variant in moves:
		var move: Dictionary = raw_move
		var probability: float = _success_probability(move, rolls)
		probabilities[String(move.get("id", ""))] = probability
		total += probability
		minimum = min(minimum, probability)
		green_count += 1 if probability >= GREEN_THRESHOLD else 0
		power += _move_power(move)
	var average: float = total / float(max(moves.size(), 1))
	var power_weight: float = {&"easy": 0.15, &"normal": 0.35, &"hard": 0.55}[difficulty]
	var synergy_weight: float = {&"easy": 0.5, &"normal": 1.0, &"hard": 1.3}[difficulty]
	return {
		"score": average * 200.0 + minimum * 80.0 + green_count * 25.0
			+ power * power_weight + _synergy(moves) * synergy_weight,
		"probabilities": probabilities,
		"average_probability": average,
		"minimum_probability": minimum,
		"green_count": green_count,
		"signature": _signature(moves)
	}


static func _move_power(move: Dictionary) -> float:
	var power: float = float(max(_optional_int(move.get("printed_damage", null)), 0))
	for raw_action: Variant in move.get("base_actions", []):
		if not raw_action is Dictionary:
			continue
		var action: Dictionary = raw_action
		var opcode: String = String(action.get("opcode", ""))
		var args: Dictionary = action.get("args", {})
		if opcode == "hp.restore":
			power += abs(int(args.get("amount", 0))) * 0.45
		elif opcode == "incoming_damage.modify":
			power += abs(int(args.get("amount", 0))) * 0.35
		elif opcode == "energy_dice.modify":
			power += abs(int(args.get("amount", 0))) * 5.0
		elif opcode == "move.repeat_permission" or opcode == "weakness.disable":
			power += 8.0
	return power


static func _synergy(moves: Array) -> float:
	var has_attack: bool = false
	var has_defense: bool = false
	var has_energy_setup: bool = false
	var has_expensive: bool = false
	var has_repeat: bool = false
	var highest_damage: int = 0
	for raw_move: Variant in moves:
		var move: Dictionary = raw_move
		var damage: int = max(_optional_int(move.get("printed_damage", null)), 0)
		has_attack = has_attack or damage > 0
		highest_damage = max(highest_damage, damage)
		var total_cost: int = 0
		for raw_cost: Variant in move.get("energy_cost", []):
			if raw_cost is Dictionary:
				total_cost += int((raw_cost as Dictionary).get("count", 0))
		has_expensive = has_expensive or total_cost >= 3
		for raw_action: Variant in move.get("base_actions", []):
			if not raw_action is Dictionary:
				continue
			var action: Dictionary = raw_action
			var opcode: String = String(action.get("opcode", ""))
			var args: Dictionary = action.get("args", {})
			has_defense = has_defense or opcode == "hp.restore" or opcode == "incoming_damage.modify"
			if opcode == "energy_dice.modify":
				var target: String = String(args.get("target", "self"))
				var amount: int = int(args.get("amount", 0))
				has_energy_setup = has_energy_setup or (
					(target == "self" and amount > 0) or (target == "opponent" and amount < 0)
				)
			has_repeat = has_repeat or opcode == "move.repeat_permission"
	var score: float = 0.0
	score += 8.0 if has_attack and has_defense else 0.0
	score += 14.0 if has_energy_setup and has_expensive else 0.0
	score += 10.0 if has_repeat and highest_damage >= 30 else 0.0
	return score


static func _optional_int(value: Variant) -> int:
	if value is int or value is float:
		return int(value)
	return 0


static func _enumerate_rolls(setup: Variant) -> Array[Dictionary]:
	var die_faces: Array = []
	for die: Variant in setup.dice:
		var faces: Array[Dictionary] = []
		for face: Dictionary in die.get_faces_by_orientation().values():
			var counts: Dictionary = {}
			for raw_energy: Variant in face.get("energies", []):
				var energy: StringName = StringName(raw_energy)
				counts[energy] = int(counts.get(energy, 0)) + 1
			faces.append(counts)
		die_faces.append(faces)
	var results: Array[Dictionary] = []
	for a: Dictionary in die_faces[0]:
		for b: Dictionary in die_faces[1]:
			for c: Dictionary in die_faces[2]:
				var combined: Dictionary = {}
				_merge_counts(combined, a)
				_merge_counts(combined, b)
				_merge_counts(combined, c)
				results.append(combined)
	return results


static func _merge_counts(target: Dictionary, source: Dictionary) -> void:
	for energy: Variant in source:
		target[energy] = int(target.get(energy, 0)) + int(source[energy])


static func _success_probability(move: Dictionary, rolls: Array[Dictionary]) -> float:
	var success_count: int = 0
	for counts: Dictionary in rolls:
		if _can_pay(move.get("energy_cost", []), counts):
			success_count += 1
	return float(success_count) / float(max(rolls.size(), 1))


static func _can_pay(raw_costs: Variant, energy_counts: Dictionary) -> bool:
	if not raw_costs is Array:
		return false
	var remaining: Dictionary = energy_counts.duplicate(true)
	var wildcard: int = 0
	for raw_cost: Variant in raw_costs:
		if not raw_cost is Dictionary:
			return false
		var cost: Dictionary = raw_cost
		var energy: StringName = StringName(cost.get("energy_type", ""))
		var required: int = max(int(cost.get("count", 0)), 0)
		if energy == &"normal":
			wildcard += required
			continue
		var available: int = max(int(remaining.get(energy, 0)), 0)
		if available < required:
			return false
		remaining[energy] = available - required
	var remaining_total: int = 0
	for count: Variant in remaining.values():
		remaining_total += max(int(count), 0)
	return remaining_total >= wildcard


static func _is_better(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_score: float = float(candidate["score"])
	var current_score: float = float(current["score"])
	if not is_equal_approx(candidate_score, current_score):
		return candidate_score > current_score
	return String(candidate["signature"]) < String(current["signature"])


static func _signature(moves: Array) -> String:
	var ids: Array[String] = []
	for raw_move: Variant in moves:
		ids.append(String((raw_move as Dictionary).get("id", "")))
	ids.sort()
	return "|".join(ids)
