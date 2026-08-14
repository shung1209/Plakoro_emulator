extends RefCounted


const TEAM_BUILDER_SERVICE: Script = preload(
	"res://scripts/team_builder/TeamBuilderService.gd"
)


var database: Node
var rules: Dictionary = {}
var rng: RandomNumberGenerator


func _init(
	database_service: Node,
	team_builder_rules: Dictionary,
	random_seed: int = 2026
) -> void:
	database = database_service
	rules = team_builder_rules.duplicate(true)

	rng = RandomNumberGenerator.new()
	rng.seed = random_seed


func build_random_loadout() -> Variant:
	var pokemon_ids: Array = database.pokemon.keys()

	if pokemon_ids.is_empty():
		push_error(
			"AI Team Builder: no Pokémon are available."
		)
		return null

	var selected_pokemon_id: StringName = StringName(
		pokemon_ids[
			rng.randi_range(
				0,
				pokemon_ids.size() - 1
			)
		]
	)

	return build_for_pokemon(
		selected_pokemon_id
	)


func build_for_pokemon(
	pokemon_id: StringName
) -> Variant:
	var service: Variant = TEAM_BUILDER_SERVICE.new(
		database,
		rules
	)
	var loadout: Variant = service.create_empty_loadout(
		&"ai"
	)

	if not service.set_pokemon(
		loadout,
		pokemon_id
	):
		return null

	var move_candidates: Array = (
		loadout.pokemon_data
		.available_move_cards.duplicate()
	)

	_shuffle_array(move_candidates)

	var selected_move_names: Dictionary = {}
	var required_move_count: int = int(
		rules.get(
			"required_selected_move_cards",
			4
		)
	)

	for card: Variant in move_candidates:
		var move_name_id: StringName = StringName(
			card.move_name_id
		)

		if selected_move_names.has(
			move_name_id
		):
			continue

		if service.select_move_card(
			loadout,
			StringName(card.id)
		):
			selected_move_names[move_name_id] = true

		if (
			loadout.selected_move_cards.size()
			>= required_move_count
		):
			break

	if (
		loadout.selected_move_cards.size()
		!= required_move_count
	):
		push_error(
			"AI Team Builder: Pokémon '%s' does not have enough unique move names."
			% String(pokemon_id)
		)
		return null

	var energy_priority: Array[StringName] = (
		_collect_energy_priority(
			loadout.selected_move_cards
		)
	)

	if not _assign_energy_dice(
		service,
		loadout,
		energy_priority
	):
		return null

	if not service.validate_loadout(loadout):
		return null

	return loadout


func _collect_energy_priority(
	selected_cards: Array
) -> Array[StringName]:
	var usage_count: Dictionary = {}

	for card: Variant in selected_cards:
		for cost: Variant in card.energy_costs:
			var energy_type: StringName = StringName(
				cost.energy_type
			)

			usage_count[energy_type] = (
				int(
					usage_count.get(
						energy_type,
						0
					)
				)
				+ int(cost.count)
			)

	var result: Array[StringName] = []

	while not usage_count.is_empty():
		var best_energy: StringName = &""
		var best_count: int = -1

		for raw_energy: Variant in usage_count.keys():
			var energy_type: StringName = StringName(
				raw_energy
			)
			var count: int = int(
				usage_count[raw_energy]
			)

			if count > best_count:
				best_energy = energy_type
				best_count = count

		result.append(best_energy)
		usage_count.erase(best_energy)

	return result


func _assign_energy_dice(
	service: Variant,
	loadout: Variant,
	priority: Array[StringName]
) -> bool:
	var all_energy_types: Array[StringName] = []

	for raw_energy: Variant in (
		database.reference_data.energy_types.keys()
	):
		all_energy_types.append(
			StringName(raw_energy)
		)

	_shuffle_array(all_energy_types)

	var selected: Array[StringName] = []

	for energy_type: StringName in priority:
		if not selected.has(energy_type):
			selected.append(energy_type)

	for energy_type: StringName in all_energy_types:
		if not selected.has(energy_type):
			selected.append(energy_type)

	var required_unique_count: int = int(
		rules.get(
			"required_unique_fixed_energy_count",
			6
		)
	)

	if selected.size() < required_unique_count:
		push_error(
			"AI Team Builder: not enough distinct energy types."
		)
		return false

	for die_index: int in range(3):
		var energy_a: StringName = selected[
			die_index * 2
		]
		var energy_b: StringName = selected[
			die_index * 2 + 1
		]

		if not service.set_energy_die(
			loadout,
			die_index,
			energy_a,
			energy_b
		):
			return false

	return true


func _shuffle_array(array: Array) -> void:
	for index: int in range(
		array.size() - 1,
		0,
		-1
	):
		var swap_index: int = rng.randi_range(
			0,
			index
		)

		var temporary: Variant = array[index]
		array[index] = array[swap_index]
		array[swap_index] = temporary
