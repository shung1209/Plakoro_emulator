extends RefCounted


const OPCODE_REGISTRY: Script = preload(
    "res://scripts/battle/opcode/OpcodeRegistry.gd"
)

const PLUGIN_DISCOVERY: Script = preload(
    "res://scripts/battle/opcode/OpcodePluginDiscovery.gd"
)


var handler_directory: String = (
    "res://scripts/battle/opcode/handlers"
)

var descriptors: Array = []
var registry: Variant = null


func _init(
    source_handler_directory: String = (
        "res://scripts/battle/opcode/handlers"
    )
) -> void:
    handler_directory = source_handler_directory


func build_registry() -> Variant:
    descriptors = PLUGIN_DISCOVERY.discover(
        handler_directory
    )

    if descriptors.is_empty():
        push_error(
            "OpcodePluginManager: no opcode handlers discovered."
        )
        return null

    var new_registry: Variant = OPCODE_REGISTRY.new()

    for descriptor: Variant in descriptors:
        if not new_registry.register_handler(
            descriptor.handler
        ):
            push_error(
                "OpcodePluginManager: failed to register '%s' from %s."
                % [
                    String(descriptor.opcode),
                    descriptor.script_path
                ]
            )
            return null

    registry = new_registry
    return registry


func get_plugin_count() -> int:
    return descriptors.size()


func get_descriptors() -> Array:
    return descriptors.duplicate()


func find_descriptor(
    opcode: StringName
) -> Variant:
    for descriptor: Variant in descriptors:
        if StringName(descriptor.opcode) == opcode:
            return descriptor

    return null
