extends RefCounted


const REPLAY_TURN_DATA: Script = preload(
    "res://scripts/replay/data/ReplayTurnData.gd"
)


var schema_version: String = "1.0"
var random_seed: int = 0

var player_pokemon_id: StringName = &""
var enemy_pokemon_id: StringName = &""

var player_move_card_ids: Array = []
var enemy_move_card_ids: Array = []

var turns: Array = []

var final_player_hp: int = 0
var final_enemy_hp: int = 0
var winner_participant_id: StringName = &""


func to_dictionary() -> Dictionary:
    var serialized_turns: Array = []

    for turn: Variant in turns:
        serialized_turns.append(
            turn.to_dictionary()
        )

    return {
        "schema_version": schema_version,
        "random_seed": random_seed,
        "player_pokemon_id": String(
            player_pokemon_id
        ),
        "enemy_pokemon_id": String(
            enemy_pokemon_id
        ),
        "player_move_card_ids": (
            player_move_card_ids.duplicate()
        ),
        "enemy_move_card_ids": (
            enemy_move_card_ids.duplicate()
        ),
        "turns": serialized_turns,
        "final_player_hp": final_player_hp,
        "final_enemy_hp": final_enemy_hp,
        "winner_participant_id": String(
            winner_participant_id
        )
    }


static func from_dictionary(
    data: Dictionary
) -> Variant:
    var result: Variant = new()

    result.schema_version = String(
        data.get("schema_version", "1.0")
    )
    result.random_seed = int(
        data.get("random_seed", 0)
    )
    result.player_pokemon_id = StringName(
        data.get("player_pokemon_id", "")
    )
    result.enemy_pokemon_id = StringName(
        data.get("enemy_pokemon_id", "")
    )

    var raw_player_moves: Variant = data.get(
        "player_move_card_ids",
        []
    )
    var raw_enemy_moves: Variant = data.get(
        "enemy_move_card_ids",
        []
    )

    if raw_player_moves is Array:
        result.player_move_card_ids = (
            raw_player_moves as Array
        ).duplicate()

    if raw_enemy_moves is Array:
        result.enemy_move_card_ids = (
            raw_enemy_moves as Array
        ).duplicate()

    var raw_turns: Variant = data.get("turns", [])

    if raw_turns is Array:
        for raw_turn: Variant in raw_turns:
            if raw_turn is Dictionary:
                result.turns.append(
                    REPLAY_TURN_DATA.from_dictionary(
                        raw_turn as Dictionary
                    )
                )

    result.final_player_hp = int(
        data.get("final_player_hp", 0)
    )
    result.final_enemy_hp = int(
        data.get("final_enemy_hp", 0)
    )
    result.winner_participant_id = StringName(
        data.get("winner_participant_id", "")
    )

    return result
