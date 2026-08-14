extends RefCounted


const MOVE_RULE_SERVICE: Script = preload(
    "res://scripts/battle/rules/MoveRuleService.gd"
)


var move_rule_engine: Variant = null
var move_card: Variant = null


func initialize(
    source_move_card: Variant
) -> bool:
    move_card = source_move_card
    move_rule_engine = (
        MOVE_RULE_SERVICE.create_engine_for_move(
            move_card
        )
    )

    return move_rule_engine != null


func execute(
    trigger_id: StringName,
    actor: Variant,
    target: Variant,
    dice_result: Variant,
    damage_context: Variant,
    battle_state: Variant,
    turn_result: Variant,
    command_queue: Variant,
    opcode_registry: Variant,
    logger_script: Script
) -> bool:
    if move_rule_engine == null:
        return false

    return MOVE_RULE_SERVICE.execute(
        move_rule_engine,
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
