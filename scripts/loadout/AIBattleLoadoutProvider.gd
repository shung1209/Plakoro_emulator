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
const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const AI_LOADOUT_STRATEGY: Script = preload(
    "res://scripts/ai/AILoadoutStrategyService.gd"
)


const USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/ai_battle_loadout.json"
)

const FREE_MODE_USER_LOADOUT_PATH: String = (
    "user://user_database/loadouts/free_mode_ai_battle_loadout.json"
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


static func get_user_loadout_path() -> String:
    return (
        FREE_MODE_USER_LOADOUT_PATH
        if GameFlow.free_mode
        else USER_LOADOUT_PATH
    )


static func load_ai_loadout() -> Variant:
    if EncounterSession.has_active_encounter():
        return EncounterSession.get_ai_loadout()

    USER_DATABASE.migrate_legacy_user_files()
    var loadout_path: String = get_user_loadout_path()
    if FileAccess.file_exists(
        loadout_path
    ):
        var saved_loadout: Variant = (
            SAVE_SERVICE.load_loadout(
                loadout_path
            )
        )

        if saved_loadout != null:
            _apply_difficulty_strategy(saved_loadout, true)
            return saved_loadout

    return create_default_ai_loadout()


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


static func create_default_ai_loadout() -> Variant:
    var result: Variant = LOADOUT_DATA.new()

    result.loadout_id = &"ai_squirtle_default"
    result.pokemon_id = &"squirtle_standard"
    result.difficulty = &"hard"

    if _apply_difficulty_strategy(result, false):
        return result

    for move_id: StringName in DEFAULT_MOVE_IDS:
        result.move_card_ids.append(move_id)

    result.energy_dice_setup = (
        ENERGY_SETUP_LOADER.load_setup(
            DEFAULT_DICE_PATH
        )
    )

    return result


static func _apply_difficulty_strategy(
    loadout: Variant,
    preserve_selected_moves: bool
) -> bool:
    if loadout == null:
        return false
    var pokemon: Dictionary = POKEMON_AUTHORING.load_by_id(
        String(loadout.pokemon_id)
    )
    if pokemon.is_empty():
        return false

    var requested_moves: Array = []
    if preserve_selected_moves:
        requested_moves = loadout.move_card_ids.duplicate()
    var strategy: Dictionary = AI_LOADOUT_STRATEGY.build(
        pokemon,
        StringName(loadout.difficulty),
        requested_moves
    )
    if not bool(strategy.get("success", false)):
        return false

    loadout.move_card_ids.clear()
    for raw_move_id: Variant in strategy.get("move_ids", []):
        loadout.move_card_ids.append(StringName(raw_move_id))
    loadout.energy_dice_setup = strategy.get("energy_dice_setup", null)
    loadout.uses_difficulty_dice = true
    return loadout.is_complete()
