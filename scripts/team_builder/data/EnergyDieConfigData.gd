extends RefCounted


const PROFILE_FACTORY: Script = preload(
    "res://scripts/dice/EnergyDieProfileFactory.gd"
)


var id: StringName = &""

var fixed_energy_a: StringName = &""
var fixed_energy_b: StringName = &""

var single_energy_a: StringName = &""
var single_energy_b: StringName = &""

var double_energy_a: StringName = &""
var double_energy_b: StringName = &""


func _init(
    die_id: StringName = &"",
    energy_a: StringName = &"",
    energy_b: StringName = &""
) -> void:
    id = die_id
    fixed_energy_a = energy_a
    fixed_energy_b = energy_b

    single_energy_a = energy_a
    single_energy_b = energy_b

    double_energy_a = energy_a
    double_energy_b = energy_b


func configure_all_faces(
    fixed_a: StringName,
    fixed_b: StringName,
    single_a: StringName,
    single_b: StringName,
    double_a: StringName,
    double_b: StringName
) -> void:
    fixed_energy_a = fixed_a
    fixed_energy_b = fixed_b

    single_energy_a = single_a
    single_energy_b = single_b

    double_energy_a = double_a
    double_energy_b = double_b


func get_fixed_energies() -> Array[StringName]:
    return [
        fixed_energy_a,
        fixed_energy_b
    ]


func contains_energy(
    energy_type: StringName
) -> bool:
    return (
        fixed_energy_a == energy_type
        or fixed_energy_b == energy_type
        or single_energy_a == energy_type
        or single_energy_b == energy_type
        or double_energy_a == energy_type
        or double_energy_b == energy_type
    )


func create_profile() -> Variant:
    return PROFILE_FACTORY.create_profile(
        id,
        fixed_energy_a,
        fixed_energy_b,
        single_energy_a,
        single_energy_b,
        double_energy_a,
        double_energy_b
    )
