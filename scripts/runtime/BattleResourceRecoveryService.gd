extends RefCounted


static func inspect_loadout(
    loadout_data: Variant,
    database: Variant,
    participant_label: String = "Loadout"
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "fatal_errors": [],
        "warnings": [],
        "valid_move_ids": [],
        "missing_move_ids": [],
        "pokemon": null,
        "energy_dice_setup": null
    }

    if loadout_data == null:
        _fatal(result, participant_label + " data is missing.")
        return result

    if database == null:
        _fatal(result, "Database service is unavailable.")
        return result

    var pokemon_id: StringName = StringName(
        _get_property(loadout_data, &"pokemon_id", &"")
    )

    if pokemon_id == &"":
        _fatal(result, participant_label + " Pokémon ID is missing.")
    else:
        var pokemon: Variant = database.get_pokemon(pokemon_id)

        if pokemon == null:
            _fatal(
                result,
                participant_label
                + " Pokémon was not found in the database: "
                + String(pokemon_id)
            )
        else:
            result["pokemon"] = pokemon

    var setup: Variant = _get_property(
        loadout_data,
        &"energy_dice_setup",
        null
    )

    if setup == null:
        _fatal(
            result,
            participant_label + " Enerkoro setup is missing."
        )
    else:
        result["energy_dice_setup"] = setup

        var dice: Variant = _get_property(
            setup,
            &"dice",
            null
        )

        if not dice is Array:
            _fatal(
                result,
                participant_label
                + " Enerkoro setup does not contain a dice array."
            )
        elif (dice as Array).is_empty():
            _fatal(
                result,
                participant_label
                + " Enerkoro setup contains no dice."
            )

    var raw_move_ids: Variant = _get_property(
        loadout_data,
        &"move_card_ids",
        []
    )

    if not raw_move_ids is Array:
        _fatal(
            result,
            participant_label + " Move list is invalid."
        )
        return result

    if (raw_move_ids as Array).is_empty():
        _fatal(
            result,
            participant_label + " has no selected Moves."
        )
        return result

    for raw_move_id: Variant in raw_move_ids:
        var move_id: StringName = StringName(raw_move_id)
        var move_card: Variant = database.get_move_card(
            move_id
        )

        if move_card == null:
            result["missing_move_ids"].append(move_id)
            _warning(
                result,
                participant_label
                + " Move is missing and will be skipped in UI preview: "
                + String(move_id)
            )
        else:
            result["valid_move_ids"].append(move_id)

    if not result["missing_move_ids"].is_empty():
        _fatal(
            result,
            participant_label
            + " cannot enter battle until all selected Move Cards exist."
        )

    return result


static func format_blocking_message(
    report: Dictionary
) -> String:
    var errors: Array = report.get(
        "fatal_errors",
        []
    )

    if errors.is_empty():
        return ""

    var lines: Array[String] = [
        "Battle cannot start."
    ]

    for raw_error: Variant in errors:
        lines.append("• " + String(raw_error))

    var warnings: Array = report.get(
        "warnings",
        []
    )

    if not warnings.is_empty():
        lines.append("")
        lines.append("Warnings:")

        for raw_warning: Variant in warnings:
            lines.append(
                "• " + String(raw_warning)
            )

    return "\n".join(lines)


static func print_report(
    participant_label: String,
    report: Dictionary
) -> void:
    for raw_warning: Variant in report.get(
        "warnings",
        []
    ):
        push_warning(
            participant_label
            + ": "
            + String(raw_warning)
        )

    for raw_error: Variant in report.get(
        "fatal_errors",
        []
    ):
        push_error(
            participant_label
            + ": "
            + String(raw_error)
        )


static func safe_get_move(
    database: Variant,
    move_id: StringName,
    context: String = ""
) -> Variant:
    if database == null:
        push_warning(
            "Move lookup skipped because Database is unavailable."
        )
        return null

    var move_card: Variant = database.get_move_card(
        move_id
    )

    if move_card == null:
        var prefix: String = (
            context + ": "
            if not context.is_empty()
            else ""
        )

        push_warning(
            prefix
            + "Move not found: "
            + String(move_id)
        )

    return move_card


static func _fatal(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false
    var errors: Array = result["fatal_errors"]
    errors.append(message)


static func _warning(
    result: Dictionary,
    message: String
) -> void:
    var warnings: Array = result["warnings"]
    warnings.append(message)


static func _get_property(
    object: Variant,
    property_name: StringName,
    default_value: Variant
) -> Variant:
    if object == null:
        return default_value

    if object is Dictionary:
        return (object as Dictionary).get(
            property_name,
            default_value
        )

    if not object is Object:
        return default_value

    for property_info: Dictionary in object.get_property_list():
        if StringName(
            property_info.get("name", "")
        ) == property_name:
            return object.get(property_name)

    return default_value
