extends RefCounted


static func execute_actions(
    actions: Array,
    stage: StringName,
    actor: Variant,
    target: Variant,
    move_card: Variant,
    damage_context: Variant,
    battle_state: Variant,
    turn_result: Variant,
    logger_script: Script
) -> bool:
    for action: Variant in actions:
        if not _execute_action(
            action,
            stage,
            actor,
            target,
            move_card,
            damage_context,
            battle_state,
            turn_result,
            logger_script
        ):
            return false

    return true


static func _execute_action(
    action: Variant,
    stage: StringName,
    actor: Variant,
    target: Variant,
    move_card: Variant,
    damage_context: Variant,
    battle_state: Variant,
    turn_result: Variant,
    logger_script: Script
) -> bool:
    var opcode: StringName = StringName(
        action.opcode
    )
    var args: Dictionary = action.args

    match opcode:
        &"damage.create":
            damage_context.base_damage = int(
                args.get("amount", 0)
            )
            damage_context.attack_type = StringName(
                args.get(
                    "damage_type",
                    move_card.attack_type
                )
            )

            logger_script.add(
                battle_state,
                turn_result,
                "Base damage created: %d."
                % damage_context.base_damage
            )

        &"damage.add":
            var amount: int = int(
                args.get("amount", 0)
            )

            if stage == &"outcome":
                damage_context.outcome_bonus += amount
            else:
                damage_context.other_modifiers += amount

            logger_script.add(
                battle_state,
                turn_result,
                "Damage increased by %d."
                % amount
            )

        &"damage.set":
            damage_context.base_damage = int(
                args.get("amount", 0)
            )

        &"damage.deal":
            var direct_target: Variant = _resolve_target(
                StringName(args.get("target", "opponent")),
                actor,
                target
            )
            var direct_amount: int = int(
                args.get("amount", 0)
            )
            var direct_applied: int = (
                direct_target.apply_damage(
                    direct_amount
                )
            )

            logger_script.add(
                battle_state,
                turn_result,
                "%s took %d direct damage."
                % [
                    direct_target.display_name,
                    direct_applied
                ]
            )

        &"hp.restore":
            var heal_target: Variant = _resolve_target(
                StringName(args.get("target", "self")),
                actor,
                target
            )
            var restored: int = heal_target.heal(
                int(args.get("amount", 0))
            )

            logger_script.add(
                battle_state,
                turn_result,
                "%s restored %d HP."
                % [
                    heal_target.display_name,
                    restored
                ]
            )

        &"incoming_damage.modify":
            var modifier_target: Variant = _resolve_target(
                StringName(args.get("target", "self")),
                actor,
                target
            )
            modifier_target.next_incoming_damage_modifier += int(
                args.get("amount", 0)
            )

        &"energy_dice.modify":
            var energy_target: Variant = _resolve_target(
                StringName(args.get("target", "self")),
                actor,
                target
            )
            energy_target.next_turn_energy_dice_modifier += int(
                args.get("amount", 0)
            )

        &"move.repeat_permission":
            var repeat_target: Variant = _resolve_target(
                StringName(args.get("target", "self")),
                actor,
                target
            )
            repeat_target.repeat_permission_move_name_id = StringName(
                args.get(
                    "move_name_id",
                    move_card.move_name_id
                )
            )

        &"weakness.disable":
            var weakness_target: Variant = _resolve_target(
                StringName(args.get("target", "self")),
                actor,
                target
            )
            weakness_target.disable_weakness_for_next_move = true

        &"turn.end":
            return true

        _:
            push_warning(
                "Battle ActionEngine: unsupported opcode '%s'."
                % String(opcode)
            )

    return true


static func apply_defender_reduction(
    defender: Variant,
    damage_context: Variant
) -> void:
    var modifier: int = int(
        defender.next_incoming_damage_modifier
    )

    if modifier < 0:
        damage_context.defender_reduction = abs(
            modifier
        )
    elif modifier > 0:
        damage_context.other_modifiers += modifier

    defender.next_incoming_damage_modifier = 0


static func _resolve_target(
    target_id: StringName,
    actor: Variant,
    opponent: Variant
) -> Variant:
    if target_id == &"self":
        return actor

    return opponent
