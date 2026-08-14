extends RefCounted


const LOADOUT_DATA: Script = preload(
	"res://scripts/team_builder/data/PlayerLoadoutData.gd"
)


static func validate_loadout(
	loadout: Variant,
	database: Node,
	rules: Dictionary
) -> bool:
	if loadout == null:
		push_error("Team Builder: loadout cannot be null.")
		return false

	if not _validate_pokemon(
		loadout,
		database
	):
		return false

	if not _validate_move_cards(
		loadout,
		database,
		rules
	):
		return false

	if not _validate_energy_dice(
		loadout,
		database,
		rules
	):
		return false

	return true


static func _validate_pokemon(
	loadout: Variant,
	database: Node
) -> bool:
	if loadout.pokemon_id == &"":
		push_error(
			"Team Builder: pokemon_id cannot be empty."
		)
		return false

	if not database.has_pokemon(
		loadout.pokemon_id
	):
		push_error(
			"Team Builder: unknown Pokémon '%s'."
			% String(loadout.pokemon_id)
		)
		return false

	var expected_pokemon: Variant = (
		database.get_pokemon(
			loadout.pokemon_id
		)
	)

	if loadout.pokemon_data == null:
		push_error(
			"Team Builder: pokemon_data is not resolved."
		)
		return false

	if (
		StringName(loadout.pokemon_data.id)
		!= StringName(expected_pokemon.id)
	):
		push_error(
			"Team Builder: pokemon_data does not match pokemon_id."
		)
		return false

	return true


static func _validate_move_cards(
	loadout: Variant,
	database: Node,
	rules: Dictionary
) -> bool:
	var required_count: int = int(
		rules.get(
			"required_selected_move_cards",
			4
		)
	)

	if (
		loadout.selected_move_card_ids.size()
		!= required_count
	):
		push_error(
			"Team Builder: exactly %d move cards are required."
			% required_count
		)
		return false

	if (
		loadout.selected_move_cards.size()
		!= required_count
	):
		push_error(
			"Team Builder: selected_move_cards were not fully resolved."
		)
		return false

	var used_card_ids: Dictionary = {}
	var used_move_names: Dictionary = {}

	for index: int in range(
		loadout.selected_move_cards.size()
	):
		var card: Variant = (
			loadout.selected_move_cards[index]
		)

		if card == null:
			push_error(
				"Team Builder: selected move card %d is null."
				% index
			)
			return false

		var card_id: StringName = StringName(
			card.id
		)
		var move_name_id: StringName = StringName(
			card.move_name_id
		)

		if used_card_ids.has(card_id):
			push_error(
				"Team Builder: move card '%s' was selected more than once."
				% String(card_id)
			)
			return false

		if used_move_names.has(move_name_id):
			push_error(
				"Team Builder: moves with the same name cannot be selected together: '%s'."
				% String(move_name_id)
			)
			return false

		if not database.has_move_card(card_id):
			push_error(
				"Team Builder: unknown move card '%s'."
				% String(card_id)
			)
			return false

		if not loadout.pokemon_data.has_available_card(
			card_id
		):
			push_error(
				"Team Builder: move card '%s' is not available to Pokémon '%s'."
				% [
					String(card_id),
					String(loadout.pokemon_id)
				]
			)
			return false

		used_card_ids[card_id] = true
		used_move_names[move_name_id] = true

	return true


static func _validate_energy_dice(
	loadout: Variant,
	database: Node,
	rules: Dictionary
) -> bool:
	var required_dice_count: int = int(
		rules.get(
			"required_energy_dice_count",
			3
		)
	)

	if loadout.energy_dice.size() != required_dice_count:
		push_error(
			"Team Builder: exactly %d energy dice are required."
			% required_dice_count
		)
		return false

	var used_die_ids: Dictionary = {}
	var used_fixed_energies: Dictionary = {}

	for index: int in range(
		loadout.energy_dice.size()
	):
		var die: Variant = loadout.energy_dice[index]

		if die == null:
			push_error(
				"Team Builder: energy die %d is null."
				% index
			)
			return false

		if die.id == &"":
			push_error(
				"Team Builder: energy die %d has no ID."
				% index
			)
			return false

		if used_die_ids.has(die.id):
			push_error(
				"Team Builder: duplicate energy die ID '%s'."
				% String(die.id)
			)
			return false

		if (
			die.fixed_energy_a == &""
			or die.fixed_energy_b == &""
		):
			push_error(
				"Team Builder: each die needs two fixed energies."
			)
			return false

		if die.fixed_energy_a == die.fixed_energy_b:
			push_error(
				"Team Builder: a die's two fixed energies must be different."
			)
			return false

		for energy_type: StringName in (
			die.get_fixed_energies()
		):
			if not database.reference_data.has_energy_type(
				energy_type
			):
				push_error(
					"Team Builder: unknown energy type '%s'."
					% String(energy_type)
				)
				return false

			if used_fixed_energies.has(
				energy_type
			):
				push_error(
					"Team Builder: fixed energy '%s' appears on more than one die."
					% String(energy_type)
				)
				return false

			used_fixed_energies[energy_type] = true

		used_die_ids[die.id] = true

	var required_unique_energy_count: int = int(
		rules.get(
			"required_unique_fixed_energy_count",
			6
		)
	)

	if (
		used_fixed_energies.size()
		!= required_unique_energy_count
	):
		push_error(
			"Team Builder: expected %d unique fixed energies, got %d."
			% [
				required_unique_energy_count,
				used_fixed_energies.size()
			]
		)
		return false

	return true
