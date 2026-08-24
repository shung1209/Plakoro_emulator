extends RefCounted


static func build_display_label(
    move_id: String,
    move_data: Dictionary
) -> String:
    if move_data.is_empty():
        return move_id

    return (
        String(
            move_data.get(
                "display_name",
                move_id
            )
        )
        + "  ["
        + move_id
        + "]"
    )


static func build_tooltip(
    move_id: String,
    move_data: Dictionary
) -> String:
    if move_data.is_empty():
        return move_id

    var damage_value: Variant = move_data.get(
        "printed_damage",
        null
    )

    var lines: Array[String] = [
        String(
            move_data.get(
                "display_name",
                move_id
            )
        ),
        (
            String(
                move_data.get(
                    "move_category",
                    "attack"
                )
            ).capitalize()
            + " | "
            + String(
                move_data.get(
                    "attack_type",
                    "normal"
                )
            ).capitalize()
        ),
        "",
        (
            "Damage: "
            + (
                "-"
                if damage_value == null
                else str(
                    int(
                        damage_value
                    )
                )
            )
        ),
        LocalizationService.tr_key(
            "move_popup.energy_cost",
            "Energy Cost:"
        ) + " " + format_energy_cost(
            move_data
        ),
        "Move ID: " + move_id
    ]

    var effects: Array[String] = (
        extract_effect_texts(
            move_data
        )
    )

    if not effects.is_empty():
        lines.append("")
        lines.append("Effects")

        for effect_text: String in effects:
            lines.append(
                " |  " + effect_text
            )

    return "\n".join(
        lines
    )


static func format_energy_cost(
    move_data: Dictionary
) -> String:
    var raw_cost: Variant = move_data.get(
        "energy_cost",
        []
    )

    if (
        not raw_cost is Array
        or (
            raw_cost as Array
        ).is_empty()
    ):
        return "None"

    var parts: Array[String] = []

    for raw_entry: Variant in raw_cost as Array:
        if not raw_entry is Dictionary:
            continue

        var entry: Dictionary = raw_entry

        parts.append(
            String(
                entry.get(
                    "energy_type",
                    "normal"
                )
            ).capitalize()
            + " x"
            + str(
                int(
                    entry.get(
                        "count",
                        0
                    )
                )
            )
        )

    return (
        ", ".join(
            parts
        )
        if not parts.is_empty()
        else "None"
    )


static func extract_effect_texts(
    move_data: Dictionary
) -> Array[String]:
    var result: Array[String] = []

    var raw_rules: Variant = move_data.get(
        "outcome_rules",
        []
    )

    if raw_rules is Array:
        for raw_rule: Variant in raw_rules as Array:
            if not raw_rule is Dictionary:
                continue

            var raw_text: String = String(
                (raw_rule as Dictionary).get(
                    "raw_text",
                    ""
                )
            ).strip_edges()

            if (
                not raw_text.is_empty()
                and not result.has(
                    raw_text
                )
            ):
                result.append(
                    raw_text
                )

    var source: Variant = move_data.get(
        "source",
        {}
    )

    if source is Dictionary:
        var source_text: String = String(
            (source as Dictionary).get(
                "raw_text",
                ""
            )
        ).strip_edges()

        if (
            not source_text.is_empty()
            and not result.has(
                source_text
            )
        ):
            result.append(
                source_text
            )

    if result.is_empty():
        var actions: Variant = move_data.get(
            "base_actions",
            []
        )

        if actions is Array:
            for raw_action: Variant in actions as Array:
                if not raw_action is Dictionary:
                    continue

                var opcode: String = String(
                    (raw_action as Dictionary).get(
                        "opcode",
                        ""
                    )
                ).strip_edges()

                if not opcode.is_empty():
                    result.append(
                        opcode
                    )

    return result
