extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload("res://scripts/battle/commands/BattleCommandFactory.gd")

func get_opcode() -> StringName:
    return &"move.repeat_permission"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    context.command_queue.enqueue(COMMAND_FACTORY.create_repeat_permission_command(StringName(context.actor.id), context.resolve_target_id(StringName(args.get("target", "self"))), StringName(args.get("move_name_id", context.move_card.move_name_id))))
    return true
