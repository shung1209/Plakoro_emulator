extends RefCounted


const MOVE_BUILDER_ANALYSIS: Script = preload(
    "res://scripts/analysis/MoveBuilderAnalysisService.gd"
)
const MOVE_AUTHORING: Script = preload(
    "res://scripts/content/MoveCardAuthoringService.gd"
)
const MOVE_RUNTIME_COMPATIBILITY: Script = preload(
    "res://scripts/runtime/MoveRuntimeCompatibilityService.gd"
)


static func build_player_report(
    loadout_data: Variant,
    database: Variant
) -> Dictionary:
    return _build_report(
        loadout_data,
        database,
        &"player"
    )


static func build_ai_report(
    loadout_data: Variant,
    database: Variant
) -> Dictionary:
    return _build_report(
        loadout_data,
        database,
        &"ai"
    )


static func _build_report(
    loadout_data: Variant,
    database: Variant,
    participant_type: StringName
) -> Dictionary:
    var result: Dictionary = {
        "success": false,
        "participant_type": participant_type,
        "loadout_id": &"",
        "pokemon_id": &"",
        "pokemon_name": "",
        "move_ids": [],
        "move_names": [],
        "dice_lines": [],
        "overall_probability": 0.0,
        "stars": 0,
        "rating": &"none",
        "signature": "",
        "errors": []
    }

    if loadout_data == null:
        result["errors"].append(
            "Loadout data is null."
        )
        return result

    if database == null:
        result["errors"].append(
            "Database is null."
        )
        return result

    result["loadout_id"] = loadout_data.loadout_id
    result["pokemon_id"] = loadout_data.pokemon_id

    var pokemon: Variant = database.get_pokemon(
        loadout_data.pokemon_id
    )

    if pokemon == null:
        result["errors"].append(
            "Pokémon not found: "
            + String(loadout_data.pokemon_id)
        )
        return result

    result["pokemon_name"] = String(
        pokemon.display_name
    )

    var selected_ids: Array[StringName] = []

    for move_id: StringName in loadout_data.move_card_ids:
        selected_ids.append(move_id)
        result["move_ids"].append(move_id)

        var move_card: Variant = database.get_move_card(
            move_id
        )

        if move_card == null:
            result["move_names"].append(
                "[Missing] " + String(move_id)
            )
            result["errors"].append(
                "Move not found: " + String(move_id)
            )
        else:
            result["move_names"].append(
                String(move_card.display_name)
            )
            var move_document: Dictionary = (
                MOVE_AUTHORING.load_by_id(String(move_id))
            )
            if move_document.is_empty():
                result["errors"].append(
                    "Move JSON could not be loaded for runtime verification: "
                    + String(move_id)
                )
            else:
                var compatibility: Dictionary = (
                    MOVE_RUNTIME_COMPATIBILITY.inspect_move_document(
                        move_document
                    )
                )
                if not bool(compatibility.get("success", false)):
                    for raw_error: Variant in compatibility.get("errors", []):
                        result["errors"].append(
                            String(move_id) + ": " + String(raw_error)
                        )

    result["dice_lines"] = _build_dice_lines(
        loadout_data.energy_dice_setup
    )

    if (
        loadout_data.energy_dice_setup != null
        and not selected_ids.is_empty()
    ):
        var analysis: Dictionary = (
            MOVE_BUILDER_ANALYSIS.analyze_selection(
                loadout_data.energy_dice_setup,
                selected_ids,
                database
            )
        )

        result["overall_probability"] = float(
            analysis.get(
                "overall_probability",
                0.0
            )
        )
        result["stars"] = int(
            analysis.get(
                "stars",
                0
            )
        )
        result["rating"] = StringName(
            analysis.get(
                "rating",
                &"none"
            )
        )

    result["signature"] = _build_signature(
        loadout_data
    )

    result["success"] = result["errors"].is_empty()
    return result


static func _build_dice_lines(
    setup: Variant
) -> Array[String]:
    var lines: Array[String] = []

    if setup == null:
        lines.append("No Enerkoro setup.")
        return lines

    for index: int in range(setup.dice.size()):
        var die_data: Variant = setup.dice[index]

        lines.append(
            "Dice "
            + str(index + 1)
            + ": "
            + String(die_data.fixed_a)
            + " ↔ "
            + String(die_data.fixed_b)
            + " | Double "
            + String(die_data.double_a_first)
            + "+"
            + String(die_data.double_a_second)
            + " / "
            + String(die_data.double_b_first)
            + "+"
            + String(die_data.double_b_second)
            + " | Single "
            + String(die_data.single_a)
            + " ↔ "
            + String(die_data.single_b)
        )

    return lines


static func _build_signature(
    loadout_data: Variant
) -> String:
    var source: String = (
        String(loadout_data.loadout_id)
        + "|"
        + String(loadout_data.pokemon_id)
    )

    for move_id: StringName in loadout_data.move_card_ids:
        source += "|" + String(move_id)

    if loadout_data.energy_dice_setup != null:
        source += "|"
        source += JSON.stringify(
            loadout_data.energy_dice_setup.to_dictionary()
        )

    var context: HashingContext = HashingContext.new()

    if context.start(
        HashingContext.HASH_SHA256
    ) != OK:
        return "UNAVAILABLE"

    context.update(
        source.to_utf8_buffer()
    )

    var digest: PackedByteArray = context.finish()

    if digest.size() < 4:
        return "UNAVAILABLE"

    return (
        "%02X%02X%02X%02X"
        % [
            digest[0],
            digest[1],
            digest[2],
            digest[3]
        ]
    )


static func print_report(
    title: String,
    report: Dictionary
) -> void:
    print("")
    print("=====================================")
    print(title)
    print("=====================================")

    if not bool(report.get("success", false)):
        print("Verification FAILED")

        for raw_error: Variant in report.get(
            "errors",
            []
        ):
            print("ERROR: ", String(raw_error))

        print("=====================================")
        return

    print("Loadout ID: ", String(report["loadout_id"]))
    print(
        "Pokemon: ",
        report["pokemon_name"],
        " [",
        String(report["pokemon_id"]),
        "]"
    )

    print("")
    print("Moves")
    print("-----")

    var move_names: Array = report["move_names"]
    var move_ids: Array = report["move_ids"]

    for index: int in range(move_names.size()):
        print(
            str(index + 1),
            ". ",
            String(move_names[index]),
            " [",
            String(move_ids[index]),
            "]"
        )

    print("")
    print("Enerkoro")
    print("-----------")

    for raw_line: Variant in report["dice_lines"]:
        print(String(raw_line))

    print("")
    print("Coverage")
    print("--------")
    print(
        _stars_text(int(report["stars"])),
        " ",
        _rating_text(
            StringName(report["rating"])
        )
    )
    print(
        "Overall: ",
        "%.1f%%"
        % (
            float(report["overall_probability"])
            * 100.0
        )
    )

    print("")
    print("Loadout Signature: ", report["signature"])
    print("=====================================")
    print("Runtime Ready")
    print("=====================================")
    print("")


static func _stars_text(
    filled_count: int
) -> String:
    var result: String = ""

    for index: int in range(5):
        result += (
            "★"
            if index < filled_count
            else "☆"
        )

    return result


static func _rating_text(
    rating: StringName
) -> String:
    match rating:
        &"excellent":
            return "Excellent"
        &"good":
            return "Good"
        &"acceptable":
            return "Acceptable"
        &"poor":
            return "Needs Improvement"
        _:
            return "No Analysis"
