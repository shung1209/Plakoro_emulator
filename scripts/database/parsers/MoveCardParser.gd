extends RefCounted


const MOVE_CARD_DATA: Script = preload(
    "res://scripts/data/MoveCardData.gd"
)
const ENERGY_COST_DATA: Script = preload(
    "res://scripts/data/EnergyCostData.gd"
)
const ACTION_DATA: Script = preload(
    "res://scripts/data/ActionData.gd"
)
const CONDITION_DATA: Script = preload(
    "res://scripts/data/ConditionData.gd"
)
const OUTCOME_RULE_DATA: Script = preload(
    "res://scripts/data/OutcomeRuleData.gd"
)


const VALID_MOVE_CATEGORIES: Array[StringName] = [
	&"attack",
	&"defense",
	&"support",
	&"recovery",
	&"control",
	&"hybrid"
]


static func parse(
	data: Dictionary,
	source_path: String,
	reference_data: Variant
) -> Variant:
	for key: String in [
		"id",
		"move_name_id",
		"owner_id",
		"display_name",
        "move_category"
	]:
		if not _require_string(
			data,
			key,
			source_path
		):
			return null

	var card: Variant = MOVE_CARD_DATA.new()
	card.id = StringName(data["id"])
	card.move_name_id = StringName(data["move_name_id"])
	card.owner_id = StringName(data["owner_id"])
	card.display_name = String(data["display_name"])
	card.move_category = StringName(data["move_category"])

	if not VALID_MOVE_CATEGORIES.has(card.move_category):
		push_error(
            "%s: invalid move_category '%s'."
			% [source_path, String(card.move_category)]
		)
		return null

	var attack_value: Variant = data.get(
		"attack_type",
        ""
	)

	if not attack_value is String:
		return null

	card.attack_type = StringName(attack_value)

	if (
		card.attack_type != &""
		and not reference_data.has_pokemon_type(
			card.attack_type
		)
	):
		push_error(
			"%s: invalid attack_type '%s'."
			% [source_path, String(card.attack_type)]
		)
		return null

	var damage_value: Variant = data.get(
		"printed_damage",
		null
	)

	if damage_value == null:
		card.printed_damage = null
	elif damage_value is int or damage_value is float:
		card.printed_damage = int(damage_value)
	else:
		return null

	if not _parse_energy_costs(
		card,
		data.get("energy_cost", []),
		source_path,
		reference_data
	):
		return null

	var base_actions: Variant = _parse_actions(
		data.get("base_actions", []),
		source_path,
		reference_data,
        "base_actions"
	)

	if base_actions == null:
		return null

	card.base_actions = base_actions

	var outcome_rules: Variant = _parse_outcomes(
		data.get("outcome_rules", []),
		source_path,
		reference_data
	)

	if outcome_rules == null:
		return null

	card.outcome_rules = outcome_rules

	var special_effects_value: Variant = data.get(
		"special_effects",
		[]
	)

	if not special_effects_value is Array:
		push_error(
			"%s: special_effects must be an Array."
			% source_path
		)
		return null

	card.special_effects = (
		(special_effects_value as Array).duplicate(
			true
		)
	)

	for field_name: String in [
		"resolution",
		"source",
        "review"
	]:
		var field_value: Variant = data.get(
			field_name,
			{}
		)

		if not field_value is Dictionary:
			return null

		card.set(
			field_name,
			(field_value as Dictionary).duplicate(true)
		)

	return card


static func _parse_energy_costs(
	card: Variant,
	raw_costs: Variant,
	source_path: String,
	reference_data: Variant
) -> bool:
	if not raw_costs is Array:
		return false

	for raw_cost: Variant in raw_costs:
		if not raw_cost is Dictionary:
			return false

		var cost_data: Dictionary = raw_cost as Dictionary

		if not _require_string(
			cost_data,
			"energy_type",
			source_path
		):
			return false

		var energy_type: StringName = StringName(
			cost_data["energy_type"]
		)

		# Normal is a Move-cost wildcard in Plakoro. It is intentionally not
		# part of the Enerkoro reference list because dice cannot roll it.
		if (
			energy_type != &"normal"
			and not reference_data.has_energy_type(
				energy_type
			)
		):
			push_error(
				"%s: invalid energy_cost type '%s'."
				% [source_path, String(energy_type)]
			)
			return false

		var count_value: Variant = cost_data.get(
			"count",
			0
		)

		if not (
			count_value is int
			or count_value is float
		):
			return false

		var cost: Variant = ENERGY_COST_DATA.new()
		cost.energy_type = energy_type
		cost.count = int(count_value)
		card.energy_costs.append(cost)

	return true


static func _parse_actions(
	raw_actions: Variant,
	source_path: String,
	reference_data: Variant,
	field_path: String
) -> Variant:
	if not raw_actions is Array:
		push_error(
            "%s: %s must be an Array."
			% [source_path, field_path]
		)
		return null

	var result: Array = []

	for index: int in range(
		(raw_actions as Array).size()
	):
		var raw_action: Variant = (
			raw_actions as Array
		)[index]

		if not raw_action is Dictionary:
			return null

		var action_data: Dictionary = raw_action as Dictionary

		if not _require_string(
			action_data,
			"opcode",
			source_path
		):
			return null

		var opcode: StringName = StringName(
			action_data["opcode"]
		)

		var args_value: Variant = action_data.get(
			"args",
			{}
		)

		if not args_value is Dictionary:
			return null

		if not reference_data.has_opcode(opcode):
			push_warning(
                "%s: unknown opcode '%s'."
				% [source_path, String(opcode)]
			)

		var action: Variant = ACTION_DATA.new(
			opcode,
			args_value as Dictionary
		)

		var then_value: Variant = action_data.get(
			"then",
			[]
		)
		var else_value: Variant = action_data.get(
			"else",
			[]
		)

		var parsed_then: Variant = _parse_actions(
			then_value,
			source_path,
			reference_data,
			"%s[%d].then" % [field_path, index]
		)

		if parsed_then == null:
			return null

		var parsed_else: Variant = _parse_actions(
			else_value,
			source_path,
			reference_data,
			"%s[%d].else" % [field_path, index]
		)

		if parsed_else == null:
			return null

		action.then_actions = parsed_then
		action.else_actions = parsed_else
		result.append(action)

	return result


static func _parse_outcomes(
	raw_outcomes: Variant,
	source_path: String,
	reference_data: Variant
) -> Variant:
	if not raw_outcomes is Array:
		return null

	var result: Array = []

	for index: int in range(
		(raw_outcomes as Array).size()
	):
		var raw_outcome: Variant = (
			raw_outcomes as Array
		)[index]

		if not raw_outcome is Dictionary:
			return null

		var outcome_data: Dictionary = raw_outcome as Dictionary
		var condition_value: Variant = outcome_data.get(
			"condition",
			{}
		)

		if not condition_value is Dictionary:
			return null

		var condition: Variant = _parse_condition(
			condition_value as Dictionary,
			source_path,
			reference_data
		)

		if condition == null:
			return null

		var actions: Variant = _parse_actions(
			outcome_data.get("actions", []),
			source_path,
			reference_data,
			"outcome_rules[%d].actions" % index
		)

		if actions == null:
			return null

		var outcome: Variant = OUTCOME_RULE_DATA.new()
		outcome.condition = condition
		outcome.actions = actions
		outcome.raw_text = String(
			outcome_data.get("raw_text", "")
		)
		result.append(outcome)

	return result


static func _parse_condition(
	raw_condition: Dictionary,
	source_path: String,
	reference_data: Variant
) -> Variant:
	if not _require_string(
		raw_condition,
		"type",
		source_path
	):
		return null

	var condition_type: StringName = StringName(
		raw_condition["type"]
	)

	var parameters: Dictionary = (
		raw_condition.duplicate(true)
	)
	parameters.erase("type")
	parameters.erase("conditions")

	var result: Variant = CONDITION_DATA.new(
		condition_type,
		parameters
	)

	var children_value: Variant = raw_condition.get(
		"conditions",
		[]
	)

	if not children_value is Array:
		return null

	for child_value: Variant in children_value:
		if not child_value is Dictionary:
			return null

		var child: Variant = _parse_condition(
			child_value as Dictionary,
			source_path,
			reference_data
		)

		if child == null:
			return null

		result.child_conditions.append(child)

	return result


static func _require_string(
	data: Dictionary,
	key: String,
	source_path: String
) -> bool:
	if not data.has(key):
		push_error(
            "%s: missing field '%s'."
			% [source_path, key]
		)
		return false

	return (
		data[key] is String
		and not String(data[key]).strip_edges().is_empty()
	)
