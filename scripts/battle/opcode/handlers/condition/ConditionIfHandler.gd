extends "res://scripts/battle/opcode/OpcodeHandler.gd"


const CONDITION_EVALUATOR: Script = preload(
    "res://scripts/battle/condition/ConditionEvaluator.gd"
)


func get_opcode() -> StringName:
    return &"condition.if"


func compile(
    action: Variant,
    context: Variant
) -> bool:
    var condition_value: Variant = action.args.get(
        "condition",
        null
    )

    if not condition_value is Dictionary:
        push_error(
            "condition.if requires args.condition object."
        )
        return false

    var matched: bool = CONDITION_EVALUATOR.evaluate(
        condition_value as Dictionary,
        context
    )

    context.log(
        "Condition evaluated: %s."
        % str(matched)
    )

    if matched:
        return context.compile_nested_actions(
            action.then_actions
        )

    return context.compile_nested_actions(
        action.else_actions
    )
