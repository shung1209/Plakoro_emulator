extends RefCounted


const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const KYOKORO_AUTHORING: Script = preload(
    "res://scripts/content/KyokoroProfileAuthoringService.gd"
)


const MODE_POKEMON: StringName = &"pokemon"
const MODE_KYOKORO: StringName = &"kyokoro"
const MODE_MOVE: StringName = &"move"

const PLAYER_BATTLE_LOADOUT_PATH: String = (
    "user://user_database/loadouts/player_battle_loadout.json"
)
const AI_BATTLE_LOADOUT_PATH: String = (
    "user://user_database/loadouts/ai_battle_loadout.json"
)


static func preview_delete(
    mode: StringName,
    content_id: String
) -> Dictionary:
    var normalized_id: String = (
        content_id.strip_edges().to_lower()
    )

    if normalized_id.is_empty():
        return {
            "success": false,
            "blocked": true,
            "errors": [
                "No database entry is selected."
            ]
        }

    match mode:
        MODE_POKEMON:
            return _preview_pokemon(
                normalized_id
            )
        MODE_MOVE:
            return _preview_move(
                normalized_id
            )
        MODE_KYOKORO:
            return _preview_kyokoro(
                normalized_id
            )

    return {
        "success": false,
        "blocked": true,
        "errors": [
            "Unsupported Content Studio mode."
        ]
    }


static func delete(
    mode: StringName,
    content_id: String
) -> Dictionary:
    var preview: Dictionary = preview_delete(
        mode,
        content_id
    )

    if not bool(
        preview.get(
            "success",
            false
        )
    ):
        return preview

    if bool(
        preview.get(
            "blocked",
            false
        )
    ):
        return {
            "success": false,
            "blocked": true,
            "errors": preview.get(
                "errors",
                [
                    "Delete is blocked."
                ]
            )
        }

    var normalized_id: String = (
        content_id.strip_edges().to_lower()
    )

    var stale_loadouts_removed: Array[String] = []

    if mode == MODE_MOVE:
        var cleanup: Dictionary = (
            _remove_move_references(
                normalized_id
            )
        )

        if not bool(
            cleanup.get(
                "success",
                false
            )
        ):
            return cleanup

        var loadout_cleanup: Dictionary = (
            _remove_stale_battle_loadouts(
                normalized_id
            )
        )

        if not bool(
            loadout_cleanup.get(
                "success",
                false
            )
        ):
            return loadout_cleanup

        stale_loadouts_removed = (
            loadout_cleanup.get(
                "removed",
                []
            )
        )

    var path: String = String(
        preview.get(
            "path",
            ""
        )
    )

    if path.is_empty():
        return {
            "success": false,
            "blocked": false,
            "errors": [
                "Delete path could not be resolved."
            ]
        }

    if not FileAccess.file_exists(
        path
    ):
        return {
            "success": false,
            "blocked": false,
            "errors": [
                "JSON file no longer exists: "
                + path
            ]
        }

    var error: Error = DirAccess.remove_absolute(
        ProjectSettings.globalize_path(
            path
        )
    )

    if error != OK:
        return {
            "success": false,
            "blocked": false,
            "errors": [
                "Could not delete "
                + path
                + " (Error "
                + str(
                    int(
                        error
                    )
                )
                + ")."
            ]
        }

    return {
        "success": true,
        "blocked": false,
        "path": path,
        "content_id": normalized_id,
        "cleaned_references": preview.get(
            "references",
            []
        ),
        "stale_loadouts_removed": stale_loadouts_removed,
        "errors": []
    }


static func _preview_pokemon(
    pokemon_id: String
) -> Dictionary:
    var data: Dictionary = (
        POKEMON_AUTHORING.load_by_id(
            pokemon_id
        )
    )

    if data.is_empty():
        return _missing_result(
            "Pokémon",
            pokemon_id
        )

    var user_path: String = "user://user_database/pokemon/" + pokemon_id + ".json"
    if not FileAccess.file_exists(user_path):
        return {
            "success": true,
            "blocked": true,
            "kind": "Pokémon",
            "content_id": pokemon_id,
            "display_name": String(data.get("display_name", pokemon_id)),
            "path": user_path,
            "warnings": [],
            "references": [],
            "errors": ["Built-in Pokémon is read-only. Save an override before deleting it."]
        }

    var species_id: String = String(
        data.get(
            "species_id",
            ""
        )
    ).strip_edges().to_lower()

    return {
        "success": true,
        "blocked": false,
        "kind": "Pokémon",
        "content_id": pokemon_id,
        "display_name": String(
            data.get(
                "display_name",
                pokemon_id
            )
        ),
        "path": (
            "user://user_database/pokemon/"
            + pokemon_id
            + ".json"
        ),
        "warnings": [
            (
                "Only the Pokémon JSON will be deleted."
            ),
            (
                "The species Default Dice file is preserved because other "
                + "Pokémon variants may share species_id '"
                + species_id
                + "'."
            )
        ],
        "references": []
    }


static func _preview_move(
    move_id: String
) -> Dictionary:
    var data: Dictionary = (
        MOVE_AUTHORING.load_by_id(
            move_id
        )
    )

    if data.is_empty():
        return _missing_result(
            "Move",
            move_id
        )

    var user_path: String = "user://user_database/move_cards/" + move_id + ".json"
    if not FileAccess.file_exists(user_path):
        return {
            "success": true,
            "blocked": true,
            "kind": "Move",
            "content_id": move_id,
            "display_name": String(data.get("display_name", move_id)),
            "path": user_path,
            "warnings": [],
            "references": [],
            "errors": ["Built-in Move is read-only. Save an override before deleting it."]
        }

    var references: Array[String] = (
        _find_move_references(
            move_id
        )
    )
    var warnings: Array[String] = []

    if not references.is_empty():
        warnings.append(
            (
                "This Move is currently referenced by "
                + str(
                    references.size()
                )
                + " Pokémon JSON file(s). Those references will be removed "
                + "before the Move JSON is deleted."
            )
        )

    return {
        "success": true,
        "blocked": false,
        "kind": "Move",
        "content_id": move_id,
        "display_name": String(
            data.get(
                "display_name",
                move_id
            )
        ),
        "path": (
            "user://user_database/move_cards/"
            + move_id
            + ".json"
        ),
        "warnings": warnings,
        "references": references
    }


static func _preview_kyokoro(
    profile_id: String
) -> Dictionary:
    var data: Dictionary = (
        KYOKORO_AUTHORING.load_by_id(
            profile_id
        )
    )

    if data.is_empty():
        return _missing_result(
            "Charakoro Profile",
            profile_id
        )

    var user_path: String = "user://user_database/kyokoro_profiles/" + profile_id + ".json"
    if not FileAccess.file_exists(user_path):
        return {
            "success": true,
            "blocked": true,
            "kind": "Charakoro Profile",
            "content_id": profile_id,
            "display_name": profile_id,
            "path": user_path,
            "warnings": [],
            "references": [],
            "errors": ["Built-in Charakoro Profile is read-only. Save an override before deleting it."]
        }

    var references: Array[String] = (
        _find_kyokoro_references(
            profile_id
        )
    )

    if not references.is_empty():
        return {
            "success": true,
            "blocked": true,
            "kind": "Charakoro Profile",
            "content_id": profile_id,
            "display_name": profile_id,
            "path": (
                "user://user_database/kyokoro_profiles/"
                + profile_id
                + ".json"
            ),
            "warnings": [],
            "references": references,
            "errors": [
                (
                    "Delete is blocked because this Charakoro Profile is used by: "
                    + ", ".join(
                        references
                    )
                )
            ]
        }

    return {
        "success": true,
        "blocked": false,
        "kind": "Charakoro Profile",
        "content_id": profile_id,
        "display_name": profile_id,
        "path": (
            "user://user_database/kyokoro_profiles/"
            + profile_id
            + ".json"
        ),
        "warnings": [],
        "references": []
    }


static func _find_move_references(
    move_id: String
) -> Array[String]:
    var result: Array[String] = []

    for pokemon_id: String in (
        POKEMON_AUTHORING.list_saved()
    ):
        var data: Dictionary = (
            POKEMON_AUTHORING.load_by_id(
                pokemon_id
            )
        )

        if data.is_empty():
            continue

        var raw_moves: Variant = data.get(
            "available_move_card_ids",
            []
        )

        if (
            raw_moves is Array
            and (
                raw_moves as Array
            ).has(
                move_id
            )
        ):
            result.append(
                pokemon_id
            )

    return result


static func _find_kyokoro_references(
    profile_id: String
) -> Array[String]:
    var result: Array[String] = []

    for pokemon_id: String in (
        POKEMON_AUTHORING.list_saved()
    ):
        var data: Dictionary = (
            POKEMON_AUTHORING.load_by_id(
                pokemon_id
            )
        )

        if data.is_empty():
            continue

        if String(
            data.get(
                "kyokoro_profile_id",
                ""
            )
        ).strip_edges().to_lower() == profile_id:
            result.append(
                pokemon_id
            )

    return result


static func _remove_move_references(
    move_id: String
) -> Dictionary:
    var updated: Array[String] = []
    var errors: Array[String] = []

    for pokemon_id: String in (
        _find_move_references(
            move_id
        )
    ):
        var data: Dictionary = (
            POKEMON_AUTHORING.load_by_id(
                pokemon_id
            )
        )

        if data.is_empty():
            continue

        var cleaned: Array[String] = []
        var raw_moves: Variant = data.get(
            "available_move_card_ids",
            []
        )

        if raw_moves is Array:
            for raw_move_id: Variant in (
                raw_moves as Array
            ):
                var existing_id: String = (
                    String(
                        raw_move_id
                    )
                    .strip_edges()
                    .to_lower()
                )

                if (
                    not existing_id.is_empty()
                    and existing_id != move_id
                ):
                    cleaned.append(
                        existing_id
                    )

        data[
            "available_move_card_ids"
        ] = cleaned

        var save_result: Dictionary = (
            POKEMON_AUTHORING.save(
                data
            )
        )

        if bool(
            save_result.get(
                "success",
                false
            )
        ):
            updated.append(
                pokemon_id
            )
        else:
            errors.append(
                (
                    pokemon_id
                    + ": "
                    + "; ".join(
                        save_result.get(
                            "errors",
                            []
                        )
                    )
                )
            )

    return {
        "success": errors.is_empty(),
        "blocked": false,
        "updated": updated,
        "errors": errors
    }


static func _remove_stale_battle_loadouts(
    move_id: String
) -> Dictionary:
    var removed: Array[String] = []
    var errors: Array[String] = []

    for path: String in [
        PLAYER_BATTLE_LOADOUT_PATH,
        AI_BATTLE_LOADOUT_PATH
    ]:
        if not FileAccess.file_exists(path):
            continue

        var file: FileAccess = FileAccess.open(
            path,
            FileAccess.READ
        )

        if file == null:
            errors.append(
                "Could not inspect " + path
            )
            continue

        var parsed: Variant = JSON.parse_string(
            file.get_as_text()
        )
        file.close()

        if not parsed is Dictionary:
            continue

        var raw_moves: Variant = (
            parsed as Dictionary
        ).get(
            "move_card_ids",
            []
        )

        if not raw_moves is Array:
            continue

        var references_deleted_move: bool = false

        for raw_move_id: Variant in raw_moves:
            if (
                String(raw_move_id)
                .strip_edges()
                .to_lower()
                == move_id
            ):
                references_deleted_move = true
                break

        if not references_deleted_move:
            continue

        var remove_error: Error = (
            DirAccess.remove_absolute(
                ProjectSettings.globalize_path(
                    path
                )
            )
        )

        if remove_error == OK:
            removed.append(path)
        else:
            errors.append(
                "Could not remove stale battle loadout "
                + path
            )

    return {
        "success": errors.is_empty(),
        "removed": removed,
        "errors": errors
    }


static func _missing_result(
    kind: String,
    content_id: String
) -> Dictionary:
    return {
        "success": false,
        "blocked": false,
        "errors": [
            (
                kind
                + " JSON could not be loaded: "
                + content_id
            )
        ]
    }
