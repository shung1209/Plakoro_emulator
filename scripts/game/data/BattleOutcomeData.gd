extends RefCounted


var winner_participant_id: StringName = &""
var encounter_id: StringName = &""
var reward_pokemon_id: StringName = &""
var reward_move_card_ids: Array[String] = []
var player_pokemon_id: StringName = &""
var turn_count: int = 0

var player_name: String = ""
var enemy_name: String = ""

var player_damage_dealt: int = 0
var enemy_damage_dealt: int = 0

var player_hp: int = 0
var player_max_hp: int = 0
var enemy_hp: int = 0
var enemy_max_hp: int = 0


func is_valid() -> bool:
	return (
		winner_participant_id in [&"player", &"enemy"]
		and turn_count > 0
		and not player_name.is_empty()
		and not enemy_name.is_empty()
	)


func player_won() -> bool:
	return winner_participant_id == &"player"
