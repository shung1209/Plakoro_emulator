extends RefCounted


const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")


const BUILTIN_ROOT: String = "res://database"
const ROOT: String = "user://user_database"
const DICE_SETUPS: String = ROOT + "/dice_setups"
const KYOKORO_PROFILES: String = ROOT + "/kyokoro_profiles"
const KYOKORO_RESULTS: String = ROOT + "/kyokoro_results"
const MOVE_CARDS: String = ROOT + "/move_cards"
const POKEMON: String = ROOT + "/pokemon"
const LOADOUTS: String = ROOT + "/loadouts"
const REFERENCE: String = ROOT + "/reference"
const RULES: String = ROOT + "/rules"
const LANGUAGE: String = ROOT + "/language"

const PLAYER_ENERGY_DICE_PATH: String = DICE_SETUPS + "/player_energy_dice_setup.json"
const PLAYER_LOADOUT_PATH: String = LOADOUTS + "/player_battle_loadout.json"
const AI_LOADOUT_PATH: String = LOADOUTS + "/ai_battle_loadout.json"

const REQUIRED_DIRECTORY_NAMES: Array[String] = [
    "dice_setups",
    "kyokoro_profiles",
    "kyokoro_results",
    "move_cards",
    "pokemon",
    "loadouts",
    "reference",
    "rules",
    "language"
]

const REQUIRED_DIRECTORIES: Array[String] = [
    DICE_SETUPS,
    KYOKORO_PROFILES,
    KYOKORO_RESULTS,
    MOVE_CARDS,
    POKEMON,
    LOADOUTS,
    REFERENCE,
    RULES,
    LANGUAGE
]

# Root-level database files that are runtime content rather than development reports.
const BUILTIN_ROOT_JSON_FILES: Array[String] = [
    "catalog.json",
    "kyokoro_orientation_map.json"
]

const LEGACY_USER_FILES: Dictionary = {
    "user://player_energy_dice_setup.json": PLAYER_ENERGY_DICE_PATH,
    "user://player_battle_loadout.json": PLAYER_LOADOUT_PATH,
    "user://ai_battle_loadout.json": AI_LOADOUT_PATH
}

# Old development fixtures that were previously shipped by mistake.
# These exact IDs are removed once from user_database as part of startup cleanup.
const RETIRED_TEST_CONTENT_PATHS: Array[String] = [
    POKEMON + "/pikachu_test.json",
    MOVE_CARDS + "/test.json",
    MOVE_CARDS + "/test_pikachu_move.json"
]


static func ensure_layout() -> bool:
    return ensure_layout_at(ROOT)


static func ensure_layout_at(root_path: String) -> bool:
    var root_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(root_path)
    )
    if root_error != OK and root_error != ERR_ALREADY_EXISTS:
        push_error("UserDatabasePathService: could not create " + root_path)
        return false

    for directory_name: String in REQUIRED_DIRECTORY_NAMES:
        var directory: String = root_path.path_join(directory_name)
        var error: Error = DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(directory)
        )
        if error != OK and error != ERR_ALREADY_EXISTS:
            push_error("UserDatabasePathService: could not create " + directory)
            return false
    return true


# First-run/update bootstrap policy:
# - Always ensure the complete user_database folder layout exists.
# - Copy built-in content JSON into user_database when the destination file is missing.
# - Never overwrite an existing user JSON file.
# This allows first launch to start with editable copies while preserving user changes on later launches.
static func bootstrap_from_builtin_database(
    destination_root: String = ROOT,
    source_root: String = BUILTIN_ROOT
) -> Dictionary:
    var root_existed: bool = DirAccess.dir_exists_absolute(
        ProjectSettings.globalize_path(destination_root)
    )
    var result: Dictionary = {
        "success": ensure_layout_at(destination_root),
        "first_run": not root_existed,
        "copied": [],
        "skipped_existing": [],
        "errors": []
    }
    if not bool(result["success"]):
        result["errors"].append("Could not initialize user_database layout.")
        return result

    # Export-safe: do not enumerate res:// database directories at runtime.
    # Built-in JSON files are addressed explicitly through a generated manifest,
    # so the same bootstrap works in Editor, native Linux and Windows/Proton PCKs.
    for file_name: String in BUILTIN_MANIFEST.ROOT_JSON_FILES:
        _copy_json_if_missing(
            source_root.path_join(file_name),
            destination_root.path_join(file_name),
            result
        )

    for directory_name: String in REQUIRED_DIRECTORY_NAMES:
        for file_name: String in BUILTIN_MANIFEST.files_for(directory_name):
            _copy_json_if_missing(
                source_root.path_join(directory_name).path_join(file_name),
                destination_root.path_join(directory_name).path_join(file_name),
                result
            )

    return result


static func _copy_json_tree_if_missing(
    source_directory: String,
    destination_directory: String,
    result: Dictionary
) -> void:
    var source_dir: DirAccess = DirAccess.open(source_directory)
    if source_dir == null:
        result["success"] = false
        result["errors"].append("Could not open built-in directory: " + source_directory)
        return

    var make_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(destination_directory)
    )
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        result["success"] = false
        result["errors"].append("Could not create user directory: " + destination_directory)
        return

    for file_name: String in source_dir.get_files():
        if file_name.get_extension().to_lower() != "json":
            continue
        _copy_json_if_missing(
            source_directory.path_join(file_name),
            destination_directory.path_join(file_name),
            result
        )

    for child_directory: String in source_dir.get_directories():
        _copy_json_tree_if_missing(
            source_directory.path_join(child_directory),
            destination_directory.path_join(child_directory),
            result
        )


static func _copy_json_if_missing(
    source_path: String,
    destination_path: String,
    result: Dictionary
) -> void:
    if not FileAccess.file_exists(source_path):
        return
    if FileAccess.file_exists(destination_path):
        result["skipped_existing"].append(destination_path)
        return

    var parent_directory: String = destination_path.get_base_dir()
    var make_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(parent_directory)
    )
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        result["success"] = false
        result["errors"].append("Could not create destination directory: " + parent_directory)
        return

    var source: FileAccess = FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        result["success"] = false
        result["errors"].append("Could not read built-in JSON: " + source_path)
        return
    var bytes: PackedByteArray = source.get_buffer(source.get_length())
    source.close()

    var destination: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
    if destination == null:
        result["success"] = false
        result["errors"].append("Could not create user JSON: " + destination_path)
        return
    destination.store_buffer(bytes)
    destination.close()
    result["copied"].append(destination_path)


static func migrate_legacy_user_files() -> Dictionary:
    var result: Dictionary = {
        "success": ensure_layout(),
        "migrated": [],
        "errors": []
    }
    if not bool(result["success"]):
        result["errors"].append("Could not initialize user_database layout.")
        return result

    for old_path: String in LEGACY_USER_FILES.keys():
        var new_path: String = String(LEGACY_USER_FILES[old_path])
        if old_path == new_path:
            continue
        if not FileAccess.file_exists(old_path) or FileAccess.file_exists(new_path):
            continue
        var source: FileAccess = FileAccess.open(old_path, FileAccess.READ)
        if source == null:
            result["success"] = false
            result["errors"].append("Could not read legacy file: " + old_path)
            continue
        var bytes: PackedByteArray = source.get_buffer(source.get_length())
        source.close()
        var destination: FileAccess = FileAccess.open(new_path, FileAccess.WRITE)
        if destination == null:
            result["success"] = false
            result["errors"].append("Could not migrate legacy file to: " + new_path)
            continue
        destination.store_buffer(bytes)
        destination.close()
        result["migrated"].append(new_path)
    return result


# v2.2 data correction migration.
# Built-in content is mirrored to user:// only when missing, so users who already
# launched a previous v2.2 build may still have the provisional weakness values.
# Patch only the exact known old values, preserving any other user edits.
static func migrate_v22_corrected_weaknesses() -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "updated": [],
        "skipped": [],
        "errors": []
    }

    var corrections: Array[Dictionary] = [
        {
            "path": POKEMON + "/gengar_standard.json",
            "old_type": "dark",
            "new_type": "psychic",
            "bonus": 20.0
        },
        {
            "path": POKEMON + "/lucario_standard.json",
            "old_type": "psychic",
            "new_type": "fire",
            "bonus": 20.0
        }
    ]

    for correction: Dictionary in corrections:
        var path: String = String(correction.get("path", ""))
        if not FileAccess.file_exists(path):
            result["skipped"].append(path)
            continue

        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null:
            result["success"] = false
            result["errors"].append("Could not read corrected Pokemon JSON: " + path)
            continue

        var parsed: Variant = JSON.parse_string(file.get_as_text())
        file.close()
        if not parsed is Dictionary:
            result["success"] = false
            result["errors"].append("Invalid corrected Pokemon JSON: " + path)
            continue

        var data: Dictionary = parsed as Dictionary
        var weaknesses_variant: Variant = data.get("weaknesses", [])
        if not weaknesses_variant is Array:
            result["skipped"].append(path)
            continue

        var weaknesses: Array = weaknesses_variant as Array
        if weaknesses.size() != 1 or not weaknesses[0] is Dictionary:
            result["skipped"].append(path)
            continue

        var weakness: Dictionary = weaknesses[0] as Dictionary
        var old_type: String = String(correction.get("old_type", ""))
        var bonus: float = float(correction.get("bonus", 20.0))
        if (
            String(weakness.get("attack_type", "")).to_lower() != old_type
            or not is_equal_approx(float(weakness.get("bonus_damage", 0.0)), bonus)
        ):
            result["skipped"].append(path)
            continue

        weakness["attack_type"] = String(correction.get("new_type", old_type))
        weakness["bonus_damage"] = bonus
        data["weaknesses"] = [weakness]

        var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
        if output == null:
            result["success"] = false
            result["errors"].append("Could not update corrected Pokemon JSON: " + path)
            continue
        output.store_string(JSON.stringify(data, "  ") + "\n")
        output.close()
        result["updated"].append(path)

    return result


# V2.3 hotfix: early Metagross data shipped Beam without its confirmed
# Charakoro faces. Patch only the exact empty legacy value so custom mappings
# remain untouched.
static func migrate_v23_metagross_beam_orientation() -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "updated": [],
        "skipped": [],
        "errors": []
    }
    var card_path: String = MOVE_CARDS + "/metagross_beam_stw08_001.json"
    if FileAccess.file_exists(card_path):
        var card: Dictionary = _read_json_dictionary(card_path)
        if card.is_empty():
            result["success"] = false
            result["errors"].append("Invalid Metagross Beam JSON: " + card_path)
        elif (card.get("outcome_rules", []) as Array).is_empty():
            card["outcome_rules"] = [_metagross_beam_outcome_rule()]
            if _write_json_dictionary(card_path, card):
                result["updated"].append(card_path)
            else:
                result["success"] = false
                result["errors"].append("Could not update Metagross Beam JSON: " + card_path)
        else:
            result["skipped"].append(card_path)

    var map_path: String = ROOT + "/kyokoro_orientation_map.json"
    if FileAccess.file_exists(map_path):
        var orientation_map: Dictionary = _read_json_dictionary(map_path)
        var mappings: Dictionary = orientation_map.get(
            "confirmed_effect_mappings",
            {}
        ) as Dictionary
        var current_faces: Variant = mappings.get(
            "metagross_beam_stw08_001",
            null
        )
        if current_faces is Array and (current_faces as Array).is_empty():
            mappings["metagross_beam_stw08_001"] = ["HEAD_UP", "FACE_UP"]
            orientation_map["confirmed_effect_mappings"] = mappings
            if _write_json_dictionary(map_path, orientation_map):
                result["updated"].append(map_path)
            else:
                result["success"] = false
                result["errors"].append("Could not update orientation map: " + map_path)
        else:
            result["skipped"].append(map_path)

    return result


static func _metagross_beam_outcome_rule() -> Dictionary:
    return {
        "condition": {
            "type": "kyokoro_orientation_any",
            "orientations": ["HEAD_UP", "FACE_UP"]
        },
        "actions": [
            {
                "opcode": "damage.add",
                "args": {"target": "opponent", "amount": 20}
            }
        ],
        "raw_text": "This attack does 20 more damage."
    }


static func _read_json_dictionary(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed as Dictionary if parsed is Dictionary else {}


static func _write_json_dictionary(path: String, data: Dictionary) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "  ") + "\n")
    file.close()
    return true


static func remove_retired_test_content() -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "removed": [],
        "errors": []
    }

    for path: String in RETIRED_TEST_CONTENT_PATHS:
        if not FileAccess.file_exists(path):
            continue
        var error: Error = DirAccess.remove_absolute(
            ProjectSettings.globalize_path(path)
        )
        if error == OK:
            result["removed"].append(path)
        else:
            result["success"] = false
            result["errors"].append("Could not remove retired test content: " + path)

    return result


static func user_path_for_builtin_path(source_path: String) -> String:
    if not source_path.begins_with(BUILTIN_ROOT + "/"):
        return source_path
    var relative_path: String = source_path.trim_prefix(BUILTIN_ROOT + "/")
    return ROOT.path_join(relative_path)


static func ensure_user_editable_copy(source_path: String) -> String:
    # Editable runtime content must never target res:// in an exported build.
    # Map built-in database paths to the matching user_database override and
    # copy the shipped JSON once when the user copy does not exist yet.
    var destination_path: String = user_path_for_builtin_path(source_path)
    if destination_path == source_path:
        return source_path
    if FileAccess.file_exists(destination_path):
        return destination_path
    if not FileAccess.file_exists(source_path):
        return destination_path

    var parent_directory: String = destination_path.get_base_dir()
    var make_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(parent_directory)
    )
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        push_error("UserDatabasePathService: could not create " + parent_directory)
        return ""

    var source: FileAccess = FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        push_error("UserDatabasePathService: could not read " + source_path)
        return ""
    var bytes: PackedByteArray = source.get_buffer(source.get_length())
    source.close()

    var destination: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
    if destination == null:
        push_error("UserDatabasePathService: could not create " + destination_path)
        return ""
    destination.store_buffer(bytes)
    destination.close()
    return destination_path


static func user_json_path(directory: String, content_id: String) -> String:
    var normalized: String = content_id.strip_edges().to_lower()
    if normalized.is_empty():
        return ""
    return directory + "/" + normalized + ".json"
