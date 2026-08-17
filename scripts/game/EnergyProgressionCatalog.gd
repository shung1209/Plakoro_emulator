extends RefCounted


const MAX_LEVEL: int = 5
const NEW_POKEMON_ENERGY_COUNT: int = 6
const STARTER_PRIMARY_BONUS: int = 3

const ALL_ENERGY_TYPES: Array[String] = [
	"grass", "fire", "water", "electric", "psychic",
	"fighting", "dark", "steel", "flying"
]

# Legacy/default 24-unit pool. New profiles own three additional primary
# Energy, giving them 27 units to choose from for the 24 Enerkoro slots.
const BASE_ENERGY_INVENTORY: Dictionary = {
	"grass": 3,
	"fire": 3,
	"water": 3,
	"electric": 3,
	"psychic": 3,
	"fighting": 3,
	"dark": 2,
	"steel": 2,
	"flying": 2
}

const SPECIES_ENERGY_OPTIONS: Dictionary = {
	"bulbasaur": ["grass", "dark"],
	"charmander": ["fire", "steel"],
	"squirtle": ["water", "fighting"],
	"eevee": ["fighting", "dark"],
	"pikachu": ["electric", "steel"],
	"mew": ["psychic", "flying"],
	"pinsir": ["grass", "fighting"],
	"onix": ["fighting", "steel"],
	"grimer": ["dark", "psychic"],
	"articuno": ["water", "flying"],
	"moltres": ["fire", "flying"],
	"zapdos": ["electric", "flying"]
}


static func get_energy_options(pokemon_id: StringName) -> Array[String]:
	var species_id: String = _species_from_pokemon_id(String(pokemon_id))
	var raw_options: Variant = SPECIES_ENERGY_OPTIONS.get(species_id, [])
	var result: Array[String] = []
	if raw_options is Array:
		for raw_energy: Variant in raw_options:
			result.append(String(raw_energy))
	return result


static func get_new_pokemon_pack(pokemon_id: StringName) -> Dictionary:
	var options: Array[String] = get_energy_options(pokemon_id)
	if options.is_empty():
		return {}
	var primary: String = options[0]
	var secondary: String = options[1] if options.size() > 1 else primary
	var tertiary_index: int = ALL_ENERGY_TYPES.find(primary) + 1
	var tertiary: String = ALL_ENERGY_TYPES[tertiary_index % ALL_ENERGY_TYPES.size()]
	var result: Dictionary = {}
	_add_to_pack(result, primary, 3)
	_add_to_pack(result, secondary, 2)
	_add_to_pack(result, tertiary, 1)
	return result


static func create_starter_inventory(
	pokemon_id: StringName,
	sixth_energy: StringName,
	primary_bonus: int = STARTER_PRIMARY_BONUS
) -> Dictionary:
	var options: Array[String] = get_energy_options(pokemon_id)
	if options.is_empty() or not options.has(String(sixth_energy)):
		return {}
	var primary: String = options[0]
	var secondary: String = options[1] if options.size() > 1 else primary
	var result: Dictionary = {}
	for energy: String in ALL_ENERGY_TYPES:
		result[energy] = 0
	# Five units always belong to the Pokémon's primary Energy. The player
	# chooses the sixth unit, then receives three more primary Energy so the
	# starting pool can support attacks more consistently.
	result[primary] = 5 + max(0, primary_bonus)
	result[String(sixth_energy)] = int(result[String(sixth_energy)]) + 1

	var support_types: Array[String] = []
	for energy: String in ALL_ENERGY_TYPES:
		if energy != primary and energy != secondary:
			support_types.append(energy)
	# 4×3 + 3×2 = 18 supporting units; the default starter total is 27.
	for index: int in range(support_types.size()):
		result[support_types[index]] = 3 if index < 4 else 2
	return result


static func create_balanced_setup(source_inventory: Dictionary = {}) -> Variant:
	var setup_script: Script = preload(
		"res://scripts/dice/setup/EnergyDiceSetupData.gd"
	)
	var die_script: Script = preload(
		"res://scripts/dice/setup/EnergyDieSetupData.gd"
	)
	var setup: Variant = setup_script.new()
	var inventory: Dictionary = (
		source_inventory.duplicate(true)
		if not source_inventory.is_empty()
		else BASE_ENERGY_INVENTORY.duplicate(true)
	)
	var fixed_values: Array[String] = []
	for energy: String in ALL_ENERGY_TYPES:
		if int(inventory.get(energy, 0)) > 0 and fixed_values.size() < 6:
			fixed_values.append(energy)
			inventory[energy] = int(inventory[energy]) - 1
	var remaining_values: Array[String] = []
	for energy: String in ALL_ENERGY_TYPES:
		for _unit: int in range(max(0, int(inventory.get(energy, 0)))):
			remaining_values.append(energy)
	if fixed_values.size() != 6 or remaining_values.size() < 18:
		return null
	if remaining_values.size() > 18:
		remaining_values = _select_setup_energy_values(inventory, 18)
	for index: int in range(3):
		var die: Variant = die_script.new()
		die.die_id = StringName("player_die_" + str(index + 1))
		die.fixed_a = StringName(fixed_values[index * 2])
		die.fixed_b = StringName(fixed_values[index * 2 + 1])
		var offset: int = index * 6
		die.double_a_first = StringName(remaining_values[offset])
		die.double_a_second = StringName(remaining_values[offset + 1])
		die.double_b_first = StringName(remaining_values[offset + 2])
		die.double_b_second = StringName(remaining_values[offset + 3])
		die.single_a = StringName(remaining_values[offset + 4])
		die.single_b = StringName(remaining_values[offset + 5])
		setup.add_die(die)
	return setup


static func count_setup_energy(setup: Variant) -> Dictionary:
	var result: Dictionary = {}
	if setup == null:
		return result
	for die: Variant in setup.dice:
		for face: Dictionary in die.get_faces_by_orientation().values():
			for raw_energy: Variant in face.get("energies", []):
				var energy: String = String(raw_energy)
				if not energy.is_empty():
					result[energy] = int(result.get(energy, 0)) + 1
	return result


static func validate_inventory(setup: Variant, inventory: Dictionary) -> Dictionary:
	var result: Dictionary = {"success": true, "errors": []}
	var used: Dictionary = count_setup_energy(setup)
	var used_total: int = 0
	for raw_count: Variant in used.values():
		used_total += int(raw_count)
	if used_total < 24:
		result["success"] = false
		result["errors"].append(
			"Enerkoro setup is incomplete: %d Energy slot(s) are empty."
			% (24 - used_total)
		)
	for raw_energy: Variant in used.keys():
		var energy: String = String(raw_energy)
		var used_count: int = int(used[raw_energy])
		var owned_count: int = max(0, int(inventory.get(energy, 0)))
		if used_count > owned_count:
			result["success"] = false
			result["errors"].append(
				"%s Energy: using %d, owned %d." % [
					energy.capitalize(), used_count, owned_count
				]
			)
	return result


static func _species_from_pokemon_id(pokemon_id: String) -> String:
	for species_id: String in SPECIES_ENERGY_OPTIONS.keys():
		if pokemon_id == species_id or pokemon_id.begins_with(species_id + "_"):
			return species_id
	return pokemon_id.get_slice("_", 0)


static func _select_setup_energy_values(
	inventory: Dictionary,
	count: int
) -> Array[String]:
	var energy_types: Array[String] = ALL_ENERGY_TYPES.duplicate()
	energy_types.sort_custom(
		func(a: String, b: String) -> bool:
			var a_count: int = max(0, int(inventory.get(a, 0)))
			var b_count: int = max(0, int(inventory.get(b, 0)))
			if a_count == b_count:
				return ALL_ENERGY_TYPES.find(a) < ALL_ENERGY_TYPES.find(b)
			return a_count > b_count
	)
	var result: Array[String] = []
	for energy: String in energy_types:
		for _unit: int in range(max(0, int(inventory.get(energy, 0)))):
			if result.size() >= count:
				return result
			result.append(energy)
	return result


static func _add_to_pack(pack: Dictionary, energy: String, count: int) -> void:
	pack[energy] = int(pack.get(energy, 0)) + count
