extends RefCounted


const RULE_COMPILER: Script = preload(
    "res://scripts/battle/rules/RuleCompiler.gd"
)


var _rules_by_trigger: Dictionary = {}


func register_rule(rule: Variant) -> bool:
    if rule == null:
        return false

    var trigger_id: StringName = StringName(
        rule.trigger
    )

    if trigger_id == &"":
        return false

    if not _rules_by_trigger.has(trigger_id):
        _rules_by_trigger[trigger_id] = []

    var trigger_rules: Array = _rules_by_trigger[
        trigger_id
    ]

    for existing_rule: Variant in trigger_rules:
        if StringName(existing_rule.id) == StringName(rule.id):
            push_error(
                "TriggerEngine: duplicate rule id '%s'."
                % String(rule.id)
            )
            return false

    trigger_rules.append(rule)
    trigger_rules.sort_custom(
        func(a: Variant, b: Variant) -> bool:
            return int(a.priority) > int(b.priority)
    )

    return true


func register_rules(rules: Array) -> bool:
    for rule: Variant in rules:
        if not register_rule(rule):
            return false

    return true


func execute_trigger(
    trigger_id: StringName,
    execution_context: Variant
) -> bool:
    if not _rules_by_trigger.has(trigger_id):
        return true

    var trigger_rules: Array = _rules_by_trigger[
        trigger_id
    ]

    for rule: Variant in trigger_rules:
        if not RULE_COMPILER.compile_rule(
            rule,
            execution_context
        ):
            return false

    return true


func get_rules(
    trigger_id: StringName
) -> Array:
    if not _rules_by_trigger.has(trigger_id):
        return []

    return (
        _rules_by_trigger[trigger_id]
        as Array
    ).duplicate()


func clear() -> void:
    _rules_by_trigger.clear()
