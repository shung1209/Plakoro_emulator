extends PanelContainer


signal setup_changed


const FACE_BUTTON: Script = preload(
    "res://scripts/ui/components/EnergyFaceButton.gd"
)
const ENERGY_PALETTE: Script = preload(
    "res://scripts/ui/components/EnergyPalette.gd"
)
const THEME_FACTORY: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


const FIXED_FIELDS: Array[StringName] = [
    &"fixed_a",
    &"fixed_b"
]


var die_index: int = 0
var setup: Variant = null
var editor_service: Script = null
var energy_inventory: Dictionary = {}
var allow_repeated_fixed_energy: bool = false

var _face_buttons: Dictionary = {}
var _palette_host: VBoxContainer = null
var _palette: PanelContainer = null
var _palette_window: PopupPanel = null
var _palette_window_content: VBoxContainer = null
var _active_field_id: StringName = &""
var _active_face_kind: StringName = &""


func initialize(
    source_setup: Variant,
    source_die_index: int,
    source_editor_service: Script,
    source_energy_inventory: Dictionary = {},
    source_allow_repeated_fixed_energy: bool = false
) -> void:
    setup = source_setup
    die_index = source_die_index
    editor_service = source_editor_service
    energy_inventory = source_energy_inventory.duplicate(true)
    allow_repeated_fixed_energy = source_allow_repeated_fixed_energy

    _build_ui()
    refresh_from_setup()


func set_allow_repeated_fixed_energy(value: bool) -> void:
    allow_repeated_fixed_energy = value
    close_palette()


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
    var window_to_close: PopupPanel = _palette_window
    _palette_window = null
    _palette_window_content = null
    _palette = null

    if window_to_close != null and is_instance_valid(window_to_close):
        window_to_close.hide()
        window_to_close.queue_free()

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

    _palette_window = PopupPanel.new()
    _palette_window.name = "EnergySelectionWindow"
    _palette_window.exclusive = true
    _palette_window.transparent_bg = true
    _palette_window.unresizable = true
    _palette_window.popup_hide.connect(_on_palette_window_hidden)
    add_child(_palette_window)

    var popup_style: StyleBoxFlat = StyleBoxFlat.new()
    popup_style.bg_color = THEME_FACTORY.get_color("surface")
    popup_style.border_color = THEME_FACTORY.get_color("accent")
    popup_style.set_border_width_all(2)
    popup_style.corner_radius_top_left = 14
    popup_style.corner_radius_top_right = 14
    popup_style.corner_radius_bottom_left = 14
    popup_style.corner_radius_bottom_right = 14
    popup_style.shadow_color = Color(
        0.11, 0.15, 0.25,
        0.16 if THEME_FACTORY.is_warm_theme() else 0.82
    )
    popup_style.shadow_size = 10 if THEME_FACTORY.is_warm_theme() else 22
    popup_style.content_margin_left = 14.0
    popup_style.content_margin_top = 14.0
    popup_style.content_margin_right = 14.0
    popup_style.content_margin_bottom = 14.0
    _palette_window.add_theme_stylebox_override("panel", popup_style)

    _palette_window_content = VBoxContainer.new()
    _palette_window_content.add_theme_constant_override("separation", 10)
    _palette_window.add_child(_palette_window_content)

    _palette = ENERGY_PALETTE.new()
    _palette.energy_selected.connect(
        _on_palette_energy_selected
    )
    _palette.energy_cleared.connect(
        _on_palette_energy_cleared
    )
    _palette.cancelled.connect(close_palette)
    _palette_window_content.add_child(_palette)

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
            first_energy,
            _build_inventory_disabled_reasons([
                &"double_a_first" if field_id == &"double_a" else &"double_b_first",
                &"double_a_second" if field_id == &"double_a" else &"double_b_second"
            ]),
            true
        )
        _palette.set_clear_button_text(
            LocalizationService.tr_key(
                "enerkoro_builder.remove_both_energy",
                "Remove Both Energy"
            )
        )
        _palette.set_clear_enabled(
            first_energy != &"" or second_energy != &""
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
        _merge_disabled_reasons(
            unavailable,
            _build_inventory_disabled_reasons([field_id])
        )

        _palette.configure(
            LocalizationService.tr_key("enerkoro_builder.choose_energy", "Choose Energy"),
            0,
            current_energy,
            unavailable,
            face_kind == &"single"
        )

    _palette_window.popup_centered(
        Vector2i(500, 470 if face_kind == &"double" else 410)
    )


func _on_palette_window_hidden() -> void:
    if _palette_window == null:
        return
    close_palette()


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
                ),
                _build_inventory_disabled_reasons(
                    [
                        &"double_a_first" if _active_field_id == &"double_a" else &"double_b_first",
                        &"double_a_second" if _active_field_id == &"double_a" else &"double_b_second"
                    ],
                    {String(energy_type): 1}
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


func _on_palette_energy_cleared(slot_index: int) -> void:
    if slot_index != 0:
        return
    if _active_face_kind == &"single":
        editor_service.set_energy(
            setup,
            die_index,
            _active_field_id,
            &""
        )
    elif _active_face_kind == &"double":
        var first_field: StringName = (
            &"double_a_first" if _active_field_id == &"double_a" else &"double_b_first"
        )
        var second_field: StringName = (
            &"double_a_second" if _active_field_id == &"double_a" else &"double_b_second"
        )
        editor_service.set_energy(setup, die_index, first_field, &"")
        editor_service.set_energy(setup, die_index, second_field, &"")
    else:
        return
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
        if (
            allow_repeated_fixed_energy
            and current_die_index != die_index
        ):
            continue

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


func _build_inventory_disabled_reasons(
    excluded_fields: Array[StringName],
    pending_usage: Dictionary = {}
) -> Dictionary:
    var result: Dictionary = {}
    if energy_inventory.is_empty():
        return result
    var usage: Dictionary = {}
    for current_die_index: int in range(setup.dice.size()):
        for field_id: StringName in [
            &"fixed_a", &"fixed_b", &"double_a_first", &"double_a_second",
            &"double_b_first", &"double_b_second", &"single_a", &"single_b"
        ]:
            if current_die_index == die_index and excluded_fields.has(field_id):
                continue
            var energy: String = String(editor_service.get_energy(
                setup, current_die_index, field_id
            ))
            usage[energy] = int(usage.get(energy, 0)) + 1
    for raw_energy: Variant in pending_usage.keys():
        var pending_energy: String = String(raw_energy)
        usage[pending_energy] = (
            int(usage.get(pending_energy, 0)) + int(pending_usage[raw_energy])
        )
    for raw_energy: Variant in energy_inventory.keys():
        var energy: String = String(raw_energy)
        var owned: int = int(energy_inventory[raw_energy])
        if int(usage.get(energy, 0)) >= owned:
            result[StringName(energy)] = LocalizationService.tr_format(
                "enerkoro_builder.energy_owned_limit",
                {"energy": GameContentLocalizationService.localize_type(StringName(energy)), "owned": owned},
                "{energy}: all {owned} owned units are already used"
            )
    return result


func _merge_disabled_reasons(target: Dictionary, source: Dictionary) -> void:
    for key: Variant in source.keys():
        if not target.has(key):
            target[key] = source[key]
