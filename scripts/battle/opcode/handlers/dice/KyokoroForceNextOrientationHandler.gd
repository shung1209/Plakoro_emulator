extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)

func get_opcode() -> StringName:
    return &"kyokoro.force_next_orientation"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    var target_name: StringName = StringName(args.get("target", "self"))
    var target_id: StringName = context.resolve_target_id(target_name)
    if target_id == &"":
        return false

    var orientation: StringName = StringName(args.get("orientation", ""))
    if orientation == &"current":
        if context.dice_result == null:
            return false
        orientation = StringName(context.dice_result.kyokoro_orientation)
    if orientation == &"":
        return false

    context.command_queue.enqueue(
        COMMAND_FACTORY.create_add_status_command(
            StringName(context.actor.id),
            target_id,
            {
                "status_type": "kyokoro_forced_orientation",
                "stack_mode": "replace",
                "remaining_uses": 1,
                "timing": "next_owner_turn",
                "parameters": {"orientation": String(orientation)}
            }
        )
    )
    context.log("Next Charakoro orientation forced to %s." % String(orientation))
    return true
