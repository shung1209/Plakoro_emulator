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


const USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/player_battle_loadout.json"
)

const USER_DICE_PATH: String = (
    "user://user_database/dice_setups/player_energy_dice_setup.json"
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


static func load_player_loadout() -> Variant:
    USER_DATABASE.migrate_legacy_user_files()
    if FileAccess.file_exists(
        USER_LOADOUT_PATH
    ):
        var saved_loadout: Variant = (
            LOADOUT_SAVE_SERVICE.load_loadout(
                USER_LOADOUT_PATH
            )
        )

        if saved_loadout != null:
            return saved_loadout

    return create_default_player_loadout()


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
            USER_DICE_PATH
        )
    ):
        result.energy_dice_setup = (
            ENERGY_SETUP_SAVE_SERVICE.load_setup(
                USER_DICE_PATH
            )
        )
        result.energy_dice_source = "player_custom"

    return result
