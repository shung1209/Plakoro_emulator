extends RefCounted


const JSON_LOADER: Script = preload(
    "res://scripts/database/JsonLoader.gd"
)
const SETUP_DATA: Script = preload(
    "res://scripts/dice/setup/EnergyDiceSetupData.gd"
)


static func load_setup(
    file_path: String
) -> Variant:
    var data: Dictionary = (
        JSON_LOADER.load_dictionary(file_path)
    )

    if data.is_empty():
        return null

    return SETUP_DATA.from_dictionary(data)
