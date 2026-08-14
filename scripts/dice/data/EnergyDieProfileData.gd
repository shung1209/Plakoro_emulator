extends RefCounted


const REQUIRED_FACE_IDS: Array[StringName] = [
    &"FIXED_A",
    &"FIXED_B",
    &"SINGLE_A",
    &"SINGLE_B",
    &"DOUBLE_A",
    &"DOUBLE_B"
]

const OPPOSITE_FACE_PAIRS: Array = [
    [&"FIXED_A", &"FIXED_B"],
    [&"SINGLE_A", &"SINGLE_B"],
    [&"DOUBLE_A", &"DOUBLE_B"]
]

const EXPECTED_AXES: Dictionary = {
    &"FIXED_A": &"+X",
    &"FIXED_B": &"-X",
    &"SINGLE_A": &"+Y",
    &"SINGLE_B": &"-Y",
    &"DOUBLE_A": &"+Z",
    &"DOUBLE_B": &"-Z"
}


var id: StringName = &""
var faces: Dictionary = {}


func add_face(face: Variant) -> bool:
    if face == null:
        return false

    var face_id: StringName = StringName(face.id)

    if face_id == &"":
        return false

    if faces.has(face_id):
        return false

    faces[face_id] = face
    return true


func get_face(
    face_id: StringName
) -> Variant:
    return faces.get(face_id, null)


func get_all_faces() -> Array:
    var result: Array = []

    for face_id: StringName in REQUIRED_FACE_IDS:
        if faces.has(face_id):
            result.append(faces[face_id])

    return result


func get_opposite_face_id(
    face_id: StringName
) -> StringName:
    for raw_pair: Variant in OPPOSITE_FACE_PAIRS:
        var pair: Array = raw_pair as Array

        if StringName(pair[0]) == face_id:
            return StringName(pair[1])

        if StringName(pair[1]) == face_id:
            return StringName(pair[0])

    return &""


func get_total_weight() -> float:
    var total: float = 0.0

    for face: Variant in faces.values():
        total += float(face.weight)

    return total


func validate(
    reference_data: Variant
) -> bool:
    if id == &"":
        push_error(
            "EnergyDieProfileData: id cannot be empty."
        )
        return false

    if faces.size() != 6:
        push_error(
            "Energy die '%s' must contain exactly 6 faces."
            % String(id)
        )
        return false

    for face_id: StringName in REQUIRED_FACE_IDS:
        if not faces.has(face_id):
            push_error(
                "Energy die '%s' is missing face '%s'."
                % [
                    String(id),
                    String(face_id)
                ]
            )
            return false

        if not _validate_face(
            faces[face_id],
            face_id,
            reference_data
        ):
            return false

    if get_total_weight() <= 0.0:
        push_error(
            "Energy die '%s' must have positive total weight."
            % String(id)
        )
        return false

    return true


func _validate_face(
    face: Variant,
    expected_face_id: StringName,
    reference_data: Variant
) -> bool:
    if face == null:
        return false

    if StringName(face.id) != expected_face_id:
        push_error(
            "Energy die '%s' has a mismatched face ID."
            % String(id)
        )
        return false

    var expected_role: StringName = (
        _get_expected_role(expected_face_id)
    )

    if StringName(face.role) != expected_role:
        push_error(
            "Face '%s' must use role '%s'."
            % [
                String(expected_face_id),
                String(expected_role)
            ]
        )
        return false

    var expected_axis: StringName = StringName(
        EXPECTED_AXES.get(expected_face_id, &"")
    )

    if StringName(face.local_axis) != expected_axis:
        push_error(
            "Face '%s' must use local axis '%s'."
            % [
                String(expected_face_id),
                String(expected_axis)
            ]
        )
        return false

    var expected_energy_count: int = 1

    if expected_role == &"double":
        expected_energy_count = 2

    if face.energies.size() != expected_energy_count:
        push_error(
            "Face '%s' must contain %d energy value(s)."
            % [
                String(expected_face_id),
                expected_energy_count
            ]
        )
        return false

    if float(face.weight) < 0.0:
        push_error(
            "Face '%s' cannot have a negative weight."
            % String(expected_face_id)
        )
        return false

    for raw_energy: Variant in face.energies:
        var energy_type: StringName = StringName(
            raw_energy
        )

        if not reference_data.has_energy_type(
            energy_type
        ):
            push_error(
                "Face '%s' contains unknown energy '%s'."
                % [
                    String(expected_face_id),
                    String(energy_type)
                ]
            )
            return false

    return true


func _get_expected_role(
    face_id: StringName
) -> StringName:
    if (
        face_id == &"FIXED_A"
        or face_id == &"FIXED_B"
    ):
        return &"fixed"

    if (
        face_id == &"DOUBLE_A"
        or face_id == &"DOUBLE_B"
    ):
        return &"double"

    return &"single"
