extends RefCounted


const TURN_DATA: Script = preload(
	"res://scripts/presentation/timeline/BattleTimelineTurnData.gd"
)
const ENTRY_DATA: Script = preload(
	"res://scripts/presentation/timeline/BattleTimelineEntryData.gd"
)
const EFFECT_DESCRIPTION: Script = preload(
	"res://scripts/presentation/timeline/BattleEffectDescription.gd"
)
const CHARAKORO_FEEDBACK: Script = preload(
	"res://scripts/presentation/CharakoroBattleFeedbackService.gd"
)


static func build_turn(
	turn_number: int,
	actor_id: StringName,
	move_card: Variant,
	dice_result: Variant,
	turn_result: Variant,
	ai_decision: Variant = null
) -> Variant:
	var turn: Variant = TURN_DATA.new()

	turn.turn_number = turn_number
	turn.actor_id = actor_id
	turn.move_card_id = StringName(move_card.id)
	turn.move_name = GameContentLocalizationService.localize_move(move_card)

	turn.add_entry(
		ENTRY_DATA.new(
			&"move",
			actor_id,
			LocalizationService.tr_key("battle.timeline.move", "Move"),
			[
				LocalizationService.tr_format(
					"battle.timeline.move_selected",
					{
						"actor": _actor_label(
							actor_id
						),
						"move": GameContentLocalizationService.localize_move(
							move_card
						)
					},
					"{actor} selected {move}."
				)
			],
			&"actor"
		)
	)

	if ai_decision != null and ai_decision.is_valid():
		turn.add_entry(
			_build_ai_entry(
				actor_id,
				ai_decision
			)
		)

	turn.add_entry(
		ENTRY_DATA.new(
			&"dice",
			actor_id,
			LocalizationService.tr_key("battle.timeline.dice_result", "Dice Result"),
			[
				LocalizationService.tr_format(
					"battle.timeline.energy",
					{
						"energy": _format_energy_counts(
							dice_result.energy_counts
						)
					},
					"Energy: {energy}"
				),
				LocalizationService.tr_format(
					"battle.timeline.charakoro",
					{
						"charakoro": _format_charakoro_orientations(
							dice_result
						)
					},
					"Charakoro: {charakoro}"
				)
			],
			&"dice"
		)
	)

	turn.add_entry(
		ENTRY_DATA.new(
			&"energy_check",
			actor_id,
			LocalizationService.tr_key("battle.timeline.energy_check", "Energy Check"),
			_build_energy_check_lines(
				move_card,
				dice_result,
				bool(turn_result.energy_sufficient)
			),
			(
				&"success"
				if bool(turn_result.energy_sufficient)
				else &"failure"
			)
		)
	)

	if not bool(turn_result.energy_sufficient):
		_append_effect_lifecycle_entries(
			turn,
			actor_id,
			turn_result
		)

		turn.add_entry(
			ENTRY_DATA.new(
				&"result",
				actor_id,
				LocalizationService.tr_key("battle.timeline.turn_result", "Turn Result"),
				[
					LocalizationService.tr_key(
					"battle.timeline.energy_failed",
					"The move did not execute because the energy requirement was not met."
				)
				],
				&"failure"
			)
		)
		return turn

	var damage_context: Variant = (
		turn_result.damage_context
	)

	if damage_context != null:
		turn.add_entry(
			_build_damage_entry(
				actor_id,
				damage_context,
				int(turn_result.applied_damage)
			)
		)

	var effect_lines: Array[String] = []

	effect_lines.append_array(
		EFFECT_DESCRIPTION.describe_actions(
			move_card.base_actions,
			"Base effect"
		)
	)

	var charakoro_feedback: Dictionary = (
		CHARAKORO_FEEDBACK.build_feedback(
			move_card,
			dice_result
		)
	)

	if bool(
		charakoro_feedback.get(
			"triggered",
			false
		)
	):
		for raw_group: Variant in charakoro_feedback.get(
			"groups",
			[]
		):
			if not raw_group is Dictionary:
				continue

			var group: Dictionary = raw_group
			var effect_text: String = String(
				group.get(
					"effect_text",
					""
				)
			).strip_edges()

			if effect_text.is_empty():
				continue

			effect_lines.append(
				LocalizationService.tr_format(
					"battle.timeline.charakoro_effect",
					{
						"orientations": _format_orientation_list(
							group.get(
								"orientations",
								[]
							)
						),
						"effect": effect_text
					},
					"Charakoro effect [{orientations}]: {effect}"
				)
			)

	if not effect_lines.is_empty():
		turn.add_entry(
			ENTRY_DATA.new(
				&"effects",
				actor_id,
				LocalizationService.tr_key("battle.timeline.effect_explanation", "Effect Explanation"),
				effect_lines,
				&"status"
			)
		)

	_append_effect_lifecycle_entries(
		turn,
		actor_id,
		turn_result
	)

	turn.add_entry(
		ENTRY_DATA.new(
			&"result",
			actor_id,
			LocalizationService.tr_key("battle.timeline.turn_result", "Turn Result"),
			[
				LocalizationService.tr_format(
					"battle.timeline.applied_damage",
					{
						"damage": int(
							turn_result.applied_damage
						)
					},
					"Applied damage: {damage}"
				),
				(
					LocalizationService.tr_key("battle.timeline.battle_finished", "Battle finished.")
					if bool(turn_result.battle_finished)
					else LocalizationService.tr_key("battle.timeline.turn_completed", "Turn completed.")
				)
			],
			(
				&"result"
				if bool(turn_result.battle_finished)
				else &"normal"
			)
		)
	)

	return turn


static func _append_effect_lifecycle_entries(
	turn: Variant,
	actor_id: StringName,
	turn_result: Variant
) -> void:
	if turn_result == null:
		return

	var raw_entries: Variant = turn_result.effect_lifecycle_entries

	if not raw_entries is Array:
		return

	for raw_entry: Variant in raw_entries:
		if not raw_entry is Dictionary:
			continue

		var entry: Dictionary = raw_entry
		var state_name: StringName = StringName(
			entry.get(
				"state",
				""
			)
		)
		var effect_type: String = String(
			entry.get(
				"effect_type",
				""
			)
		)
		var message: String = String(
			entry.get(
				"message",
				""
			)
		)

		var title: String = LocalizationService.tr_key(
			"battle.timeline.effect_state",
			"Effect State"
		)

		match state_name:
			&"created":
				title = LocalizationService.tr_key("battle.timeline.effect_created", "Effect Created")
			&"active":
				title = LocalizationService.tr_key("battle.timeline.effect_active", "Effect Active")
			&"triggered":
				title = LocalizationService.tr_key("battle.timeline.effect_triggered", "Effect Triggered")
			&"consumed":
				title = LocalizationService.tr_key("battle.timeline.effect_consumed", "Effect Consumed")
			&"expired":
				title = LocalizationService.tr_key("battle.timeline.effect_expired", "Effect Expired")

		var lines: Array[String] = []

		if not effect_type.is_empty():
			lines.append(
				LocalizationService.tr_format(
					"battle.timeline.type",
					{
						"type": effect_type.replace(
							"_",
							" "
						)
					},
					"Type: {type}"
				)
			)

		if not message.is_empty():
			lines.append(
				message
			)

		turn.add_entry(
			ENTRY_DATA.new(
				&"effect_lifecycle",
				actor_id,
				title,
				lines,
				(
					&"success"
					if state_name == &"triggered"
					else &"status"
				)
			)
		)


static func build_status_entry(
	actor_id: StringName,
	status_type: StringName,
	value: int
) -> Variant:
	return ENTRY_DATA.new(
		&"status",
		actor_id,
		LocalizationService.tr_key("battle.timeline.status_applied", "Status Applied"),
		[
			EFFECT_DESCRIPTION.describe_status(
				status_type,
				value
			)
		],
		&"status"
	)


static func _build_ai_entry(
	actor_id: StringName,
	decision: Variant
) -> Variant:
	var evaluation: Variant = (
		decision.selected_evaluation
	)

	return ENTRY_DATA.new(
		&"ai_decision",
		actor_id,
		LocalizationService.tr_key("battle.timeline.ai_decision", "AI Decision"),
		[
			LocalizationService.tr_format(
				"battle.timeline.selected",
				{"move": String(evaluation.display_name)},
				"Selected: {move}"
			),
			LocalizationService.tr_format(
				"battle.timeline.score",
				{"score": _format_float(float(evaluation.score))},
				"Score: {score}"
			),
			LocalizationService.tr_format(
				"battle.timeline.expected_damage",
				{"damage": _format_float(float(evaluation.expected_damage))},
				"Expected damage: {damage}"
			),
			LocalizationService.tr_format(
				"battle.timeline.energy_success",
				{"value": _format_percent(float(evaluation.success_probability))},
				"Energy success: {value}"
			),
			LocalizationService.tr_format(
				"battle.timeline.ko_probability",
				{"value": _format_percent(float(evaluation.knockout_probability))},
				"KO probability: {value}"
			)
		],
		&"ai"
	)


static func _build_energy_check_lines(
	move_card: Variant,
	dice_result: Variant,
	passed: bool
) -> Array[String]:
	var lines: Array[String] = []

	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.required",
			{
				"value": _format_costs(
					move_card.energy_costs
				)
			},
			"Required: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.rolled",
			{
				"value": _format_energy_counts(
					dice_result.energy_counts
				)
			},
			"Rolled: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.result",
			{
				"value": LocalizationService.tr_key(
					(
						"battle.timeline.pass"
						if passed
						else "battle.timeline.fail"
					),
					(
						"PASS"
						if passed
						else "FAIL"
					)
				)
			},
			"Result: {value}"
		)
	)

	return lines



static func _build_damage_entry(
	actor_id: StringName,
	damage_context: Variant,
	applied_damage: int
) -> Variant:
	var lines: Array[String] = []

	var base_damage: int = int(
		damage_context.base_damage
	)
	var charakoro_bonus: int = int(
		damage_context.outcome_bonus
	)
	var other_modifiers: int = int(
		damage_context.other_modifiers
	)
	var weakness_bonus: int = int(
		damage_context.weakness_bonus
	)
	var defender_reduction: int = int(
		damage_context.defender_reduction
	)

	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.move_damage",
			{"value": base_damage},
			"Move damage: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.charakoro_damage",
			{"value": _signed(charakoro_bonus)},
			"Charakoro damage/effect: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.other_modifiers",
			{"value": _signed(other_modifiers)},
			"Other attack modifiers: {value}"
		)
	)

	var attack_before_weakness: int = (
		base_damage
		+ charakoro_bonus
		+ other_modifiers
	)

	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.attack_subtotal",
			{"value": attack_before_weakness},
			"Attack subtotal before weakness: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.weakness_bonus",
			{"value": _signed(weakness_bonus)},
			"Weakness bonus: {value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.defense_reduction",
			{"value": defender_reduction},
			"Defense reduction: -{value}"
		)
	)
	lines.append(
		LocalizationService.tr_format(
			"battle.timeline.final_damage",
			{"value": applied_damage},
			"Final applied damage: {value}"
		)
	)

	return ENTRY_DATA.new(
		&"damage",
		actor_id,
		LocalizationService.tr_key("battle.timeline.damage_calculation", "Damage Calculation"),
		lines,
		&"damage"
	)


static func _format_charakoro_orientations(
	dice_result: Variant
) -> String:
	var orientations: Array = []

	if dice_result.has_method(
		"get_all_kyokoro_orientations"
	):
		orientations = (
			dice_result.get_all_kyokoro_orientations()
		)
	else:
		if StringName(
			dice_result.kyokoro_orientation
		) != &"":
			orientations.append(
				dice_result.kyokoro_orientation
			)

		for raw_orientation: Variant in (
			dice_result.additional_kyokoro_orientations
		):
			orientations.append(
				raw_orientation
			)

	if orientations.is_empty():
		return LocalizationService.tr_key("battle.none", "(none)")

	return _format_orientation_list(
		orientations
	)


static func _format_orientation_list(
	orientations: Array
) -> String:
	var parts: Array[String] = []

	for raw_orientation: Variant in orientations:
		var orientation: String = String(
			raw_orientation
		)

		if orientation.is_empty():
			continue

		if not parts.has(
			orientation
		):
			parts.append(
				orientation
			)

	if parts.is_empty():
		return LocalizationService.tr_key("battle.none", "(none)")

	return " -> ".join(
		parts
	)


static func _format_energy_counts(
	energy_counts: Dictionary
) -> String:
	var parts: Array[String] = []
	var keys: Array = energy_counts.keys()
	keys.sort()

	for raw_key: Variant in keys:
		var count: int = int(
			energy_counts[raw_key]
		)

		if count <= 0:
			continue

		parts.append(
			String(raw_key)
			+ " x "
			+ str(count)
		)

	if parts.is_empty():
		return LocalizationService.tr_key("battle.none", "(none)")

	return ", ".join(parts)


static func _format_costs(
	costs: Array
) -> String:
	var parts: Array[String] = []

	for cost: Variant in costs:
		parts.append(
			String(cost.energy_type)
			+ " x "
			+ str(int(cost.count))
		)

	if parts.is_empty():
		return LocalizationService.tr_key("battle.none", "(none)")

	return ", ".join(parts)


static func _actor_label(
	actor_id: StringName
) -> String:
	if actor_id == &"player":
		return LocalizationService.tr_key("battle.actor.you", "You")

	return "AI"


static func _signed(value: int) -> String:
	if value > 0:
		return "+" + str(value)

	return str(value)


static func _format_float(value: float) -> String:
	return "%.2f" % value


static func _format_percent(value: float) -> String:
	return "%.1f%%" % (value * 100.0)
