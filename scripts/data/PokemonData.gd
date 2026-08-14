extends RefCounted
var id: StringName = &""
var species_id: StringName = &""
var display_name: String = ""
var pokemon_type: StringName = &""
var max_hp: int = 0
var weaknesses: Array = []
var available_move_card_ids: Array[StringName] = []
var available_move_cards: Array = []
var kyokoro_profile_id: StringName = &""
var kyokoro_profile: Variant = null
func get_weakness_bonus(attack_type: StringName) -> int:
	for weakness: Variant in weaknesses:
		if StringName(weakness.attack_type) == attack_type: return int(weakness.bonus_damage)
	return 0
func has_available_card(card_id: StringName) -> bool: return available_move_card_ids.has(card_id)
