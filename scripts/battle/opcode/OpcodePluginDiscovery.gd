extends RefCounted


const PLUGIN_DESCRIPTOR: Script = preload(
    "res://scripts/battle/opcode/OpcodePluginDescriptor.gd"
)

const DEFAULT_HANDLER_MANIFEST: Script = preload(
    "res://scripts/battle/opcode/DefaultOpcodeHandlerManifest.gd"
)

const DEFAULT_HANDLER_DIRECTORY: String = (
    "res://scripts/battle/opcode/handlers"
)


static func discover(
    root_directory: String
) -> Array:
    # Built-in handlers use an explicit manifest so exported PCK builds do not
    # depend on source-directory enumeration. Custom/plugin directories keep
    # the original filesystem discovery behavior for development tooling.
    if root_directory == DEFAULT_HANDLER_DIRECTORY:
        return _discover_default_manifest()

    var result: Array = []

    if not DirAccess.dir_exists_absolute(
        ProjectSettings.globalize_path(
            root_directory
        )
    ):
        push_error(
            "OpcodePluginDiscovery: directory does not exist: %s"
            % root_directory
        )
        return result

    _scan_directory(
        root_directory,
        result
    )

    result.sort_custom(
        func(a: Variant, b: Variant) -> bool:
            return String(a.script_path) < String(b.script_path)
    )

    return result


static func _discover_default_manifest() -> Array:
    var result: Array = []

    for handler_script: Script in DEFAULT_HANDLER_MANIFEST.get_scripts():
        var descriptor: Variant = _build_handler_descriptor(
            handler_script,
            handler_script.resource_path
        )
        if descriptor != null:
            result.append(descriptor)

    result.sort_custom(
        func(a: Variant, b: Variant) -> bool:
            return String(a.script_path) < String(b.script_path)
    )

    if result.is_empty():
        push_error(
            "OpcodePluginDiscovery: default opcode handler manifest is empty."
        )

    return result


static func _scan_directory(
    directory_path: String,
    result: Array
) -> void:
    var directory: DirAccess = DirAccess.open(
        directory_path
    )

    if directory == null:
        push_error(
            "OpcodePluginDiscovery: could not open directory: %s"
            % directory_path
        )
        return

    var subdirectories: PackedStringArray = (
        directory.get_directories()
    )
    subdirectories.sort()

    for subdirectory_name: String in subdirectories:
        _scan_directory(
            directory_path.path_join(
                subdirectory_name
            ),
            result
        )

    var file_names: PackedStringArray = (
        directory.get_files()
    )
    file_names.sort()

    for file_name: String in file_names:
        if file_name.get_extension().to_lower() != "gd":
            continue

        if not file_name.ends_with("Handler.gd"):
            continue

        var script_path: String = (
            directory_path.path_join(file_name)
        )

        var descriptor: Variant = (
            _load_handler_descriptor(
                script_path
            )
        )

        if descriptor != null:
            result.append(descriptor)


static func _load_handler_descriptor(
    script_path: String
) -> Variant:
    var loaded_resource: Resource = load(script_path)

    if loaded_resource == null:
        push_error(
            "OpcodePluginDiscovery: failed to load: %s"
            % script_path
        )
        return null

    if not loaded_resource is Script:
        push_error(
            "OpcodePluginDiscovery: resource is not a Script: %s"
            % script_path
        )
        return null

    return _build_handler_descriptor(
        loaded_resource as Script,
        script_path
    )


static func _build_handler_descriptor(
    handler_script: Script,
    script_path: String
) -> Variant:
    var handler: Variant = handler_script.new()

    if handler == null:
        push_error(
            "OpcodePluginDiscovery: failed to instantiate: %s"
            % script_path
        )
        return null

    if not handler.has_method("get_opcode"):
        push_error(
            "OpcodePluginDiscovery: handler lacks get_opcode(): %s"
            % script_path
        )
        return null

    if not handler.has_method("compile"):
        push_error(
            "OpcodePluginDiscovery: handler lacks compile(): %s"
            % script_path
        )
        return null

    var opcode: StringName = StringName(
        handler.get_opcode()
    )

    if opcode == &"":
        push_error(
            "OpcodePluginDiscovery: handler has empty opcode: %s"
            % script_path
        )
        return null

    return PLUGIN_DESCRIPTOR.new(
        opcode,
        script_path,
        handler
    )
