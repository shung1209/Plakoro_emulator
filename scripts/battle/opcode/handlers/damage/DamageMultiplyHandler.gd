extends "res://scripts/battle/opcode/OpcodeHandler.gd"

func get_opcode() -> StringName:
    return &"damage.multiply"

func compile(action: Variant, context: Variant) -> bool:
    var factor: float = float(
        action.args.get(
            "factor",
            1.0
        )
    )

    if factor < 0.0:
        push_error(
            "damage.multiply factor cannot be negative."
        )
        return false

    context.damage_context.damage_multiplier *= factor
    context.log(
        "Damage multiplier ×%s."
        % str(factor)
    )
    return true
