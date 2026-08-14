extends RefCounted


const ORIENTATION_IDS: Array[StringName] = [
    &"FACE_DOWN",
    &"FACE_UP",
    &"HEAD_UP",
    &"HEAD_DOWN",
    &"HEAD_LEFT",
    &"HEAD_RIGHT"
]


static func build_preview(
    move_card: Variant
) -> Dictionary:
    var result: Dictionary = {
        "has_kyokoro_effect": false,
        "summary": "Charakoro Effect: None",
        "detail": "No Charakoro-specific effect.",
        "trigger_groups": [],
        "trigger_lines": [],
        "orientations": [],
        "raw_text": ""
    }

    if move_card == null:
        result["summary"] = "Charakoro Effect: Unavailable"
        result["detail"] = "Move data is unavailable."
        return result

    var raw_text: String = String(
        _get_property(
            move_card,
            &"raw_text",
            ""
        )
    ).strip_edges()

    result["raw_text"] = raw_text

    var trigger_groups: Array[Dictionary] = []

    for property_name: StringName in [
        &"outcomes",
        &"outcome_rules",
        &"kyokoro_outcomes"
    ]:
        var raw_outcomes: Variant = _get_property(
            move_card,
            property_name,
            null
        )

        if raw_outcomes is Array:
            for outcome: Variant in raw_outcomes:
                _append_outcome_group(
                    trigger_groups,
                    outcome
                )

    # Pending/non-executable Charakoro effects still belong to the card and
    # must be shown in Preparation. These are stored in special_effects[]
    # when the runtime primitive or orchestration is not ready yet.
    var raw_special_effects: Variant = _get_property(
        move_card,
        &"special_effects",
        []
    )

    if raw_special_effects is Array:
        for raw_special: Variant in (
            raw_special_effects as Array
        ):
            if not raw_special is Dictionary:
                continue

            var special: Dictionary = (
                raw_special as Dictionary
            )

            if String(
                special.get(
                    "trigger",
                    ""
                )
            ) != "kyokoro_outcome":
                continue

            # Imported move JSON commonly contains the same ordinary Charakoro
            # effect twice: once as executable outcome_rules and again as a
            # legacy special_effects mirror. When outcome_rules exist, those
            # mirror rows are archival metadata and must not be presented as
            # additional effects. Structural special effects (multi-roll,
            # repeat, opponent roll, etc.) remain eligible.
            var effect_type: String = String(
                special.get(
                    "effect_type",
                    ""
                )
            ).strip_edges()

            if (
                not trigger_groups.is_empty()
                and effect_type.is_empty()
            ):
                continue

            var special_text: String = String(
                special.get(
                    "source_text",
                    special.get(
                        "description",
                        ""
                    )
                )
            ).strip_edges()

            var special_orientations: Array[StringName] = (
                _to_orientation_array(
                    special.get(
                        "confirmed_orientations",
                        []
                    )
                )
            )

            if (
                special_text.is_empty()
                and special_orientations.is_empty()
            ):
                continue

            trigger_groups.append(
                {
                    "orientations": special_orientations,
                    "effect_text": special_text
                }
            )

    # Source metadata is archival/reference text, not an additional runtime
    # effect source. Only use it when this Move has no authoritative
    # outcome_rules/special_effects groups at all. Otherwise copied/derived Move
    # Cards can accidentally display the parent Move's old effect text together
    # with their own newly-authored effects.
    var source_data: Variant = _get_property(
        move_card,
        &"source",
        {}
    )

    if (
        trigger_groups.is_empty()
        and source_data is Dictionary
    ):
        var source_effects: Variant = (
            (source_data as Dictionary).get(
                "kyokoro_effect_text",
                []
            )
        )

        if source_effects is String:
            source_effects = [
                source_effects
            ]

        if source_effects is Array:
            for raw_effect_text: Variant in (
                source_effects as Array
            ):
                var source_effect_text: String = String(
                    raw_effect_text
                ).strip_edges()

                if source_effect_text.is_empty():
                    continue

                var already_present: bool = false
                var normalized_source_text: String = (
                    _normalize_effect_text(
                        source_effect_text
                    )
                )

                for existing_group: Dictionary in trigger_groups:
                    var existing_text: String = String(
                        existing_group.get(
                            "effect_text",
                            ""
                        )
                    )

                    if (
                        _normalize_effect_text(
                            existing_text
                        )
                        == normalized_source_text
                    ):
                        already_present = true
                        break

                if not already_present:
                    trigger_groups.append(
                        {
                            "orientations": [],
                            "effect_text": source_effect_text
                        }
                    )

    # Compatibility with direct per-orientation outcome properties.
    for orientation: StringName in ORIENTATION_IDS:
        var snake_name: StringName = StringName(
            String(orientation).to_lower()
            + "_outcome"
        )

        var direct_outcome: Variant = _get_property(
            move_card,
            snake_name,
            null
        )

        if direct_outcome != null:
            _append_outcome_group(
                trigger_groups,
                direct_outcome,
                [orientation]
            )

    trigger_groups = _dedupe_groups(
        trigger_groups
    )

    result["trigger_groups"] = trigger_groups

    var trigger_lines: Array[String] = []
    var all_orientations: Array[StringName] = []

    for group: Dictionary in trigger_groups:
        var orientations: Array[StringName] = (
            _to_orientation_array(
                group.get(
                    "orientations",
                    []
                )
            )
        )

        var effect_text: String = String(
            group.get(
                "effect_text",
                ""
            )
        ).strip_edges()

        for orientation: StringName in orientations:
            if not all_orientations.has(
                orientation
            ):
                all_orientations.append(
                    orientation
                )

        var orientation_text: String = (
            " / ".join(
                _orientation_strings(
                    orientations
                )
            )
        )

        if (
            not orientation_text.is_empty()
            and not effect_text.is_empty()
        ):
            trigger_lines.append(
                orientation_text
                + " → "
                + effect_text
            )
        elif not orientation_text.is_empty():
            trigger_lines.append(
                orientation_text
                + " → Effect"
            )
        elif not effect_text.is_empty():
            trigger_lines.append(
                effect_text
            )

    result["trigger_lines"] = trigger_lines
    result["orientations"] = all_orientations

    if not trigger_groups.is_empty():
        result["has_kyokoro_effect"] = true

        if trigger_groups.size() == 1:
            var group: Dictionary = trigger_groups[0]
            var orientations: Array[StringName] = (
                _to_orientation_array(
                    group.get(
                        "orientations",
                        []
                    )
                )
            )

            var effect_text: String = String(
                group.get(
                    "effect_text",
                    ""
                )
            )

            var orientation_text: String = (
                " / ".join(
                    _orientation_strings(
                        orientations
                    )
                )
            )

            if not orientation_text.is_empty():
                result["summary"] = (
                    "Charakoro: "
                    + orientation_text
                    + (
                        " → " + effect_text
                        if not effect_text.is_empty()
                        else ""
                    )
                )
            elif not effect_text.is_empty():
                result["summary"] = (
                    "Charakoro Effect: "
                    + effect_text
                )
        else:
            result["summary"] = (
                "Charakoro: "
                + " | ".join(
                    trigger_lines
                )
            )

        result["detail"] = _build_detail_text(
            trigger_groups,
            raw_text
        )

        return result

    if not raw_text.is_empty():
        result["summary"] = (
            "Effect text: "
            + _single_line(raw_text)
        )
        result["detail"] = (
            "Card Text\n"
            + raw_text
            + "\n\n"
            + "Charakoro trigger mapping is not exposed by this MoveCardData."
        )

    return result


static func get_compact_summary(
    move_card: Variant
) -> String:
    return String(
        build_preview(
            move_card
        )["summary"]
    )


static func get_full_detail(
    move_card: Variant
) -> String:
    return String(
        build_preview(
            move_card
        )["detail"]
    )


static func _append_outcome_group(
    output: Array[Dictionary],
    outcome: Variant,
    forced_orientations: Array[StringName] = []
) -> void:
    if outcome == null:
        return

    var orientations: Array[StringName] = []

    if not forced_orientations.is_empty():
        orientations = forced_orientations.duplicate()
    else:
        orientations = _extract_all_orientations(
            outcome
        )

    var effect_text: String = _extract_effect_text(
        outcome
    )

    if (
        orientations.is_empty()
        and effect_text.is_empty()
    ):
        return

    output.append(
        {
            "orientations": orientations,
            "effect_text": effect_text
        }
    )


static func _extract_all_orientations(
    outcome: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    # Runtime MoveCardParser converts JSON outcome_rules into OutcomeRuleData.
    # OutcomeRuleData stores orientations inside ConditionData.parameters and
    # already exposes get_all_orientations(). Use that authoritative API first.
    # This avoids relying on generic object reflection for the Battle tooltip.
    if (
        outcome is Object
        and outcome.has_method(
            "get_all_orientations"
        )
    ):
        var runtime_orientations: Variant = (
            outcome.get_all_orientations()
        )

        if runtime_orientations is Array:
            for raw_orientation: Variant in (
                runtime_orientations as Array
            ):
                var orientation: StringName = StringName(
                    raw_orientation
                )

                if (
                    ORIENTATION_IDS.has(
                        orientation
                    )
                    and not result.has(
                        orientation
                    )
                ):
                    result.append(
                        orientation
                    )

        if not result.is_empty():
            return result

    # Direct single-orientation fields.
    for property_name: StringName in [
        &"orientation",
        &"orientation_id",
        &"kyokoro_orientation",
        &"result_id"
    ]:
        _collect_orientations_recursive(
            _get_property(
                outcome,
                property_name,
                null
            ),
            result
        )

    # Current V2 structure normally stores:
    #
    # condition:
    #   type: kyokoro_orientation_any
    #   orientations: [...]
    #
    # Recursively collect ALL matching orientation values.
    for property_name: StringName in [
        &"condition",
        &"conditions"
    ]:
        _collect_orientations_recursive(
            _get_property(
                outcome,
                property_name,
                null
            ),
            result
        )

    return result


static func _collect_orientations_recursive(
    value: Variant,
    output: Array[StringName]
) -> void:
    if value == null:
        return

    if value is String or value is StringName:
        var candidate: StringName = StringName(
            value
        )

        if (
            ORIENTATION_IDS.has(candidate)
            and not output.has(candidate)
        ):
            output.append(candidate)

        return

    if value is Dictionary:
        var dictionary: Dictionary = value as Dictionary

        # Prefer explicit orientations arrays first to preserve JSON order.
        if dictionary.has("orientations"):
            _collect_orientations_recursive(
                dictionary["orientations"],
                output
            )

        if dictionary.has(&"orientations"):
            _collect_orientations_recursive(
                dictionary[&"orientations"],
                output
            )

        for key: Variant in dictionary.keys():
            if (
                String(key) == "orientations"
            ):
                continue

            _collect_orientations_recursive(
                dictionary[key],
                output
            )

        return

    if value is Array:
        for item: Variant in value:
            _collect_orientations_recursive(
                item,
                output
            )

        return

    if value is Object:
        # Prefer a runtime object's explicit orientations property.
        var explicit_orientations: Variant = (
            _get_property(
                value,
                &"orientations",
                null
            )
        )

        if explicit_orientations != null:
            _collect_orientations_recursive(
                explicit_orientations,
                output
            )

        for property_info: Dictionary in (
            value.get_property_list()
        ):
            var property_name: StringName = StringName(
                property_info.get(
                    "name",
                    ""
                )
            )

            if (
                property_name == &""
                or property_name == &"orientations"
            ):
                continue

            _collect_orientations_recursive(
                value.get(property_name),
                output
            )


static func _extract_effect_text(
    outcome: Variant
) -> String:
    for property_name: StringName in [
        &"raw_text",
        &"description",
        &"effect_text",
        &"text"
    ]:
        var value: Variant = _get_property(
            outcome,
            property_name,
            null
        )

        if value != null:
            var text: String = String(
                value
            ).strip_edges()

            if not text.is_empty():
                return _single_line(
                    text
                )

    var actions: Variant = _get_property(
        outcome,
        &"actions",
        null
    )

    if actions is Array:
        var parts: Array[String] = []

        for action: Variant in actions:
            var formatted: String = (
                _format_action(
                    action
                )
            )

            if not formatted.is_empty():
                parts.append(formatted)

        if not parts.is_empty():
            return "; ".join(parts)

    return ""


static func _format_action(
    action: Variant
) -> String:
    if action == null:
        return ""

    var opcode: String = String(
        _get_property(
            action,
            &"opcode",
            ""
        )
    )

    var args: Variant = _get_property(
        action,
        &"args",
        {}
    )

    if opcode.is_empty():
        return _single_line(
            String(
                _get_property(
                    action,
                    &"description",
                    ""
                )
            )
        )

    if args is Dictionary:
        var parts: Array[String] = []

        for key: Variant in (
            args as Dictionary
        ).keys():
            parts.append(
                str(key)
                + "="
                + str(
                    (args as Dictionary)[key]
                )
            )

        if not parts.is_empty():
            return (
                opcode
                + " ("
                + ", ".join(parts)
                + ")"
            )

    return opcode


static func _build_detail_text(
    trigger_groups: Array[Dictionary],
    raw_text: String
) -> String:
    var lines: Array[String] = [
        "Charakoro Trigger / Effect"
    ]

    for index: int in range(
        trigger_groups.size()
    ):
        var group: Dictionary = (
            trigger_groups[index]
        )

        var orientations: Array[StringName] = (
            _to_orientation_array(
                group.get(
                    "orientations",
                    []
                )
            )
        )

        var effect_text: String = String(
            group.get(
                "effect_text",
                ""
            )
        )

        if index > 0:
            lines.append("")

        if not orientations.is_empty():
            lines.append(
                "Trigger: "
                + " / ".join(
                    _orientation_strings(
                        orientations
                    )
                )
            )

        if not effect_text.is_empty():
            lines.append(
                "Effect: "
                + effect_text
            )

    if not raw_text.is_empty():
        lines.append("")
        lines.append("Card Text")
        lines.append(raw_text)

    return "\n".join(lines)


static func _dedupe_groups(
    groups: Array[Dictionary]
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var signatures: Dictionary = {}

    for group: Dictionary in groups:
        var orientations: Array[StringName] = (
            _to_orientation_array(
                group.get(
                    "orientations",
                    []
                )
            )
        )

        var signature: String = (
            ",".join(
                _orientation_strings(
                    orientations
                )
            )
            + "|"
            + _normalize_effect_text(
                String(
                    group.get(
                        "effect_text",
                        ""
                    )
                )
            )
        )

        if signatures.has(signature):
            continue

        signatures[signature] = true
        result.append(
            {
                "orientations": orientations,
                "effect_text": String(
                    group.get(
                        "effect_text",
                        ""
                    )
                )
            }
        )

    return result


static func _to_orientation_array(
    value: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    if value is Array:
        for item: Variant in value:
            var candidate: StringName = StringName(
                item
            )

            if (
                ORIENTATION_IDS.has(candidate)
                and not result.has(candidate)
            ):
                result.append(candidate)

    return result


static func _orientation_strings(
    orientations: Array[StringName]
) -> Array[String]:
    var result: Array[String] = []

    for orientation: StringName in orientations:
        result.append(
            String(orientation)
        )

    return result


static func _get_property(
    object: Variant,
    property_name: StringName,
    default_value: Variant
) -> Variant:
    if object == null:
        return default_value

    if object is Dictionary:
        var dictionary: Dictionary = object as Dictionary

        if dictionary.has(property_name):
            return dictionary[property_name]

        var string_key: String = String(
            property_name
        )

        if dictionary.has(string_key):
            return dictionary[string_key]

        return default_value

    if not object is Object:
        return default_value

    for property_info: Dictionary in (
        object.get_property_list()
    ):
        if StringName(
            property_info.get(
                "name",
                ""
            )
        ) == property_name:
            return object.get(
                property_name
            )

    return default_value


static func _normalize_effect_text(
    value: String
) -> String:
    var normalized: String = value.replace(
        "\r",
        " "
    ).replace(
        "\n",
        " "
    )

    while normalized.contains(
        "  "
    ):
        normalized = normalized.replace(
            "  ",
            " "
        )

    return normalized.strip_edges()


static func _single_line(
    text: String
) -> String:
    return (
        text
        .replace("\r", " ")
        .replace("\n", " ")
        .strip_edges()
    )
