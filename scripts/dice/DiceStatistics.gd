extends RefCounted


const ENERGY_DIE_ROLLER: Script = preload(
    "res://scripts/dice/EnergyDieRoller.gd"
)


static func simulate_energy_die(
    profile: Variant,
    reference_data: Variant,
    roll_count: int,
    initial_random_seed: int
) -> Dictionary:
    var result: Dictionary = {}

    if roll_count <= 0:
        return result

    if not profile.validate(reference_data):
        return result

    var rng: RandomNumberGenerator = (
        RandomNumberGenerator.new()
    )
    rng.seed = initial_random_seed

    for face: Variant in profile.get_all_faces():
        result[StringName(face.id)] = 0

    for _roll_index: int in range(roll_count):
        var rolled_face: Variant = (
            ENERGY_DIE_ROLLER.roll(
                profile,
                rng
            )
        )

        if rolled_face == null:
            return {}

        result[rolled_face.id] = (
            int(result[rolled_face.id]) + 1
        )

    return result


static func simulate_kyokoro(
    profile: Variant,
    reference_data: Variant,
    roll_count: int,
    initial_random_seed: int
) -> Dictionary:
    var result: Dictionary = {}

    if roll_count <= 0:
        return result

    var orientation_ids: Array[StringName] = (
        reference_data.get_orientation_ids()
    )

    for orientation: StringName in orientation_ids:
        result[orientation] = 0

    var rng: RandomNumberGenerator = (
        RandomNumberGenerator.new()
    )
    rng.seed = initial_random_seed

    for _roll_index: int in range(roll_count):
        var orientation: StringName = (
            profile.roll_weighted(
                rng,
                orientation_ids
            )
        )

        result[orientation] = (
            int(result[orientation]) + 1
        )

    return result
