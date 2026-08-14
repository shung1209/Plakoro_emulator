extends RefCounted


func get_opcode() -> StringName:
    return &""


func get_authoring_metadata() -> Dictionary:
    # Runtime handlers may override this to provide Content Studio metadata.
    # Returning an empty dictionary keeps third-party/runtime-only handlers
    # backward compatible.
    return {}


func compile(
    _action: Variant,
    _context: Variant
) -> bool:
    push_error(
        "OpcodeHandler.compile() must be implemented."
    )
    return false
