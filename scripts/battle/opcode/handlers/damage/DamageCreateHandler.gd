extends "res://scripts/battle/opcode/OpcodeHandler.gd"

func get_opcode() -> StringName:
    return &"damage.create"

func compile(action: Variant, context: Variant) -> bool:
    var args: Dictionary = action.args
    context.damage_context.base_damage = int(args.get("amount", 0))
    context.damage_context.attack_type = StringName(args.get("damage_type", context.move_card.attack_type))
    context.log("Base damage created: %d." % context.damage_context.base_damage)
    return true
