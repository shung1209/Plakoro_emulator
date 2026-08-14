extends RefCounted


var owner_type: StringName = &"player"

var pokemon_id: StringName = &""
var pokemon_data: Variant = null

var selected_move_card_ids: Array[StringName] = []
var selected_move_cards: Array = []

var energy_dice: Array = []


func clear() -> void:
	pokemon_id = &""
	pokemon_data = null
	selected_move_card_ids.clear()
	selected_move_cards.clear()
	energy_dice.clear()


func has_move_card(
	card_id: StringName
) -> bool:
	return selected_move_card_ids.has(card_id)


func has_move_name(
	move_name_id: StringName
) -> bool:
	for card: Variant in selected_move_cards:
		if StringName(card.move_name_id) == move_name_id:
			return true

	return false


func get_all_fixed_energy_types() -> Array[StringName]:
	var result: Array[StringName] = []

	for die: Variant in energy_dice:
		for energy_type: StringName in die.get_fixed_energies():
			result.append(energy_type)

	return result
