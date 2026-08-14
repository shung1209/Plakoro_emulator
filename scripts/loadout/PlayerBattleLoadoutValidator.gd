extends RefCounted


const ENERGY_DICE_VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)


const VALID_ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]


static func validate(
    loadout_data: Variant,
    database: Variant
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "errors": []
    }

    if loadout_data == null:
        _add_error(
            result,
            "Loadout is null."
        )
        return result

    if database == null:
        _add_error(
            result,
            "Database is null."
        )
        return result

    if loadout_data.pokemon_id == &"":
        _add_error(
            result,
            "Pokemon is not selected."
        )
    elif database.get_pokemon(
        loadout_data.pokemon_id
    ) == null:
        _add_error(
            result,
            "Pokemon does not exist: "
            + String(loadout_data.pokemon_id)
        )

    if loadout_data.move_card_ids.size() != 4:
        _add_error(
            result,
            "Exactly four move cards are required."
        )

    var unique_moves: Dictionary = {}

    for move_card_id: StringName in (
        loadout_data.move_card_ids
    ):
        if database.get_move_card(move_card_id) == null:
            _add_error(
                result,
                "Move card does not exist: "
                + String(move_card_id)
            )

        if unique_moves.has(move_card_id):
            _add_error(
                result,
                "Move card is duplicated: "
                + String(move_card_id)
            )
        else:
            unique_moves[move_card_id] = true

    if loadout_data.energy_dice_setup == null:
        _add_error(
            result,
            "Enerkoro setup is missing."
        )
    else:
        var energy_types: Array = []

        for energy_type: StringName in (
            VALID_ENERGY_TYPES
        ):
            energy_types.append(energy_type)

        var dice_result: Dictionary = (
            ENERGY_DICE_VALIDATOR.validate(
                loadout_data.energy_dice_setup,
                energy_types
            )
        )

        if not bool(dice_result["success"]):
            for raw_error: Variant in dice_result["errors"]:
                _add_error(
                    result,
                    "Enerkoro: "
                    + String(raw_error)
                )

    return result


static func _add_error(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false

    var errors: Array = result["errors"]
    errors.append(message)
