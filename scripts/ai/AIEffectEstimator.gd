extends RefCounted


static func estimate_damage(
    move_card: Variant,
    orientation: StringName,
    weakness_bonus: int
) -> int:
    var damage: int = 0
    var created: bool = false

    for action: Variant in move_card.base_actions:
        var opcode: StringName = StringName(
            action.opcode
        )

        match opcode:
            &"damage.create":
                damage = int(
                    action.args.get("amount", 0)
                )
                created = true

            &"damage.set":
                damage = int(
                    action.args.get("amount", 0)
                )
                created = true

            &"damage.add":
                damage += int(
                    action.args.get("amount", 0)
                )

    var outcome: Variant = (
        move_card.get_outcome_for_orientation(
            orientation
        )
    )

    if outcome != null:
        for action: Variant in outcome.actions:
            var opcode: StringName = StringName(
                action.opcode
            )

            if opcode == &"damage.add":
                damage += int(
                    action.args.get("amount", 0)
                )
            elif opcode == &"damage.set":
                damage = int(
                    action.args.get("amount", 0)
                )
                created = true

    if created and damage > 0:
        damage += weakness_bonus

    return max(damage, 0)


static func estimate_self_heal(
    move_card: Variant,
    orientation: StringName
) -> int:
    var total: int = 0

    total += _sum_heal_actions(
        move_card.base_actions
    )

    var outcome: Variant = (
        move_card.get_outcome_for_orientation(
            orientation
        )
    )

    if outcome != null:
        total += _sum_heal_actions(
            outcome.actions
        )

    return total


static func estimate_status_utility(
    move_card: Variant,
    orientation: StringName
) -> float:
    var utility: float = 0.0

    utility += _sum_status_utility(
        move_card.base_actions
    )

    var outcome: Variant = (
        move_card.get_outcome_for_orientation(
            orientation
        )
    )

    if outcome != null:
        utility += _sum_status_utility(
            outcome.actions
        )

    return utility


static func _sum_heal_actions(
    actions: Array
) -> int:
    var total: int = 0

    for action: Variant in actions:
        if StringName(action.opcode) != &"hp.restore":
            continue

        if StringName(
            action.args.get("target", "self")
        ) != &"self":
            continue

        total += int(
            action.args.get("amount", 0)
        )

    return total


static func _sum_status_utility(
    actions: Array
) -> float:
    var utility: float = 0.0

    for action: Variant in actions:
        var opcode: StringName = StringName(
            action.opcode
        )
        var args: Dictionary = action.args
        var target: StringName = StringName(
            args.get("target", "self")
        )
        var amount: int = int(
            args.get("amount", 0)
        )

        match opcode:
            &"incoming_damage.modify":
                if target == &"self" and amount < 0:
                    utility += float(abs(amount)) * 0.65
                elif target == &"opponent" and amount > 0:
                    utility += float(amount) * 0.65

            &"energy_dice.modify":
                if target == &"self" and amount > 0:
                    utility += float(amount) * 8.0
                elif target == &"opponent" and amount < 0:
                    utility += float(abs(amount)) * 8.0

            &"move.repeat_permission":
                utility += 8.0

            &"weakness.disable":
                utility += 5.0

            &"status.add":
                utility += _estimate_generic_status(
                    args
                )

    return utility


static func _estimate_generic_status(
    args: Dictionary
) -> float:
    var status_type: StringName = StringName(
        args.get("status_type", "")
    )
    var value: int = int(
        args.get("value", 0)
    )

    match status_type:
        &"incoming_damage_modifier":
            return float(abs(value)) * 0.65

        &"energy_dice_modifier":
            return float(abs(value)) * 8.0

        &"repeat_move_permission":
            return 8.0

        &"weakness_disable":
            return 5.0

        _:
            return 2.0
