extends RefCounted


const BATTLE_STATE_DATA: Script = preload(
    "res://scripts/battle/data/BattleStateData.gd"
)
const PARTICIPANT_DATA: Script = preload(
    "res://scripts/battle/data/BattleParticipantData.gd"
)
const TURN_RESULT_DATA: Script = preload(
    "res://scripts/battle/data/BattleTurnResultData.gd"
)
const TURN_HISTORY_RECORD: Script = preload(
    "res://scripts/battle/history/BattleTurnHistoryRecord.gd"
)
const DAMAGE_CONTEXT_DATA: Script = preload(
    "res://scripts/battle/data/DamageContextData.gd"
)
const COMMAND_QUEUE_DATA: Script = preload(
    "res://scripts/battle/commands/CommandQueueData.gd"
)
const COMMAND_FACTORY: Script = preload(
    "res://scripts/battle/commands/BattleCommandFactory.gd"
)
const COMMAND_EXECUTOR: Script = preload(
    "res://scripts/battle/commands/BattleCommandExecutor.gd"
)
const EVENT_BUS: Script = preload(
    "res://scripts/battle/events/BattleEventBus.gd"
)
const ENERGY_RESOLVER: Script = preload(
    "res://scripts/battle/EnergyResolver.gd"
)
const WEAKNESS_RESOLVER: Script = preload(
    "res://scripts/battle/WeaknessResolver.gd"
)
const OUTCOME_RESOLVER: Script = preload(
    "res://scripts/battle/OutcomeResolver.gd"
)
const STATUS_RESOLVER: Script = preload(
    "res://scripts/battle/status/StatusResolver.gd"
)
const OPCODE_COMPILER: Script = preload(
    "res://scripts/battle/opcode/OpcodeCompiler.gd"
)
const DEFAULT_REGISTRY_FACTORY: Script = preload(
    "res://scripts/battle/opcode/DefaultOpcodeRegistryFactory.gd"
)
const BATTLE_LOGGER: Script = preload(
    "res://scripts/battle/BattleLogger.gd"
)
const RULE_PIPELINE: Script = preload(
    "res://scripts/battle/rules/BattleRulePipeline.gd"
)
const SPECIAL_KYOKORO_SEQUENCE: Script = preload(
    "res://scripts/battle/special/SpecialKyokoroSequenceService.gd"
)
const SPECIAL_MOVE_SELECTION: Script = preload(
    "res://scripts/battle/special/SpecialMoveSelectionService.gd"
)
const SPECIAL_OPPONENT_ENERKORO: Script = preload(
    "res://scripts/battle/special/SpecialOpponentEnerkoroService.gd"
)
const PREVIOUS_MOVE_EFFECT: Script = preload(
    "res://scripts/battle/effects/PreviousMoveConditionalEffectService.gd"
)
const EFFECT_LIFECYCLE: Script = preload(
    "res://scripts/battle/effects/BattleEffectLifecycleCoordinator.gd"
)
const RESOLUTION_EVENT_BUILDER: Script = preload(
    "res://scripts/presentation/BattleResolutionEventBuilder.gd"
)


var database: Node
var state: Variant = null
var event_bus: Variant = EVENT_BUS.new()

var opcode_registry: Variant = null
var opcode_compiler: Variant = null


func _init(database_service: Node) -> void:
	database = database_service
	opcode_registry = (
		DEFAULT_REGISTRY_FACTORY.create()
	)

	if opcode_registry != null:
		opcode_compiler = OPCODE_COMPILER.new(
			opcode_registry
		)


func start_battle(
	player_loadout: Variant,
	enemy_loadout: Variant
) -> Variant:
	state = BATTLE_STATE_DATA.new()
	event_bus.clear()

	state.player = PARTICIPANT_DATA.new()
	state.player.initialize(
		&"player",
		"Player",
		player_loadout
	)

	state.enemy = PARTICIPANT_DATA.new()
	state.enemy.initialize(
		&"enemy",
		"Enemy",
		enemy_loadout
	)

	state.current_participant_id = &"player"
	state.turn_number = 1
	state.battle_log.append("Battle started.")

	event_bus.emit_event(
		&"battle_started",
		1,
		&"",
		&""
	)

	return state


func execute_turn(
	move_card_id: StringName,
	dice_result: Variant
) -> Variant:
	var result: Variant = TURN_RESULT_DATA.new()

	if opcode_compiler == null:
		return _fail(
			result,
            "Opcode compiler is not initialized."
		)

	if state == null:
		return _fail(
			result,
            "Battle has not started."
		)

	if state.is_finished:
		return _fail(
			result,
            "Battle is already finished."
		)

	var original_turn_number: int = state.turn_number
	var actor: Variant = state.get_current_participant()
	var target: Variant = state.get_opponent_participant()

	result.actor_participant_id = actor.id
	result.target_participant_id = target.id
	result.move_card_id = move_card_id
	result.kyokoro_orientation = (
		dice_result.kyokoro_orientation
	)

	if not actor.loadout.has_move_card(move_card_id):
		return _fail(
			result,
            "Selected move is not in the actor's loadout."
		)

	var move_card: Variant = database.get_move_card(
		move_card_id
	)

	if move_card == null:
		return _fail(
			result,
            "Move card does not exist."
		)

	if not actor.can_use_move(
		StringName(move_card.move_name_id)
	):
		return _fail(
			result,
            "The same move cannot be used on consecutive turns."
		)

	var rule_pipeline: Variant = RULE_PIPELINE.new()

	if not rule_pipeline.initialize(move_card):
		return _fail(
			result,
            "Rule pipeline initialization failed."
		)

	var damage_context: Variant = (
		DAMAGE_CONTEXT_DATA.new()
	)
	damage_context.source_participant_id = actor.id
	damage_context.target_participant_id = target.id
	damage_context.move_card_id = move_card_id
	damage_context.attack_type = StringName(
		move_card.attack_type
	)
	result.damage_context = damage_context

	var command_queue: Variant = COMMAND_QUEUE_DATA.new()

	if not _execute_trigger(
		rule_pipeline,
		&"start_turn",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "start_turn trigger failed."
		)

	BATTLE_LOGGER.add(
		state,
		result,
        "Turn %d: %s used %s."
		% [
			original_turn_number,
			actor.display_name,
			move_card.display_name
		]
	)

	if not _execute_trigger(
		rule_pipeline,
		&"on_move",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "on_move trigger failed."
		)

	result.energy_sufficient = (
		ENERGY_RESOLVER.can_pay_cost(
			move_card,
			dice_result
		)
	)

	if not result.energy_sufficient:
		BATTLE_LOGGER.add(
			state,
			result,
            "Energy check failed."
		)

		actor.mark_move_used(
			StringName(move_card.move_name_id)
		)

		_execute_trigger(
			rule_pipeline,
			&"end_turn",
			actor,
			target,
			dice_result,
			damage_context,
			result,
			command_queue
		)

		_execute_commands(
			command_queue,
			result
		)

		_record_turn_history(
			original_turn_number,
			actor,
			target,
			move_card,
			result,
			dice_result
		)

		var previous_effect_report: Dictionary = (
			PREVIOUS_MOVE_EFFECT.rotate_after_move(
				actor,
				move_card,
				false,
				original_turn_number
			)
		)

		_record_previous_move_effect_lifecycle(
			result,
			previous_effect_report
		)

		var duration_report: Dictionary = (
			EFFECT_LIFECYCLE.tick_owner_turn_duration(
				actor,
				original_turn_number
			)
		)

		_record_effect_expiration_lifecycle(
			result,
			duration_report
		)

		_finish_or_switch_turn(result)
		result.success = true
		result.events_generated = event_bus.events.size()
		return result

	BATTLE_LOGGER.add(
		state,
		result,
        "Energy check passed."
	)

	if not _execute_trigger(
		rule_pipeline,
		&"before_attack",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "before_attack trigger failed."
		)

	if not opcode_compiler.compile_actions(
		move_card.base_actions,
		&"base",
		actor,
		target,
		move_card,
		damage_context,
		dice_result,
		command_queue,
		state,
		result,
		BATTLE_LOGGER
	):
		return _fail(
			result,
            "Base action compilation failed."
		)

	var weakness_report: Dictionary = {}

	if bool(
		damage_context.ignore_weakness
	):
		weakness_report = {
			"bonus": 0,
			"weakness_disabled": false,
			"status_report": {}
		}
	else:
		weakness_report = (
			WEAKNESS_RESOLVER.get_weakness_bonus_report(
				actor,
				target,
				move_card
			)
		)

	damage_context.weakness_bonus = int(
		weakness_report.get(
			"bonus",
			0
		)
	)

	if bool(
		weakness_report.get(
			"weakness_disabled",
			false
		)
	):
		var weakness_lifecycle_message: String = (
			actor.display_name
			+ " consumed weakness_disable."
		)
		BATTLE_LOGGER.add(
			state,
			result,
			weakness_lifecycle_message
		)
		result.add_status_lifecycle_entry(
			weakness_lifecycle_message
		)

	if damage_context.weakness_bonus > 0:
		BATTLE_LOGGER.add(
			state,
			result,
            "Weakness added %d damage."
			% damage_context.weakness_bonus
		)

	var outcome: Variant = (
		OUTCOME_RESOLVER.get_matching_outcome(
			move_card,
			dice_result.kyokoro_orientation
		)
	)

	if outcome != null:
		result.outcome_triggered = true

		BATTLE_LOGGER.add(
			state,
			result,
            "Outcome triggered for %s."
			% String(dice_result.kyokoro_orientation)
		)

		if not opcode_compiler.compile_actions(
			outcome.actions,
			&"outcome",
			actor,
			target,
			move_card,
			damage_context,
			dice_result,
			command_queue,
			state,
			result,
			BATTLE_LOGGER
		):
			return _fail(
				result,
                "Outcome action compilation failed."
			)

	result.additional_kyokoro_orientations = (
		dice_result.additional_kyokoro_orientations
		.duplicate()
	)
	result.opponent_kyokoro_orientation = StringName(
		dice_result.opponent_kyokoro_orientation
	)

	var opponent_roll_batch: Dictionary = (
		SPECIAL_KYOKORO_SEQUENCE
		.get_opponent_roll_action_batch(
			move_card,
			dice_result
		)
	)

	if (
		opponent_roll_batch.is_empty()
		and SPECIAL_KYOKORO_SEQUENCE.has_opponent_roll_effect(
			move_card
		)
	):
		var opponent_trigger_faces: Array[StringName] = (
			SPECIAL_KYOKORO_SEQUENCE
			.get_opponent_roll_trigger_orientations(
				move_card
			)
		)

		BATTLE_LOGGER.add(
			state,
			result,
            "Opponent Charakoro was not triggered: "
			+ "attacker rolled %s; trigger faces are %s."
			% [
				String(
					dice_result.kyokoro_orientation
				),
				str(
					opponent_trigger_faces
				)
			]
		)

	if not opponent_roll_batch.is_empty():
		result.opponent_kyokoro_success = bool(
			opponent_roll_batch.get(
				"success",
				false
			)
		)

		BATTLE_LOGGER.add(
			state,
			result,
            "Opponent Charakoro rolled %s: %s."
			% [
				String(
					opponent_roll_batch.get(
						"orientation",
                        ""
					)
				),
				(
                    "effect triggered"
					if result.opponent_kyokoro_success
					else "effect failed"
				)
			]
		)

		if result.opponent_kyokoro_success:
			if not opcode_compiler.compile_actions(
				opponent_roll_batch.get(
					"actions",
					[]
				),
				&"opponent_kyokoro",
				actor,
				target,
				move_card,
				damage_context,
				dice_result,
				command_queue,
				state,
				result,
				BATTLE_LOGGER
			):
				return _fail(
					result,
                    "Opponent Charakoro action compilation failed."
				)

	var extra_batches: Array = (
		SPECIAL_KYOKORO_SEQUENCE
		.get_extra_success_action_batches(
			move_card,
			dice_result
		)
	)

	for raw_batch: Variant in extra_batches:
		if not raw_batch is Dictionary:
			continue

		var batch: Dictionary = (
			raw_batch as Dictionary
		)
		var extra_orientation: StringName = (
			StringName(
				batch.get(
					"orientation",
                    ""
				)
			)
		)

		BATTLE_LOGGER.add(
			state,
			result,
            "Special Charakoro succeeded for %s."
			% String(
				extra_orientation
			)
		)

		if not opcode_compiler.compile_actions(
			batch.get(
				"actions",
				[]
			),
			&"special_kyokoro",
			actor,
			target,
			move_card,
			damage_context,
			dice_result,
			command_queue,
			state,
			result,
			BATTLE_LOGGER
		):
			return _fail(
				result,
                "Special Charakoro action compilation failed."
			)

		result.special_kyokoro_success_count += 1

	var opponent_enerkoro_batch: Dictionary = (
		SPECIAL_OPPONENT_ENERKORO
		.get_damage_action_batch(
			move_card,
			dice_result
		)
	)

	if not opponent_enerkoro_batch.is_empty():
		BATTLE_LOGGER.add(
			state,
			result,
            "Opponent Enerkoro top count: %d; tied top types: %s; "
			+ "counted Energy: %d. Psychic adds %d damage."
			% [
				int(
					opponent_enerkoro_batch.get(
						"max_count",
						0
					)
				),
				str(
					opponent_enerkoro_batch.get(
						"most_common_types",
						[]
					)
				),
				int(
					opponent_enerkoro_batch.get(
						"bonus_energy_count",
						0
					)
				),
				int(
					opponent_enerkoro_batch.get(
						"damage_bonus",
						0
					)
				)
			]
		)

		if not opcode_compiler.compile_actions(
			opponent_enerkoro_batch.get(
				"actions",
				[]
			),
			&"outcome",
			actor,
			target,
			move_card,
			damage_context,
			dice_result,
			command_queue,
			state,
			result,
			BATTLE_LOGGER
		):
			return _fail(
				result,
                "Opponent Enerkoro damage compilation failed."
			)

	var selected_lock_move_name_id: StringName = (
		SPECIAL_MOVE_SELECTION.get_selected_target(
			move_card,
			dice_result
		)
	)

	if selected_lock_move_name_id != &"":
		command_queue.enqueue(
			COMMAND_FACTORY.create_move_lock_command(
				actor.id,
				target.id,
				selected_lock_move_name_id,
				1
			)
		)

		BATTLE_LOGGER.add(
			state,
			result,
            "%s selected opponent Move '%s' to lock next turn."
			% [
				actor.display_name,
				String(
					selected_lock_move_name_id
				)
			]
		)

	if not _execute_trigger(
		rule_pipeline,
		&"before_damage",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "before_damage trigger failed."
		)

	_apply_defender_statuses(
		target,
		damage_context,
		result
	)

	var final_damage: int = (
		damage_context.calculate_final_damage()
	)

	result.resolution_events = (
		RESOLUTION_EVENT_BUILDER.build_damage_events(
			damage_context,
			result.resolution_damage_atoms
		)
	)

	if final_damage > 0:
		command_queue.enqueue(
			COMMAND_FACTORY.create_damage_command(
				actor.id,
				target.id,
				final_damage,
				damage_context.attack_type,
				&"attack"
			)
		)

	result.commands_generated = command_queue.size()

	if not _execute_commands(
		command_queue,
		result
	):
		return _fail(
			result,
            "Command execution failed."
		)

	if not _execute_trigger(
		rule_pipeline,
		&"after_damage",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "after_damage trigger failed."
		)

	if not _execute_commands(
		command_queue,
		result
	):
		return _fail(
			result,
            "after_damage command execution failed."
		)

	_check_knockout(result, actor)

	if (
		not state.is_finished
		and SPECIAL_KYOKORO_SEQUENCE
		.is_repeat_same_move_chain(
			move_card,
			dice_result
		)
	):
		if not _execute_repeat_same_move_chain(
			actor,
			target,
			move_card,
			dice_result,
			result
		):
			return _fail(
				result,
                "Repeat same Move chain failed."
			)

	if state.is_finished:
		if not _execute_trigger(
			rule_pipeline,
			&"after_ko",
			actor,
			target,
			dice_result,
			damage_context,
			result,
			command_queue
		):
			return _fail(
				result,
                "after_ko trigger failed."
			)

		_execute_commands(
			command_queue,
			result
		)
	else:
		if not _execute_trigger(
			rule_pipeline,
			&"after_attack",
			actor,
			target,
			dice_result,
			damage_context,
			result,
			command_queue
		):
			return _fail(
				result,
                "after_attack trigger failed."
			)

		_execute_commands(
			command_queue,
			result
		)

	actor.mark_move_used(
		StringName(move_card.move_name_id)
	)

	result.move_executed = true
	result.success = true

	if not _execute_trigger(
		rule_pipeline,
		&"end_turn",
		actor,
		target,
		dice_result,
		damage_context,
		result,
		command_queue
	):
		return _fail(
			result,
            "end_turn trigger failed."
		)

	_execute_commands(
		command_queue,
		result
	)

	_record_turn_history(
		original_turn_number,
		actor,
		target,
		move_card,
		result,
		dice_result
	)

	var previous_effect_report: Dictionary = (
		PREVIOUS_MOVE_EFFECT.rotate_after_move(
			actor,
			move_card,
			bool(result.outcome_triggered),
			original_turn_number
		)
	)

	_record_previous_move_effect_lifecycle(
		result,
		previous_effect_report
	)

	var duration_report: Dictionary = (
		EFFECT_LIFECYCLE.tick_owner_turn_duration(
			actor,
			original_turn_number
		)
	)

	_record_effect_expiration_lifecycle(
		result,
		duration_report
	)

	_finish_or_switch_turn(result)
	result.events_generated = event_bus.events.size()

	return result


func _record_previous_move_effect_lifecycle(
	result: Variant,
	report: Dictionary
) -> void:
	if (
		result == null
		or not result.has_method(
            "add_effect_lifecycle_entry"
		)
	):
		return

	for raw_id: Variant in report.get(
		"consumed_ids",
		[]
	):
		result.add_effect_lifecycle_entry(
			&"consumed",
			PREVIOUS_MOVE_EFFECT.EFFECT_TYPE,
			StringName(raw_id),
            "Previous Move effect window consumed."
		)

	if bool(
		report.get(
			"created",
			false
		)
	):
		var effect_id: StringName = StringName(
			report.get(
				"created_id",
                ""
			)
		)
		var effect_type: StringName = StringName(
			report.get(
				"created_effect_type",
				PREVIOUS_MOVE_EFFECT.EFFECT_TYPE
			)
		)
		var display_text: String = String(
			report.get(
				"created_display_text",
                "Temporary battle effect created."
			)
		)

		result.add_effect_lifecycle_entry(
			&"created",
			effect_type,
			effect_id,
			display_text
		)
		result.add_effect_lifecycle_entry(
			&"active",
			effect_type,
			effect_id,
            "Effect is pending for the next owner Move."
		)


func _record_effect_expiration_lifecycle(
	result: Variant,
	report: Dictionary
) -> void:
	if (
		result == null
		or not result.has_method(
            "add_effect_lifecycle_entry"
		)
	):
		return

	for raw_id: Variant in report.get(
		"expired_ids",
		[]
	):
		result.add_effect_lifecycle_entry(
			&"expired",
			&"temporary_effect",
			StringName(raw_id),
            "Temporary battle effect expired."
		)


func _execute_repeat_same_move_chain(
	actor: Variant,
	target: Variant,
	move_card: Variant,
	original_dice_result: Variant,
	result: Variant
) -> bool:
	var orientations: Array[StringName] = (
		SPECIAL_KYOKORO_SEQUENCE
		.get_repeat_same_move_orientations(
			move_card,
			original_dice_result
		)
	)

	for orientation: StringName in orientations:
		if state.is_finished:
			break

		var repeat_dice_result: Variant = (
			original_dice_result.duplicate()
			if original_dice_result.has_method(
                "duplicate"
			)
			else original_dice_result
		)

		# DiceRollResultData is a RefCounted rather than Resource, so build a
		# small compatible object by reusing the original energy counts and
		# swapping only the Charakoro result for this repeated Move.
		if repeat_dice_result == original_dice_result:
			repeat_dice_result = (
				load(
                    "res://scripts/battle/data/DiceRollResultData.gd"
				).new()
			)
			repeat_dice_result.energy_counts = (
				original_dice_result.energy_counts.duplicate(
					true
				)
			)

		repeat_dice_result.kyokoro_orientation = (
			orientation
		)

		var repeat_damage_context: Variant = (
			DAMAGE_CONTEXT_DATA.new()
		)
		repeat_damage_context.source_participant_id = (
			actor.id
		)
		repeat_damage_context.target_participant_id = (
			target.id
		)
		repeat_damage_context.move_card_id = (
			move_card.id
		)
		repeat_damage_context.attack_type = StringName(
			move_card.attack_type
		)

		var repeat_queue: Variant = (
			COMMAND_QUEUE_DATA.new()
		)

		if not opcode_compiler.compile_actions(
			move_card.base_actions,
			&"repeat_same_move_base",
			actor,
			target,
			move_card,
			repeat_damage_context,
			repeat_dice_result,
			repeat_queue,
			state,
			result,
			BATTLE_LOGGER
		):
			return false

		var weakness_report: Dictionary = {}

		if bool(
			repeat_damage_context.ignore_weakness
		):
			weakness_report = {
				"bonus": 0,
				"weakness_disabled": false,
				"status_report": {}
			}
		else:
			weakness_report = (
				WEAKNESS_RESOLVER
				.get_weakness_bonus_report(
					actor,
					target,
					move_card
				)
			)

		repeat_damage_context.weakness_bonus = int(
			weakness_report.get(
				"bonus",
				0
			)
		)

		var repeat_outcome: Variant = (
			OUTCOME_RESOLVER.get_matching_outcome(
				move_card,
				orientation
			)
		)

		if repeat_outcome != null:
			if not opcode_compiler.compile_actions(
				repeat_outcome.actions,
				&"repeat_same_move_outcome",
				actor,
				target,
				move_card,
				repeat_damage_context,
				repeat_dice_result,
				repeat_queue,
				state,
				result,
				BATTLE_LOGGER
			):
				return false

		_apply_defender_statuses(
			target,
			repeat_damage_context,
			result
		)

		var repeat_damage: int = (
			repeat_damage_context
			.calculate_final_damage()
		)

		if repeat_damage > 0:
			repeat_queue.enqueue(
				COMMAND_FACTORY.create_damage_command(
					actor.id,
					target.id,
					repeat_damage,
					repeat_damage_context.attack_type,
					&"repeat_same_move"
				)
			)

		BATTLE_LOGGER.add(
			state,
			result,
            "%s repeated %s. Charakoro: %s."
			% [
				actor.display_name,
				move_card.display_name,
				String(orientation)
			]
		)

		if not _execute_commands(
			repeat_queue,
			result
		):
			return false

		result.repeated_move_count += 1
		_check_knockout(result, actor)

	return true


func _record_turn_history(
	original_turn_number: int,
	actor: Variant,
	target: Variant,
	move_card: Variant,
	result: Variant,
	dice_result: Variant
) -> void:
	if (
		state == null
		or actor == null
		or move_card == null
	):
		return

	var record: Variant = (
		TURN_HISTORY_RECORD.new()
	)

	record.turn_number = original_turn_number
	record.actor_participant_id = StringName(
		actor.id
	)
	record.target_participant_id = (
		StringName(
			target.id
		)
		if target != null
		else &""
	)
	record.move_card_id = StringName(
		move_card.id
	)
	record.move_name_id = StringName(
		move_card.move_name_id
	)
	record.had_printed_damage = (
		move_card.printed_damage != null
	)
	record.printed_damage = (
		int(
			move_card.printed_damage
		)
		if move_card.printed_damage != null
		else 0
	)
	record.energy_sufficient = bool(
		result.energy_sufficient
	)
	record.move_executed = bool(
		result.move_executed
	)
	record.outcome_triggered = bool(
		result.outcome_triggered
	)
	record.kyokoro_orientation = (
		StringName(
			dice_result.kyokoro_orientation
		)
		if dice_result != null
		else &""
	)
	record.applied_damage = int(
		result.applied_damage
	)

	state.add_turn_history(
		record
	)


func get_registered_opcodes() -> Array[StringName]:
	if opcode_registry == null:
		return []

	return opcode_registry.get_registered_opcodes()


func _execute_trigger(
	pipeline: Variant,
	trigger_id: StringName,
	actor: Variant,
	target: Variant,
	dice_result: Variant,
	damage_context: Variant,
	result: Variant,
	command_queue: Variant
) -> bool:
	return pipeline.execute(
		trigger_id,
		actor,
		target,
		dice_result,
		damage_context,
		state,
		result,
		command_queue,
		opcode_registry,
		BATTLE_LOGGER
	)


func _execute_commands(
	command_queue: Variant,
	result: Variant
) -> bool:
	if command_queue.is_empty():
		return true

	return COMMAND_EXECUTOR.execute_queue(
		command_queue,
		state,
		result,
		event_bus,
		BATTLE_LOGGER
	)


func _apply_defender_statuses(
	defender: Variant,
	damage_context: Variant,
	result: Variant
) -> void:
	if STATUS_RESOLVER.has_attack_damage_immunity(
		defender
	):
		damage_context.damage_multiplier = 0.0

		var immunity_message: String = (
			defender.display_name
			+ " is immune to attack damage for this resolution."
		)
		BATTLE_LOGGER.add(
			state,
			result,
			immunity_message
		)
		result.add_status_lifecycle_entry(
			immunity_message
		)

	var report: Dictionary = (
		STATUS_RESOLVER
		.consume_incoming_damage_modifier_report(
			defender
		)
	)
	var modifier: int = int(
		report.get(
			"value",
			0
		)
	)

	if bool(
		report.get(
			"consumed",
			false
		)
	):
		var lifecycle_message: String = (
			defender.display_name
			+ " consumed incoming_damage_modifier "
			+ str(modifier)
			+ "."
		)

		BATTLE_LOGGER.add(
			state,
			result,
			lifecycle_message
		)
		result.add_status_lifecycle_entry(
			lifecycle_message
		)

	if modifier < 0:
		damage_context.defender_reduction = abs(
			modifier
		)
	elif modifier > 0:
		damage_context.other_modifiers += modifier


func _check_knockout(
	result: Variant,
	acting_participant: Variant
) -> void:
	var player_knocked_out: bool = (
		state.player.is_knocked_out()
	)
	var enemy_knocked_out: bool = (
		state.enemy.is_knocked_out()
	)

	if (
		player_knocked_out
		and enemy_knocked_out
	):
		# Plakoro rule: if an attack's own Charakoro/recoil effect causes both
		# Pokémon to reach 0 HP during that Move, the side using the Move loses.
		var acting_id: StringName = (
			StringName(
				acting_participant.id
			)
			if acting_participant != null
			else state.current_participant_id
		)

		state.is_finished = true
		state.winner_participant_id = (
			&"enemy"
			if acting_id == &"player"
			else &"player"
		)

		BATTLE_LOGGER.add(
			state,
			result,
            "Both Pokémon were knocked out. "
			+ "The acting side loses the simultaneous-KO tie."
		)
	elif player_knocked_out:
		state.is_finished = true
		state.winner_participant_id = &"enemy"
	elif enemy_knocked_out:
		state.is_finished = true
		state.winner_participant_id = &"player"

	result.battle_finished = state.is_finished


func _finish_or_switch_turn(
	result: Variant
) -> void:
	if state.is_finished:
		return

	var completed_participant: Variant = (
		state.get_current_participant()
	)
	var completed_turn_number: int = int(
		state.turn_number
	)

	_tick_owner_turn_statuses(
		completed_participant,
		completed_turn_number,
		result
	)

	state.switch_turn()

	BATTLE_LOGGER.add(
		state,
		result,
        "Next turn: %s."
		% String(state.current_participant_id)
	)


func _tick_owner_turn_statuses(
	participant: Variant,
	completed_turn_number: int,
	result: Variant
) -> void:
	if (
		participant == null
		or participant.status_container == null
	):
		return

	var report: Dictionary = (
		participant.status_container.tick_owner_turn(
			completed_turn_number
		)
	)

	for raw_status_id: Variant in report.get(
		"ticked_ids",
		[]
	):
		var status_id: String = String(
			raw_status_id
		)
		var remaining_turns: int = int(
			(
				report.get(
					"remaining_turns",
					{}
				)
				as Dictionary
			).get(
				status_id,
				0
			)
		)

		var tick_message: String = (
			participant.display_name
			+ " status "
			+ status_id
			+ " duration ticked to "
			+ str(
				remaining_turns
			)
			+ "."
		)

		BATTLE_LOGGER.add(
			state,
			result,
			tick_message
		)
		result.add_status_lifecycle_entry(
			tick_message
		)

	for raw_status_id: Variant in report.get(
		"expired_ids",
		[]
	):
		var expire_message: String = (
			participant.display_name
			+ " status "
			+ String(
				raw_status_id
			)
			+ " expired."
		)

		BATTLE_LOGGER.add(
			state,
			result,
			expire_message
		)
		result.add_status_lifecycle_entry(
			expire_message
		)


func _fail(
	result: Variant,
	message: String
) -> Variant:
	result.success = false
	result.error_message = message
	push_error(
        "BattleController: %s"
		% message
	)
	return result
