extends RefCounted


var dice: Array = []


func add_die(
    die_data: Variant
) -> void:
    if die_data == null:
        return

    dice.append(die_data)


func to_dictionary() -> Dictionary:
    var serialized: Array = []

    for die_data: Variant in dice:
        serialized.append(
            die_data.to_dictionary()
        )

    return {
        "schema_version": "1.0",
        "dice": serialized
    }


static func from_dictionary(
    data: Dictionary
) -> Variant:
    var result: Variant = new()
    var raw_dice: Variant = data.get("dice", [])

    if raw_dice is Array:
        var die_script: Script = preload(
            "res://scripts/dice/setup/EnergyDieSetupData.gd"
        )

        for raw_die: Variant in raw_dice:
            if raw_die is Dictionary:
                result.add_die(
                    die_script.from_dictionary(
                        raw_die
                    )
                )

    return result
