extends RefCounted


var entry_type: StringName = &""
var actor_id: StringName = &""
var title: String = ""

# Keep this untyped because Godot 4.7 does not automatically convert
# an Array literal into Array[String] when passed to a constructor.
var body_lines: Array = []

var emphasis: StringName = &"normal"
var metadata: Dictionary = {}


func _init(
    type_id: StringName = &"",
    source_actor_id: StringName = &"",
    entry_title: String = "",
    lines: Array = [],
    entry_emphasis: StringName = &"normal",
    entry_metadata: Dictionary = {}
) -> void:
    entry_type = type_id
    actor_id = source_actor_id
    title = entry_title
    body_lines = lines.duplicate()
    emphasis = entry_emphasis
    metadata = entry_metadata.duplicate(true)
