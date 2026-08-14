extends RefCounted

const REGISTRY_FACTORY: Script = preload(
    "res://scripts/battle/opcode/DefaultOpcodeRegistryFactory.gd"
)

static func inspect_move_document(move_data: Dictionary) -> Dictionary:
    var registry: Variant = REGISTRY_FACTORY.create()
    if registry == null:
        return {
            "success": false,
            "registered_opcodes": [],
            "used_opcodes": [],
            "unsupported_opcodes": [],
            "errors": ["Runtime opcode registry could not be created."]
        }

    var used: Array[StringName] = []
    _collect_actions(move_data.get("base_actions", []), used)

    var rules: Variant = move_data.get("outcome_rules", [])
    if rules is Array:
        for raw_rule: Variant in rules as Array:
            if raw_rule is Dictionary:
                _collect_actions(
                    (raw_rule as Dictionary).get("actions", []),
                    used
                )

    used.sort()
    var unsupported: Array[StringName] = []
    for opcode: StringName in used:
        if not registry.has_handler(opcode):
            unsupported.append(opcode)

    var errors: Array[String] = []
    for opcode: StringName in unsupported:
        errors.append(
            "Move uses unsupported runtime opcode: " + String(opcode)
        )

    return {
        "success": unsupported.is_empty(),
        "registered_opcodes": registry.get_registered_opcodes(),
        "used_opcodes": used,
        "unsupported_opcodes": unsupported,
        "errors": errors
    }

static func _collect_actions(
    raw_actions: Variant,
    result: Array[StringName]
) -> void:
    if not raw_actions is Array:
        return

    for raw_action: Variant in raw_actions as Array:
        if not raw_action is Dictionary:
            continue

        var action: Dictionary = raw_action
        var opcode: StringName = StringName(
            String(action.get("opcode", ""))
        )
        if opcode != &"" and not result.has(opcode):
            result.append(opcode)

        for nested_key: String in ["then_actions", "else_actions"]:
            _collect_actions(
                action.get(nested_key, []),
                result
            )
