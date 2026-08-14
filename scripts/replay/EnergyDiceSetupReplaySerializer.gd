extends RefCounted


static func serialize_loadout_dice(
    loadout: Variant
) -> Array:
    var result: Array = []

    if loadout == null:
        return result

    for die_config: Variant in loadout.energy_dice:
        if die_config != null and die_config.has_method(
            "to_dictionary"
        ):
            result.append(
                die_config.to_dictionary()
            )

    return result
