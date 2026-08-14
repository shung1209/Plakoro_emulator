extends RefCounted


const OPCODE_AUTHORING_METADATA: Script = preload(
    "res://scripts/content/OpcodeAuthoringMetadataCatalogue.gd"
)


var _handlers: Dictionary = {}


func register_handler(
    handler: Variant
) -> bool:
    if handler == null:
        push_error(
            "OpcodeRegistry: handler cannot be null."
        )
        return false

    if not handler.has_method("get_opcode"):
        push_error(
            "OpcodeRegistry: handler does not provide get_opcode()."
        )
        return false

    if not handler.has_method("compile"):
        push_error(
            "OpcodeRegistry: handler does not provide compile()."
        )
        return false

    var opcode: StringName = StringName(
        handler.get_opcode()
    )

    if opcode == &"":
        push_error(
            "OpcodeRegistry: handler opcode cannot be empty."
        )
        return false

    if _handlers.has(opcode):
        push_error(
            "OpcodeRegistry: duplicate handler for opcode '%s'."
            % String(opcode)
        )
        return false

    _handlers[opcode] = handler
    return true


func unregister_handler(
    opcode: StringName
) -> bool:
    if not _handlers.has(opcode):
        return false

    _handlers.erase(opcode)
    return true


func has_handler(
    opcode: StringName
) -> bool:
    return _handlers.has(opcode)


func get_handler(
    opcode: StringName
) -> Variant:
    return _handlers.get(opcode, null)


func compile_action(
    action: Variant,
    context: Variant
) -> bool:
    if action == null:
        push_error(
            "OpcodeRegistry: action cannot be null."
        )
        return false

    var opcode: StringName = StringName(
        action.opcode
    )
    var handler: Variant = get_handler(opcode)

    if handler == null:
        push_error(
            "OpcodeRegistry: no handler registered for opcode '%s'."
            % String(opcode)
        )
        return false

    return bool(
        handler.compile(
            action,
            context
        )
    )


func size() -> int:
    return _handlers.size()


func get_registered_opcodes() -> Array[StringName]:
    var result: Array[StringName] = []

    for raw_opcode: Variant in _handlers.keys():
        result.append(StringName(raw_opcode))

    result.sort()
    return result



func get_authoring_metadata(
    opcode: StringName
) -> Dictionary:
    var handler: Variant = get_handler(opcode)
    var metadata: Dictionary = {}

    if (
        handler != null
        and handler.has_method(
            "get_authoring_metadata"
        )
    ):
        var handler_metadata: Variant = (
            handler.get_authoring_metadata()
        )
        if handler_metadata is Dictionary:
            metadata = (
                handler_metadata as Dictionary
            ).duplicate(true)

    var catalogue_metadata: Dictionary = (
        OPCODE_AUTHORING_METADATA.get_metadata(
            opcode
        )
    )

    for key: Variant in catalogue_metadata.keys():
        if not metadata.has(key):
            metadata[key] = catalogue_metadata[key]

    metadata["opcode"] = String(opcode)
    metadata["runtime_registered"] = (
        handler != null
    )
    return metadata


func get_all_authoring_metadata() -> Array[Dictionary]:
    var result: Array[Dictionary] = []

    for opcode: StringName in get_registered_opcodes():
        result.append(
            get_authoring_metadata(opcode)
        )

    result.sort_custom(
        func(a: Dictionary, b: Dictionary) -> bool:
            var category_compare: bool = (
                String(a.get("category", ""))
                == String(b.get("category", ""))
            )
            if category_compare:
                return (
                    String(a.get("display_name", ""))
                    < String(b.get("display_name", ""))
                )
            return (
                String(a.get("category", ""))
                < String(b.get("category", ""))
            )
    )
    return result
