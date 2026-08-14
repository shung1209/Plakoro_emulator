extends RefCounted


const OPCODE_CONTEXT: Script = preload(
    "res://scripts/battle/opcode/OpcodeContext.gd"
)


var registry: Variant = null


func _init(
    opcode_registry: Variant
) -> void:
    registry = opcode_registry


func compile_actions(
    actions: Array,
    stage: StringName,
    actor: Variant,
    target: Variant,
    move_card: Variant,
    damage_context: Variant,
    dice_result: Variant,
    command_queue: Variant,
    battle_state: Variant,
    turn_result: Variant,
    logger_script: Script
) -> bool:
    if registry == null:
        push_error(
            "OpcodeCompiler: registry cannot be null."
        )
        return false

    var context: Variant = OPCODE_CONTEXT.new()

    context.initialize(
        stage,
        actor,
        target,
        move_card,
        damage_context,
        dice_result,
        command_queue,
        battle_state,
        turn_result,
        logger_script,
        registry
    )

    return context.compile_nested_actions(actions)
