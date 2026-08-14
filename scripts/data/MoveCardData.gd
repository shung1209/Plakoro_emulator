extends RefCounted


var id: StringName = &""
var move_name_id: StringName = &""
var owner_id: StringName = &""
var display_name: String = ""
var move_category: StringName = &""
var attack_type: StringName = &""

var energy_costs: Array = []
var printed_damage: Variant = null
var base_actions: Array = []
var outcome_rules: Array = []
var special_effects: Array = []

# Milestone 5.4 rule-based model.
var rules: Array = []

var resolution: Dictionary = {}
var source: Dictionary = {}
var review: Dictionary = {}


func has_printed_damage() -> bool:
    return printed_damage != null


func get_printed_damage() -> int:
    if printed_damage == null:
        return 0

    return int(printed_damage)


func get_outcome_for_orientation(
    orientation: StringName
) -> Variant:
    var matched_outcome: Variant = null

    for outcome: Variant in outcome_rules:
        if not outcome.contains_orientation(orientation):
            continue

        if matched_outcome != null:
            push_error(
                "Move card '%s' has multiple outcomes for '%s'."
                % [String(id), String(orientation)]
            )
            return null

        matched_outcome = outcome

    return matched_outcome
