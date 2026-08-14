extends RefCounted

const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")

const MODE_POKEMON: StringName = &"pokemon"
const MODE_KYOKORO: StringName = &"kyokoro"
const MODE_MOVE: StringName = &"move"

static func describe(mode: StringName, content_id: String) -> Dictionary:
    var normalized_id := content_id.strip_edges().to_lower()
    if normalized_id.is_empty():
        return {"source": "new", "label": "New Content", "has_builtin": false, "has_user": false, "user_path": "", "builtin_path": ""}

    var directory: String = _directory_for_mode(mode)
    if directory.is_empty():
        return {}

    var user_path: String = "user://user_database/%s/%s.json" % [directory, normalized_id]
    var builtin_path: String = "res://database/%s/%s.json" % [directory, normalized_id]
    var has_user: bool = FileAccess.file_exists(user_path)
    var has_builtin: bool = (
        BUILTIN_MANIFEST.ids_for(directory).has(normalized_id)
        or FileAccess.file_exists(builtin_path)
    )

    var user_copy_matches_builtin: bool = false
    if has_user and has_builtin:
        user_copy_matches_builtin = _files_have_same_json(user_path, builtin_path)

    var source: String = "missing"
    var label: String = "Unavailable"
    if has_user and has_builtin and not user_copy_matches_builtin:
        source = "override"
        label = "User Override"
    elif has_builtin:
        # First-run bootstrap intentionally mirrors built-in JSON into user://.
        # An identical local mirror is still presented as Built-in Content.
        source = "builtin"
        label = "Built-in Content"
    elif has_user:
        source = "user"
        label = "User Content"

    return {
        "source": source,
        "label": label,
        "has_builtin": has_builtin,
        "has_user": has_user,
        "user_copy_matches_builtin": user_copy_matches_builtin,
        "user_path": user_path,
        "builtin_path": builtin_path
    }

static func restore_builtin(mode: StringName, content_id: String) -> Dictionary:
    var info: Dictionary = describe(mode, content_id)
    if not bool(info.get("has_builtin", false)):
        return {"success": false, "errors": ["This entry has no built-in version to restore."]}
    var user_path: String = String(info.get("user_path", ""))
    if user_path.is_empty() or not FileAccess.file_exists(user_path):
        return {"success": true, "changed": false, "errors": []}
    var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(user_path))
    if error != OK:
        return {"success": false, "errors": ["Could not remove the user override."]}
    return {"success": true, "changed": true, "errors": []}

static func _files_have_same_json(first_path: String, second_path: String) -> bool:
    var first_file: FileAccess = FileAccess.open(first_path, FileAccess.READ)
    var second_file: FileAccess = FileAccess.open(second_path, FileAccess.READ)
    if first_file == null or second_file == null:
        return false

    var first_text: String = first_file.get_as_text()
    var second_text: String = second_file.get_as_text()
    first_file.close()
    second_file.close()

    if first_text == second_text:
        return true

    var first_parsed: Variant = JSON.parse_string(first_text)
    var second_parsed: Variant = JSON.parse_string(second_text)
    if first_parsed == null or second_parsed == null:
        return false
    return first_parsed == second_parsed


static func _directory_for_mode(mode: StringName) -> String:
    match mode:
        MODE_POKEMON:
            return "pokemon"
        MODE_KYOKORO:
            return "kyokoro_profiles"
        MODE_MOVE:
            return "move_cards"
    return ""
