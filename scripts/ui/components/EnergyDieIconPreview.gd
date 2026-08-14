extends PanelContainer


const ENERGY_COST_CHIP: Script = preload(
    "res://scripts/ui/components/EnergyCostChip.gd"
)
const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)


func setup(
    die_data: Variant,
    die_number: int,
    compact: bool = false
) -> void:
    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override(
        "separation",
        7
    )
    add_child(box)

    var title: Label = Label.new()
    title.text = LocalizationService.tr_format(
        "enerkoro_builder.dice_preview_title",
        {"index": die_number},
        "Dice {index}"
    )
    title.add_theme_font_size_override(
        "font_size",
        17 if compact else 19
    )
    box.add_child(title)

    if die_data == null:
        var missing: Label = Label.new()
        missing.text = LocalizationService.tr_key(
            "enerkoro_builder.dice_data_unavailable",
            "Dice data unavailable"
        )
        missing.modulate.a = 0.70
        box.add_child(missing)
        return

    _add_face_pair(
        box,
        LocalizationService.tr_key(
            "enerkoro_builder.preview_fixed",
            "Fixed"
        ),
        StringName(die_data.fixed_a),
        StringName(die_data.fixed_b),
        1,
        1,
        compact
    )

    _add_face_pair(
        box,
        LocalizationService.tr_key(
            "enerkoro_builder.preview_double",
            "Double"
        ),
        StringName(die_data.double_a_first),
        StringName(die_data.double_b_first),
        2,
        2,
        compact,
        StringName(die_data.double_a_second),
        StringName(die_data.double_b_second)
    )

    _add_face_pair(
        box,
        LocalizationService.tr_key(
            "enerkoro_builder.preview_single",
            "Single"
        ),
        StringName(die_data.single_a),
        StringName(die_data.single_b),
        1,
        1,
        compact
    )


func _add_face_pair(
    parent: VBoxContainer,
    category: String,
    left_energy: StringName,
    right_energy: StringName,
    left_count: int,
    right_count: int,
    compact: bool,
    left_second: StringName = &"",
    right_second: StringName = &""
) -> void:
    var section: VBoxContainer = VBoxContainer.new()
    section.add_theme_constant_override(
        "separation",
        3
    )
    parent.add_child(section)

    var category_label: Label = Label.new()
    category_label.text = category
    category_label.modulate.a = 0.68
    category_label.add_theme_font_size_override(
        "font_size",
        12 if compact else 13
    )
    section.add_child(category_label)

    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override(
        "separation",
        8
    )
    section.add_child(row)

    _add_face(
        row,
        left_energy,
        left_count,
        compact,
        left_second
    )

    var divider: Label = Label.new()
    divider.text = "↔"
    divider.modulate.a = 0.55
    row.add_child(divider)

    _add_face(
        row,
        right_energy,
        right_count,
        compact,
        right_second
    )


func _add_face(
    parent: HBoxContainer,
    energy_type: StringName,
    count: int,
    compact: bool,
    second_energy: StringName = &""
) -> void:
    var face_panel: PanelContainer = PanelContainer.new()
    face_panel.custom_minimum_size = Vector2(
        76 if compact else 96,
        42 if compact else 52
    )
    parent.add_child(face_panel)

    var face_row: HBoxContainer = HBoxContainer.new()
    face_row.alignment = BoxContainer.ALIGNMENT_CENTER
    face_row.add_theme_constant_override(
        "separation",
        3
    )
    face_panel.add_child(face_row)

    if second_energy == &"":
        _add_energy_icon(
            face_row,
            energy_type,
            24 if compact else 30
        )

        if count > 1:
            var count_label: Label = Label.new()
            count_label.text = "×" + str(count)
            face_row.add_child(count_label)
        return

    _add_energy_icon(
        face_row,
        energy_type,
        22 if compact else 27
    )

    var plus_label: Label = Label.new()
    plus_label.text = "+"
    plus_label.modulate.a = 0.70
    face_row.add_child(plus_label)

    _add_energy_icon(
        face_row,
        second_energy,
        22 if compact else 27
    )


func _add_energy_icon(
    parent: HBoxContainer,
    energy_type: StringName,
    icon_size: int
) -> void:
    var texture: Texture2D = ICONS.load_energy_icon(
        energy_type
    )

    if texture != null:
        var icon: TextureRect = TextureRect.new()
        icon.texture = texture
        icon.custom_minimum_size = Vector2(
            icon_size,
            icon_size
        )
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.tooltip_text = GameContentLocalizationService.localize_type(
            energy_type
        )
        parent.add_child(icon)
    else:
        var fallback: Label = Label.new()
        fallback.text = ICONS.energy_fallback(
            energy_type
        )
        fallback.modulate.a = 0.80
        fallback.add_theme_font_size_override(
            "font_size",
            11
        )
        parent.add_child(fallback)
