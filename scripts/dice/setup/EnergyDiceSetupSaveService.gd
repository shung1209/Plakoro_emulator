extends RefCounted


const SETUP_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupData.gd"
)


static func save_setup(
    setup: Variant,
    file_path: String
) -> bool:
    if setup == null:
        return false

    # res:// is writable while developing from a normal project directory,
    # but it is packaged/read-only in exported builds. Fail explicitly rather
    # than reporting an opaque save error after export. Player-editable data
    # must use user://.
    if (
        file_path.begins_with("res://")
        and not OS.has_feature("editor")
    ):
        push_error(
            "EnergyDiceSetupSaveService: exported builds cannot write "
            + "to res://; use user:// for editable Enerkoro data. Path: "
            + file_path
        )
        return false

    if file_path.begins_with("user://"):
        var parent_directory: String = file_path.get_base_dir()
        var directory_error: Error = DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(parent_directory)
        )
        if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
            push_error(
                "EnergyDiceSetupSaveService: cannot create "
                + parent_directory
            )
            return false

    var file: FileAccess = FileAccess.open(
        file_path,
        FileAccess.WRITE
    )

    if file == null:
        push_error(
            "EnergyDiceSetupSaveService: cannot open "
            + file_path
        )
        return false

    file.store_string(
        JSON.stringify(
            setup.to_dictionary(),
            "  "
        )
    )
    file.close()
    return true


static func load_setup(
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

    var text: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()

    if json.parse(text) != OK:
        push_error(
            "EnergyDiceSetupSaveService: invalid JSON."
        )
        return null

    if not json.data is Dictionary:
        return null

    return SETUP_DATA.from_dictionary(
        json.data as Dictionary
    )
