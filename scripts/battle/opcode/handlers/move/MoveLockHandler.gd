extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)

func get_opcode() -> StringName:
    return &"move.lock"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    var move_name_id: StringName = StringName(
        args.get(
            "move_name_id",
            ""
        )
    )

    if move_name_id == &"":
        push_error(
            "move.lock requires args.move_name_id."
        )
        return false

    context.command_queue.enqueue(
        COMMAND_FACTORY.create_move_lock_command(
            StringName(context.actor.id),
            context.resolve_target_id(
                StringName(
                    args.get(
                        "target",
                        "opponent"
                    )
                )
            ),
            move_name_id,
            int(
                args.get(
                    "duration_turns",
                    1
                )
            )
        )
    )
    return true
