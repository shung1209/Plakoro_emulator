extends RefCounted


static func validate(
    pokemon_data: Variant,
    selected_move_ids: Array[StringName],
    database: Variant
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "errors": []
    }

    if pokemon_data == null:
        _add_error(
            result,
            "Pokémon data is missing."
        )
        return result

    if database == null:
        _add_error(
            result,
            "Database is missing."
        )
        return result

    if selected_move_ids.size() != 4:
        _add_error(
            result,
            "Exactly 4 moves must be selected."
        )

    var seen_ids: Dictionary = {}
    var seen_names: Dictionary = {}
    var legal_move_ids: Dictionary = {}

    for legal_move_id: StringName in (
        pokemon_data.available_move_card_ids
    ):
        legal_move_ids[legal_move_id] = true

    for move_card_id: StringName in selected_move_ids:
        if seen_ids.has(move_card_id):
            _add_error(
                result,
                "Duplicate move selected: "
                + String(move_card_id)
            )
        else:
            seen_ids[move_card_id] = true

        if not legal_move_ids.has(move_card_id):
            _add_error(
                result,
                "Move is not legal for "
                + String(pokemon_data.display_name)
                + ": "
                + String(move_card_id)
            )

        var move_card: Variant = database.get_move_card(
            move_card_id
        )

        if move_card == null:
            _add_error(
                result,
                "Move does not exist in database: "
                + String(move_card_id)
            )
            continue

        var normalized_name: String = (
            String(move_card.display_name)
            .strip_edges()
            .to_lower()
        )

        if seen_names.has(normalized_name):
            _add_error(
                result,
                "Another move with the same name is already selected: "
                + String(move_card.display_name)
            )
        else:
            seen_names[normalized_name] = move_card_id

        if (
            "owner_id" in move_card
            and "species_id" in pokemon_data
            and StringName(move_card.owner_id)
            != StringName(pokemon_data.species_id)
        ):
            _add_error(
                result,
                "Move owner does not match Pokémon species: "
                + String(move_card_id)
            )

    return result


static func has_selected_move_name(
    move_card: Variant,
    selected_move_ids: Array[StringName],
    database: Variant
) -> bool:
    if move_card == null or database == null:
        return false

    var target_name: String = (
        String(move_card.display_name)
        .strip_edges()
        .to_lower()
    )

    for selected_move_id: StringName in selected_move_ids:
        if selected_move_id == StringName(move_card.id):
            continue

        var selected_move: Variant = database.get_move_card(
            selected_move_id
        )

        if selected_move == null:
            continue

        var selected_name: String = (
            String(selected_move.display_name)
            .strip_edges()
            .to_lower()
        )

        if selected_name == target_name:
            return true

    return false


static func _add_error(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false

    var errors: Array = result["errors"]
    errors.append(message)
