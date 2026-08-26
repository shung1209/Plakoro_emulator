extends PanelContainer

const PRESENTATION: Script = preload(
    "res://scripts/presentation/PokemonPresentationManager.gd"
)

@onready var visual_slot: Control = %VisualSlot

func setup(
    pokemon: Variant,
    compact: bool = false
) -> void:
    if not is_node_ready():
        await ready
    if pokemon == null:
        PRESENTATION.present(
            visual_slot,
            &"",
            "Unknown PLAKORO",
            compact
        )
        return

    var pokemon_id: StringName = StringName(_get_property(pokemon, &"id", &""))
    var display_name: String = String(_get_property(pokemon, &"display_name", pokemon_id))
    PRESENTATION.present(
        visual_slot,
        pokemon_id,
        display_name,
        compact
    )

static func _get_property(object: Variant, property_name: StringName, default_value: Variant) -> Variant:
    if object == null:
        return default_value
    if object is Dictionary:
        var d: Dictionary = object as Dictionary
        if d.has(property_name):
            return d[property_name]
        var string_key: String = String(property_name)
        if d.has(string_key):
            return d[string_key]
        return default_value
    if not object is Object:
        return default_value
    for property_info: Dictionary in object.get_property_list():
        if StringName(property_info.get("name", "")) == property_name:
            return object.get(property_name)
    return default_value
