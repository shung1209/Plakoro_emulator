extends RefCounted


const RULE_PARSER: Script = preload(
    "res://scripts/battle/rules/RuleParser.gd"
)


static func attach_rules(
    move_card: Variant,
    raw_rules: Variant,
    source_path: String = ""
) -> bool:
    if move_card == null:
        return false

    if not raw_rules is Array:
        push_error(
            "%s: rules must be an Array."
            % source_path
        )
        return false

    move_card.rules.clear()

    for index: int in range(
        (raw_rules as Array).size()
    ):
        var raw_rule: Variant = (
            raw_rules as Array
        )[index]

        if not raw_rule is Dictionary:
            return false

        var rule: Variant = RULE_PARSER.parse_rule(
            raw_rule as Dictionary,
            "%s.rules[%d]" % [source_path, index]
        )

        if rule == null:
            return false

        move_card.rules.append(rule)

    return true
