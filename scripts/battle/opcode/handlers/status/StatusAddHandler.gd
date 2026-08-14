extends "res://scripts/battle/opcode/OpcodeHandler.gd"


const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)


func get_opcode() -> StringName:
    return &"status.add"


func compile(
    action: Variant,
    context: Variant
) -> bool:
    var args: Dictionary = action.args

    var target_name: StringName = StringName(
        args.get("target", "self")
    )
    var target_id: StringName = (
        context.resolve_target_id(target_name)
    )

    if target_id == &"":
        return false

    var payload: Dictionary = args.duplicate(true)
    payload.erase("target")

    context.command_queue.enqueue(
        COMMAND_FACTORY.create_add_status_command(
            StringName(context.actor.id),
            target_id,
            payload
        )
    )

    return true
