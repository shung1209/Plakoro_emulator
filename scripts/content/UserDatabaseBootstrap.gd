extends Node


const USER_DATABASE: Script = preload(
    "res://scripts/content/UserDatabasePathService.gd"
)
const USER_ASSETS: Script = preload(
    "res://scripts/presentation/UserAssetService.gd"
)
const USER_DATABASE_SHORTCUT: Script = preload(
    "res://scripts/content/UserDatabaseShortcutService.gd"
)


const BUILTIN_LANGUAGE_FILES: Array[String] = [
    "en_US.json",
    "zh_TW.json"
]


func _ready() -> void:
    var bootstrap: Dictionary = USER_DATABASE.bootstrap_from_builtin_database()
    if not bool(bootstrap.get("success", false)):
        for message: Variant in bootstrap.get("errors", []):
            push_error("UserDatabaseBootstrap: " + String(message))
        return

    _bootstrap_language_files()

    var weakness_migration: Dictionary = USER_DATABASE.migrate_v22_corrected_weaknesses()
    if not bool(weakness_migration.get("success", false)):
        for message: Variant in weakness_migration.get("errors", []):
            push_error("UserDatabaseBootstrap weakness correction: " + String(message))
    elif not (weakness_migration.get("updated", []) as Array).is_empty():
        print(
            "UserDatabaseBootstrap: corrected v2.2 Pokemon weakness data in ",
            (weakness_migration.get("updated", []) as Array).size(),
            " user JSON file(s)."
        )

    var beam_migration: Dictionary = (
        USER_DATABASE.migrate_v23_metagross_beam_orientation()
    )
    if not bool(beam_migration.get("success", false)):
        for message: Variant in beam_migration.get("errors", []):
            push_error("UserDatabaseBootstrap Beam correction: " + String(message))
    elif not (beam_migration.get("updated", []) as Array).is_empty():
        print(
            "UserDatabaseBootstrap: corrected Metagross Beam orientation data in ",
            (beam_migration.get("updated", []) as Array).size(),
            " user JSON file(s)."
        )

    if not OS.has_feature("web"):
        var shortcut: Dictionary = USER_DATABASE_SHORTCUT.ensure_shortcut()
        if bool(shortcut.get("created", false)):
            print(
                "UserDatabaseBootstrap: user_database_link → ",
                shortcut.get("target_path", "")
            )
        elif not bool(shortcut.get("success", false)):
            push_warning(
                "UserDatabaseBootstrap shortcut: "
                + String(shortcut.get("message", "Unknown shortcut error."))
            )

    var retired_cleanup: Dictionary = USER_DATABASE.remove_retired_test_content()
    if not bool(retired_cleanup.get("success", false)):
        for message: Variant in retired_cleanup.get("errors", []):
            push_error("UserDatabaseBootstrap retired-content cleanup: " + String(message))

    var asset_bootstrap: Dictionary = USER_ASSETS.bootstrap_from_builtin()
    if not bool(asset_bootstrap.get("success", false)):
        for message: Variant in asset_bootstrap.get("errors", []):
            push_error("UserDatabaseBootstrap assets: " + String(message))

    var migration: Dictionary = USER_DATABASE.migrate_legacy_user_files()
    if not bool(migration.get("success", false)):
        for message: Variant in migration.get("errors", []):
            push_error("UserDatabaseBootstrap migration: " + String(message))

    if bool(bootstrap.get("first_run", false)):
        print(
            "UserDatabaseBootstrap: first-run database initialized; copied ",
            bootstrap.get("copied", []).size(),
            " JSON files to user://user_database."
        )



func _bootstrap_language_files() -> void:
    var destination_directory: String = (
        "user://user_database/language"
    )

    var error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(
            destination_directory
        )
    )

    if (
        error != OK
        and error != ERR_ALREADY_EXISTS
    ):
        push_warning(
            "UserDatabaseBootstrap: could not create language directory."
        )
        return

    for file_name: String in BUILTIN_LANGUAGE_FILES:
        var destination: String = (
            destination_directory
            + "/"
            + file_name
        )

        if FileAccess.file_exists(
            destination
        ):
            continue

        var source: String = (
            "res://language/"
            + file_name
        )

        if not FileAccess.file_exists(
            source
        ):
            continue

        var source_file: FileAccess = FileAccess.open(
            source,
            FileAccess.READ
        )

        if source_file == null:
            continue

        var bytes: PackedByteArray = source_file.get_buffer(
            source_file.get_length()
        )
        source_file.close()

        var destination_file: FileAccess = FileAccess.open(
            destination,
            FileAccess.WRITE
        )

        if destination_file == null:
            continue

        destination_file.store_buffer(
            bytes
        )
        destination_file.close()
