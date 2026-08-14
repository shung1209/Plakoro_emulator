extends "res://scripts/battle/opcode/OpcodeHandler.gd"

func get_opcode() -> StringName:
    return &"turn.end"

func compile(action: Variant, context: Variant) -> bool:
    pass
    return true
