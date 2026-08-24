extends RefCounted


const LOADOUT_DATA: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutData.gd"
)
const LOADOUT_SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/PlayerBattleLoadoutSaveService.gd"
)
const ENERGY_SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const ENERGY_SETUP_SAVE_SERVICE: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupSaveService.gd"
)
const USER_DATABASE: Script = preload(
    "res://scripts/content/UserDatabasePathService.gd"
)
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)


const USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/player_battle_loadout.json"
)

const FREE_MODE_USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/free_mode_player_battle_loadout.json"
)

const USER_DICE_PATH: String = (
    "user://user_database/dice_setups/player_energy_dice_setup.json"
)

const FREE_MODE_USER_DICE_PATH: String = (
    "user://user_database/dice_setups/free_mode_player_energy_dice_setup.json"
)

const DEFAULT_DICE_PATH: String = (
    "res://database/dice_setups/pikachu_default.json"
)


const DEFAULT_MOVE_IDS: Array[StringName] = [
    &"pikachu_gnaw_stw04_001",
    &"pikachu_thunder_shock_stw04_002",
    &"pikachu_thunderbolt_stw04_004",
    &"pikachu_iron_tail_stw04_007"
]


static func get_user_loadout_path() -> String:
    return (
        FREE_MODE_USER_LOADOUT_PATH
        if GameFlow.free_mode
        else USER_LOADOUT_PATH
    )


static func get_user_dice_path() -> String:
    return (
        FREE_MODE_USER_DICE_PATH
        if GameFlow.free_mode
        else USER_DICE_PATH
    )


static func load_player_loadout() -> Variant:
    USER_DATABASE.migrate_legacy_user_files()
    var loadout_path: String = get_user_loadout_path()
    if FileAccess.file_exists(
        loadout_path
    ):
        var saved_loadout: Variant = (
            LOADOUT_SAVE_SERVICE.load_loadout(
                loadout_path
            )
        )

        if saved_loadout != null:
            if GameFlow.free_mode:
                _apply_free_mode_pokemon_default_dice(saved_loadout)
            return saved_loadout

    return create_default_player_loadout()


static func _apply_free_mode_pokemon_default_dice(loadout: Variant) -> void:
    if loadout == null:
        return
    var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(
        String(loadout.pokemon_id)
    )
    if pokemon.is_empty():
        return
    var species_id: String = String(
        pokemon.get("species_id", "")
    ).strip_edges().to_lower()
    if species_id.is_empty():
        return
    var user_path: String = (
        USER_DATABASE.DICE_SETUPS + "/" + species_id + "_default.json"
    )
    var builtin_path: String = (
        "res://database/dice_setups/" + species_id + "_default.json"
    )
    var dice_path: String = (
        user_path if FileAccess.file_exists(user_path) else builtin_path
    )
    if not FileAccess.file_exists(dice_path):
        return
    var setup: Variant = ENERGY_SETUP_LOADER.load_setup(dice_path)
    if setup != null:
        loadout.energy_dice_setup = setup
        loadout.energy_dice_source = "pokemon_default"


static func create_default_player_loadout() -> Variant:
    var result: Variant = LOADOUT_DATA.new()

    result.loadout_id = &"player_default"
    result.pokemon_id = &"pikachu_standard"

    for move_id: StringName in DEFAULT_MOVE_IDS:
        result.move_card_ids.append(move_id)

    # New default behavior: Pokémon Default has priority. The legacy
    # user:// custom file is only a fallback when the database default cannot
    # be loaded.
    result.energy_dice_setup = (
        ENERGY_SETUP_LOADER.load_setup(
            DEFAULT_DICE_PATH
        )
    )
    result.energy_dice_source = "pokemon_default"

    if (
        result.energy_dice_setup == null
        and FileAccess.file_exists(
            get_user_dice_path()
        )
    ):
        result.energy_dice_setup = (
            ENERGY_SETUP_SAVE_SERVICE.load_setup(
                get_user_dice_path()
            )
        )
        result.energy_dice_source = "player_custom"

    return result
