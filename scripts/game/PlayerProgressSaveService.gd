extends RefCounted


const PROGRESS_DATA: Script = preload(
	"res://scripts/game/data/PlayerProgressData.gd"
)
const DEFAULT_PATH: String = "user://save/player_progress.json"
const PLAYER_LOADOUT_PATH: String = (
	"user://user_database/loadouts/player_battle_loadout.json"
)
const PLAYER_DICE_PATH: String = (
	"user://user_database/dice_setups/player_energy_dice_setup.json"
)
const DICE_BUILDER_CONTEXT_PATH: String = (
	"user://energy_dice_builder_context.json"
)


static func save_progress(
	progress: Variant,
	file_path: String = DEFAULT_PATH
) -> bool:
	if progress == null or not progress.has_method("to_dictionary"):
		return false

	if file_path.begins_with("user://"):
		var parent_directory: String = file_path.get_base_dir()
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(parent_directory)
		)
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			push_error(
				"PlayerProgressSaveService: cannot create "
				+ parent_directory
			)
			return false

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error(
			"PlayerProgressSaveService: cannot open " + file_path
		)
		return false

	file.store_string(JSON.stringify(progress.to_dictionary(), "  "))
	file.close()
	return true


static func load_progress(
	file_path: String = DEFAULT_PATH
) -> Variant:
	if not FileAccess.file_exists(file_path):
		return PROGRESS_DATA.new()

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error(
			"PlayerProgressSaveService: cannot read " + file_path
		)
		return PROGRESS_DATA.new()

	var raw_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(raw_text) != OK or not json.data is Dictionary:
		push_error(
			"PlayerProgressSaveService: invalid progress JSON; using defaults."
		)
		return PROGRESS_DATA.new()

	return PROGRESS_DATA.from_dictionary(json.data as Dictionary)


static func delete_player_save() -> Dictionary:
	# Delete supporting player files first and the canonical progress file last.
	# If a supporting deletion fails, the profile remains discoverable and the
	# player can retry instead of being left with an invisible partial save.
	var paths: Array[String] = [
		PLAYER_LOADOUT_PATH,
		PLAYER_DICE_PATH,
		DICE_BUILDER_CONTEXT_PATH,
		DEFAULT_PATH
	]
	var deleted_paths: Array[String] = []
	for path: String in paths:
		if not FileAccess.file_exists(path):
			continue
		var absolute_path: String = ProjectSettings.globalize_path(path)
		var error: Error = DirAccess.remove_absolute(absolute_path)
		if error != OK:
			return {
				"success": false,
				"failed_path": path,
				"error_code": int(error),
				"deleted_paths": deleted_paths
			}
		deleted_paths.append(path)
	return {
		"success": true,
		"deleted_paths": deleted_paths
	}
