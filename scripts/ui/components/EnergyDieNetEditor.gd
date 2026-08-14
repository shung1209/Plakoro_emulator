extends PanelContainer


signal setup_changed


const FACE_BUTTON: Script = preload(
    "res://scripts/ui/components/EnergyFaceButton.gd"
)
const ENERGY_PALETTE: Script = preload(
    "res://scripts/ui/components/EnergyPalette.gd"
)


const FIXED_FIELDS: Array[StringName] = [
    &"fixed_a",
    &"fixed_b"
]


var die_index: int = 0
var setup: Variant = null
var editor_service: Script = null

var _face_buttons: Dictionary = {}
var _palette_host: VBoxContainer = null
var _palette: PanelContainer = null
var _active_field_id: StringName = &""
var _active_face_kind: StringName = &""


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


func refresh_from_setup() -> void:
    if setup == null:
        return

    var die_data: Variant = setup.dice[die_index]

    _set_face(&"fixed_a", die_data.fixed_a)
    _set_face(&"fixed_b", die_data.fixed_b)

    _set_face(
        &"double_a",
        die_data.double_a_first,
        die_data.double_a_second
    )
    _set_face(
        &"double_b",
        die_data.double_b_first,
        die_data.double_b_second
    )

    _set_face(&"single_a", die_data.single_a)
    _set_face(&"single_b", die_data.single_b)




func relocalize() -> void:
    close_palette()
    _build_ui()
    refresh_from_setup()


func close_palette() -> void:
    if _palette != null and is_instance_valid(_palette):
        _palette.queue_free()

    _palette = null
    _active_field_id = &""
    _active_face_kind = &""


func _build_ui() -> void:
    for child: Node in get_children():
        child.queue_free()

    _face_buttons.clear()

    var root_box: VBoxContainer = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 12)
    add_child(root_box)

    var title: Label = Label.new()
    title.text = LocalizationService.tr_format("enerkoro_builder.die_title", {"index": die_index + 1}, "Enerkoro {index}")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    root_box.add_child(title)

    var subtitle: Label = Label.new()
    subtitle.text = LocalizationService.tr_key("enerkoro_builder.die_edit_hint", "Click a dice face to edit its energy.")
    root_box.add_child(subtitle)

    var net: GridContainer = GridContainer.new()
    net.columns = 3
    net.add_theme_constant_override("h_separation", 8)
    net.add_theme_constant_override("v_separation", 8)

    var net_center: CenterContainer = CenterContainer.new()
    net_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    net_center.add_child(net)
    root_box.add_child(net_center)

    _add_empty_cell(net)
    _add_face_button(
        net,
        &"fixed_a",
        &"FACE_UP",
        &"fixed"
    )
    _add_empty_cell(net)

    _add_face_button(
        net,
        &"single_a",
        &"HEAD_LEFT",
        &"single"
    )
    _add_face_button(
        net,
        &"double_a",
        &"HEAD_UP",
        &"double"
    )
    _add_face_button(
        net,
        &"single_b",
        &"HEAD_RIGHT",
        &"single"
    )

    _add_empty_cell(net)
    _add_face_button(
        net,
        &"fixed_b",
        &"FACE_DOWN",
        &"fixed"
    )
    _add_empty_cell(net)

    _add_empty_cell(net)
    _add_face_button(
        net,
        &"double_b",
        &"HEAD_DOWN",
        &"double"
    )
    _add_empty_cell(net)

    _palette_host = VBoxContainer.new()
    _palette_host.add_theme_constant_override(
        "separation",
        8
    )
    root_box.add_child(_palette_host)


func _add_empty_cell(
    parent: GridContainer
) -> void:
    var spacer: Control = Control.new()
    spacer.custom_minimum_size = Vector2(
        140,
        112
    )
    parent.add_child(spacer)


func _add_face_button(
    parent: GridContainer,
    field_id: StringName,
    orientation_id: StringName,
    face_kind: StringName
) -> void:
    var button: Button = FACE_BUTTON.new()
    button.initialize(
        die_index,
        field_id,
        orientation_id,
        face_kind
    )
    button.edit_requested.connect(
        _on_edit_requested
    )

    _face_buttons[field_id] = button
    parent.add_child(button)


func _set_face(
    field_id: StringName,
    first_energy: StringName,
    second_energy: StringName = &""
) -> void:
    if not _face_buttons.has(field_id):
        return

    var button: Variant = _face_buttons[field_id]
    button.set_energy(
        first_energy,
        second_energy
    )


func _on_edit_requested(
    requested_die_index: int,
    field_id: StringName,
    face_kind: StringName
) -> void:
    if requested_die_index != die_index:
        return

    close_palette()

    _active_field_id = field_id
    _active_face_kind = face_kind

    _palette = ENERGY_PALETTE.new()
    _palette.energy_selected.connect(
        _on_palette_energy_selected
    )
    _palette.cancelled.connect(close_palette)
    _palette_host.add_child(_palette)

    if face_kind == &"double":
        var die_data: Variant = setup.dice[die_index]
        var first_energy: StringName = &""
        var second_energy: StringName = &""

        if field_id == &"double_a":
            first_energy = die_data.double_a_first
            second_energy = die_data.double_a_second
        else:
            first_energy = die_data.double_b_first
            second_energy = die_data.double_b_second

        _palette.configure(
            LocalizationService.tr_key("enerkoro_builder.choose_energy_1", "Choose Energy 1"),
            0,
            first_energy
        )

        _palette.set_meta(
            "pending_second_energy",
            second_energy
        )
        _palette.set_meta(
            "selection_stage",
            0
        )
    else:
        var current_energy: StringName = (
            _get_current_single_energy(field_id)
        )
        var unavailable: Dictionary = {}

        if face_kind == &"fixed":
            unavailable = (
                _build_fixed_disabled_reasons(
                    field_id
                )
            )

        _palette.configure(
            LocalizationService.tr_key("enerkoro_builder.choose_energy", "Choose Energy"),
            0,
            current_energy,
            unavailable
        )


func _on_palette_energy_selected(
    energy_type: StringName,
    slot_index: int
) -> void:
    if slot_index != 0 or _palette == null:
        return

    if _active_face_kind == &"double":
        var stage: int = int(
            _palette.get_meta(
                "selection_stage",
                0
            )
        )

        if stage == 0:
            _palette.set_meta(
                "first_energy",
                energy_type
            )
            _palette.set_meta(
                "selection_stage",
                1
            )

            _palette.configure(
                LocalizationService.tr_key("enerkoro_builder.choose_energy_2", "Choose Energy 2"),
                0,
                StringName(
                    _palette.get_meta(
                        "pending_second_energy",
                        ""
                    )
                )
            )
            return

        var first_energy: StringName = StringName(
            _palette.get_meta(
                "first_energy",
                ""
            )
        )

        if _active_field_id == &"double_a":
            editor_service.set_energy(
                setup,
                die_index,
                &"double_a_first",
                first_energy
            )
            editor_service.set_energy(
                setup,
                die_index,
                &"double_a_second",
                energy_type
            )
        else:
            editor_service.set_energy(
                setup,
                die_index,
                &"double_b_first",
                first_energy
            )
            editor_service.set_energy(
                setup,
                die_index,
                &"double_b_second",
                energy_type
            )
    else:
        editor_service.set_energy(
            setup,
            die_index,
            _active_field_id,
            energy_type
        )

    refresh_from_setup()
    close_palette()
    setup_changed.emit()


func _get_current_single_energy(
    field_id: StringName
) -> StringName:
    var die_data: Variant = setup.dice[die_index]

    match field_id:
        &"fixed_a":
            return die_data.fixed_a
        &"fixed_b":
            return die_data.fixed_b
        &"single_a":
            return die_data.single_a
        &"single_b":
            return die_data.single_b
        _:
            return &""


func _build_fixed_disabled_reasons(
    excluded_field_id: StringName
) -> Dictionary:
    var result: Dictionary = {}

    for current_die_index: int in range(
        setup.dice.size()
    ):
        for current_field_id: StringName in FIXED_FIELDS:
            if (
                current_die_index == die_index
                and current_field_id == excluded_field_id
            ):
                continue

            var energy_type: StringName = (
                editor_service.get_energy(
                    setup,
                    current_die_index,
                    current_field_id
                )
            )

            result[energy_type] = LocalizationService.tr_format(
                "enerkoro_builder.already_used_by_die",
                {
                    "die": current_die_index + 1,
                    "face": LocalizationService.tr_key(
                        "orientation." + _field_label(current_field_id),
                        _field_label(current_field_id).replace("_", " ").capitalize()
                    )
                },
                "Already used by Dice {die} {face}"
            )

    return result


func _field_label(
    field_id: StringName
) -> String:
    if field_id == &"fixed_a":
        return "FACE_UP"

    if field_id == &"fixed_b":
        return "FACE_DOWN"

    return String(field_id)
