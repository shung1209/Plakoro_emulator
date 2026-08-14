extends RefCounted


const PREVIOUS_MOVE_EFFECT: Script = preload(
    "res://scripts/battle/effects/PreviousMoveConditionalEffectService.gd"
)


static func evaluate(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    var condition_type: StringName = StringName(
        condition_data.get("type", "")
    )

    match condition_type:
        &"always":
            return true

        &"hp":
            return _evaluate_hp(
                condition_data,
                context
            )

        &"energy_count":
            return _evaluate_energy_count(
                condition_data,
                context
            )

        &"previous_self_energy_failed":
            return _evaluate_previous_energy_failed(
                context,
                false
            )

        &"previous_opponent_energy_failed":
            return _evaluate_previous_energy_failed(
                context,
                true
            )

        &"previous_self_move_outcome_success":
            return _evaluate_previous_move_outcome_success(
                condition_data,
                context
            )

        &"all":
            return _evaluate_all(
                condition_data,
                context
            )

        &"any":
            return _evaluate_any(
                condition_data,
                context
            )

        &"not":
            return _evaluate_not(
                condition_data,
                context
            )

        _:
            push_error(
                "ConditionEvaluator: unsupported condition type '%s'."
                % String(condition_type)
            )
            return false


static func _evaluate_hp(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    var target: Variant = context.resolve_target(
        StringName(
            condition_data.get("target", "self")
        )
    )

    if target == null:
        return false

    return _compare_numbers(
        int(target.current_hp),
        int(condition_data.get("value", 0)),
        StringName(
            condition_data.get("operator", "<=")
        )
    )


static func _evaluate_energy_count(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    if context.dice_result == null:
        return false

    var energy_type: StringName = StringName(
        condition_data.get("energy_type", "")
    )

    var actual_count: int = (
        context.dice_result.get_energy_count(
            energy_type
        )
    )

    return _compare_numbers(
        actual_count,
        int(condition_data.get("value", 0)),
        StringName(
            condition_data.get("operator", ">=")
        )
    )


static func _evaluate_previous_energy_failed(
    context: Variant,
    opponent: bool
) -> bool:
    var record: Variant = (
        _get_previous_record(
            context,
            opponent
        )
    )

    if record == null:
        return false

    return record.energy_roll_failed()


static func _evaluate_previous_move_outcome_success(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    if (
        context == null
        or context.actor == null
    ):
        return false

    var move_name_id: StringName = StringName(
        condition_data.get(
            "move_name_id",
            ""
        )
    )
    var matched: bool = PREVIOUS_MOVE_EFFECT.has_previous_move_success(
        context.actor,
        move_name_id
    )

    if (
        matched
        and context.turn_result != null
        and context.turn_result.has_method(
            "add_effect_lifecycle_entry"
        )
    ):
        var effect: Variant = (
            context.actor.effect_container.find_first(
                PREVIOUS_MOVE_EFFECT.EFFECT_TYPE,
                "move_name_id",
                String(move_name_id)
            )
        )

        context.turn_result.add_effect_lifecycle_entry(
            &"triggered",
            PREVIOUS_MOVE_EFFECT.EFFECT_TYPE,
            (
                StringName(effect.id)
                if effect != null
                else &""
            ),
            (
                "Previous Move condition triggered: "
                + String(move_name_id)
                + "."
            )
        )

    return matched


static func _get_previous_record(
    context: Variant,
    opponent: bool
) -> Variant:
    if (
        context == null
        or context.battle_state == null
        or context.actor == null
    ):
        return null

    if opponent:
        return (
            context.battle_state
            .get_previous_opponent_record_for(
                StringName(
                    context.actor.id
                )
            )
        )

    return (
        context.battle_state
        .get_previous_record_for(
            StringName(
                context.actor.id
            )
        )
    )


static func _evaluate_all(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    var children: Variant = condition_data.get(
        "conditions",
        []
    )

    if not children is Array:
        return false

    for child: Variant in children:
        if not child is Dictionary:
            return false

        if not evaluate(
            child as Dictionary,
            context
        ):
            return false

    return true


static func _evaluate_any(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    var children: Variant = condition_data.get(
        "conditions",
        []
    )

    if not children is Array:
        return false

    for child: Variant in children:
        if not child is Dictionary:
            continue

        if evaluate(
            child as Dictionary,
            context
        ):
            return true

    return false


static func _evaluate_not(
    condition_data: Dictionary,
    context: Variant
) -> bool:
    var child: Variant = condition_data.get(
        "condition",
        null
    )

    if not child is Dictionary:
        return false

    return not evaluate(
        child as Dictionary,
        context
    )


static func _compare_numbers(
    actual_value: int,
    expected_value: int,
    operator_id: StringName
) -> bool:
    match operator_id:
        &"<":
            return actual_value < expected_value
        &"<=":
            return actual_value <= expected_value
        &"==":
            return actual_value == expected_value
        &"!=":
            return actual_value != expected_value
        &">=":
            return actual_value >= expected_value
        &">":
            return actual_value > expected_value
        _:
            push_error(
                "ConditionEvaluator: unsupported operator '%s'."
                % String(operator_id)
            )
            return false
