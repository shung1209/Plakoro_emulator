extends RefCounted


var player_pokemon_id: StringName = &""
var enemy_pokemon_id: StringName = &""

var player_move_card_ids: Array = []
var enemy_move_card_ids: Array = []

var player_energy_dice_setup: Variant = null
var enemy_energy_dice_setup: Variant = null

var ai_difficulty: StringName = &"hard"


func is_ready() -> bool:
    return (
        player_pokemon_id != &""
        and enemy_pokemon_id != &""
        and player_move_card_ids.size() == 4
        and enemy_move_card_ids.size() == 4
        and player_energy_dice_setup != null
        and enemy_energy_dice_setup != null
    )
