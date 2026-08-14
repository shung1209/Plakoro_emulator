extends RefCounted

const USER_DATABASE: Script = preload(
    "res://scripts/content/UserDatabasePathService.gd"
)

const CONTEXT_PATH: String = "user://energy_dice_builder_context.json"

static func set_context(
    mode: String,
    target_path: String,
    return_scene: String,
    pokemon_id: String = "",
    species_id: String = ""
) -> bool:
    var writable_target: String = USER_DATABASE.ensure_user_editable_copy(target_path)
    if writable_target.is_empty():
        return false
    var file: FileAccess = FileAccess.open(CONTEXT_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({
        "mode": mode,
        "target_path": writable_target,
        "return_scene": return_scene,
        "pokemon_id": pokemon_id,
        "species_id": species_id
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
        DirAccess.remove_absolute(
            ProjectSettings.globalize_path(CONTEXT_PATH)
        )
