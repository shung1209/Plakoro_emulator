extends RefCounted


const PLAYER_LOADOUT_PROVIDER: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const PLAYER_LOADOUT_SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)
const MOVE_SELECTION_VALIDATOR: Script = preload(
    "res://scripts/loadout/MoveSelectionValidator.gd"
)
const MOVE_DRAFT_PROVIDER: Script = preload(
    "res://scripts/draft/MoveDraftProvider.gd"
)


static func apply_draft(
    draft: Variant,
    database: Variant
) -> Dictionary:
    var result: Dictionary = {
        "success": false,
        "errors": []
    }

    if draft == null:
        result["errors"].append(
            "Move draft is missing."
        )
        return result

    if database == null:
        result["errors"].append(
            "Database is missing."
        )
        return result

    var loadout: Variant = (
        PLAYER_LOADOUT_PROVIDER.load_player_loadout()
    )

    if loadout == null:
        result["errors"].append(
            "Player Battle Loadout could not be loaded."
        )
        return result

    if draft.pokemon_id != loadout.pokemon_id:
        result["errors"].append(
            "Move draft Pokémon does not match the saved loadout."
        )
        return result

    var pokemon: Variant = database.get_pokemon(
        loadout.pokemon_id
    )

    if pokemon == null:
        result["errors"].append(
            "Current Pokémon could not be found in the database."
        )
        return result

    var selected_ids: Array[StringName] = []

    for move_id: StringName in draft.selected_move_ids:
        selected_ids.append(move_id)

    var validation: Dictionary = (
        MOVE_SELECTION_VALIDATOR.validate(
            pokemon,
            selected_ids,
            database
        )
    )

    if not bool(validation["success"]):
        for raw_error: Variant in validation["errors"]:
            result["errors"].append(
                String(raw_error)
            )

        return result

    loadout.move_card_ids.clear()

    for move_id: StringName in selected_ids:
        loadout.move_card_ids.append(move_id)

    if not PLAYER_LOADOUT_SAVE_SERVICE.save_loadout(
        loadout,
        PLAYER_LOADOUT_PROVIDER.USER_LOADOUT_PATH
    ):
        result["errors"].append(
            "Could not save Player Battle Loadout."
        )
        return result

    if not MOVE_DRAFT_PROVIDER.discard_draft():
        result["errors"].append(
            "Loadout was saved, but the draft could not be deleted."
        )
        return result

    result["success"] = true
    return result
