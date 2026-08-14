extends RefCounted


const TRIGGER_ENGINE: Script = preload(
    "res://scripts/battle/rules/TriggerEngine.gd"
)
const EXECUTION_CONTEXT: Script = preload(
    "res://scripts/battle/rules/data/RuleExecutionContext.gd"
)


static func create_engine_for_move(
    move_card: Variant
) -> Variant:
    var engine: Variant = TRIGGER_ENGINE.new()

    if move_card == null:
        return engine

    if not engine.register_rules(move_card.rules):
        return null

    return engine


static func execute(
    engine: Variant,
    trigger_id: StringName,
    actor: Variant,
    target: Variant,
    move_card: Variant,
    dice_result: Variant,
    damage_context: Variant,
    battle_state: Variant,
    turn_result: Variant,
    command_queue: Variant,
    opcode_registry: Variant,
    logger_script: Script
) -> bool:
    var context: Variant = EXECUTION_CONTEXT.new()

    context.initialize(
        trigger_id,
        actor,
        target,
        move_card,
        dice_result,
        damage_context,
        battle_state,
        turn_result,
        command_queue,
        opcode_registry,
        logger_script
    )

    return engine.execute_trigger(
        trigger_id,
        context
    )
