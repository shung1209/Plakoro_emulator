extends RefCounted


static func add_face_result(
    dice_result: Variant,
    face_result: Dictionary
) -> bool:
    if dice_result == null:
        return false

    var raw_energies: Variant = face_result.get(
        "energies",
        []
    )

    if not raw_energies is Array:
        return false

    for raw_energy: Variant in (
        raw_energies as Array
    ):
        var energy_type: StringName = StringName(
            raw_energy
        )

        if energy_type == &"":
            return false

        dice_result.set_energy_count(
            energy_type,
            dice_result.get_energy_count(
                energy_type
            ) + 1
        )

    return true
