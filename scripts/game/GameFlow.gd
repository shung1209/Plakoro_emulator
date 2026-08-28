extends Node


const MAIN_MENU_SCENE: String = "res://scenes/game/MainMenuUI.tscn"
const SAVE_CREATION_SCENE: String = "res://scenes/game/SaveCreationUI.tscn"
const PREPARATION_SCENE: String = "res://scenes/ui/BattlePreparationUI.tscn"
const ENCOUNTER_SELECT_SCENE: String = "res://scenes/game/EncounterSelectUI.tscn"
const BATTLE_SCENE: String = "res://scenes/ui/BattleGameUI.tscn"
const BATTLE_RESULT_SCENE: String = "res://scenes/game/BattleResultUI.tscn"
const LOCAL_BATTLE_SETUP_SCENE: String = "res://scenes/game/LocalBattleSetupUI.tscn"
const ONLINE_LOBBY_SCENE: String = "res://scenes/game/OnlineLobbyUI.tscn"
const PHONE_SAVE_CREATION_SCENE: String = (
	"res://scenes/phone/PhoneSaveCreationUI.tscn"
)
const PHONE_MENU_SCENE: String = "res://scenes/phone/PhoneModeMenuUI.tscn"
const PHONE_ENCOUNTER_SELECT_SCENE: String = (
	"res://scenes/phone/PhoneEncounterSelectUI.tscn"
)
const PHONE_PREPARATION_SCENE: String = (
	"res://scenes/phone/PhoneBattlePreparationUI.tscn"
)
const PHONE_ENERKORO_BUILDER_SCENE: String = (
	"res://scenes/phone/PhoneEnergyDiceBuilderUI.tscn"
)
const PHONE_BATTLE_LOADOUT_SCENE: String = (
	"res://scenes/phone/PhoneBattleLoadoutUI.tscn"
)
const PHONE_BATTLE_SCENE: String = (
	"res://scenes/phone/PhoneBattleGameUI.tscn"
)
const PHONE_BATTLE_RESULT_SCENE: String = (
	"res://scenes/phone/PhoneBattleResultUI.tscn"
)
const CONTENT_STUDIO_SCENE: String = "res://scenes/ui/PlakoroContentStudioUI.tscn"
const PLAKORO_THEME: Script = preload("res://scripts/ui/theme/PlakoroThemeFactory.gd")


var is_transitioning: bool = false
var content_studio_return_scene: String = PREPARATION_SCENE
var battle_outcome: Variant = null
var collection_mode: bool = false
var free_mode: bool = false
var local_battle_mode: bool = false
var online_battle_mode: bool = false
var local_battle_setup_phase: StringName = &""
var free_mode_allow_repeated_fixed_energy: bool = false
var advance_after_battle_result: bool = false
var phone_mode: bool = false
var landscape_mode: bool = false


func open_main_menu() -> void:
	if phone_mode:
		open_phone_mode_menu()
		return
	exit_phone_mode()


func exit_phone_mode() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(false)
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = false
	local_battle_mode = false
	online_battle_mode = false
	local_battle_setup_phase = &""
	free_mode_allow_repeated_fixed_energy = false
	EncounterSession.clear()
	_change_scene(MAIN_MENU_SCENE)


func start_game() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(true)
	battle_outcome = null
	collection_mode = false
	free_mode = false
	local_battle_mode = false
	online_battle_mode = false
	local_battle_setup_phase = &""
	free_mode_allow_repeated_fixed_energy = false
	_change_scene(
		ENCOUNTER_SELECT_SCENE
		if PlayerProgress.has_profile()
		else SAVE_CREATION_SCENE
	)


func start_phone_mode() -> void:
	open_phone_mode_menu()


func open_phone_mode_menu() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = false
	local_battle_mode = false
	online_battle_mode = false
	local_battle_setup_phase = &""
	free_mode_allow_repeated_fixed_energy = false
	EncounterSession.clear()
	_set_phone_mode(true)
	_change_scene(PHONE_MENU_SCENE)


func start_phone_story_mode() -> void:
	battle_outcome = null
	collection_mode = false
	free_mode = false
	local_battle_mode = false
	online_battle_mode = false
	free_mode_allow_repeated_fixed_energy = false
	_set_phone_mode(true)
	_change_scene(
		PHONE_ENCOUNTER_SELECT_SCENE
		if PlayerProgress.has_profile()
		else PHONE_SAVE_CREATION_SCENE
	)


func open_phone_free_mode() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = true
	local_battle_mode = false
	online_battle_mode = false
	free_mode_allow_repeated_fixed_energy = (
		PLAKORO_THEME.get_free_mode_allow_repeated_fixed_energy()
	)
	EncounterSession.clear()
	_set_phone_mode(true)
	_change_scene(PHONE_PREPARATION_SCENE)


func open_phone_local_battle() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = true
	local_battle_mode = true
	online_battle_mode = false
	local_battle_setup_phase = &"player1_pokemon"
	free_mode_allow_repeated_fixed_energy = (
		PLAKORO_THEME.get_free_mode_allow_repeated_fixed_energy()
	)
	EncounterSession.clear()
	_set_phone_mode(true)
	_change_scene(LOCAL_BATTLE_SETUP_SCENE)


func open_phone_online_battle() -> void:
	battle_outcome = null
	collection_mode = false
	free_mode = true
	local_battle_mode = false
	online_battle_mode = true
	EncounterSession.clear()
	_set_phone_mode(true)
	_change_scene(ONLINE_LOBBY_SCENE)


func open_phone_battle_loadout() -> void:
	if not phone_mode:
		return
	_change_scene(PHONE_BATTLE_LOADOUT_SCENE)


func open_save_creation() -> void:
	battle_outcome = null
	collection_mode = false
	free_mode = false
	free_mode_allow_repeated_fixed_energy = false
	EncounterSession.clear()
	_change_scene(
		PHONE_SAVE_CREATION_SCENE if phone_mode else SAVE_CREATION_SCENE
	)


func open_encounter_select() -> void:
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = false
	free_mode_allow_repeated_fixed_energy = false
	EncounterSession.clear()
	_change_scene(
		PHONE_ENCOUNTER_SELECT_SCENE if phone_mode else ENCOUNTER_SELECT_SCENE
	)


func open_preparation() -> void:
	battle_outcome = null
	collection_mode = false
	if local_battle_mode:
		local_battle_setup_phase = &"player1_pokemon"
		_change_scene(LOCAL_BATTLE_SETUP_SCENE)
		return
	_change_scene(PHONE_PREPARATION_SCENE if phone_mode else PREPARATION_SCENE)


func open_collection() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(true)
	battle_outcome = null
	collection_mode = true
	free_mode = false
	local_battle_mode = false
	online_battle_mode = false
	free_mode_allow_repeated_fixed_energy = false
	EncounterSession.clear()
	_change_scene(PREPARATION_SCENE)


func open_free_mode() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(true)
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	free_mode = true
	local_battle_mode = false
	online_battle_mode = false
	free_mode_allow_repeated_fixed_energy = PLAKORO_THEME.get_free_mode_allow_repeated_fixed_energy()
	EncounterSession.clear()
	_change_scene(PREPARATION_SCENE)


func open_local_battle() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(true)
	battle_outcome = null
	advance_after_battle_result = false
	collection_mode = false
	# Local VS shares Free Mode's unrestricted collection, while retaining an
	# explicit controller mode for pass-and-play and future network transport.
	free_mode = true
	local_battle_mode = true
	online_battle_mode = false
	local_battle_setup_phase = &"player1_pokemon"
	free_mode_allow_repeated_fixed_energy = (
		PLAKORO_THEME.get_free_mode_allow_repeated_fixed_energy()
	)
	EncounterSession.clear()
	_change_scene(LOCAL_BATTLE_SETUP_SCENE)


func open_online_battle() -> void:
	_set_phone_mode(false)
	_set_landscape_mode(true)
	battle_outcome = null
	collection_mode = false
	free_mode = true
	local_battle_mode = false
	online_battle_mode = true
	EncounterSession.clear()
	_change_scene(ONLINE_LOBBY_SCENE)


func open_online_loadout_setup() -> void:
	if OnlineBattleService.current_room.is_empty():
		return
	free_mode = true
	local_battle_mode = false
	online_battle_mode = true
	local_battle_setup_phase = &"online_player_pokemon"
	_change_scene(LOCAL_BATTLE_SETUP_SCENE)


func return_to_online_lobby() -> void:
	if not online_battle_mode:
		return
	_change_scene(ONLINE_LOBBY_SCENE)


func open_battle() -> void:
	battle_outcome = null
	collection_mode = false
	_change_scene(PHONE_BATTLE_SCENE if phone_mode else BATTLE_SCENE)


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
	if not free_mode:
		PlayerProgress.record_battle(outcome)
	_change_scene(
		PHONE_BATTLE_RESULT_SCENE if phone_mode else BATTLE_RESULT_SCENE
	)


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
	_set_phone_mode(false)
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


func _set_phone_mode(enabled: bool) -> void:
	phone_mode = enabled
	if enabled:
		landscape_mode = false
	var window: Window = get_window()
	if window != null:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		window.content_scale_size = (
			Vector2i(480, 900) if enabled else Vector2i(1920, 1080)
		)
	if OS.has_feature("web") or OS.has_feature("mobile"):
		if enabled:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
		else:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
	if OS.has_feature("web"):
		_request_web_orientation(&"portrait" if enabled else &"")


func _set_landscape_mode(enabled: bool) -> void:
	landscape_mode = enabled and not phone_mode
	if OS.has_feature("web") or OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(
			DisplayServer.SCREEN_LANDSCAPE
			if landscape_mode
			else DisplayServer.SCREEN_SENSOR
		)
	if OS.has_feature("web"):
		_request_web_orientation(&"landscape" if landscape_mode else &"")


func _request_web_orientation(orientation: StringName) -> void:
	var script: String = ""
	if orientation != &"":
		var web_orientation: String = (
			"portrait-primary"
			if orientation == &"portrait"
			else "landscape-primary"
		)
		script = (
			"(async function () {"
			+ "try {"
			+ "if (!document.fullscreenElement "
			+ "&& document.documentElement.requestFullscreen) {"
			+ "await document.documentElement.requestFullscreen();"
			+ "}"
			+ "} catch (error) {}"
			+ "try {"
			+ "if (screen.orientation && screen.orientation.lock) {"
			+ "await screen.orientation.lock('"
			+ web_orientation
			+ "');"
			+ "}"
			+ "} catch (error) {}"
			+ "})();"
		)
	else:
		script = (
			"if (screen.orientation && screen.orientation.unlock) {"
			+ "screen.orientation.unlock();"
			+ "}"
		)
	JavaScriptBridge.eval(script)


func request_current_orientation() -> void:
	if not OS.has_feature("web"):
		return
	if phone_mode:
		_request_web_orientation(&"portrait")
	elif landscape_mode:
		_request_web_orientation(&"landscape")


func request_phone_orientation() -> void:
	request_current_orientation()
