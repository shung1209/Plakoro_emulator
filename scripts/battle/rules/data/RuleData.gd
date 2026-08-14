extends RefCounted


var id: StringName = &""
var trigger: StringName = &"on_move"
var priority: int = 0
var enabled: bool = true

var condition: Dictionary = {
    "type": "always"
}

var effects: Array = []
var source: Dictionary = {}


func _init(
    rule_id: StringName = &"",
    trigger_id: StringName = &"on_move"
) -> void:
    id = rule_id
    trigger = trigger_id
