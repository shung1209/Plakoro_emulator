extends RefCounted


const EFFECT_TYPE: String = "energy_dice.opponent_roll"


static func is_triggered(
    move_card: Variant,
    orientation: StringName
) -> bool:
    var effect: Dictionary = _find_effect(
        move_card
    )

    if effect.is_empty():
        return false

    return _orientation_array(
        effect.get(
            "confirmed_orientations",
            []
        )
    ).has(
        orientation
    )


static func populate_roll(
    move_card: Variant,
    source_dice_result: Variant,
    dice_engine: Variant,
    opponent_energy_profiles: Array
) -> Dictionary:
    var result: Dictionary = {
        "generated": false,
        "dice_result": null,
        "roll_record": null,
        "max_count": 0,
        "most_common_types": [],
        "bonus_energy_count": 0,
        "damage_bonus": 0
    }

    if (
        move_card == null
        or source_dice_result == null
        or dice_engine == null
        or opponent_energy_profiles.is_empty()
    ):
        return result

    if not is_triggered(
        move_card,
        StringName(
            source_dice_result.kyokoro_orientation
        )
    ):
        return result

    var effect: Dictionary = _find_effect(
        move_card
    )
    var roll_count: int = max(
        int(
            effect.get(
                "roll_count",
                3
            )
        ),
        1
    )

    var profiles: Array = []

    for index: int in range(
        roll_count
    ):
        profiles.append(
            opponent_energy_profiles[
                index % opponent_energy_profiles.size()
            ]
        )

    var opponent_result: Variant = (
        dice_engine.roll_battle_dice(
            profiles,
            null,
            0,
            false
        )
    )

    if opponent_result == null:
        return result

    var history: Array = (
        dice_engine.get_history()
    )
    var roll_record: Variant = (
        history.back()
        if not history.is_empty()
        else null
    )

    var counts: Dictionary = (
        opponent_result.energy_counts.duplicate(
            true
        )
    )
    var max_count: int = 0

    for raw_count: Variant in counts.values():
        max_count = max(
            max_count,
            int(
                raw_count
            )
        )

    var most_common_types: Array = []
    var bonus_energy_count: int = 0

    for raw_type: Variant in counts.keys():
        var count: int = int(
            counts.get(
                raw_type,
                0
            )
        )

        if count != max_count:
            continue

        most_common_types.append(
            StringName(
                raw_type
            )
        )
        bonus_energy_count += count

    most_common_types.sort()

    var damage_bonus: int = (
        bonus_energy_count * 10
    )

    source_dice_result.opponent_enerkoro_roll_triggered = (
        true
    )
    source_dice_result.opponent_enerkoro_counts = (
        counts.duplicate(
            true
        )
    )
    source_dice_result.opponent_enerkoro_max_count = (
        max_count
    )
    source_dice_result.opponent_enerkoro_most_common_types = (
        most_common_types.duplicate()
    )
    source_dice_result.opponent_enerkoro_damage_bonus = (
        damage_bonus
    )

    if roll_record != null:
        source_dice_result.opponent_enerkoro_face_ids = (
            roll_record.energy_die_face_ids.duplicate()
        )

    result["generated"] = true
    result["dice_result"] = opponent_result
    result["roll_record"] = roll_record
    result["max_count"] = max_count
    result["most_common_types"] = (
        most_common_types
    )
    result["bonus_energy_count"] = (
        bonus_energy_count
    )
    result["damage_bonus"] = damage_bonus
    return result


static func get_damage_action_batch(
    move_card: Variant,
    dice_result: Variant
) -> Dictionary:
    if (
        move_card == null
        or dice_result == null
        or not bool(
            dice_result.opponent_enerkoro_roll_triggered
        )
        or not is_triggered(
            move_card,
            StringName(
                dice_result.kyokoro_orientation
            )
        )
    ):
        return {}

    var bonus: int = max(
        int(
            dice_result.opponent_enerkoro_damage_bonus
        ),
        0
    )

    return {
        "damage_bonus": bonus,
        "bonus_energy_count": int(
            bonus / 10
        ),
        "max_count": int(
            dice_result.opponent_enerkoro_max_count
        ),
        "most_common_types": (
            dice_result.opponent_enerkoro_most_common_types
            .duplicate()
        ),
        "actions": [
            {
                "opcode": "damage.add",
                "args": {
                    "target": "opponent",
                    "amount": bonus
                }
            }
        ]
    }


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
