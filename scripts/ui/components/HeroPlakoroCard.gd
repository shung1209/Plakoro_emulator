extends PanelContainer


const PRESENTATION: Script = preload(
    "res://scripts/presentation/PokemonPresentationManager.gd"
)
const DICE_SUMMARY: Script = preload(
    "res://scripts/ui/components/EnergyDiceIconSummary.gd"
)
const POKEMON_ATTRIBUTE_ICONS: Script = preload(
	"res://scripts/ui/components/PokemonAttributeIconDisplay.gd"
)


@onready var name_label: Label = %NameLabel
@onready var id_label: Label = %IdLabel
@onready var visual_slot: Control = %VisualSlot
@onready var hp_label: Label = %HpLabel
@onready var type_label: HBoxContainer = %TypeLabel
@onready var dice_container: HBoxContainer = %DiceContainer
@onready var source_label: Label = %SourceLabel


func setup(
    pokemon: Variant,
    loadout: Variant = null,
    compact: bool = false
) -> void:
    if not is_node_ready():
        await ready

    if pokemon == null:
        name_label.text = "Unknown PLAKORO"
        id_label.text = ""
        hp_label.text = "HP -"
        POKEMON_ATTRIBUTE_ICONS.show_type(type_label, &"")
        source_label.text = "Presentation: unavailable"
        PRESENTATION.present(
            visual_slot,
            &"",
            "Unknown PLAKORO",
            compact
        )
        return

    var pokemon_id: StringName = StringName(
        _get_property(
            pokemon,
            &"id",
            &""
        )
    )

    var display_name: String = String(
        _get_property(
            pokemon,
            &"display_name",
            pokemon_id
        )
    )

    name_label.text = display_name
    id_label.text = String(
        pokemon_id
    )

    var hp_value: Variant = _first_property(
        pokemon,
        [
            &"max_hp",
            &"hp",
            &"base_hp"
        ],
        null
    )

    hp_label.text = (
        "HP " + str(int(hp_value))
        if hp_value != null
        else "HP -"
    )

    var type_value: Variant = _first_property(
        pokemon,
        [
            &"energy_type",
            &"pokemon_type",
            &"type",
            &"attack_type"
        ],
        null
    )

    POKEMON_ATTRIBUTE_ICONS.show_type(
		type_label,
		StringName(type_value) if type_value != null else &""
	)

    var presentation_result: Dictionary = (
        PRESENTATION.present(
            visual_slot,
            pokemon_id,
            display_name,
            compact
        )
    )

    source_label.text = (
        "Presentation: "
        + String(
            presentation_result["mode"]
        )
    )

    _refresh_dice(
        loadout,
        compact
    )


func _refresh_dice(
    loadout: Variant,
    compact: bool
) -> void:
    for child: Node in dice_container.get_children():
        child.queue_free()

    if loadout == null:
        return

    var setup_data: Variant = _get_property(
        loadout,
        &"energy_dice_setup",
        null
    )

    if setup_data == null:
        return

    var summary: HBoxContainer = HBoxContainer.new()
    summary.set_script(
        DICE_SUMMARY
    )
    summary.setup(
        setup_data,
        true
    )

    if compact:
        summary.scale = Vector2(
            0.88,
            0.88
        )

    dice_container.add_child(
        summary
    )


static func _first_property(
    object: Variant,
    property_names: Array[StringName],
    default_value: Variant
) -> Variant:
    for property_name: StringName in property_names:
        var value: Variant = _get_property(
            object,
            property_name,
            null
        )

        if value != null:
            return value

    return default_value


static func _get_property(
    object: Variant,
    property_name: StringName,
    default_value: Variant
) -> Variant:
    if object == null:
        return default_value

    if object is Dictionary:
        var dictionary: Dictionary = object as Dictionary

        if dictionary.has(property_name):
            return dictionary[property_name]

        var string_key: String = String(
            property_name
        )

        if dictionary.has(string_key):
            return dictionary[string_key]

        return default_value

    if not object is Object:
        return default_value

    for property_info: Dictionary in (
        object.get_property_list()
    ):
        if StringName(
            property_info.get(
                "name",
                ""
            )
        ) == property_name:
            return object.get(
                property_name
            )

    return default_value
