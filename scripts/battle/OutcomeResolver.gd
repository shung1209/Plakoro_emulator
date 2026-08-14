extends RefCounted


static func get_matching_outcome(
    move_card: Variant,
    orientation: StringName
) -> Variant:
    if orientation == &"":
        return null

    return move_card.get_outcome_for_orientation(
        orientation
    )
