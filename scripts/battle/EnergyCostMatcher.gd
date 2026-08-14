extends RefCounted


const WILDCARD_ENERGY: StringName = &"normal"


static func can_pay_cost(
    costs: Array,
    energy_counts: Dictionary
) -> bool:
    return bool(
        analyze_cost(
            costs,
            energy_counts
        )["success"]
    )


static func analyze_cost(
    costs: Array,
    energy_counts: Dictionary
) -> Dictionary:
    var remaining: Dictionary = (
        energy_counts.duplicate(
            true
        )
    )

    var missing: Dictionary = {}
    var typed_required: Dictionary = {}
    var wildcard_required: int = 0

    # Exact/typed requirements are always paid first.
    for cost: Variant in costs:
        var energy_type: StringName = StringName(
            cost.energy_type
        )
        var required_count: int = max(
            int(cost.count),
            0
        )

        if energy_type == WILDCARD_ENERGY:
            wildcard_required += required_count
            continue

        typed_required[energy_type] = (
            int(
                typed_required.get(
                    energy_type,
                    0
                )
            )
            + required_count
        )

    for raw_energy: Variant in typed_required.keys():
        var energy_type: StringName = StringName(
            raw_energy
        )
        var required_count: int = int(
            typed_required[raw_energy]
        )
        var available_count: int = max(
            int(
                remaining.get(
                    energy_type,
                    0
                )
            ),
            0
        )

        var paid: int = min(
            required_count,
            available_count
        )

        remaining[energy_type] = (
            available_count - paid
        )

        var shortfall: int = (
            required_count - paid
        )

        if shortfall > 0:
            missing[energy_type] = shortfall

    # Normal is a wildcard cost. After typed requirements are paid, every
    # remaining Energy symbol can satisfy Normal regardless of its type.
    var remaining_total: int = 0

    for raw_count: Variant in remaining.values():
        remaining_total += max(
            int(raw_count),
            0
        )

    var wildcard_shortfall: int = max(
        wildcard_required - remaining_total,
        0
    )

    if wildcard_shortfall > 0:
        missing[WILDCARD_ENERGY] = (
            wildcard_shortfall
        )

    var total_shortfall: int = 0

    for raw_count: Variant in missing.values():
        total_shortfall += int(
            raw_count
        )

    return {
        "success": total_shortfall == 0,
        "missing": missing,
        "total_shortfall": total_shortfall,
        "wildcard_required": wildcard_required,
        "remaining_after_typed": remaining
    }
