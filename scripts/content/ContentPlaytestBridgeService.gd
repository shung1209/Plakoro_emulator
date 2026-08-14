extends RefCounted


const LOADOUT_DATA: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutData.gd"
)
const LOADOUT_SAVE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)
const ENERGY_SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const ENERGY_SETUP_SAVE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const AI_LOADOUT_DATA: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutData.gd"
)
const AI_LOADOUT_SAVE: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutSaveService.gd"
)


const PLAYER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/player_battle_loadout.json"
)

const AI_LOADOUT_PATH: String = (
    "user://user_database/loadouts/ai_battle_loadout.json"
)

const DATABASE_DICE_DIRECTORY: String = (
    "res://database/dice_setups"
)

const USER_DICE_DIRECTORY: String = (
    "user://user_database/dice_setups"
)

const PLAYER_CUSTOM_DICE_PATH: String = (
    "user://user_database/dice_setups/player_energy_dice_setup.json"
)

const FALLBACK_DICE_PATH: String = (
    "res://database/dice_setups/pikachu_default.json"
)


static func create_playtest_loadout(
    pokemon: Dictionary,
    selected_move_ids: Array[String] = [],
    dice_source: String = "pokemon_default"
) -> Dictionary:
    var pokemon_id: String = String(
        pokemon.get(
            "id",
            ""
        )
    ).strip_edges()

    if pokemon_id.is_empty():
        return {
            "success": false,
            "errors": [
                "Pokémon id is required."
            ]
        }

    var raw_moves: Variant = pokemon.get(
        "available_move_card_ids",
        []
    )
    var available_move_ids: Array[String] = []

    if raw_moves is Array:
        for raw_move: Variant in raw_moves:
            var move_id: String = String(
                raw_move
            ).strip_edges()

            if (
                not move_id.is_empty()
                and not available_move_ids.has(
                    move_id
                )
            ):
                available_move_ids.append(
                    move_id
                )

    var requested_move_ids: Array[String] = []

    if selected_move_ids.is_empty():
        # Backward-compatible fallback for tests/older callers.
        for move_id: String in available_move_ids:
            requested_move_ids.append(
                move_id
            )

            if requested_move_ids.size() == 4:
                break
    else:
        for raw_selected_id: String in selected_move_ids:
            var selected_id: String = (
                raw_selected_id.strip_edges()
            )

            if selected_id.is_empty():
                continue

            if not available_move_ids.has(
                selected_id
            ):
                return {
                    "success": false,
                    "errors": [
                        "Selected Move is not assigned to this Pokémon: "
                        + selected_id
                    ]
                }

            if not requested_move_ids.has(
                selected_id
            ):
                requested_move_ids.append(
                    selected_id
                )

    if requested_move_ids.size() != 4:
        return {
            "success": false,
            "errors": [
                "Playtest requires exactly four selected Move Cards."
            ]
        }

    var move_name_ids: Dictionary = {}

    for requested_id: String in requested_move_ids:
        var move_data: Dictionary = (
            MOVE_AUTHORING.load_by_id(
                requested_id
            )
        )
        var move_name_id: String = String(
            move_data.get(
                "move_name_id",
                ""
            )
        ).strip_edges()

        if move_name_id.is_empty():
            move_name_id = requested_id

        if move_name_ids.has(
            move_name_id
        ):
            return {
                "success": false,
                "errors": [
                    "Duplicate Move name is not allowed in one loadout: "
                    + move_name_id
                ]
            }

        move_name_ids[
            move_name_id
        ] = true

    var move_ids: Array[StringName] = []

    for move_id: String in requested_move_ids:
        move_ids.append(
            StringName(
                move_id
            )
        )

    var dice_path: String = ""

    match dice_source:
        "pokemon_default":
            dice_path = get_pokemon_default_dice_path(pokemon)
        "player_custom":
            dice_path = PLAYER_CUSTOM_DICE_PATH
        _:
            return {
                "success": false,
                "errors": [
                    "Unsupported Player Dice Source: " + dice_source
                ]
            }

    if dice_path.is_empty() or not FileAccess.file_exists(dice_path):
        return {
            "success": false,
            "errors": [
                "Enerkoro setup does not exist: " + dice_path
            ]
        }

    var dice_setup: Variant = ENERGY_SETUP_SAVE.load_setup(dice_path)

    if dice_setup == null:
        return {
            "success": false,
            "errors": [
                "Enerkoro setup could not be loaded: "
                + dice_path
            ]
        }

    var loadout: Variant = (
        LOADOUT_DATA.new()
    )

    loadout.loadout_id = StringName(
        "studio_playtest_"
        + pokemon_id
    )
    loadout.pokemon_id = StringName(
        pokemon_id
    )
    loadout.move_card_ids = move_ids
    loadout.energy_dice_setup = dice_setup
    loadout.energy_dice_source = dice_source

    if not loadout.is_complete():
        return {
            "success": false,
            "errors": [
                "Generated playtest loadout is incomplete."
            ]
        }

    if not LOADOUT_SAVE.save_loadout(
        loadout,
        PLAYER_LOADOUT_PATH
    ):
        return {
            "success": false,
            "errors": [
                "Could not save the temporary playtest loadout."
            ]
        }

    return {
        "success": true,
        "pokemon_id": pokemon_id,
        "move_ids": move_ids,
        "dice_path": dice_path,
        "loadout_path": PLAYER_LOADOUT_PATH
    }


static func get_pokemon_default_dice_path(
    pokemon: Dictionary
) -> String:
    var species_id: String = String(
        pokemon.get("species_id", "")
    ).strip_edges().to_lower()
    if species_id.is_empty():
        return ""
    var user_path: String = USER_DICE_DIRECTORY + "/" + species_id + "_default.json"
    if FileAccess.file_exists(user_path):
        return user_path
    return DATABASE_DICE_DIRECTORY + "/" + species_id + "_default.json"


static func has_pokemon_default_dice(
    pokemon: Dictionary
) -> bool:
    var path: String = get_pokemon_default_dice_path(pokemon)
    return not path.is_empty() and FileAccess.file_exists(path)


static func has_player_custom_dice() -> bool:
    return FileAccess.file_exists(PLAYER_CUSTOM_DICE_PATH)


static func list_playtest_opponents(
    exclude_pokemon_id: String = ""
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var excluded_id: String = (
        exclude_pokemon_id.strip_edges()
    )

    for pokemon_id: String in (
        POKEMON_AUTHORING.list_saved()
    ):
        if pokemon_id == excluded_id:
            continue

        var pokemon: Dictionary = (
            POKEMON_AUTHORING.load_by_id(
                pokemon_id
            )
        )

        if pokemon.is_empty():
            continue

        var move_ids: Array[String] = (
            _collect_unique_move_ids(
                pokemon
            )
        )
        var dice_path: String = (
            _find_dice_setup_path(
                pokemon,
                false
            )
        )

        var playable: bool = (
            move_ids.size() >= 4
            and not dice_path.is_empty()
        )

        var reason: String = ""

        if move_ids.size() < 4:
            reason = (
                "Needs at least four unique Moves."
            )
        elif dice_path.is_empty():
            reason = (
                "No Pokémon/species Enerkoro setup."
            )

        result.append(
            {
                "pokemon_id": pokemon_id,
                "display_name": String(
                    pokemon.get(
                        "display_name",
                        pokemon_id
                    )
                ),
                "species_id": String(
                    pokemon.get(
                        "species_id",
                        ""
                    )
                ),
                "playable": playable,
                "reason": reason,
                "dice_path": dice_path,
                "move_count": move_ids.size()
            }
        )

    return result


static func create_playtest_opponent_loadout(
    pokemon_id: String,
    difficulty: StringName,
    selected_move_ids: Array[String] = []
) -> Dictionary:
    var normalized_id: String = (
        pokemon_id.strip_edges()
    )

    if normalized_id.is_empty():
        return {
            "success": false,
            "errors": [
                "Opponent Pokémon is required."
            ]
        }

    if not difficulty in [
        &"easy",
        &"normal",
        &"hard"
    ]:
        return {
            "success": false,
            "errors": [
                "Unsupported opponent difficulty: "
                + String(
                    difficulty
                )
            ]
        }

    var pokemon: Dictionary = (
        POKEMON_AUTHORING.load_by_id(
            normalized_id
        )
    )

    if pokemon.is_empty():
        return {
            "success": false,
            "errors": [
                "Opponent Pokémon could not be loaded: "
                + normalized_id
            ]
        }

    var available_move_ids: Array[String] = (
        _collect_unique_move_ids(
            pokemon
        )
    )
    var raw_move_ids: Array[String] = []

    if selected_move_ids.is_empty():
        for move_id: String in available_move_ids:
            raw_move_ids.append(
                move_id
            )

            if raw_move_ids.size() == 4:
                break
    else:
        var selected_move_names: Dictionary = {}

        for raw_selected_id: String in selected_move_ids:
            var selected_id: String = (
                raw_selected_id.strip_edges()
            )

            if not available_move_ids.has(
                selected_id
            ):
                return {
                    "success": false,
                    "errors": [
                        "Selected opponent Move is not assigned or is an alternate duplicate: "
                        + selected_id
                    ]
                }

            var move_data: Dictionary = (
                MOVE_AUTHORING.load_by_id(
                    selected_id
                )
            )
            var move_name_id: String = String(
                move_data.get(
                    "move_name_id",
                    selected_id
                )
            ).strip_edges()

            if selected_move_names.has(
                move_name_id
            ):
                return {
                    "success": false,
                    "errors": [
                        "Duplicate opponent Move name is not allowed: "
                        + move_name_id
                    ]
                }

            selected_move_names[
                move_name_id
            ] = true
            raw_move_ids.append(
                selected_id
            )

    if raw_move_ids.size() != 4:
        return {
            "success": false,
            "errors": [
                "Opponent requires exactly four unique Moves."
            ]
        }

    var dice_path: String = (
        _find_dice_setup_path(
            pokemon,
            false
        )
    )

    if dice_path.is_empty():
        return {
            "success": false,
            "errors": [
                "No compatible Enerkoro setup was found for opponent "
                + normalized_id
            ]
        }

    var dice_setup: Variant = (
        ENERGY_SETUP_LOADER.load_setup(
            dice_path
        )
    )

    if dice_setup == null:
        return {
            "success": false,
            "errors": [
                "Opponent Enerkoro setup could not be loaded: "
                + dice_path
            ]
        }

    var loadout: Variant = (
        AI_LOADOUT_DATA.new()
    )

    loadout.loadout_id = StringName(
        "studio_playtest_ai_"
        + normalized_id
    )
    loadout.pokemon_id = StringName(
        normalized_id
    )
    loadout.difficulty = difficulty

    for index: int in range(4):
        loadout.move_card_ids.append(
            StringName(
                raw_move_ids[index]
            )
        )

    loadout.energy_dice_setup = dice_setup

    if not loadout.is_complete():
        return {
            "success": false,
            "errors": [
                "Generated opponent playtest loadout is incomplete."
            ]
        }

    if not AI_LOADOUT_SAVE.save_loadout(
        loadout,
        AI_LOADOUT_PATH
    ):
        return {
            "success": false,
            "errors": [
                "Could not save the temporary opponent loadout."
            ]
        }

    return {
        "success": true,
        "pokemon_id": normalized_id,
        "move_ids": loadout.move_card_ids,
        "dice_path": dice_path,
        "difficulty": String(
            difficulty
        ),
        "loadout_path": AI_LOADOUT_PATH
    }


static func _collect_unique_move_ids(
    pokemon: Dictionary
) -> Array[String]:
    var result: Array[String] = []
    var move_names: Dictionary = {}
    var raw_moves: Variant = pokemon.get(
        "available_move_card_ids",
        []
    )

    if raw_moves is Array:
        for raw_move: Variant in (
            raw_moves as Array
        ):
            var move_id: String = String(
                raw_move
            ).strip_edges()

            if move_id.is_empty():
                continue

            var move_data: Dictionary = (
                MOVE_AUTHORING.load_by_id(
                    move_id
                )
            )

            if move_data.is_empty():
                continue

            var move_name_id: String = String(
                move_data.get(
                    "move_name_id",
                    move_id
                )
            ).strip_edges()

            if move_names.has(
                move_name_id
            ):
                continue

            move_names[
                move_name_id
            ] = true
            result.append(
                move_id
            )

    return result


static func _find_dice_setup_path(
    pokemon: Dictionary,
    allow_fallback: bool = true
) -> String:
    var pokemon_id: String = String(
        pokemon.get(
            "id",
            ""
        )
    ).strip_edges()

    var species_id: String = String(
        pokemon.get(
            "species_id",
            ""
        )
    ).strip_edges()

    var candidates: Array[String] = [
        USER_DICE_DIRECTORY + "/" + pokemon_id + ".json",
        USER_DICE_DIRECTORY + "/" + species_id + "_default.json",
        DATABASE_DICE_DIRECTORY + "/" + pokemon_id + ".json",
        DATABASE_DICE_DIRECTORY + "/" + species_id + "_default.json"
    ]

    for path: String in candidates:
        if FileAccess.file_exists(
            path
        ):
            return path

    if (
        allow_fallback
        and FileAccess.file_exists(
            FALLBACK_DICE_PATH
        )
    ):
        return FALLBACK_DICE_PATH

    return ""
