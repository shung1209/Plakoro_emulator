extends RefCounted


const ENERGY_COST_MATCHER: Script = preload(
    "res://scripts/battle/EnergyCostMatcher.gd"
)


static func can_pay_cost(
    move_card: Variant,
    dice_result: Variant
) -> bool:
    if (
        move_card == null
        or dice_result == null
    ):
        return false

    return ENERGY_COST_MATCHER.can_pay_cost(
        move_card.energy_costs,
        dice_result.energy_counts
    )
