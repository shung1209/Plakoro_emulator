extends HBoxContainer


signal changed
signal remove_requested(row)
signal move_up_requested(row)
signal move_down_requested(row)


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)

const ENERGY_TYPES: Array[String] = [
    "normal",
    "grass",
    "fire",
    "water",
    "electric",
    "psychic",
    "fighting",
    "dark",
    "steel",
    "flying"
]


var type_option: OptionButton
var count_spin: SpinBox
var icon: TextureRect
var remove_button: Button
var up_button: Button
var down_button: Button


func _ready() -> void:
    add_theme_constant_override(
        "separation",
        8
    )


func initialize(
    energy_type: String = "grass",
    count: int = 1
) -> void:
    if get_child_count() > 0:
        return

    icon = TextureRect.new()
    icon.custom_minimum_size = Vector2(
        38,
        38
    )
    icon.expand_mode = (
        TextureRect.EXPAND_IGNORE_SIZE
    )
    icon.stretch_mode = (
        TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    )
    add_child(icon)

    type_option = OptionButton.new()
    type_option.custom_minimum_size = Vector2(
        300,
        0
    )
    type_option.size_flags_horizontal = (
        Control.SIZE_EXPAND_FILL
    )

    for type_name: String in ENERGY_TYPES:
        type_option.add_item(
            type_name.capitalize()
        )
        type_option.set_item_metadata(
            type_option.item_count - 1,
            type_name
        )

    add_child(type_option)

    var count_label: Label = Label.new()
    count_label.text = "Count"
    add_child(count_label)

    count_spin = SpinBox.new()
    count_spin.custom_minimum_size = Vector2(
        120,
        0
    )
    count_spin.min_value = 1.0
    count_spin.max_value = 99.0
    count_spin.step = 1.0
    count_spin.value = max(
        1,
        count
    )
    add_child(count_spin)

    up_button = Button.new()
    up_button.text = "^"
    up_button.tooltip_text = LocalizationService.tr_key(
        "content_studio.energy_cost_move_up",
        "Move this Energy Cost up."
    )
    up_button.custom_minimum_size.x = 44
    add_child(up_button)

    down_button = Button.new()
    down_button.text = "v"
    down_button.tooltip_text = LocalizationService.tr_key(
        "content_studio.energy_cost_move_down",
        "Move this Energy Cost down."
    )
    down_button.custom_minimum_size.x = 44
    add_child(down_button)

    remove_button = Button.new()
    remove_button.text = "Remove"
    remove_button.custom_minimum_size.x = 105
    add_child(remove_button)

    set_energy_type(
        energy_type
    )

    type_option.item_selected.connect(
        func(_index: int) -> void:
            _refresh_icon()
            changed.emit()
    )
    count_spin.value_changed.connect(
        func(_value: float) -> void:
            changed.emit()
    )
    up_button.pressed.connect(
        func() -> void:
            move_up_requested.emit(
                self
            )
    )
    down_button.pressed.connect(
        func() -> void:
            move_down_requested.emit(
                self
            )
    )
    remove_button.pressed.connect(
        func() -> void:
            remove_requested.emit(
                self
            )
    )

    _refresh_icon()


func set_energy_type(
    energy_type: String
) -> void:
    var desired: String = (
        energy_type.to_lower()
    )

    for index: int in range(
        type_option.item_count
    ):
        if String(
            type_option.get_item_metadata(
                index
            )
        ) == desired:
            type_option.select(
                index
            )
            _refresh_icon()
            return

    type_option.select(0)
    _refresh_icon()


func get_energy_type() -> String:
    if (
        type_option == null
        or type_option.item_count <= 0
    ):
        return ""

    return String(
        type_option.get_item_metadata(
            type_option.selected
        )
    )


func get_count() -> int:
    if count_spin == null:
        return 0

    return int(
        count_spin.value
    )


func to_dictionary() -> Dictionary:
    return {
        "energy_type": get_energy_type(),
        "count": get_count()
    }


func set_unavailable_types(
    unavailable: Array[String]
) -> void:
    var current: String = get_energy_type()

    for index: int in range(
        type_option.item_count
    ):
        var type_name: String = String(
            type_option.get_item_metadata(
                index
            )
        )

        type_option.set_item_disabled(
            index,
            (
                unavailable.has(
                    type_name
                )
                and type_name != current
            )
        )


func set_order_buttons(
    can_move_up: bool,
    can_move_down: bool
) -> void:
    if up_button != null:
        up_button.disabled = (
            not can_move_up
        )

    if down_button != null:
        down_button.disabled = (
            not can_move_down
        )


func _refresh_icon() -> void:
    if icon == null:
        return

    icon.texture = ICONS.load_energy_icon(
        StringName(
            get_energy_type()
        )
    )
    icon.tooltip_text = (
        get_energy_type()
    )
