extends RefCounted


var stage: StringName = &""

var actor: Variant = null
var target: Variant = null
var move_card: Variant = null
var damage_context: Variant = null
var dice_result: Variant = null

var command_queue: Variant = null
var battle_state: Variant = null
var turn_result: Variant = null

var logger_script: Script = null
var registry: Variant = null


func initialize(
    action_stage: StringName,
    action_actor: Variant,
    action_target: Variant,
    source_move_card: Variant,
    source_damage_context: Variant,
    source_dice_result: Variant,
    target_command_queue: Variant,
    source_battle_state: Variant,
    source_turn_result: Variant,
    source_logger_script: Script,
    opcode_registry: Variant
) -> void:
    stage = action_stage
    actor = action_actor
    target = action_target
    move_card = source_move_card
    damage_context = source_damage_context
    dice_result = source_dice_result
    command_queue = target_command_queue
    battle_state = source_battle_state
    turn_result = source_turn_result
    logger_script = source_logger_script
    registry = opcode_registry


func resolve_target_id(
    target_name: StringName
) -> StringName:
    var resolved: Variant = resolve_target(target_name)

    if resolved == null:
        return &""

    return StringName(resolved.id)


func resolve_target(
    target_name: StringName
) -> Variant:
    if target_name == &"self":
        return actor

    if target_name == &"opponent":
        return target

    if target_name == StringName(actor.id):
        return actor

    if target_name == StringName(target.id):
        return target

    return null


func compile_nested_actions(
    actions: Array
) -> bool:
    if registry == null:
        push_error(
            "OpcodeContext: registry is not available."
        )
        return false

    for action: Variant in actions:
        if not registry.compile_action(
            action,
            self
        ):
            return false

    return true


func log(message: String) -> void:
    if logger_script == null:
        return

    logger_script.add(
        battle_state,
        turn_result,
        message
    )
