extends RefCounted


const BUILTIN_MANIFEST: Script = preload("res://scripts/content/BuiltinDatabaseManifest.gd")


const SCHEMA_VERSION: String = "2.0"

const DEFAULT_DICE_GENERATOR: Script = preload(
    "res://scripts/dice/setup/PokemonDefaultDiceGenerator.gd"
)

const POKEMON_DIRECTORY: String = (
    "res://database/pokemon"
)

const USER_POKEMON_DIRECTORY: String = (
    "user://user_database/pokemon"
)

const KYOKORO_PROFILE_DIRECTORY: String = (
    "res://database/kyokoro_profiles"
)

const USER_KYOKORO_PROFILE_DIRECTORY: String = (
    "user://user_database/kyokoro_profiles"
)

const MOVE_DIRECTORY_CANDIDATES: Array[String] = [
    "user://user_database/move_cards",
    "res://database/move_cards",
    "res://database/moves"
]

const VALID_TYPES: Array[String] = [
    "normal",
    "grass",
    "fire",
    "water",
    "electric",
    "psychic",
    "fighting",
    "dark",
    "steel",
    "flying"
]


static func create_default() -> Dictionary:
    return {
        "schema_version": SCHEMA_VERSION,
        "id": "",
        "species_id": "",
        "display_name": "",
        "pokemon_type": "normal",
        "max_hp": 100,
        "weaknesses": [],
        "available_move_card_ids": [],
        "kyokoro_profile_id": "standard_equal"
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

    var content_id: String = String(
        data.get(
            "id",
            ""
        )
    ).strip_edges()

    if content_id.is_empty():
        errors.append(
            "Pokémon ID is required."
        )
    elif not _is_safe_id(content_id):
        errors.append(
            "Pokémon ID may only use a-z, 0-9 and underscore."
        )

    var species_id: String = String(
        data.get(
            "species_id",
            ""
        )
    ).strip_edges()

    if species_id.is_empty():
        errors.append(
            "species_id is required."
        )
    elif not _is_safe_id(species_id):
        errors.append(
            "species_id may only use a-z, 0-9 and underscore."
        )

    if String(
        data.get(
            "display_name",
            ""
        )
    ).strip_edges().is_empty():
        errors.append(
            "Display name is required."
        )

    var pokemon_type: String = String(
        data.get(
            "pokemon_type",
            ""
        )
    ).to_lower()

    if not VALID_TYPES.has(
        pokemon_type
    ):
        errors.append(
            "pokemon_type is invalid."
        )

    if int(
        data.get(
            "max_hp",
            0
        )
    ) <= 0:
        errors.append(
            "max_hp must be greater than 0."
        )

    var weaknesses: Variant = data.get(
        "weaknesses",
        []
    )

    if not weaknesses is Array:
        errors.append(
            "weaknesses must be an array."
        )
    else:
        for weakness: Variant in weaknesses:
            if not weakness is Dictionary:
                errors.append(
                    "Each weakness must be an object."
                )
                continue

            var weakness_dict: Dictionary = (
                weakness as Dictionary
            )

            var attack_type: String = String(
                weakness_dict.get(
                    "attack_type",
                    ""
                )
            ).to_lower()

            if not VALID_TYPES.has(
                attack_type
            ):
                errors.append(
                    "Weakness attack_type is invalid: "
                    + attack_type
                )

            if int(
                weakness_dict.get(
                    "bonus_damage",
                    -1
                )
            ) < 0:
                errors.append(
                    "Weakness bonus_damage cannot be negative."
                )

    var move_ids: Variant = data.get(
        "available_move_card_ids",
        []
    )

    if not move_ids is Array:
        errors.append(
            "available_move_card_ids must be an array."
        )
    else:
        var seen: Dictionary = {}

        for raw_move_id: Variant in move_ids:
            var move_id: String = String(
                raw_move_id
            ).strip_edges()

            if move_id.is_empty():
                errors.append(
                    "Move ID cannot be empty."
                )
                continue

            if seen.has(
                move_id
            ):
                errors.append(
                    "Duplicate Move ID: "
                    + move_id
                )

            seen[move_id] = true

    var kyokoro_profile_id: String = String(
        data.get(
            "kyokoro_profile_id",
            ""
        )
    ).strip_edges()

    if kyokoro_profile_id.is_empty():
        errors.append(
            "kyokoro_profile_id is required."
        )

    return {
        "success": errors.is_empty(),
        "errors": errors
    }


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

    var content_id: String = String(
        data["id"]
    ).strip_edges().to_lower()

    var path: String = (
        USER_POKEMON_DIRECTORY
        + "/"
        + content_id
        + ".json"
    )

    var absolute_directory: String = (
        ProjectSettings.globalize_path(
            USER_POKEMON_DIRECTORY
        )
    )

    var directory_error: Error = (
        DirAccess.make_dir_recursive_absolute(
            absolute_directory
        )
    )

    if (
        directory_error != OK
        and directory_error != ERR_ALREADY_EXISTS
    ):
        return {
            "success": false,
            "errors": [
                "Could not create user://user_database/pokemon."
            ]
        }

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
                + ". Run Content Studio from the editable Godot project, not a read-only exported PCK."
            ]
        }

    file.store_string(
        JSON.stringify(
            _ordered_document(data),
            "  "
        )
    )
    file.close()

    var dice_result: Dictionary = (
        DEFAULT_DICE_GENERATOR
        .ensure_default_for_pokemon(
            data,
            "user://user_database/dice_setups"
        )
    )

    if not bool(
        dice_result.get(
            "success",
            false
        )
    ):
        return {
            "success": false,
            "errors": [
                "Pokémon JSON was saved, but Default Dice generation failed:"
            ] + dice_result.get(
                "errors",
                []
            ),
            "path": path
        }

    return {
        "success": true,
        "errors": [],
        "path": path,
        "default_dice_path": String(
            dice_result.get(
                "path",
                ""
            )
        ),
        "default_dice_created": bool(
            dice_result.get(
                "created",
                false
            )
        )
    }


static func load_by_id(
    content_id: String
) -> Dictionary:
    var safe_id: String = (
        content_id.strip_edges().to_lower()
    )

    if safe_id.is_empty():
        return {}

    var user_path: String = USER_POKEMON_DIRECTORY + "/" + safe_id + ".json"
    if FileAccess.file_exists(user_path):
        return _load_dictionary(user_path)

    return _load_dictionary(POKEMON_DIRECTORY + "/" + safe_id + ".json")


static func list_saved() -> Array[String]:
    return _merge_user_and_builtin_ids(USER_POKEMON_DIRECTORY, "pokemon")


static func list_kyokoro_profiles() -> Array[String]:
    return _merge_user_and_builtin_ids(USER_KYOKORO_PROFILE_DIRECTORY, "kyokoro_profiles")


static func kyokoro_profile_exists(
    profile_id: String
) -> bool:
    if profile_id.strip_edges().is_empty():
        return false

    var file_name: String = profile_id.strip_edges() + ".json"
    return (
        FileAccess.file_exists(USER_KYOKORO_PROFILE_DIRECTORY + "/" + file_name)
        or FileAccess.file_exists(KYOKORO_PROFILE_DIRECTORY + "/" + file_name)
    )


static func list_move_card_ids() -> Array[String]:
    var result: Array[String] = BUILTIN_MANIFEST.ids_for("move_cards")
    for move_id: String in _list_json_ids("user://user_database/move_cards"):
        if not result.has(move_id):
            result.append(move_id)
    # Legacy res://database/moves is development-only fallback.
    for move_id: String in _list_json_ids("res://database/moves"):
        if not result.has(move_id):
            result.append(move_id)
    result.sort()
    return result


static func _merge_user_and_builtin_ids(user_directory: String, manifest_directory: String) -> Array[String]:
    var result: Array[String] = BUILTIN_MANIFEST.ids_for(manifest_directory)
    for content_id: String in _list_json_ids(user_directory):
        if not result.has(content_id):
            result.append(content_id)
    result.sort()
    return result


static func _merge_json_ids(directories: Array[String]) -> Array[String]:
    var result: Array[String] = []
    for directory: String in directories:
        for content_id: String in _list_json_ids(directory):
            if not result.has(content_id):
                result.append(content_id)
    result.sort()
    return result


static func _ordered_document(
    source: Dictionary
) -> Dictionary:
    # Match the V2 Pokémon JSON schema already used by the project.
    var result: Dictionary = {
        "schema_version": SCHEMA_VERSION,
        "id": String(
            source.get(
                "id",
                ""
            )
        ),
        "species_id": String(
            source.get(
                "species_id",
                ""
            )
        ),
        "display_name": String(
            source.get(
                "display_name",
                ""
            )
        ),
        "pokemon_type": String(
            source.get(
                "pokemon_type",
                "normal"
            )
        ),
        "max_hp": int(
            source.get(
                "max_hp",
                100
            )
        ),
        "weaknesses": (
            source.get(
                "weaknesses",
                []
            )
        ),
        "available_move_card_ids": (
            source.get(
                "available_move_card_ids",
                []
            )
        ),
        "kyokoro_profile_id": String(
            source.get(
                "kyokoro_profile_id",
                ""
            )
        )
    }

    # Preserve the existing optional review metadata if this document was
    # loaded from the project database.
    if source.has(
        "review"
    ):
        result["review"] = source["review"]

    return result


static func _list_json_ids(
    directory_path: String
) -> Array[String]:
    var result: Array[String] = []

    var directory: DirAccess = DirAccess.open(
        directory_path
    )

    if directory == null:
        return result

    directory.list_dir_begin()

    while true:
        var file_name: String = (
            directory.get_next()
        )

        if file_name.is_empty():
            break

        if directory.current_is_dir():
            continue

        if not file_name.ends_with(
            ".json"
        ):
            continue

        result.append(
            file_name.trim_suffix(
                ".json"
            )
        )

    directory.list_dir_end()
    result.sort()

    return result


static func _load_dictionary(
    path: String
) -> Dictionary:
    if not FileAccess.file_exists(
        path
    ):
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
