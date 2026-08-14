extends RefCounted


const EFFECT_TYPE: String = "move.select_and_lock"


static func is_triggered(
    move_card: Variant,
    orientation: StringName
) -> bool:
    if move_card == null:
        return false

    var effect: Dictionary = _find_effect(
        move_card
    )

    if effect.is_empty():
        return false

    var orientations: Array[StringName] = (
        _orientation_array(
            effect.get(
                "confirmed_orientations",
                []
            )
        )
    )

    return orientations.has(
        orientation
    )


static func requires_selection(
    move_card: Variant,
    dice_result: Variant
) -> bool:
    if (
        move_card == null
        or dice_result == null
    ):
        return false

    if not is_triggered(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    ):
        return false

    return StringName(
        dice_result.selected_opponent_move_name_id
    ) == &""


static func get_available_targets(
    participant: Variant
) -> Array[Dictionary]:
    var result: Array[Dictionary] = []

    if (
        participant == null
        or participant.loadout == null
    ):
        return result

    for move_card: Variant in (
        participant.loadout.selected_move_cards
    ):
        if move_card == null:
            continue

        result.append(
            {
                "move_card_id": StringName(
                    move_card.id
                ),
                "move_name_id": StringName(
                    move_card.move_name_id
                ),
                "display_name": String(
                    move_card.display_name
                ),
                "printed_damage": (
                    int(
                        move_card.printed_damage
                    )
                    if move_card.printed_damage != null
                    else 0
                )
            }
        )

    return result


static func choose_ai_target(
    participant: Variant
) -> StringName:
    var targets: Array[Dictionary] = (
        get_available_targets(
            participant
        )
    )

    if targets.is_empty():
        return &""

    targets.sort_custom(
        func(
            a: Dictionary,
            b: Dictionary
        ) -> bool:
            var a_damage: int = int(
                a.get(
                    "printed_damage",
                    0
                )
            )
            var b_damage: int = int(
                b.get(
                    "printed_damage",
                    0
                )
            )

            if a_damage != b_damage:
                return a_damage > b_damage

            return String(
                a.get(
                    "display_name",
                    ""
                )
            ) < String(
                b.get(
                    "display_name",
                    ""
                )
            )
    )

    return StringName(
        targets[0].get(
            "move_name_id",
            ""
        )
    )


static func get_selected_target(
    move_card: Variant,
    dice_result: Variant
) -> StringName:
    if (
        move_card == null
        or dice_result == null
        or not is_triggered(
            move_card,
            StringName(
                dice_result.kyokoro_orientation
            )
        )
    ):
        return &""

    return StringName(
        dice_result.selected_opponent_move_name_id
    )


static func _find_effect(
    move_card: Variant
) -> Dictionary:
    var raw_effects: Variant = _get_property(
        move_card,
        &"special_effects",
        []
    )

    if not raw_effects is Array:
        return {}

    for raw_effect: Variant in (
        raw_effects as Array
    ):
        if not raw_effect is Dictionary:
            continue

        var effect: Dictionary = (
            raw_effect as Dictionary
        )

        if String(
            effect.get(
                "effect_type",
                ""
            )
        ) == EFFECT_TYPE:
            return effect

    return {}


static func _orientation_array(
    raw: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    if not raw is Array:
        return result

    for value: Variant in raw:
        result.append(
            StringName(
                value
            )
        )

    return result


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

    for property_info: Dictionary in (
        source.get_property_list()
    ):
        if StringName(
            property_info.get(
                "name",
                ""
            )
        ) == property_name:
            return source.get(
                property_name
            )

    return fallback
