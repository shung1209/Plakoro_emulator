extends RefCounted


const SETUP_VALIDATOR: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupValidator.gd"
)
const ADAPTER: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupAdapter.gd"
)
const COMPATIBILITY_VALIDATOR: Script = preload(
    "res://scripts/team_builder/EnergyDieCompatibilityValidator.gd"
)


const VALID_ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]


static func apply_setup_to_loadout(
    loadout: Variant,
    setup: Variant
) -> bool:
    if loadout == null or setup == null:
        return false

    var valid_energy_types: Array = []

    for energy_type: StringName in VALID_ENERGY_TYPES:
        valid_energy_types.append(energy_type)

    var setup_validation: Dictionary = (
        SETUP_VALIDATOR.validate(
            setup,
            valid_energy_types
        )
    )

    if not bool(setup_validation["success"]):
        for raw_message: Variant in (
            setup_validation["errors"]
        ):
            push_error(
                "StructuredEnergyDiceService: "
                + String(raw_message)
            )

        return false

    var configs: Array = (
        ADAPTER.create_runtime_configs(
            setup
        )
    )

    if configs.size() != 3:
        push_error(
            "StructuredEnergyDiceService: "
            + "expected exactly three runtime configs."
        )
        return false

    var runtime_validation: Dictionary = (
        COMPATIBILITY_VALIDATOR
        .validate_energy_dice(configs)
    )

    if not bool(runtime_validation["success"]):
        for raw_message: Variant in (
            runtime_validation["errors"]
        ):
            push_error(
                "StructuredEnergyDiceService: "
                + String(raw_message)
            )

        return false

    loadout.energy_dice.clear()

    for config: Variant in configs:
        loadout.energy_dice.append(config)

    return true
