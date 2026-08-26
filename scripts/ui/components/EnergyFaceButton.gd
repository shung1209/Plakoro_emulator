extends Button


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)
const SPLIT_FACE_ICON: Script = preload(
    "res://scripts/ui/components/EnergySplitFaceIcon.gd"
)
const THEME_FACTORY: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


signal edit_requested(
    die_index: int,
    field_id: StringName,
    face_kind: StringName
)


var die_index: int = 0
var field_id: StringName = &""
var orientation_id: StringName = &""
var face_kind: StringName = &""

var primary_energy: StringName = &""
var secondary_energy: StringName = &""
var invalid: bool = false

var _content_box: VBoxContainer = null
var _kind_text_label: Label = null
var _energy_icon_row: HBoxContainer = null
var _energy_text_label: Label = null


func initialize(
    source_die_index: int,
    source_field_id: StringName,
    source_orientation_id: StringName,
    source_face_kind: StringName
) -> void:
    die_index = source_die_index
    field_id = source_field_id
    orientation_id = source_orientation_id
    face_kind = source_face_kind

    custom_minimum_size = Vector2(140, 112)
    pressed.connect(_on_pressed)
    _ensure_custom_content()
    refresh_visual()


func set_energy(
    first_energy: StringName,
    second_energy: StringName = &""
) -> void:
    primary_energy = first_energy
    secondary_energy = second_energy
    refresh_visual()


func set_invalid(value: bool) -> void:
    invalid = value
    _refresh_validation_style()


func refresh_visual() -> void:
    _ensure_custom_content()
    _rebuild_energy_icons()

    # All visual content is rendered by child controls.
    icon = null
    text = ""

    _kind_text_label.text = _kind_label()

    if face_kind == &"double":
        _energy_text_label.text = _display_energy(primary_energy) + " + " + _display_energy(secondary_energy)
        tooltip_text = (
            LocalizationService.tr_format(
                "enerkoro_builder.face_edit_tooltip",
                {"energy": GameContentLocalizationService.localize_type(primary_energy) + " + " + GameContentLocalizationService.localize_type(secondary_energy)},
                "Click to edit this face. {energy}"
            )
        )
    else:
        _energy_text_label.text = _display_energy(primary_energy)
        tooltip_text = (
            LocalizationService.tr_format(
                "enerkoro_builder.face_edit_tooltip",
                {"energy": GameContentLocalizationService.localize_type(primary_energy)},
                "Click to edit this face. {energy}"
            )
        )
    _refresh_validation_style()


func _refresh_validation_style() -> void:
    if not invalid:
        for state: StringName in [
            &"normal", &"hover", &"pressed", &"focus"
        ]:
            remove_theme_stylebox_override(state)
        return

    var normal: StyleBoxFlat = _invalid_style(0.42)
    var hover: StyleBoxFlat = _invalid_style(0.56)
    var pressed: StyleBoxFlat = _invalid_style(0.68)
    add_theme_stylebox_override("normal", normal)
    add_theme_stylebox_override("hover", hover)
    add_theme_stylebox_override("pressed", pressed)
    add_theme_stylebox_override("focus", hover)


func _invalid_style(alpha: float) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(
        THEME_FACTORY.get_color("danger"),
        alpha
    )
    style.border_color = THEME_FACTORY.get_color("danger")
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    style.content_margin_left = 8.0
    style.content_margin_top = 8.0
    style.content_margin_right = 8.0
    style.content_margin_bottom = 8.0
    return style


func _ensure_custom_content() -> void:
    if (
        _content_box != null
        and is_instance_valid(
            _content_box
        )
    ):
        return

    _content_box = VBoxContainer.new()
    _content_box.name = "FaceContent"
    _content_box.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )
    _content_box.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT,
        Control.PRESET_MODE_MINSIZE,
        8
    )
    _content_box.alignment = (
        BoxContainer.ALIGNMENT_CENTER
    )
    _content_box.add_theme_constant_override(
        "separation",
        2
    )
    add_child(
        _content_box
    )

    _kind_text_label = Label.new()
    _kind_text_label.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )
    _kind_text_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )
    _kind_text_label.add_theme_font_size_override(
        "font_size",
        12
    )
    _content_box.add_child(
        _kind_text_label
    )

    _energy_icon_row = HBoxContainer.new()
    _energy_icon_row.name = "EnergyIconRow"
    _energy_icon_row.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )
    _energy_icon_row.alignment = (
        BoxContainer.ALIGNMENT_CENTER
    )
    _energy_icon_row.add_theme_constant_override(
        "separation",
        3
    )
    _energy_icon_row.custom_minimum_size = Vector2(
        0,
        34
    )
    _content_box.add_child(
        _energy_icon_row
    )

    _energy_text_label = Label.new()
    _energy_text_label.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )
    _energy_text_label.horizontal_alignment = (
        HORIZONTAL_ALIGNMENT_CENTER
    )
    _energy_text_label.add_theme_font_size_override(
        "font_size",
        14
    )
    _energy_text_label.clip_text = true
    _content_box.add_child(
        _energy_text_label
    )


func _rebuild_energy_icons() -> void:
    if _energy_icon_row == null:
        return

    for child: Node in _energy_icon_row.get_children():
        child.queue_free()

    if (
        face_kind == &"double"
        and secondary_energy != &""
    ):
        var split_icon: Control = SPLIT_FACE_ICON.new()
        split_icon.setup(primary_energy, secondary_energy)
        _energy_icon_row.add_child(
            split_icon
        )
        return

    _add_energy_icon(
        primary_energy
    )


func _add_energy_icon(
    energy_type: StringName
) -> void:
    var texture: Texture2D = (
        ICONS.load_energy_icon(
            energy_type
        )
    )

    if texture == null:
        return

    var texture_rect: TextureRect = TextureRect.new()
    texture_rect.texture = texture
    texture_rect.custom_minimum_size = Vector2(
        30,
        30
    )
    texture_rect.expand_mode = (
        TextureRect.EXPAND_IGNORE_SIZE
    )
    texture_rect.stretch_mode = (
        TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    )
    texture_rect.mouse_filter = (
        Control.MOUSE_FILTER_IGNORE
    )
    texture_rect.tooltip_text = String(
        energy_type
    )

    _energy_icon_row.add_child(
        texture_rect
    )


func _display_energy(energy_type: StringName) -> String:
    if energy_type == &"":
        return LocalizationService.tr_key(
            "enerkoro_builder.empty_energy",
            "EMPTY"
        )
    return GameContentLocalizationService.localize_type(
        energy_type
    )


func _kind_label() -> String:
    match face_kind:
        &"fixed":
            return LocalizationService.tr_key("enerkoro_builder.face_kind_fixed", "FIXED")
        &"double":
            return LocalizationService.tr_key("enerkoro_builder.face_kind_double", "DOUBLE")
        &"single":
            return LocalizationService.tr_key("enerkoro_builder.face_kind_single", "SINGLE")
        _:
            return LocalizationService.tr_key("enerkoro_builder.face_kind_face", "FACE")


func _on_pressed() -> void:
    edit_requested.emit(
        die_index,
        field_id,
        face_kind
    )
