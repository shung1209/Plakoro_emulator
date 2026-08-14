extends "res://scripts/battle/opcode/OpcodeHandler.gd"

func get_opcode() -> StringName:
    return &"damage.set"

func compile(action: Variant, context: Variant) -> bool:
    context.damage_context.base_damage = int(action.args.get("amount", 0))
    context.log("Damage set to %d." % context.damage_context.base_damage)
    return true
