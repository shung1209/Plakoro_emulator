extends RefCounted


const USER_DATABASE_ROOT: String = "user://user_database"
const LINK_NAME: String = "user_database_link"


static func ensure_shortcut() -> Dictionary:
	var target_path: String = ProjectSettings.globalize_path(
		USER_DATABASE_ROOT
	)
	var game_root: String = _game_root_directory()
	var link_path: String = game_root.path_join(
		LINK_NAME
	)

	var result: Dictionary = {
		"success": false,
		"created": false,
		"already_exists": false,
		"platform": OS.get_name(),
		"game_root": game_root,
		"link_path": link_path,
		"target_path": target_path,
		"message": ""
	}

	if not DirAccess.dir_exists_absolute(
		target_path
	):
		result["message"] = (
			"user_database target does not exist: "
			+ target_path
		)
		return result

	# A pre-existing directory/junction/symlink is accepted as-is.
	# Never delete or replace a path in the game directory automatically.
	if (
		DirAccess.dir_exists_absolute(
			link_path
		)
		or FileAccess.file_exists(
			link_path
		)
	):
		result["success"] = true
		result["already_exists"] = true
		result["message"] = (
			"Shortcut path already exists."
		)
		return result

	var platform: String = OS.get_name()

	if platform == "Windows":
		return _create_windows_junction(
			result
		)

	if (
		platform == "Linux"
		or platform == "macOS"
		or platform == "FreeBSD"
	):
		return _create_posix_symlink(
			result
		)

	result["message"] = (
		"Shortcut creation is not implemented for platform: "
		+ platform
	)
	return result


static func _game_root_directory() -> String:
	# In editor/development runs, res:// resolves to the project root.
	if OS.has_feature(
		"editor"
	):
		return ProjectSettings.globalize_path(
			"res://"
		).trim_suffix("/").trim_suffix("\\")

	# In an exported build, put the convenience link beside the executable.
	var executable_path: String = (
		OS.get_executable_path()
	)

	if not executable_path.is_empty():
		return executable_path.get_base_dir()

	# Conservative fallback; runtime data still uses user:// regardless.
	return ProjectSettings.globalize_path(
		"res://"
	).trim_suffix("/").trim_suffix("\\")


static func _create_windows_junction(
	result: Dictionary
) -> Dictionary:
	var output: Array = []
	var exit_code: int = OS.execute(
		"cmd.exe",
		PackedStringArray([
			"/C",
			"mklink",
			"/J",
			String(result["link_path"]),
			String(result["target_path"])
		]),
		output,
		true
	)

	if (
		exit_code == 0
		and DirAccess.dir_exists_absolute(
			String(result["link_path"])
		)
	):
		result["success"] = true
		result["created"] = true
		result["message"] = (
			"Windows directory junction created."
		)
		return result

	result["message"] = (
		"Could not create Windows directory junction"
		+ " (exit "
		+ str(exit_code)
		+ "). "
		+ "\n".join(
			_string_array(output)
		)
	)
	return result


static func _create_posix_symlink(
	result: Dictionary
) -> Dictionary:
	var output: Array = []
	var exit_code: int = OS.execute(
		"ln",
		PackedStringArray([
			"-s",
			String(result["target_path"]),
			String(result["link_path"])
		]),
		output,
		true
	)

	if (
		exit_code == 0
		and DirAccess.dir_exists_absolute(
			String(result["link_path"])
		)
	):
		result["success"] = true
		result["created"] = true
		result["message"] = (
			"Symbolic link created."
		)
		return result

	result["message"] = (
		"Could not create symbolic link"
		+ " (exit "
		+ str(exit_code)
		+ "). "
		+ "\n".join(
			_string_array(output)
		)
	)
	return result


static func _string_array(
	values: Array
) -> Array[String]:
	var result: Array[String] = []

	for value: Variant in values:
		result.append(
			String(value)
		)

	return result
