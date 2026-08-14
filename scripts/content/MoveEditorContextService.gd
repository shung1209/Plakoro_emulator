extends RefCounted

const CONTEXT_PATH: String = "user://move_editor_context.json"

static func set_context(move_id: String, return_scene: String) -> bool:
    var normalized: String = move_id.strip_edges()
    if normalized.is_empty():
        return false
    var file: FileAccess = FileAccess.open(CONTEXT_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({
        "move_id": normalized,
        "return_scene": return_scene
    }, "  "))
    file.close()
    return true

static func load_context() -> Dictionary:
    if not FileAccess.file_exists(CONTEXT_PATH):
        return {}
    var file: FileAccess = FileAccess.open(CONTEXT_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed as Dictionary if parsed is Dictionary else {}

static func clear_context() -> void:
    if FileAccess.file_exists(CONTEXT_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(CONTEXT_PATH))
