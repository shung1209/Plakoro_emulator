extends RefCounted


var opcode: StringName = &""
var args: Dictionary = {}

var then_actions: Array = []
var else_actions: Array = []


func _init(
    action_opcode: StringName = &"",
    action_args: Dictionary = {}
) -> void:
    opcode = action_opcode
    args = action_args.duplicate(true)
