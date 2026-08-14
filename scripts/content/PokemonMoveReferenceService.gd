extends RefCounted


const POKEMON_AUTHORING: Script = preload(
    "res://scripts/content/PokemonAuthoringService.gd"
)


static func list_pokemon_usage(
    move_id: String,
    owner_id: String
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var normalized_move_id: String = (
        move_id.strip_edges().to_lower()
    )
    var normalized_owner_id: String = (
        owner_id.strip_edges().to_lower()
    )

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

        var species_id: String = String(
            data.get(
                "species_id",
                ""
            )
        ).strip_edges().to_lower()

        if species_id != normalized_owner_id:
            continue

        var move_ids: Variant = data.get(
            "available_move_card_ids",
            []
        )
        var referenced: bool = false

        if move_ids is Array:
            referenced = (
                move_ids as Array
            ).has(
                normalized_move_id
            )

        result.append(
            {
                "pokemon_id": pokemon_id,
                "species_id": species_id,
                "display_name": String(
                    data.get(
                        "display_name",
                        pokemon_id
                    )
                ),
                "referenced": referenced
            }
        )

    return result


static func apply_assignments(
    move_id: String,
    owner_id: String,
    selected_pokemon_ids: Array[String],
    previous_move_id: String = ""
) -> Dictionary:
    var errors: Array[String] = []
    var updated: Array[String] = []

    var current_id: String = (
        move_id.strip_edges().to_lower()
    )
    var _previous_id: String = (
        previous_move_id.strip_edges().to_lower()
    )
    var normalized_owner_id: String = (
        owner_id.strip_edges().to_lower()
    )

    if current_id.is_empty():
        return {
            "success": false,
            "errors": [
                "Move ID is required."
            ],
            "updated": []
        }

    if normalized_owner_id.is_empty():
        return {
            "success": false,
            "errors": [
                "owner_id is required before assigning Pokémon."
            ],
            "updated": []
        }

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

        var species_id: String = String(
            data.get(
                "species_id",
                ""
            )
        ).strip_edges().to_lower()

        var raw_move_ids: Variant = data.get(
            "available_move_card_ids",
            []
        )
        var move_ids: Array[String] = []

        if raw_move_ids is Array:
            for raw_id: Variant in (
                raw_move_ids as Array
            ):
                var existing_id: String = (
                    String(raw_id)
                    .strip_edges()
                    .to_lower()
                )

                if existing_id.is_empty():
                    continue

                # Only remove the current id before rebuilding its assignment.
                # Changing the ID of a loaded Move is Save-As semantics:
                # MoveCardAuthoringService writes a new JSON and leaves the
                # original JSON in place, so the original Move assignment must
                # remain available to the Pokémon as well.
                if (
                    species_id == normalized_owner_id
                    and existing_id == current_id
                ):
                    continue

                move_ids.append(
                    existing_id
                )

        if (
            species_id == normalized_owner_id
            and selected_pokemon_ids.has(
                pokemon_id
            )
        ):
            move_ids.append(
                current_id
            )

        data["available_move_card_ids"] = move_ids

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
                pokemon_id
                + ": "
                + "; ".join(
                    save_result.get(
                        "errors",
                        []
                    )
                )
            )

    return {
        "success": errors.is_empty(),
        "errors": errors,
        "updated": updated
    }
