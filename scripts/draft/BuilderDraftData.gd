extends RefCounted

var schema_version: String = "1.0"
var builder_version: String = "9.7"
var draft_type: StringName = &""
var last_modified: String = ""

func touch() -> void:
    last_modified = Time.get_datetime_string_from_system(true, true)

func to_base_dictionary() -> Dictionary:
    return {
        "schema_version": schema_version,
        "builder_version": builder_version,
        "draft_type": String(draft_type),
        "last_modified": last_modified
    }

func load_base_dictionary(data: Dictionary) -> void:
    schema_version = String(data.get("schema_version", "1.0"))
    builder_version = String(data.get("builder_version", "9.7"))
    draft_type = StringName(data.get("draft_type", ""))
    last_modified = String(data.get("last_modified", ""))
