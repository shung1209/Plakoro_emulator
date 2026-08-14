extends RefCounted


var die_id: StringName = &""

var fixed_a: StringName = &""
var fixed_b: StringName = &""

var double_a_first: StringName = &""
var double_a_second: StringName = &""

var double_b_first: StringName = &""
var double_b_second: StringName = &""

var single_a: StringName = &""
var single_b: StringName = &""


func to_dictionary() -> Dictionary:
    return {
        "die_id": String(die_id),
        "fixed": [
            String(fixed_a),
            String(fixed_b)
        ],
        "double": [
            [
                String(double_a_first),
                String(double_a_second)
            ],
            [
                String(double_b_first),
                String(double_b_second)
            ]
        ],
        "single": [
            String(single_a),
            String(single_b)
        ]
    }


static func from_dictionary(
    data: Dictionary
) -> Variant:
    var result: Variant = new()

    result.die_id = StringName(
        data.get("die_id", "")
    )

    var fixed_value: Variant = data.get(
        "fixed",
        []
    )
    var double_value: Variant = data.get(
        "double",
        []
    )
    var single_value: Variant = data.get(
        "single",
        []
    )

    if fixed_value is Array and fixed_value.size() == 2:
        result.fixed_a = StringName(fixed_value[0])
        result.fixed_b = StringName(fixed_value[1])

    if double_value is Array and double_value.size() == 2:
        var first_double: Variant = double_value[0]
        var second_double: Variant = double_value[1]

        if first_double is Array and first_double.size() == 2:
            result.double_a_first = StringName(
                first_double[0]
            )
            result.double_a_second = StringName(
                first_double[1]
            )

        if second_double is Array and second_double.size() == 2:
            result.double_b_first = StringName(
                second_double[0]
            )
            result.double_b_second = StringName(
                second_double[1]
            )

    if single_value is Array and single_value.size() == 2:
        result.single_a = StringName(single_value[0])
        result.single_b = StringName(single_value[1])

    return result


func get_faces_by_orientation() -> Dictionary:
    return {
        &"FACE_UP": {
            "kind": "fixed",
            "energies": [fixed_a]
        },
        &"FACE_DOWN": {
            "kind": "fixed",
            "energies": [fixed_b]
        },
        &"HEAD_UP": {
            "kind": "double",
            "energies": [
                double_a_first,
                double_a_second
            ]
        },
        &"HEAD_DOWN": {
            "kind": "double",
            "energies": [
                double_b_first,
                double_b_second
            ]
        },
        &"HEAD_LEFT": {
            "kind": "single",
            "energies": [single_a]
        },
        &"HEAD_RIGHT": {
            "kind": "single",
            "energies": [single_b]
        }
    }


func get_expected_energy_counts() -> Dictionary:
    var totals: Dictionary = {}

    for face_data: Dictionary in (
        get_faces_by_orientation().values()
    ):
        var energies: Array = face_data.get(
            "energies",
            []
        )

        for raw_energy: Variant in energies:
            var energy_type: StringName = StringName(
                raw_energy
            )

            if energy_type == &"":
                continue

            totals[energy_type] = (
                float(totals.get(energy_type, 0.0))
                + (1.0 / 6.0)
            )

    return totals
