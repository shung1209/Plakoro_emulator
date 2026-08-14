extends RefCounted


const CONDITION_EVALUATOR: Script = preload(
    "res://scripts/battle/condition/ConditionEvaluator.gd"
)
const EFFECT_COMPILER: Script = preload(
    "res://scripts/battle/rules/EffectCompiler.gd"
)
const OPCODE_CONTEXT: Script = preload(
    "res://scripts/battle/opcode/OpcodeContext.gd"
)


static func compile_rule(
    rule: Variant,
    execution_context: Variant
) -> bool:
    if rule == null or not rule.enabled:
        return true

    var opcode_context: Variant = OPCODE_CONTEXT.new()

    opcode_context.initialize(
        execution_context.trigger,
        execution_context.actor,
        execution_context.target,
        execution_context.move_card,
        execution_context.damage_context,
        execution_context.dice_result,
        execution_context.command_queue,
        execution_context.battle_state,
        execution_context.turn_result,
        execution_context.logger_script,
        execution_context.opcode_registry
    )

    if not CONDITION_EVALUATOR.evaluate(
        rule.condition,
        opcode_context
    ):
        return true

    for effect: Variant in rule.effects:
        var action: Variant = (
            EFFECT_COMPILER.compile_effect(effect)
        )

        if action == null:
            return false

        if not execution_context.opcode_registry.compile_action(
            action,
            opcode_context
        ):
            return false

    if execution_context.logger_script != null:
        execution_context.logger_script.add(
            execution_context.battle_state,
            execution_context.turn_result,
            "Rule executed: %s."
            % String(rule.id)
        )

    return true
