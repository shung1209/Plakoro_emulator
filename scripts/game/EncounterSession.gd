extends Node


const CATALOG: Script = preload("res://scripts/game/EncounterCatalog.gd")
const AI_LOADOUT_DATA: Script = preload(
	"res://scripts/loadout/AIBattleLoadoutData.gd"
)
const PLAYER_LOADOUT_PROVIDER: Script = preload(
	"res://scripts/loadout/PlayerBattleLoadoutProvider.gd"
)
const AI_LOADOUT_STRATEGY: Script = preload(
	"res://scripts/ai/AILoadoutStrategyService.gd"
)
const JSON_LOADER: Script = preload(
	"res://scripts/database/JsonLoader.gd"
)


const POKEMON_DIRECTORY: String = "res://database/pokemon"


var current_encounter: Dictionary = {}
var current_ai_loadout: Variant = null


func select_encounter(encounter_id: StringName) -> bool:
	var progress: Variant = PlayerProgress.get_progress()
	var encounter: Dictionary = CATALOG.get_by_id(
		encounter_id,
		progress.starter_pokemon_id,
		progress.encounter_order_ids
	)
	if encounter.is_empty():
		push_error("EncounterSession: unknown encounter " + String(encounter_id))
		return false

	if not CATALOG.is_unlocked(
		encounter_id,
		progress.completed_encounter_ids,
		progress.starter_pokemon_id,
		progress.encounter_order_ids
	):
		push_warning("EncounterSession: encounter is locked: " + String(encounter_id))
		return false

	var player_loadout: Variant = PLAYER_LOADOUT_PROVIDER.load_player_loadout()
	if (
		player_loadout != null
		and StringName(player_loadout.pokemon_id)
		== StringName(encounter.get("pokemon_id", ""))
	):
		push_warning("EncounterSession: player cannot battle the same Plakoro.")
		return false

	var pokemon_id: String = String(encounter.get("pokemon_id", ""))
	var pokemon: Dictionary = JSON_LOADER.load_dictionary(
		POKEMON_DIRECTORY.path_join(pokemon_id + ".json")
	)
	var difficulty: StringName = StringName(encounter.get("difficulty", "normal"))
	var strategy: Dictionary = AI_LOADOUT_STRATEGY.build(
		pokemon,
		difficulty,
		[]
	)
	if not bool(strategy.get("success", false)):
		push_error("EncounterSession: could not generate AI strategy.")
		return false

	var loadout: Variant = AI_LOADOUT_DATA.new()
	loadout.loadout_id = StringName("encounter_" + String(encounter_id))
	loadout.pokemon_id = StringName(pokemon_id)
	loadout.difficulty = difficulty
	loadout.uses_difficulty_dice = true
	for raw_move_id: Variant in strategy.get("move_ids", []):
		loadout.move_card_ids.append(StringName(raw_move_id))
	loadout.energy_dice_setup = strategy.get("energy_dice_setup", null)

	if not loadout.is_complete():
		push_error("EncounterSession: generated AI loadout is incomplete.")
		return false

	current_encounter = encounter.duplicate(true)
	current_encounter["move_ids"] = strategy.get("move_ids", []).duplicate()
	current_encounter["ai_main_energy"] = String(strategy.get("main_energy", ""))
	current_encounter["ai_main_energy_faces_per_die"] = int(
		strategy.get("main_energy_faces_per_die", 0)
	)
	current_ai_loadout = loadout
	return true


func has_active_encounter() -> bool:
	return not current_encounter.is_empty() and current_ai_loadout != null


func get_ai_loadout() -> Variant:
	return current_ai_loadout


func get_current_encounter_id() -> StringName:
	return StringName(current_encounter.get("id", ""))


func clear() -> void:
	current_encounter.clear()
	current_ai_loadout = null
