extends "res://scripts/battle/opcode/OpcodeHandler.gd"

func get_opcode() -> StringName:
    return &"damage.add"

func compile(action: Variant, context: Variant) -> bool:
    var amount: int = int(action.args.get("amount", 0))

    if context.stage == &"outcome":
        context.damage_context.outcome_bonus += amount
    else:
        context.damage_context.other_modifiers += amount

    if (
        amount > 0
        and context.turn_result != null
        and context.turn_result.has_method(
            "add_resolution_damage_atom"
        )
    ):
        context.turn_result.add_resolution_damage_atom(
            amount,
            StringName(context.stage),
            "Charakoro / Effect Damage"
        )

    context.log("Damage increased by %d." % amount)
    return true
