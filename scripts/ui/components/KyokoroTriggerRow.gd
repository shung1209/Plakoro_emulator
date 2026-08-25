extends HBoxContainer


const ICONS: Script = preload(
    "res://scripts/presentation/PlakoroIconService.gd"
)


func setup(
    orientations: Array[StringName],
    icon_size: int = 28
) -> void:
    add_theme_constant_override(
        "separation",
        6
    )

    if orientations.is_empty():
        var none_label: Label = Label.new()
        none_label.text = "No Charakoro trigger"
        none_label.modulate.a = 0.65
        add_child(none_label)
        return

    for orientation: StringName in orientations:
        var texture: Texture2D = (
            ICONS.load_kyokoro_icon(
                orientation
            )
        )

        if texture != null:
            var icon: TextureRect = TextureRect.new()
            icon.texture = texture
            icon.custom_minimum_size = Vector2(
                icon_size,
                icon_size
            )
            icon.expand_mode = (
                TextureRect.EXPAND_IGNORE_SIZE
            )
            icon.stretch_mode = (
                TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            )
            icon.tooltip_text = LocalizationService.tr_key(
                "orientation." + String(orientation),
                String(orientation).replace("_", " ").capitalize()
            )
            add_child(icon)
        else:
            var fallback: Label = Label.new()
            fallback.text = LocalizationService.tr_key(
                "orientation." + String(orientation),
                String(orientation).replace("_", " ").capitalize()
            )
            fallback.modulate.a = 0.78
            add_child(fallback)
