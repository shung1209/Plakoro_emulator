extends RefCounted


const RESULT_RESOLVER: Script = preload(
    "res://scripts/dice/StructuredEnergyResultResolver.gd"
)


static func roll_energy_profiles(
    profiles: Array,
    random_number_generator: RandomNumberGenerator,
    dice_result: Variant,
    dice_count_modifier: int = 0
) -> bool:
    if (
        random_number_generator == null
        or dice_result == null
    ):
        return false

    var effective_count: int = clamp(
        profiles.size() + dice_count_modifier,
        0,
        profiles.size()
    )

    for index: int in range(effective_count):
        var profile: Variant = profiles[index]

        if profile == null or not profile.has_method(
            "roll_face"
        ):
            push_error(
                "StructuredEnergyDiceRoller: "
                + "profile lacks roll_face()."
            )
            return false

        var face_result: Dictionary = (
            profile.roll_face(
                random_number_generator
            )
        )

        if face_result.is_empty():
            return false

        if not RESULT_RESOLVER.add_face_result(
            dice_result,
            face_result
        ):
            return false

        if not dice_result.has_meta(
            "energy_face_results"
        ):
            dice_result.set_meta(
                "energy_face_results",
                []
            )

        var recorded_faces: Array = (
            dice_result.get_meta(
                "energy_face_results"
            )
        )
        recorded_faces.append(
            face_result.duplicate(true)
        )

    return true
