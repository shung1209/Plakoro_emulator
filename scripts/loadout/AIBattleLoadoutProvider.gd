extends RefCounted


const LOADOUT_DATA: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutData.gd"
)
const SAVE_SERVICE: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutSaveService.gd"
)
const ENERGY_SETUP_LOADER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupLoader.gd"
)
const USER_DATABASE: Script = preload(
    "res://scripts/content/UserDatabasePathService.gd"
)


const USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/ai_battle_loadout.json"
)

const DEFAULT_DICE_PATH: String = (
    "res://database/dice_setups/squirtle_default.json"
)


const DEFAULT_MOVE_IDS: Array[StringName] = [
    &"squirtle_water_gun_stw03_001",
    &"squirtle_withdraw_stw03_002",
    &"squirtle_water_pulse_stw03_003",
    &"squirtle_shell_attack_stw03_004"
]


static func load_ai_loadout() -> Variant:
    USER_DATABASE.migrate_legacy_user_files()
    if FileAccess.file_exists(
        USER_LOADOUT_PATH
    ):
        var saved_loadout: Variant = (
            SAVE_SERVICE.load_loadout(
                USER_LOADOUT_PATH
            )
        )

        if saved_loadout != null:
            return saved_loadout

    return create_default_ai_loadout()


static func create_default_ai_loadout() -> Variant:
    var result: Variant = LOADOUT_DATA.new()

    result.loadout_id = &"ai_squirtle_default"
    result.pokemon_id = &"squirtle_standard"
    result.difficulty = &"hard"

    for move_id: StringName in DEFAULT_MOVE_IDS:
        result.move_card_ids.append(move_id)

    result.energy_dice_setup = (
        ENERGY_SETUP_LOADER.load_setup(
            DEFAULT_DICE_PATH
        )
    )

    return result
