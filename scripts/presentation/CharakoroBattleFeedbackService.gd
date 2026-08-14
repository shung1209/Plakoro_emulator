extends RefCounted


const EFFECT_PRESENTATION: Script = preload(
    "res://scripts/presentation/MoveKyokoroEffectPresentationService.gd"
)


static func build_feedback(
    move_card: Variant,
    dice_result: Variant
) -> Dictionary:
    var result: Dictionary = {
        "triggered": false,
        "orientations": [],
        "groups": [],
        "summary": ""
    }

    if move_card == null or dice_result == null:
        return result

    var rolled_orientations: Array[StringName] = (
        _collect_rolled_orientations(
            dice_result
        )
    )

    if rolled_orientations.is_empty():
        return result

    var preview: Dictionary = (
        EFFECT_PRESENTATION.build_preview(
            move_card
        )
    )
    var groups: Array = preview.get(
        "trigger_groups",
        []
    )
    var matched_groups: Array[Dictionary] = []
    var matched_orientations: Array[StringName] = []

    for group_index: int in range(groups.size()):
        var raw_group: Variant = groups[group_index]
        if not raw_group is Dictionary:
            continue

        var group: Dictionary = raw_group
        var group_orientations: Array[StringName] = []

        for raw_orientation: Variant in group.get(
            "orientations",
            []
        ):
            group_orientations.append(
                StringName(
                    raw_orientation
                )
            )

        if group_orientations.is_empty():
            # Presentation-only fallback text without a mapped orientation
            # must never be announced as a runtime trigger.
            continue

        var group_matches: Array[StringName] = []

        for orientation: StringName in rolled_orientations:
            if group_orientations.has(
                orientation
            ):
                group_matches.append(
                    orientation
                )

                if not matched_orientations.has(
                    orientation
                ):
                    matched_orientations.append(
                        orientation
                    )

        if group_matches.is_empty():
            continue

        matched_groups.append(
            {
                "orientations": group_matches,
                "effect_text": GameContentLocalizationService.localize_effect_text(
                    move_card,
                    group_index,
                    String(
                        group.get(
                            "effect_text",
                            ""
                        )
                    ).strip_edges()
                )
            }
        )

    if matched_groups.is_empty():
        return result

    result["triggered"] = true
    result["orientations"] = matched_orientations
    result["groups"] = matched_groups
    result["summary"] = _build_summary(
        matched_groups
    )
    return result


static func _collect_rolled_orientations(
    dice_result: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    if dice_result.has_method(
        "get_all_kyokoro_orientations"
    ):
        for raw_orientation: Variant in (
            dice_result.get_all_kyokoro_orientations()
        ):
            var orientation: StringName = StringName(
                raw_orientation
            )

            if (
                orientation != &""
                and not result.has(
                    orientation
                )
            ):
                result.append(
                    orientation
                )

        return result

    var primary: StringName = StringName(
        _get_property(
            dice_result,
            &"kyokoro_orientation",
            &""
        )
    )

    if primary != &"":
        result.append(
            primary
        )

    for raw_orientation: Variant in _get_property(
        dice_result,
        &"additional_kyokoro_orientations",
        []
    ):
        var orientation: StringName = StringName(
            raw_orientation
        )

        if (
            orientation != &""
            and not result.has(
                orientation
            )
        ):
            result.append(
                orientation
            )

    return result


static func _build_summary(
    groups: Array[Dictionary]
) -> String:
    var lines: Array[String] = []

    for group: Dictionary in groups:
        var orientations: Array[String] = []

        for raw_orientation: Variant in group.get(
            "orientations",
            []
        ):
            orientations.append(
                LocalizationService.tr_key(
                    "orientation." + String(raw_orientation),
                    String(raw_orientation).replace("_", " ").capitalize()
                )
            )

        var effect_text: String = String(
            group.get(
                "effect_text",
                ""
            )
        ).strip_edges()

        var line: String = (
            "✓ "
            + " / ".join(
                orientations
            )
        )

        if not effect_text.is_empty():
            line += (
                "\n"
                + effect_text
            )

        lines.append(
            line
        )

    return "\n\n".join(
        lines
    )


static func _get_property(
    source: Variant,
    property_name: StringName,
    fallback: Variant
) -> Variant:
    if source == null:
        return fallback

    if source is Dictionary:
        return (
            source as Dictionary
        ).get(
            property_name,
            fallback
        )

    for property: Dictionary in source.get_property_list():
        if StringName(
            property.get(
                "name",
                ""
            )
        ) == property_name:
            return source.get(
                property_name
            )

    return fallback
