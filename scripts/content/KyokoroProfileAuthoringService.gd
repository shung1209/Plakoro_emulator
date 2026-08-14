extends RefCounted


const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")


const SCHEMA_VERSION: String = "2.0"

const PROFILE_DIRECTORY: String = (
    "res://database/kyokoro_profiles"
)

const USER_PROFILE_DIRECTORY: String = (
    "user://user_database/kyokoro_profiles"
)

const ORIENTATIONS: Array[StringName] = [
    &"FACE_DOWN",
    &"FACE_UP",
    &"HEAD_UP",
    &"HEAD_DOWN",
    &"HEAD_LEFT",
    &"HEAD_RIGHT"
]


static func create_default() -> Dictionary:
    return {
        "schema_version": SCHEMA_VERSION,
        "id": "",
        "roll_mode": "weighted",
        "orientation_weights": {
            "FACE_DOWN": 1.0,
            "FACE_UP": 1.0,
            "HEAD_UP": 1.0,
            "HEAD_DOWN": 1.0,
            "HEAD_LEFT": 1.0,
            "HEAD_RIGHT": 1.0
        },
        "scene_path": "",
        "physics_profile": {}
    }


static func validate(
    data: Dictionary
) -> Dictionary:
    var errors: Array[String] = []

    if String(
        data.get(
            "schema_version",
            ""
        )
    ) != SCHEMA_VERSION:
        errors.append(
            "schema_version must be "
            + SCHEMA_VERSION
            + "."
        )

    var profile_id: String = String(
        data.get(
            "id",
            ""
        )
    ).strip_edges()

    if profile_id.is_empty():
        errors.append(
            "Profile ID is required."
        )
    elif not _is_safe_id(
        profile_id
    ):
        errors.append(
            "Profile ID may only use a-z, 0-9 and underscore."
        )

    var roll_mode: String = String(
        data.get(
            "roll_mode",
            ""
        )
    )

    if roll_mode != "weighted":
        errors.append(
            "10.0c supports roll_mode = weighted."
        )

    var weights: Variant = data.get(
        "orientation_weights",
        {}
    )

    if not weights is Dictionary:
        errors.append(
            "orientation_weights must be an object."
        )
    else:
        var total: float = 0.0
        var weight_dict: Dictionary = (
            weights as Dictionary
        )

        for orientation: StringName in ORIENTATIONS:
            var key: String = String(
                orientation
            )

            if not weight_dict.has(
                key
            ):
                errors.append(
                    "Missing orientation weight: "
                    + key
                )
                continue

            var value: float = float(
                weight_dict.get(
                    key,
                    0.0
                )
            )

            if value < 0.0:
                errors.append(
                    key
                    + " weight cannot be negative."
                )

            total += max(
                value,
                0.0
            )

        if total <= 0.0:
            errors.append(
                "Total orientation weight must be greater than 0."
            )

    if not (
        data.get(
            "physics_profile",
            {}
        )
        is Dictionary
    ):
        errors.append(
            "physics_profile must be an object."
        )

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


static func probabilities(
    weights: Dictionary
) -> Dictionary:
    var total: float = 0.0
    var result: Dictionary = {}

    for orientation: StringName in ORIENTATIONS:
        total += max(
            0.0,
            float(
                weights.get(
                    String(orientation),
                    0.0
                )
            )
        )

    for orientation: StringName in ORIENTATIONS:
        var value: float = max(
            0.0,
            float(
                weights.get(
                    String(orientation),
                    0.0
                )
            )
        )

        result[String(orientation)] = (
            value / total
            if total > 0.0
            else 0.0
        )

    return result


static func save(
    data: Dictionary
) -> Dictionary:
    var validation: Dictionary = validate(
        data
    )

    if not bool(
        validation["success"]
    ):
        return validation

    var profile_id: String = String(
        data["id"]
    ).strip_edges().to_lower()

    var directory_error: Error = (
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(
                USER_PROFILE_DIRECTORY
            )
        )
    )

    if (
        directory_error != OK
        and directory_error != ERR_ALREADY_EXISTS
    ):
        return {
            "success": false,
            "errors": [
                "Could not create user://user_database/kyokoro_profiles."
            ]
        }

    var path: String = (
        USER_PROFILE_DIRECTORY
        + "/"
        + profile_id
        + ".json"
    )

    var file: FileAccess = FileAccess.open(
        path,
        FileAccess.WRITE
    )

    if file == null:
        return {
            "success": false,
            "errors": [
                "Could not write "
                + path
                + ". Use Content Studio from the editable Godot project."
            ]
        }

    file.store_string(
        JSON.stringify(
            _ordered_document(
                data
            ),
            "  "
        )
    )

    return {
        "success": true,
        "errors": [],
        "path": path
    }


static func load_by_id(
    profile_id: String
) -> Dictionary:
    var safe_id: String = (
        profile_id.strip_edges().to_lower()
    )

    if safe_id.is_empty():
        return {}

    var path: String = USER_PROFILE_DIRECTORY + "/" + safe_id + ".json"
    if not FileAccess.file_exists(path):
        path = PROFILE_DIRECTORY + "/" + safe_id + ".json"
    if not FileAccess.file_exists(path):
        return {}

    var file: FileAccess = FileAccess.open(
        path,
        FileAccess.READ
    )

    if file == null:
        return {}

    var parsed: Variant = JSON.parse_string(
        file.get_as_text()
    )

    if parsed is Dictionary:
        return parsed

    return {}


static func list_saved() -> Array[String]:
    var result: Array[String] = BUILTIN_MANIFEST.ids_for("kyokoro_profiles")
    var directory: DirAccess = DirAccess.open(USER_PROFILE_DIRECTORY)
    if directory != null:
        directory.list_dir_begin()
        while true:
            var file_name: String = directory.get_next()
            if file_name.is_empty():
                break
            if directory.current_is_dir() or not file_name.ends_with(".json"):
                continue
            var profile_id: String = file_name.trim_suffix(".json")
            if not result.has(profile_id):
                result.append(profile_id)
        directory.list_dir_end()
    result.sort()
    return result


static func _ordered_document(
    source: Dictionary
) -> Dictionary:
    var result: Dictionary = {
        "schema_version": SCHEMA_VERSION,
        "id": String(
            source.get(
                "id",
                ""
            )
        ),
        "roll_mode": String(
            source.get(
                "roll_mode",
                "weighted"
            )
        ),
        "orientation_weights": (
            source.get(
                "orientation_weights",
                {}
            )
        ),
        "scene_path": String(
            source.get(
                "scene_path",
                ""
            )
        ),
        "physics_profile": (
            source.get(
                "physics_profile",
                {}
            )
        )
    }

    # Model Weight Generator provenance is editor metadata. Preserve it when
    # the generated profile is subsequently edited/saved in Content Studio.
    if source.get(
        "model_analysis",
        null
    ) is Dictionary:
        result["model_analysis"] = (
            source["model_analysis"] as Dictionary
        ).duplicate(true)

    return result


static func _is_safe_id(
    content_id: String
) -> bool:
    for character: String in content_id:
        var code: int = (
            character.unicode_at(0)
        )

        var is_lower: bool = (
            code >= 97
            and code <= 122
        )
        var is_digit: bool = (
            code >= 48
            and code <= 57
        )

        if (
            not is_lower
            and not is_digit
            and character != "_"
        ):
            return false

    return true
