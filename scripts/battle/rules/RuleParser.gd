extends RefCounted


const RULE_DATA: Script = preload(
    "res://scripts/battle/rules/data/RuleData.gd"
)
const EFFECT_DATA: Script = preload(
    "res://scripts/battle/rules/data/EffectData.gd"
)


static func parse_rule(
    data: Dictionary,
    source_path: String = ""
) -> Variant:
    var raw_id: Variant = data.get("id", "")
    var raw_trigger: Variant = data.get("trigger", "")

    if not raw_id is String or String(raw_id).strip_edges().is_empty():
        push_error(
            "%s: rule id must be a non-empty String."
            % source_path
        )
        return null

    if (
        not raw_trigger is String
        or String(raw_trigger).strip_edges().is_empty()
    ):
        push_error(
            "%s: rule trigger must be a non-empty String."
            % source_path
        )
        return null

    var rule: Variant = RULE_DATA.new(
        StringName(raw_id),
        StringName(raw_trigger)
    )

    rule.priority = int(data.get("priority", 0))
    rule.enabled = bool(data.get("enabled", true))

    var raw_condition: Variant = data.get(
        "condition",
        {"type": "always"}
    )

    if not raw_condition is Dictionary:
        push_error(
            "%s: rule condition must be an object."
            % source_path
        )
        return null

    rule.condition = (
        raw_condition as Dictionary
    ).duplicate(true)

    var raw_effects: Variant = data.get("effects", [])

    if not raw_effects is Array:
        push_error(
            "%s: rule effects must be an Array."
            % source_path
        )
        return null

    for index: int in range(
        (raw_effects as Array).size()
    ):
        var raw_effect: Variant = (
            raw_effects as Array
        )[index]

        if not raw_effect is Dictionary:
            push_error(
                "%s: effects[%d] must be an object."
                % [source_path, index]
            )
            return null

        var effect_dict: Dictionary = raw_effect as Dictionary
        var raw_type: Variant = effect_dict.get("type", "")

        if (
            not raw_type is String
            or String(raw_type).strip_edges().is_empty()
        ):
            push_error(
                "%s: effects[%d].type must be a non-empty String."
                % [source_path, index]
            )
            return null

        var parameters: Dictionary = effect_dict.duplicate(true)
        parameters.erase("type")

        rule.effects.append(
            EFFECT_DATA.new(
                StringName(raw_type),
                parameters
            )
        )

    var raw_source: Variant = data.get("source", {})

    if raw_source is Dictionary:
        rule.source = (
            raw_source as Dictionary
        ).duplicate(true)

    return rule
