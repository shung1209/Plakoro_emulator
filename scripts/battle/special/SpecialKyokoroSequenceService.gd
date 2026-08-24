extends RefCounted


const KIND_NONE: StringName = &""
const KIND_MULTI_ROLL: StringName = &"multi_roll"
const KIND_REPEAT_UNTIL_FAIL: StringName = &"repeat_until_fail"
const KIND_REPEAT_SAME_MOVE: StringName = &"repeat_same_move"
const KIND_OPPONENT_ROLL: StringName = &"opponent_roll"


static func build_plan(
    move_card: Variant,
    initial_orientation: StringName
) -> Dictionary:
    var result: Dictionary = {
        "kind": KIND_NONE,
        "extra_roll_count": 0,
        "roll_count": 1,
        "success_orientations": [],
        "actions_per_success": [],
        "source_text": ""
    }

    if move_card == null:
        return result

    var special_effects: Variant = _get_property(
        move_card,
        &"special_effects",
        []
    )

    if not special_effects is Array:
        return result

    var outcome_effect: Dictionary = (
        _find_canonical_outcome_effect(
            move_card
        )
    )

    for raw_effect: Variant in (
        special_effects as Array
    ):
        if not raw_effect is Dictionary:
            continue

        var effect: Dictionary = (
            raw_effect as Dictionary
        )
        var effect_type: String = String(
            effect.get(
                "effect_type",
                ""
            )
        )

        if effect_type == "kyokoro.multi_roll":
            var roll_count: int = max(
                int(
                    effect.get(
                        "roll_count",
                        1
                    )
                ),
                1
            )

            result["kind"] = KIND_MULTI_ROLL
            result["extra_roll_count"] = max(
                roll_count - 1,
                0
            )
            result["success_orientations"] = (
                _orientation_array(
                    outcome_effect.get(
                        "confirmed_orientations",
                        []
                    )
                )
            )
            result["actions_per_success"] = (
                _action_array(
                    outcome_effect.get(
                        "parsed_actions",
                        []
                    )
                )
            )
            result["source_text"] = String(
                effect.get(
                    "source_text",
                    effect.get(
                        "text",
                        ""
                    )
                )
            )
            return result

        if (
            effect_type
            == "kyokoro.repeat_until_fail"
        ):
            var success_orientations: Array[StringName] = (
                _orientation_array(
                    effect.get(
                        "confirmed_orientations",
                        []
                    )
                )
            )

            # A reroll chain only starts when the first normal Charakoro roll
            # has already succeeded.
            if not success_orientations.has(
                initial_orientation
            ):
                return result

            var actions: Array = _action_array(
                outcome_effect.get(
                    "parsed_actions",
                    []
                )
            )

            # Electric Rush repeats the entire Move, not just an outcome
            # modifier. That semantic is intentionally left for 10.7b.
            if actions.is_empty():
                continue

            result["kind"] = (
                KIND_REPEAT_UNTIL_FAIL
            )
            result["success_orientations"] = (
                success_orientations
            )
            result["actions_per_success"] = (
                actions
            )
            result["source_text"] = String(
                effect.get(
                    "source_text",
                    effect.get(
                        "text",
                        ""
                    )
                )
            )
            return result

        if (
            effect_type
            == "kyokoro.repeat_same_move_until_fail"
        ):
            var repeat_success_orientations: Array[StringName] = (
                _orientation_array(
                    effect.get(
                        "confirmed_orientations",
                        []
                    )
                )
            )

            if not repeat_success_orientations.has(
                initial_orientation
            ):
                return result

            result["kind"] = KIND_REPEAT_SAME_MOVE
            result["success_orientations"] = (
                repeat_success_orientations
            )
            result["actions_per_success"] = []
            result["source_text"] = String(
                effect.get(
                    "source_text",
                    effect.get(
                        "text",
                        ""
                    )
                )
            )
            return result

        if effect_type == "kyokoro.opponent_roll":
            var trigger_orientations: Array[StringName] = (
                _orientation_array(
                    effect.get(
                        "confirmed_orientations",
                        []
                    )
                )
            )

            if not trigger_orientations.has(
                initial_orientation
            ):
                return result

            result["kind"] = KIND_OPPONENT_ROLL
            result["roll_count"] = max(int(effect.get("roll_count", 1)), 1)
            result["success_orientations"] = (
                _orientation_array(
                    effect.get(
                        "opponent_success_orientations",
                        []
                    )
                )
            )
            result["actions_per_success"] = (
                _action_array(
                    effect.get(
                        "opponent_success_actions",
                        []
                    )
                )
            )
            result["source_text"] = String(
                effect.get(
                    "source_text",
                    effect.get(
                        "text",
                        ""
                    )
                )
            )
            return result

    return result


static func populate_additional_rolls(
    move_card: Variant,
    dice_result: Variant,
    dice_engine: Variant,
    kyokoro_profile: Variant
) -> Dictionary:
    var result: Dictionary = {
        "generated": false,
        "kind": KIND_NONE,
        "orientations": []
    }

    if (
        move_card == null
        or dice_result == null
        or dice_engine == null
        or kyokoro_profile == null
    ):
        return result

    var plan: Dictionary = build_plan(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    )
    var kind: StringName = StringName(
        plan.get(
            "kind",
            KIND_NONE
        )
    )

    if kind == KIND_NONE:
        return result

    var orientations: Array[StringName] = []

    if kind == KIND_MULTI_ROLL:
        orientations = (
            dice_engine.roll_kyokoro_count(
                kyokoro_profile,
                int(
                    plan.get(
                        "extra_roll_count",
                        0
                    )
                )
            )
        )

    elif (
        kind == KIND_REPEAT_UNTIL_FAIL
        or kind == KIND_REPEAT_SAME_MOVE
    ):
        orientations = (
            dice_engine.roll_kyokoro_until_fail(
                kyokoro_profile,
                _orientation_array(
                    plan.get(
                        "success_orientations",
                        []
                    )
                )
            )
        )

    dice_result.set_additional_kyokoro_orientations(
        orientations
    )

    result["generated"] = not (
        orientations.is_empty()
    )
    result["kind"] = kind
    result["orientations"] = orientations
    return result


static func is_repeat_same_move_chain(
    move_card: Variant,
    dice_result: Variant
) -> bool:
    if (
        move_card == null
        or dice_result == null
    ):
        return false

    var plan: Dictionary = build_plan(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    )

    return StringName(
        plan.get(
            "kind",
            KIND_NONE
        )
    ) == KIND_REPEAT_SAME_MOVE


static func get_repeat_same_move_orientations(
    move_card: Variant,
    dice_result: Variant
) -> Array[StringName]:
    var result: Array[StringName] = []

    if not is_repeat_same_move_chain(
        move_card,
        dice_result
    ):
        return result

    for raw_orientation: Variant in (
        dice_result.additional_kyokoro_orientations
    ):
        result.append(
            StringName(
                raw_orientation
            )
        )

    return result


static func get_opponent_roll_trigger_orientations(
    move_card: Variant
) -> Array[StringName]:
    if move_card == null:
        return []

    var raw_effects: Variant = _get_property(
        move_card,
        &"special_effects",
        []
    )

    if not raw_effects is Array:
        return []

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
        ) != "kyokoro.opponent_roll":
            continue

        return _orientation_array(
            effect.get(
                "confirmed_orientations",
                []
            )
        )

    return []


static func has_opponent_roll_effect(
    move_card: Variant
) -> bool:
    return not (
        get_opponent_roll_trigger_orientations(
            move_card
        ).is_empty()
    )


static func populate_opponent_roll(
    move_card: Variant,
    dice_result: Variant,
    dice_engine: Variant,
    opponent_kyokoro_profile: Variant
) -> Dictionary:
    var result: Dictionary = {
        "generated": false,
        "orientation": &"",
        "success": false
    }

    if (
        move_card == null
        or dice_result == null
        or dice_engine == null
        or opponent_kyokoro_profile == null
    ):
        return result

    var plan: Dictionary = build_plan(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    )

    if StringName(
        plan.get(
            "kind",
            KIND_NONE
        )
    ) != KIND_OPPONENT_ROLL:
        return result

    var roll_count: int = max(int(plan.get("roll_count", 1)), 1)
    var orientations: Array[StringName] = dice_engine.roll_kyokoro_count(
        opponent_kyokoro_profile,
        roll_count
    )
    if orientations.is_empty():
        return result

    dice_result.opponent_kyokoro_orientation = orientations[0]
    dice_result.opponent_kyokoro_orientations = orientations.duplicate()
    dice_result.opponent_kyokoro_roll_triggered = true

    var success_orientations: Array[StringName] = (
        _orientation_array(plan.get("success_orientations", []))
    )
    var success_count: int = 0
    for orientation: StringName in orientations:
        if success_orientations.has(orientation):
            success_count += 1

    result["generated"] = true
    result["orientation"] = orientations[0]
    result["orientations"] = orientations
    result["success"] = success_count > 0
    result["success_count"] = success_count
    return result


static func get_opponent_roll_action_batch(
    move_card: Variant,
    dice_result: Variant
) -> Dictionary:
    if (
        move_card == null
        or dice_result == null
        or not bool(
            dice_result.opponent_kyokoro_roll_triggered
        )
    ):
        return {}

    var plan: Dictionary = build_plan(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    )

    if StringName(
        plan.get(
            "kind",
            KIND_NONE
        )
    ) != KIND_OPPONENT_ROLL:
        return {}

    var opponent_orientation: StringName = (
        StringName(
            dice_result.opponent_kyokoro_orientation
        )
    )
    var success_orientations: Array[StringName] = (
        _orientation_array(
            plan.get(
                "success_orientations",
                []
            )
        )
    )

    var orientations: Array = dice_result.opponent_kyokoro_orientations
    if orientations.is_empty() and opponent_orientation != &"":
        orientations = [opponent_orientation]

    var actions: Array = []
    var success_count: int = 0
    var per_success: Array = _action_array(plan.get("actions_per_success", []))
    for raw_orientation: Variant in orientations:
        if success_orientations.has(StringName(raw_orientation)):
            success_count += 1
            actions.append_array(per_success.duplicate(true))

    return {
        "orientation": opponent_orientation,
        "orientations": orientations.duplicate(),
        "success": success_count > 0,
        "success_count": success_count,
        "actions": actions
    }


static func get_extra_success_action_batches(
    move_card: Variant,
    dice_result: Variant
) -> Array:
    var batches: Array = []

    if (
        move_card == null
        or dice_result == null
    ):
        return batches

    var plan: Dictionary = build_plan(
        move_card,
        StringName(
            dice_result.kyokoro_orientation
        )
    )
    var success_orientations: Array[StringName] = (
        _orientation_array(
            plan.get(
                "success_orientations",
                []
            )
        )
    )
    var actions: Array = _action_array(
        plan.get(
            "actions_per_success",
            []
        )
    )

    if (
        success_orientations.is_empty()
        or actions.is_empty()
    ):
        return batches

    var kind: StringName = StringName(
        plan.get(
            "kind",
            KIND_NONE
        )
    )

    for raw_orientation: Variant in (
        dice_result.additional_kyokoro_orientations
    ):
        var orientation: StringName = StringName(
            raw_orientation
        )

        if success_orientations.has(
            orientation
        ):
            batches.append(
                {
                    "orientation": orientation,
                    "actions": actions.duplicate(
                        true
                    )
                }
            )
            continue

        if kind == KIND_REPEAT_UNTIL_FAIL:
            break

    return batches


static func _find_canonical_outcome_effect(
    move_card: Variant
) -> Dictionary:
    var outcome_rules: Variant = _get_property(
        move_card,
        &"outcome_rules",
        []
    )

    if not outcome_rules is Array:
        return {}

    for raw_rule: Variant in outcome_rules:
        if not raw_rule is Dictionary:
            continue

        var rule: Dictionary = (
            raw_rule as Dictionary
        )
        var condition: Variant = rule.get(
            "condition",
            {}
        )
        var actions: Variant = rule.get(
            "actions",
            []
        )

        if not condition is Dictionary:
            continue

        var orientations: Variant = (
            condition as Dictionary
        ).get(
            "orientations",
            []
        )

        if (
            actions is Array
            and not (actions as Array).is_empty()
            and orientations is Array
            and not (orientations as Array).is_empty()
        ):
            return {
                "confirmed_orientations": (
                    orientations as Array
                ).duplicate(
                    true
                ),
                "parsed_actions": (
                    actions as Array
                ).duplicate(
                    true
                ),
                "source_text": String(
                    rule.get(
                        "raw_text",
                        ""
                    )
                )
            }

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


static func _action_array(
    raw: Variant
) -> Array:
    if not raw is Array:
        return []

    return (
        raw as Array
    ).duplicate(
        true
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
