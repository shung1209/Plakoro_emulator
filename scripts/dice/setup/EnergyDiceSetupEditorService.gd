extends RefCounted


const SETUP_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupData.gd"
)
const DIE_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDieSetupData.gd"
)


static func create_empty_setup() -> Variant:
    var setup: Variant = SETUP_DATA.new()

    for index: int in range(3):
        var die_data: Variant = DIE_DATA.new()
        die_data.die_id = StringName(
            "player_die_" + str(index + 1)
        )
        setup.add_die(die_data)

    return setup


static func clone_setup(
    source_setup: Variant
) -> Variant:
    if source_setup == null:
        return create_empty_setup()

    return SETUP_DATA.from_dictionary(
        source_setup.to_dictionary()
    )


static func set_energy(
    setup: Variant,
    die_index: int,
    field_id: StringName,
    energy_type: StringName
) -> bool:
    if setup == null:
        return false

    if die_index < 0 or die_index >= setup.dice.size():
        return false

    var die_data: Variant = setup.dice[die_index]

    match field_id:
        &"fixed_a":
            die_data.fixed_a = energy_type

        &"fixed_b":
            die_data.fixed_b = energy_type

        &"double_a_first":
            die_data.double_a_first = energy_type

        &"double_a_second":
            die_data.double_a_second = energy_type

        &"double_b_first":
            die_data.double_b_first = energy_type

        &"double_b_second":
            die_data.double_b_second = energy_type

        &"single_a":
            die_data.single_a = energy_type

        &"single_b":
            die_data.single_b = energy_type

        _:
            return false

    return true


static func get_energy(
    setup: Variant,
    die_index: int,
    field_id: StringName
) -> StringName:
    if setup == null:
        return &""

    if die_index < 0 or die_index >= setup.dice.size():
        return &""

    var die_data: Variant = setup.dice[die_index]

    match field_id:
        &"fixed_a":
            return StringName(die_data.fixed_a)

        &"fixed_b":
            return StringName(die_data.fixed_b)

        &"double_a_first":
            return StringName(die_data.double_a_first)

        &"double_a_second":
            return StringName(die_data.double_a_second)

        &"double_b_first":
            return StringName(die_data.double_b_first)

        &"double_b_second":
            return StringName(die_data.double_b_second)

        &"single_a":
            return StringName(die_data.single_a)

        &"single_b":
            return StringName(die_data.single_b)

        _:
            return &""
