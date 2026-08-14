extends RefCounted

const MOVE_DRAFT_DATA: Script = preload(
    "res://scripts/draft/MoveDraftData.gd"
)

static func save_draft(draft: Variant, file_path: String) -> bool:
    if draft == null or not draft.is_complete_enough_to_edit():
        return false

    var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify(draft.to_dictionary(), "  "))
    file.close()
    return true

static func load_draft(file_path: String) -> Variant:
    if not FileAccess.file_exists(file_path):
        return null

    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return null

    var raw_text: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(raw_text) != OK or not json.data is Dictionary:
        return null

    return MOVE_DRAFT_DATA.from_dictionary(json.data as Dictionary)

static func delete_draft(file_path: String) -> bool:
    if not FileAccess.file_exists(file_path):
        return true

    return DirAccess.remove_absolute(
        ProjectSettings.globalize_path(file_path)
    ) == OK
