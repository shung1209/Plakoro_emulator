extends RefCounted

static func build_damage_events(
    damage_context: Variant,
    damage_atoms: Array = []
) -> Array[Dictionary]:
    var events: Array[Dictionary] = []

    if damage_context == null:
        return events

    var base_damage: int = max(
        int(damage_context.base_damage),
        0
    )
    var aggregate_effect_damage: int = max(
        int(damage_context.outcome_bonus)
        + int(damage_context.other_modifiers),
        0
    )
    var weakness_damage: int = max(
        int(damage_context.weakness_bonus),
        0
    )
    var defense_reduction: int = max(
        int(damage_context.defender_reduction),
        0
    )

    if base_damage > 0:
        events.append(
            {
                "kind": &"move_damage",
                "label": "Move Damage",
                "amount": base_damage
            }
        )

    var recorded_effect_total: int = 0

    for raw_atom: Variant in damage_atoms:
        if not raw_atom is Dictionary:
            continue

        var atom: Dictionary = raw_atom
        var amount: int = max(
            int(
                atom.get(
                    "amount",
                    0
                )
            ),
            0
        )

        if amount <= 0:
            continue

        recorded_effect_total += amount

        events.append(
            {
                "kind": &"effect_damage",
                "label": String(
                    atom.get(
                        "label",
                        "Charakoro / Effect Damage"
                    )
                ),
                "amount": amount,
                "stage": StringName(
                    atom.get(
                        "stage",
                        ""
                    )
                )
            }
        )

    # Compatibility path for any effect modifier not yet atomized.
    var unrecorded_effect_damage: int = max(
        aggregate_effect_damage
        - recorded_effect_total,
        0
    )

    if unrecorded_effect_damage > 0:
        events.append(
            {
                "kind": &"effect_damage",
                "label": "Charakoro / Effect Damage",
                "amount": unrecorded_effect_damage,
                "stage": &"fallback"
            }
        )

    if weakness_damage > 0:
        events.append(
            {
                "kind": &"weakness_damage",
                "label": "Weakness Damage",
                "amount": weakness_damage
            }
        )

    if defense_reduction > 0:
        events.append(
            {
                "kind": &"defense_reduction",
                "label": "Defense Reduction",
                "amount": -defense_reduction
            }
        )

    return events


static func sum_damage_events(events: Array[Dictionary]) -> int:
    var total: int = 0
    for event: Dictionary in events:
        total += int(event.get("amount", 0))
    return max(total, 0)
