extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)

func get_opcode() -> StringName:
    return &"incoming_damage.modify"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    context.command_queue.enqueue(
        COMMAND_FACTORY.create_modify_incoming_damage_command(
            StringName(context.actor.id),
            context.resolve_target_id(
                StringName(
                    args.get(
                        "target",
                        "self"
                    )
                )
            ),
            int(args.get("amount", 0)),
            int(args.get("duration_turns", 0)),
            int(args.get("remaining_uses", 1))
        )
    )
    return true
