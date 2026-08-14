extends "res://scripts/battle/opcode/OpcodeHandler.gd"

const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)

func get_opcode() -> StringName:
    return &"damage.recoil"

func compile(action: Variant, context: Variant) -> bool:
    var amount: int = max(
        int(
            action.args.get(
                "amount",
                0
            )
        ),
        0
    )

    if amount <= 0:
        return true

    context.command_queue.enqueue(
        COMMAND_FACTORY.create_damage_command(
            StringName(context.actor.id),
            StringName(context.actor.id),
            amount,
            StringName(
                context.damage_context.attack_type
            ),
            &"recoil"
        )
    )
    context.log(
        "Recoil queued: %d."
        % amount
    )
    return true
