extends Node


signal progress_changed(progress: Variant, update: Dictionary)


const SAVE_SERVICE: Script = preload(
	"res://scripts/game/PlayerProgressSaveService.gd"
)
const PROGRESS_DATA: Script = preload(
	"res://scripts/game/data/PlayerProgressData.gd"
)


var progress: Variant = null
var last_update: Dictionary = {}


func _ready() -> void:
	progress = SAVE_SERVICE.load_progress()


func record_battle(outcome: Variant) -> Dictionary:
	if outcome == null or not outcome.has_method("is_valid") or not outcome.is_valid():
		push_error("PlayerProgress: cannot record an invalid battle outcome.")
		return {}

	if progress == null:
		progress = SAVE_SERVICE.load_progress()

	var completed_before: bool = progress.completed_encounter_ids.has(
		String(outcome.encounter_id)
	)
	var pokemon_unlocked_before: bool = progress.unlocked_pokemon_ids.has(
		String(outcome.reward_pokemon_id)
	)
	var newly_unlocked: Array[String] = progress.record_battle(outcome)
	var newly_completed_encounters: Array[String] = []
	var newly_unlocked_pokemon: Array[String] = []
	if (
		outcome.player_won()
		and not String(outcome.encounter_id).is_empty()
		and not completed_before
	):
		newly_completed_encounters.append(String(outcome.encounter_id))
	if (
		outcome.player_won()
		and not String(outcome.reward_pokemon_id).is_empty()
		and not pokemon_unlocked_before
	):
		newly_unlocked_pokemon.append(String(outcome.reward_pokemon_id))
	var saved: bool = SAVE_SERVICE.save_progress(progress)
	last_update = {
		"saved": saved,
		"newly_unlocked": newly_unlocked.duplicate(),
		"newly_completed_encounters": newly_completed_encounters,
		"newly_unlocked_pokemon": newly_unlocked_pokemon,
		"total_battles": progress.total_battles,
		"wins": progress.wins,
		"losses": progress.losses,
		"current_win_streak": progress.current_win_streak,
		"best_win_streak": progress.best_win_streak
	}
	progress_changed.emit(progress, last_update.duplicate(true))
	return last_update.duplicate(true)


func get_progress() -> Variant:
	if progress == null:
		progress = SAVE_SERVICE.load_progress()
	return progress


func get_last_update() -> Dictionary:
	return last_update.duplicate(true)


func has_profile() -> bool:
	return get_progress().has_profile()


func create_profile(
	starter_pokemon_id: StringName,
	starter_move_ids: Array[String],
	starter_energy: StringName
) -> bool:
	var new_progress: Variant = PROGRESS_DATA.create_new_profile(
		starter_pokemon_id,
		starter_move_ids,
		starter_energy
	)
	if not SAVE_SERVICE.save_progress(new_progress):
		return false
	progress = new_progress
	last_update.clear()
	progress_changed.emit(progress, {})
	return true


func claim_energy_choice(
	pokemon_id: StringName,
	level: int,
	energy_type: StringName
) -> bool:
	var current: Variant = get_progress()
	if not current.claim_energy_choice(pokemon_id, level, energy_type):
		return false
	var saved: bool = SAVE_SERVICE.save_progress(current)
	last_update["saved"] = saved
	last_update["claimed_energy"] = String(energy_type)
	progress_changed.emit(current, last_update.duplicate(true))
	return saved


func delete_profile() -> Dictionary:
	var result: Dictionary = SAVE_SERVICE.delete_player_save()
	if not bool(result.get("success", false)):
		return result
	progress = PROGRESS_DATA.new()
	last_update.clear()
	EncounterSession.clear()
	progress_changed.emit(progress, {"profile_deleted": true})
	return result
