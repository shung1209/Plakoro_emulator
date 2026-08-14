extends RefCounted


static func roll(
    kyokoro_profile: Variant,
    reference_data: Variant,
    rng: RandomNumberGenerator
) -> StringName:
    if kyokoro_profile == null:
        push_error(
            "KyokoroRoller: profile cannot be null."
        )
        return &""

    var orientation_ids: Array[StringName] = (
        reference_data.get_orientation_ids()
    )

    return kyokoro_profile.roll_weighted(
        rng,
        orientation_ids
    )
