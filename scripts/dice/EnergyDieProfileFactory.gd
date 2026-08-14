extends RefCounted


const FACE_DATA: Script = preload(
    "res://scripts/dice/data/EnergyDieFaceData.gd"
)

const PROFILE_DATA: Script = preload(
    "res://scripts/dice/data/EnergyDieProfileData.gd"
)


static func create_profile(
    profile_id: StringName,
    fixed_energy_a: StringName,
    fixed_energy_b: StringName,
    single_energy_a: StringName,
    single_energy_b: StringName,
    double_energy_a: StringName,
    double_energy_b: StringName
) -> Variant:
    var profile: Variant = PROFILE_DATA.new()
    profile.id = profile_id

    profile.add_face(
        FACE_DATA.new(
            &"FIXED_A",
            &"fixed",
            &"+X",
            _make_energy_array(fixed_energy_a),
            1.0
        )
    )

    profile.add_face(
        FACE_DATA.new(
            &"FIXED_B",
            &"fixed",
            &"-X",
            _make_energy_array(fixed_energy_b),
            1.0
        )
    )

    profile.add_face(
        FACE_DATA.new(
            &"SINGLE_A",
            &"single",
            &"+Y",
            _make_energy_array(single_energy_a),
            1.0
        )
    )

    profile.add_face(
        FACE_DATA.new(
            &"SINGLE_B",
            &"single",
            &"-Y",
            _make_energy_array(single_energy_b),
            1.0
        )
    )

    profile.add_face(
        FACE_DATA.new(
            &"DOUBLE_A",
            &"double",
            &"+Z",
            _make_double_energy_array(
                double_energy_a
            ),
            1.0
        )
    )

    profile.add_face(
        FACE_DATA.new(
            &"DOUBLE_B",
            &"double",
            &"-Z",
            _make_double_energy_array(
                double_energy_b
            ),
            1.0
        )
    )

    return profile


static func _make_energy_array(
    energy_type: StringName
) -> Array:
    var result: Array = []
    result.append(energy_type)
    return result


static func _make_double_energy_array(
    energy_type: StringName
) -> Array:
    var result: Array = []
    result.append(energy_type)
    result.append(energy_type)
    return result
