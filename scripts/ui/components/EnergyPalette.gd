extends PanelContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)


signal energy_selected(
    energy_type: StringName,
    slot_index: int
)
signal cancelled


const ENERGY_TYPES: Array[StringName] = [
    &"grass",
    &"fire",
    &"water",
    &"electric",
    &"psychic",
    &"fighting",
    &"dark",
    &"steel",
    &"flying"
]


var slot_index: int = 0
var disabled_reasons: Dictionary = {}
var selected_energy: StringName = &""

var _title_label: Label = null
var _grid: GridContainer = null
var _buttons: Dictionary = {}


func _ready() -> void:
    _build_ui()


func configure(
    title_text: String,
    source_slot_index: int,
    current_energy: StringName,
    unavailable: Dictionary = {}
) -> void:
    slot_index = source_slot_index
    selected_energy = current_energy
    disabled_reasons = unavailable.duplicate(true)

    if not is_node_ready():
        await ready

    _title_label.text = title_text
    _refresh_buttons()


func _build_ui() -> void:
    size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    add_child(root_box)

    var header: HBoxContainer = HBoxContainer.new()
    root_box.add_child(header)

    _title_label = Label.new()
    _title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title_label.add_theme_font_size_override("font_size", 18)
    header.add_child(_title_label)

    var cancel_button: Button = Button.new()
    cancel_button.text = LocalizationService.tr_key("common.close", "Close")
    cancel_button.pressed.connect(
        func() -> void:
            cancelled.emit()
    )
    header.add_child(cancel_button)

    _grid = GridContainer.new()
    _grid.columns = 3
    _grid.add_theme_constant_override("h_separation", 8)
    _grid.add_theme_constant_override("v_separation", 8)
    root_box.add_child(_grid)

    for energy_type: StringName in ENERGY_TYPES:
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(120, 80)
        button.icon = ICONS.load_energy_icon(
            energy_type
        )
        button.expand_icon = false
        button.add_theme_constant_override(
            "icon_max_width",
            32
        )
        button.text = _energy_label(energy_type)
        button.pressed.connect(
            _on_energy_pressed.bind(energy_type)
        )

        _buttons[energy_type] = button
        _grid.add_child(button)


func _refresh_buttons() -> void:
    for raw_energy: Variant in _buttons.keys():
        var energy_type: StringName = StringName(raw_energy)
        var button: Button = _buttons[energy_type]

        var reason: String = String(
            disabled_reasons.get(energy_type, "")
        )
        var is_current: bool = energy_type == selected_energy

        button.disabled = not reason.is_empty() and not is_current

        if button.disabled:
            button.tooltip_text = reason
            button.modulate.a = 0.45
        else:
            button.tooltip_text = ""
            button.modulate.a = 1.0

        if is_current:
            button.text = (
                "✓ "
                + _energy_label(energy_type)
            )
        else:
            button.text = _energy_label(
                energy_type
            )


func _on_energy_pressed(
    energy_type: StringName
) -> void:
    var reason: String = String(
        disabled_reasons.get(energy_type, "")
    )

    if not reason.is_empty() and energy_type != selected_energy:
        return

    selected_energy = energy_type
    _refresh_buttons()

    energy_selected.emit(
        energy_type,
        slot_index
    )



func _energy_label(
    energy_type: StringName
) -> String:
    return GameContentLocalizationService.localize_type(energy_type)
