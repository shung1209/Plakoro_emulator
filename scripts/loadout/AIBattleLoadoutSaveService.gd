extends RefCounted


const LOADOUT_DATA: Script = preload(
    "res://scripts/loadout/AIBattleLoadoutData.gd"
)


static func save_loadout(
    loadout_data: Variant,
    file_path: String
) -> bool:
    if loadout_data == null:
        return false

    if not loadout_data.is_complete():
        push_error(
            "AIBattleLoadoutSaveService: "
            + "cannot save incomplete loadout."
        )
        return false

    if file_path.begins_with("user://"):
        var parent_directory: String = file_path.get_base_dir()
        var directory_error: Error = DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(parent_directory)
        )
        if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
            push_error("Could not create " + parent_directory)
            return false

    var file: FileAccess = FileAccess.open(
        file_path,
        FileAccess.WRITE
    )

    if file == null:
        push_error(
            "AIBattleLoadoutSaveService: cannot open "
            + file_path
        )
        return false

    file.store_string(
        JSON.stringify(
            loadout_data.to_dictionary(),
            "  "
        )
    )
    file.close()

    return true


static func load_loadout(
    file_path: String
) -> Variant:
    if not FileAccess.file_exists(file_path):
        return null

    var file: FileAccess = FileAccess.open(
        file_path,
        FileAccess.READ
    )

    if file == null:
        return null

    var raw_text: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()

    if json.parse(raw_text) != OK:
        push_error(
            "AIBattleLoadoutSaveService: invalid JSON in "
            + file_path
        )
        return null

    if not json.data is Dictionary:
        return null

    var result: Variant = LOADOUT_DATA.from_dictionary(
        json.data as Dictionary
    )

    if not result.is_complete():
        push_error(
            "AIBattleLoadoutSaveService: "
            + "loaded loadout is incomplete."
        )
        return null

    return result
