extends "res://scripts/battle/opcode/OpcodeHandler.gd"


func get_opcode() -> StringName:
    return &"damage.add_per_energy"


func compile(
    action: Variant,
    context: Variant
) -> bool:
    if context.dice_result == null:
        return false

    var energy_type: StringName = StringName(
        action.args.get(
            "energy_type",
            ""
        )
    )
    var amount_per_energy: int = int(
        action.args.get(
            "amount_per_energy",
            0
        )
    )
    var count: int = context.dice_result.get_energy_count(
        energy_type
    )
    var bonus: int = max(
        count * amount_per_energy,
        0
    )

    context.damage_context.other_modifiers += bonus

    if (
        bonus > 0
        and context.turn_result != null
        and context.turn_result.has_method(
            "add_resolution_damage_atom"
        )
    ):
        context.turn_result.add_resolution_damage_atom(
            bonus,
            StringName(context.stage),
            "Energy / Effect Damage"
        )

    context.log(
        "Damage +%d from %s Energy × %d."
        % [
            bonus,
            String(energy_type),
            count
        ]
    )
    return true
