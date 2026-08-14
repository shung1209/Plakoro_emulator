extends RefCounted


var opcode: StringName = &""
var script_path: String = ""
var handler: Variant = null


func _init(
    opcode_id: StringName = &"",
    source_script_path: String = "",
    source_handler: Variant = null
) -> void:
    opcode = opcode_id
    script_path = source_script_path
    handler = source_handler
