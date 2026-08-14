extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload("res://scripts/battle/commands/BattleCommandFactory.gd")

func get_opcode() -> StringName:
    return &"hp.restore"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    context.command_queue.enqueue(COMMAND_FACTORY.create_heal_command(StringName(context.actor.id), context.resolve_target_id(StringName(args.get("target", "self"))), int(args.get("amount", 0))))
    return true
