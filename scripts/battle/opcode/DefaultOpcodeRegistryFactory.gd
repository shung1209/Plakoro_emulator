extends RefCounted


const PLUGIN_MANAGER: Script = preload(
    "res://scripts/battle/opcode/OpcodePluginManager.gd"
)


const DEFAULT_HANDLER_DIRECTORY: String = (
    "res://scripts/battle/opcode/handlers"
)


static func create() -> Variant:
    var manager: Variant = PLUGIN_MANAGER.new(
        DEFAULT_HANDLER_DIRECTORY
    )

    return manager.build_registry()


static func create_with_directory(
    handler_directory: String
) -> Variant:
    var manager: Variant = PLUGIN_MANAGER.new(
        handler_directory
    )

    return manager.build_registry()
