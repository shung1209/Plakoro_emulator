extends "res://scripts/battle/opcode/OpcodeHandler.gd"


func get_opcode() -> StringName:
    return &"weakness.ignore_current"


func compile(
    _action: Variant,
    context: Variant
) -> bool:
    context.damage_context.ignore_weakness = true
    context.log(
        "Weakness ignored for the current attack."
    )
    return true
