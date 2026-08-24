extends HBoxContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)


func setup(
    energy_type: StringName,
    count: int,
    icon_size: int = 22
) -> void:
    add_theme_constant_override(
        "separation",
        5
    )

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
        add_child(icon)
    else:
        var fallback: Label = Label.new()
        fallback.text = ICONS.energy_fallback(
            energy_type
        )
        fallback.modulate.a = 0.80
        add_child(fallback)

    var count_label: Label = Label.new()
    count_label.text = "x" + str(count)
    count_label.add_theme_font_size_override(
        "font_size",
        max(15, icon_size - 9)
    )
    add_child(count_label)
