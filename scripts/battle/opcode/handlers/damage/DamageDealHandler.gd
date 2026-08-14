extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload("res://scripts/battle/commands/BattleCommandFactory.gd")

func get_opcode() -> StringName:
    return &"damage.deal"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    context.command_queue.enqueue(COMMAND_FACTORY.create_damage_command(StringName(context.actor.id), context.resolve_target_id(StringName(args.get("target", "opponent"))), int(args.get("amount", 0)), StringName(args.get("damage_type", "direct")), &"direct"))
    return true
