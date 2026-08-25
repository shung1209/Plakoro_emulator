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
            LocalizationService.tr_key(
                "validation.energy_setup_null",
                "Energy dice setup cannot be null."
            )
        )
        return result

    if setup.dice.size() != REQUIRED_DICE_COUNT:
        _add_error(
            result,
            LocalizationService.tr_key(
                "validation.energy_dice_count",
                "Exactly three energy dice are required."
            )
        )

    var fixed_energies: Array[StringName] = []

    for index: int in range(setup.dice.size()):
        var die_data: Variant = setup.dice[index]

        if die_data == null:
            _add_error(
                result,
                LocalizationService.tr_format(
                    "validation.energy_die_missing",
                    {"die": index + 1},
                    "Die {die} is missing."
                )
            )
            continue

        _validate_energy(
            result,
            die_data.fixed_a,
            valid_energy_types,
            _field_name(index + 1, "fixed_a")
        )
        _validate_energy(
            result,
            die_data.fixed_b,
            valid_energy_types,
            _field_name(index + 1, "fixed_b")
        )

        if StringName(die_data.fixed_a) == StringName(die_data.fixed_b):
            _add_error(
                result,
                LocalizationService.tr_format(
                    "validation.energy_fixed_same",
                    {"die": index + 1},
                    "Die {die} fixed A and fixed B must use different Energy types."
                )
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
            _field_name(index + 1, "double_a_first")
        )
        _validate_energy(
            result,
            die_data.double_a_second,
            valid_energy_types,
            _field_name(index + 1, "double_a_second")
        )
        _validate_energy(
            result,
            die_data.double_b_first,
            valid_energy_types,
            _field_name(index + 1, "double_b_first")
        )
        _validate_energy(
            result,
            die_data.double_b_second,
            valid_energy_types,
            _field_name(index + 1, "double_b_second")
        )

        _validate_energy(
            result,
            die_data.single_a,
            valid_energy_types,
            _field_name(index + 1, "single_a")
        )
        _validate_energy(
            result,
            die_data.single_b,
            valid_energy_types,
            _field_name(index + 1, "single_b")
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
                    LocalizationService.tr_format(
                        "validation.energy_fixed_duplicate",
                        {
                            "energy": GameContentLocalizationService.localize_type(
                                energy_type
                            )
                        },
                        "Fixed energy '{energy}' is used more than once."
                    )
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
            LocalizationService.tr_format(
                "validation.energy_field_empty",
                {"field": field_name},
                "{field} is empty."
            )
        )
        return

    if not valid_energy_types.has(energy_type):
        _add_error(
            result,
            LocalizationService.tr_format(
                "validation.energy_field_invalid",
                {
                    "field": field_name,
                    "energy": GameContentLocalizationService.localize_type(
                        energy_type
                    )
                },
                "{field} uses invalid energy '{energy}'."
            )
        )


static func _field_name(die_number: int, face_id: String) -> String:
    return LocalizationService.tr_format(
        "validation.energy_field",
        {
            "die": die_number,
            "face": LocalizationService.tr_key(
                "validation.energy_face." + face_id,
                face_id.replace("_", " ").capitalize()
            )
        },
        "Die {die} {face}"
    )


static func _add_error(
    result: Dictionary,
    message: String
) -> void:
    result["success"] = false
    var errors: Array = result["errors"]
    errors.append(message)
