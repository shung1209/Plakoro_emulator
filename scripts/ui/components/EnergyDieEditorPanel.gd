extends PanelContainer


signal setup_changed


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

const FIXED_FIELDS: Array[StringName] = [
    &"fixed_a",
    &"fixed_b"
]


var die_index: int = 0
var setup: Variant = null
var editor_service: Script = null

var _options: Dictionary = {}


func initialize(
    source_setup: Variant,
    source_die_index: int,
    source_editor_service: Script
) -> void:
    setup = source_setup
    die_index = source_die_index
    editor_service = source_editor_service

    _build_ui()
    refresh_from_setup()
    refresh_fixed_energy_constraints()


func _build_ui() -> void:
    for child: Node in get_children():
        child.queue_free()

    _options.clear()

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override(
        "separation",
        8
    )
    add_child(root_box)

    var title: Label = Label.new()
    title.text = "Enerkoro " + str(die_index + 1)
    title.add_theme_font_size_override(
        "font_size",
        20
    )
    root_box.add_child(title)

    _add_pair_section(
        root_box,
        "Fixed opposite faces",
        [
            [&"fixed_a", "FACE_UP"],
            [&"fixed_b", "FACE_DOWN"]
        ]
    )

    _add_pair_section(
        root_box,
        "Double-energy faces",
        [
            [&"double_a_first", "HEAD_UP / Energy 1"],
            [&"double_a_second", "HEAD_UP / Energy 2"],
            [&"double_b_first", "HEAD_DOWN / Energy 1"],
            [&"double_b_second", "HEAD_DOWN / Energy 2"]
        ]
    )

    _add_pair_section(
        root_box,
        "Single-energy opposite faces",
        [
            [&"single_a", "HEAD_LEFT"],
            [&"single_b", "HEAD_RIGHT"]
        ]
    )


func _add_pair_section(
    parent: VBoxContainer,
    title_text: String,
    fields: Array
) -> void:
    var section_label: Label = Label.new()
    section_label.text = title_text
    parent.add_child(section_label)

    var grid: GridContainer = GridContainer.new()
    grid.columns = 2
    parent.add_child(grid)

    for field_info: Array in fields:
        var field_id: StringName = StringName(
            field_info[0]
        )
        var field_label: String = String(
            field_info[1]
        )

        var label: Label = Label.new()
        label.text = field_label
        grid.add_child(label)

        var option: OptionButton = OptionButton.new()
        option.size_flags_horizontal = (
            Control.SIZE_EXPAND_FILL
        )

        for energy_type: StringName in ENERGY_TYPES:
            option.add_item(String(energy_type))
            option.set_item_metadata(
                option.item_count - 1,
                energy_type
            )

        option.item_selected.connect(
            _on_option_selected.bind(
                field_id,
                option
            )
        )

        _options[field_id] = option
        grid.add_child(option)


func refresh_from_setup() -> void:
    for raw_field_id: Variant in _options.keys():
        var field_id: StringName = StringName(
            raw_field_id
        )
        var option: OptionButton = _options[field_id]
        var selected_energy: StringName = (
            editor_service.get_energy(
                setup,
                die_index,
                field_id
            )
        )

        for item_index: int in range(
            option.item_count
        ):
            if StringName(
                option.get_item_metadata(item_index)
            ) == selected_energy:
                option.select(item_index)
                break


func refresh_fixed_energy_constraints() -> void:
    for field_id: StringName in FIXED_FIELDS:
        if not _options.has(field_id):
            continue

        var option: OptionButton = _options[field_id]
        var current_energy: StringName = (
            editor_service.get_energy(
                setup,
                die_index,
                field_id
            )
        )
        var popup: PopupMenu = option.get_popup()

        for item_index: int in range(
            option.item_count
        ):
            var candidate: StringName = StringName(
                option.get_item_metadata(item_index)
            )

            var usage: Dictionary = _find_fixed_energy_usage(
                candidate,
                die_index,
                field_id
            )

            var used_elsewhere: bool = not usage.is_empty()

            popup.set_item_disabled(
                item_index,
                used_elsewhere
            )

            if used_elsewhere:
                popup.set_item_tooltip(
                    item_index,
                    "Already used by Dice "
                    + str(int(usage["die_index"]) + 1)
                    + " "
                    + _field_display_name(
                        StringName(usage["field_id"])
                    )
                )
            else:
                popup.set_item_tooltip(
                    item_index,
                    ""
                )

            # The current field's existing value must remain usable.
            if candidate == current_energy:
                popup.set_item_disabled(
                    item_index,
                    false
                )


func _find_fixed_energy_usage(
    energy_type: StringName,
    excluded_die_index: int,
    excluded_field_id: StringName
) -> Dictionary:
    if setup == null:
        return {}

    for current_die_index: int in range(
        setup.dice.size()
    ):
        for current_field_id: StringName in FIXED_FIELDS:
            if (
                current_die_index == excluded_die_index
                and current_field_id == excluded_field_id
            ):
                continue

            var current_energy: StringName = (
                editor_service.get_energy(
                    setup,
                    current_die_index,
                    current_field_id
                )
            )

            if current_energy == energy_type:
                return {
                    "die_index": current_die_index,
                    "field_id": current_field_id
                }

    return {}


func _field_display_name(
    field_id: StringName
) -> String:
    if field_id == &"fixed_a":
        return "FACE_UP"

    if field_id == &"fixed_b":
        return "FACE_DOWN"

    return String(field_id)


func _on_option_selected(
    item_index: int,
    field_id: StringName,
    option: OptionButton
) -> void:
    var energy_type: StringName = StringName(
        option.get_item_metadata(item_index)
    )

    if editor_service.set_energy(
        setup,
        die_index,
        field_id,
        energy_type
    ):
        setup_changed.emit()
