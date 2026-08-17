extends Node


const MAIN_MENU_SCENE: String = "res://scenes/game/MainMenuUI.tscn"
const SAVE_CREATION_SCENE: String = "res://scenes/game/SaveCreationUI.tscn"
const PREPARATION_SCENE: String = "res://scenes/ui/BattlePreparationUI.tscn"
const ENCOUNTER_SELECT_SCENE: String = "res://scenes/game/EncounterSelectUI.tscn"
const BATTLE_SCENE: String = "res://scenes/ui/BattleGameUI.tscn"
const BATTLE_RESULT_SCENE: String = "res://scenes/game/BattleResultUI.tscn"
const CONTENT_STUDIO_SCENE: String = "res://scenes/ui/PlakoroContentStudioUI.tscn"


var is_transitioning: bool = false
var content_studio_return_scene: String = PREPARATION_SCENE
var battle_outcome: Variant = null
var collection_mode: bool = false
var advance_after_battle_result: bool = false


func open_main_menu() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	EncounterSession.clear()
	_change_scene(MAIN_MENU_SCENE)


func start_game() -> void:
	battle_outcome = null
	_change_scene(
		ENCOUNTER_SELECT_SCENE
		if PlayerProgress.has_profile()
		else SAVE_CREATION_SCENE
	)


func open_save_creation() -> void:
	battle_outcome = null
	EncounterSession.clear()
	_change_scene(SAVE_CREATION_SCENE)


func open_encounter_select() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	EncounterSession.clear()
	_change_scene(ENCOUNTER_SELECT_SCENE)


func open_preparation() -> void:
	battle_outcome = null
	collection_mode = false
	_change_scene(PREPARATION_SCENE)


func open_collection() -> void:
	battle_outcome = null
	collection_mode = true
	EncounterSession.clear()
	_change_scene(PREPARATION_SCENE)


func open_battle() -> void:
	battle_outcome = null
	collection_mode = false
	_change_scene(BATTLE_SCENE)


func finish_battle(
	outcome: Variant,
	advance_to_next_opponent: bool = false
) -> void:
	if is_transitioning:
		return

	if outcome == null or not outcome.has_method("is_valid"):
		push_error("GameFlow: invalid battle outcome.")
		return

	if not outcome.is_valid():
		push_error("GameFlow: incomplete battle outcome.")
		return

	battle_outcome = outcome
	advance_after_battle_result = advance_to_next_opponent
	PlayerProgress.record_battle(outcome)
	_change_scene(BATTLE_RESULT_SCENE)


func get_battle_outcome() -> Variant:
	return battle_outcome


func should_advance_after_battle_result() -> bool:
	return advance_after_battle_result


func open_content_studio() -> void:
	if not ContentStudioAccess.is_unsealed():
		push_warning("GameFlow: Content Studio is sealed.")
		return
	content_studio_return_scene = PREPARATION_SCENE
	_change_scene(CONTENT_STUDIO_SCENE)


func open_content_studio_from_main_menu() -> void:
	if not ContentStudioAccess.is_unsealed():
		push_warning("GameFlow: Content Studio is sealed.")
		return
	content_studio_return_scene = MAIN_MENU_SCENE
	_change_scene(CONTENT_STUDIO_SCENE)


func return_from_content_studio() -> void:
	_change_scene(content_studio_return_scene)


func _change_scene(scene_path: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error(
			"GameFlow: unable to open scene %s (error %d)."
			% [scene_path, error]
		)
		is_transitioning = false
		return

	# Scene changes are applied at the end of the frame. Resetting here keeps
	# the guard useful for duplicate button presses without locking navigation.
	await get_tree().process_frame
	is_transitioning = false
