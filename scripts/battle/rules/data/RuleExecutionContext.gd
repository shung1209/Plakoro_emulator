extends RefCounted


var trigger: StringName = &""

var actor: Variant = null
var target: Variant = null
var move_card: Variant = null
var dice_result: Variant = null
var damage_context: Variant = null

var battle_state: Variant = null
var turn_result: Variant = null
var command_queue: Variant = null

var opcode_registry: Variant = null
var logger_script: Script = null


func initialize(
    trigger_id: StringName,
    action_actor: Variant,
    action_target: Variant,
    source_move_card: Variant,
    source_dice_result: Variant,
    source_damage_context: Variant,
    source_battle_state: Variant,
    source_turn_result: Variant,
    target_command_queue: Variant,
    source_opcode_registry: Variant,
    source_logger_script: Script
) -> void:
    trigger = trigger_id
    actor = action_actor
    target = action_target
    move_card = source_move_card
    dice_result = source_dice_result
    damage_context = source_damage_context
    battle_state = source_battle_state
    turn_result = source_turn_result
    command_queue = target_command_queue
    opcode_registry = source_opcode_registry
    logger_script = source_logger_script
