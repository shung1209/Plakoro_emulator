extends RefCounted


const CONFIG_DATA: Script = preload(
    "res://scripts/team_builder/data/StructuredEnergyDieConfigData.gd"
)


static func create_runtime_config(
    die_setup: Variant
) -> Variant:
    if die_setup == null:
        return null

    var config: Variant = CONFIG_DATA.new()
    config.initialize(
        StringName(die_setup.die_id),
        die_setup.get_faces_by_orientation()
    )

    return config


static func create_runtime_configs(
    setup: Variant
) -> Array:
    var result: Array = []

    if setup == null:
        return result

    for die_setup: Variant in setup.dice:
        var config: Variant = (
            create_runtime_config(die_setup)
        )

        if config == null:
            return []

        result.append(config)

    return result
