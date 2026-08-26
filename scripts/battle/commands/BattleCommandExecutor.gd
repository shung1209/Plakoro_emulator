extends RefCounted


static func execute_queue(
    command_queue: Variant,
    battle_state: Variant,
    turn_result: Variant,
    event_bus: Variant,
    logger_script: Script
) -> bool:
    while not command_queue.is_empty():
        var command: Variant = command_queue.dequeue()

        if not execute_command(
            command,
            battle_state,
            turn_result,
            event_bus,
            logger_script
        ):
            return false

    return true


static func execute_command(
    command: Variant,
    battle_state: Variant,
    turn_result: Variant,
    event_bus: Variant,
    logger_script: Script
) -> bool:
    if command == null:
        return false

    var source: Variant = _get_participant(
        battle_state,
        StringName(command.source_participant_id)
    )
    var target: Variant = _get_participant(
        battle_state,
        StringName(command.target_participant_id)
    )
    var payload: Dictionary = command.payload
    var command_type: StringName = StringName(
        command.command_type
    )

    match command_type:
        &"damage.apply":
            if target == null:
                return false

            var requested_amount: int = max(
                int(payload.get("amount", 0)),
                0
            )
            var applied_amount: int = target.apply_damage(
                requested_amount
            )

            var is_self_damage: bool = (
                StringName(command.source_participant_id)
                == StringName(command.target_participant_id)
            )
            # applied_damage represents damage dealt to an opposing target.
            # Recoil/self-damage is tracked separately below and must not be
            # added to attack feedback, timeline, history, or replay totals.
            if not is_self_damage:
                turn_result.applied_damage += applied_amount

            if (
                applied_amount > 0
                and is_self_damage
                and turn_result.has_method(
                    "add_resolution_self_damage_event"
                )
            ):
                turn_result.add_resolution_self_damage_event(
                    applied_amount,
                    StringName(
                        payload.get(
                            "reason",
                            "self_damage"
                        )
                    )
                )

            event_bus.emit_event(
                &"damage_applied",
                battle_state.turn_number,
                command.source_participant_id,
                command.target_participant_id,
                {
                    "requested_amount": requested_amount,
                    "applied_amount": applied_amount,
                    "remaining_hp": target.current_hp
                }
            )

            logger_script.add(
                battle_state,
                turn_result,
                "%s took %d damage. HP: %d/%d."
                % [
                    target.display_name,
                    applied_amount,
                    target.current_hp,
                    target.max_hp
                ]
            )

        &"hp.restore":
            if target == null:
                return false

            var restored: int = target.heal(
                int(payload.get("amount", 0))
            )

            event_bus.emit_event(
                &"hp_restored",
                battle_state.turn_number,
                command.source_participant_id,
                command.target_participant_id,
                {
                    "amount": restored,
                    "remaining_hp": target.current_hp
                }
            )

        &"status.add":
            if target == null:
                return false

            var status_payload: Dictionary = (
                payload.duplicate(
                    true
                )
            )
            status_payload[
                "created_turn_number"
            ] = int(
                battle_state.turn_number
            )

            var status: Variant = (
                target.status_container
                .add_status_from_payload(
                    command.source_participant_id,
                    status_payload
                )
            )

            if status == null:
                return false

            event_bus.emit_event(
                &"status_added",
                battle_state.turn_number,
                command.source_participant_id,
                command.target_participant_id,
                {
                    "status_id": status.id,
                    "status_type": status.status_type,
                    "value": status.value,
                    "remaining_uses": status.remaining_uses,
                    "duration_turns": status.duration_turns,
                    "duration_based": status.duration_based,
                    "duration_scope": status.duration_scope
                }
            )

            var duration_text: String = (
                (
                    ", turns="
                    + str(
                        int(
                            status.duration_turns
                        )
                    )
                    + " "
                    + String(
                        status.duration_scope
                    )
                )
                if bool(
                    status.duration_based
                )
                else ""
            )

            var lifecycle_message: String = (
                "%s gained status %s (%d) [%s, uses=%d%s]."
                % [
                    target.display_name,
                    String(status.status_type),
                    int(status.value),
                    String(status.timing),
                    int(status.remaining_uses),
                    duration_text
                ]
            )

            logger_script.add(
                battle_state,
                turn_result,
                lifecycle_message
            )

            if turn_result.has_method(
                "add_status_lifecycle_entry"
            ):
                turn_result.add_status_lifecycle_entry(
                    lifecycle_message
                )

        _:
            push_error(
                "BattleCommandExecutor: unsupported command '%s'."
                % String(command_type)
            )
            return false

    return true


static func _get_participant(
    battle_state: Variant,
    participant_id: StringName
) -> Variant:
    if participant_id == &"player":
        return battle_state.player

    if participant_id == &"enemy":
        return battle_state.enemy

    return null
