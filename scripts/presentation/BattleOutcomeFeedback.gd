extends RefCounted


static func build_lines(
	actor_name: String,
	target_name: String,
	move_card: Variant,
	turn_result: Variant,
	actor_hp_before: int,
	actor_hp_after: int,
	target_hp_before: int,
	target_hp_after: int
) -> Array[String]:
	var lines: Array[String] = []
	var move_name: String = (
		GameContentLocalizationService.localize_move(
			move_card
		)
		if move_card != null
		else LocalizationService.tr_key(
			"battle.timeline.move",
			"Move"
		)
	)

	lines.append(
		LocalizationService.tr_format(
			"battle.outcome.used",
			{"actor": actor_name, "move": move_name},
			"{actor} used {move}!"
		)
	)

	if turn_result == null:
		lines.append(LocalizationService.tr_key("battle.outcome.move_failed", "The move failed!"))
		return lines

	if not bool(turn_result.energy_sufficient):
		lines.append(LocalizationService.tr_key("battle.outcome.move_failed", "The move failed!"))
		lines.append(LocalizationService.tr_key("battle.outcome.not_enough_energy", "Not enough Energy."))
		return lines

	if not bool(turn_result.move_executed):
		lines.append(LocalizationService.tr_key("battle.outcome.move_failed", "The move failed!"))
		return lines

	lines.append(LocalizationService.tr_key("battle.outcome.move_succeeded", "The move succeeded!"))

	var target_damage: int = max(
		0,
		target_hp_before - target_hp_after
	)
	var target_heal: int = max(
		0,
		target_hp_after - target_hp_before
	)
	var actor_damage: int = max(
		0,
		actor_hp_before - actor_hp_after
	)
	var actor_heal: int = max(
		0,
		actor_hp_after - actor_hp_before
	)

	if target_damage > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.damage",
				{
					"target": target_name,
					"damage": target_damage
				},
				"{target} took {damage} damage."
			)
		)
	elif target_heal > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.heal",
				{
					"target": target_name,
					"hp": target_heal
				},
				"{target} recovered {hp} HP."
			)
		)

	if actor_heal > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.heal",
				{
					"target": actor_name,
					"hp": actor_heal
				},
				"{target} recovered {hp} HP."
			)
		)

	if actor_damage > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.recoil",
				{
					"actor": actor_name,
					"damage": actor_damage
				},
				"{actor} took {damage} recoil damage."
			)
		)

	_append_damage_modifiers(
		lines,
		turn_result
	)
	_append_condition_feedback(
		lines,
		move_card,
		turn_result
	)
	_append_status_feedback(
		lines,
		turn_result
	)
	_append_temporary_effect_feedback(
		lines,
		turn_result
	)

	return _deduplicate(lines)


static func _append_damage_modifiers(
	lines: Array[String],
	turn_result: Variant
) -> void:
	var context: Variant = turn_result.damage_context
	if context == null:
		return

	var weakness_bonus: int = int(
		context.weakness_bonus
	)
	if weakness_bonus > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.weakness_added",
				{"damage": weakness_bonus},
				"Weakness added {damage} damage!"
			)
		)

	var reduction: int = int(
		context.defender_reduction
	)
	if reduction > 0:
		lines.append(
			LocalizationService.tr_format(
				"battle.outcome.damage_reduced",
				{"damage": reduction},
				"Damage was reduced by {damage}."
			)
		)


static func _append_condition_feedback(
	lines: Array[String],
	move_card: Variant,
	turn_result: Variant
) -> void:
	if move_card == null:
		return

	var outcome_rules: Variant = move_card.outcome_rules
	if not outcome_rules is Array:
		return
	if (outcome_rules as Array).is_empty():
		return

	lines.append(
		LocalizationService.tr_key("battle.outcome.condition_triggered", "Conditional effect activated!")
		if bool(turn_result.outcome_triggered)
		else LocalizationService.tr_key("battle.outcome.condition_failed", "Conditional effect did not activate.")
	)


static func _append_status_feedback(
	lines: Array[String],
	turn_result: Variant
) -> void:
	var entries: Variant = turn_result.status_lifecycle_entries
	if not entries is Array:
		return

	for raw_entry: Variant in entries:
		var entry: String = String(raw_entry)
		var lower: String = entry.to_lower()

		if lower.contains("move_lock"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.move_disabled", "A Move was disabled for the next turn.")
			)
		elif lower.contains("kyokoro_disable"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.charakoro_disabled", "Charakoro will be disabled on the next roll.")
			)
		elif lower.contains("energy_dice_modifier"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.enerkoro_modified", "The next Enerkoro roll was modified.")
			)
		elif lower.contains("incoming_damage_modifier"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.protection", "Incoming damage protection was applied.")
			)
		elif lower.contains("attack_damage_immunity"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.attack_block", "The next incoming attack will be blocked.")
			)
		elif lower.contains("weakness_disable"):
			lines.append(
				LocalizationService.tr_key("battle.outcome.weakness_disabled", "Weakness will be ignored on the next Move.")
			)


static func _append_temporary_effect_feedback(
	lines: Array[String],
	turn_result: Variant
) -> void:
	var entries: Variant = turn_result.effect_lifecycle_entries
	if not entries is Array:
		return

	var created: bool = false
	var triggered: bool = false
	var expired: bool = false

	for raw_entry: Variant in entries:
		if not raw_entry is Dictionary:
			continue

		var state_name: StringName = StringName(
			(raw_entry as Dictionary).get(
				"state",
				""
			)
		)

		match state_name:
			&"created":
				created = true
			&"triggered":
				triggered = true
			&"expired":
				expired = true

	if triggered:
		lines.append(
			LocalizationService.tr_key("battle.outcome.temp_triggered", "A temporary effect triggered.")
		)
	elif created:
		lines.append(
			LocalizationService.tr_key("battle.outcome.temp_active", "A temporary effect is now active.")
		)

	if expired:
		lines.append(
			LocalizationService.tr_key("battle.outcome.temp_expired", "A temporary effect expired.")
		)


static func _deduplicate(
	lines: Array[String]
) -> Array[String]:
	var result: Array[String] = []

	for line: String in lines:
		if line.is_empty():
			continue
		if result.has(line):
			continue
		result.append(line)

	return result
