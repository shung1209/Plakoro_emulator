extends RefCounted


const REQUIRED_DICE_COUNT: int = 3
const REQUIRED_FIXED_ENERGY_COUNT: int = 6


static func validate(
    setup: Variant,
    valid_energy_types: Array,
    allow_repeated_fixed_energy: bool = false
) -> Dictionary:
    var result: Dictionary = {
        "success": true,
        "errors": []
    }

    if setup == null:
        _add_error(
            result,
            "Energy dice setup cannot be null."
        )
        return result

    if setup.dice.size() != REQUIRED_DICE_COUNT:
        _add_error(
            result,
            "Exactly three energy dice are required."
        )

    var fixed_energies: Array[StringName] = []

    for index: int in range(setup.dice.size()):
        var die_data: Variant = setup.dice[index]

        if die_data == null:
            _add_error(
                result,
                "Die %d is missing."
                % (index + 1)
            )
            continue

        _validate_energy(
            result,
            die_data.fixed_a,
            valid_energy_types,
            "Die %d fixed A" % (index + 1)
        )
        _validate_energy(
            result,
            die_data.fixed_b,
            valid_energy_types,
            "Die %d fixed B" % (index + 1)
        )

        if StringName(die_data.fixed_a) == StringName(die_data.fixed_b):
            _add_error(
                result,
                "Die %d fixed A and fixed B must use different Energy types."
                % (index + 1)
            )

        fixed_energies.append(
            StringName(die_data.fixed_a)
        )
        fixed_energies.append(
            StringName(die_data.fixed_b)
        )

        _validate_energy(
            result,
            die_data.double_a_first,
            valid_energy_types,
            "Die %d double A first" % (index + 1)
        )
        _validate_energy(
            result,
            die_data.double_a_second,
            valid_energy_types,
            "Die %d double A second" % (index + 1)
        )
        _validate_energy(
            result,
            die_data.double_b_first,
            valid_energy_types,
            "Die %d double B first" % (index + 1)
        )
        _validate_energy(
            result,
            die_data.double_b_second,
            valid_energy_types,
            "Die %d double B second" % (index + 1)
        )

        _validate_energy(
            result,
            die_data.single_a,
            valid_energy_types,
            "Die %d single A" % (index + 1)
        )
        _validate_energy(
            result,
            die_data.single_b,
            valid_energy_types,
            "Die %d single B" % (index + 1)
        )

    if (
        not allow_repeated_fixed_energy
        and fixed_energies.size() == REQUIRED_FIXED_ENERGY_COUNT
    ):
        var unique_fixed: Dictionary = {}

        for energy_type: StringName in fixed_energies:
            if unique_fixed.has(energy_type):
                _add_error(
                    result,
                    "Fixed energy '%s' is used more than once."
                    % String(energy_type)
                )
            else:
                unique_fixed[energy_type] = true

    return result


static func _validate_energy(
    result: Dictionary,
    energy_type: StringName,
    valid_energy_types: Array,
    field_name: String
) -> void:
    if energy_type == &"":
        _add_error(
            result,
            field_name + " is empty."
        )
        return

    if not valid_energy_types.has(energy_type):
        _add_error(
            result,
            field_name
            + " uses invalid energy '"
            + String(energy_type)
            + "'."
        )


static func _add_error(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false
    var errors: Array = result["errors"]
    errors.append(message)
