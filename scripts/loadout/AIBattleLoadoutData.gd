extends RefCounted


const ENERGY_SETUP_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupData.gd"
)


var schema_version: String = "1.0"
var loadout_id: StringName = &""

var pokemon_id: StringName = &""
var move_card_ids: Array[StringName] = []

var energy_dice_setup: Variant = null
var difficulty: StringName = &"hard"


func is_complete() -> bool:
    return (
        loadout_id != &""
        and pokemon_id != &""
        and move_card_ids.size() == 4
        and energy_dice_setup != null
        and energy_dice_setup.dice.size() == 3
        and difficulty != &""
    )


func to_dictionary() -> Dictionary:
    var serialized_moves: Array[String] = []

    for move_card_id: StringName in move_card_ids:
        serialized_moves.append(
            String(move_card_id)
        )

    return {
        "schema_version": schema_version,
        "loadout_id": String(loadout_id),
        "pokemon_id": String(pokemon_id),
        "move_card_ids": serialized_moves,
        "difficulty": String(difficulty),
        "energy_dice_setup": (
            energy_dice_setup.to_dictionary()
            if energy_dice_setup != null
            else {}
        )
    }


static func from_dictionary(
    data: Dictionary
) -> Variant:
    var result: Variant = new()

    result.schema_version = String(
        data.get("schema_version", "1.0")
    )
    result.loadout_id = StringName(
        data.get("loadout_id", "")
    )
    result.pokemon_id = StringName(
        data.get("pokemon_id", "")
    )
    result.difficulty = StringName(
        data.get("difficulty", "hard")
    )

    var raw_moves: Variant = data.get(
        "move_card_ids",
        []
    )

    if raw_moves is Array:
        for raw_move: Variant in raw_moves:
            result.move_card_ids.append(
                StringName(raw_move)
            )

    var raw_setup: Variant = data.get(
        "energy_dice_setup",
        {}
    )

    if raw_setup is Dictionary:
        result.energy_dice_setup = (
            ENERGY_SETUP_DATA.from_dictionary(
                raw_setup
            )
        )

    return result
