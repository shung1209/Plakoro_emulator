extends RefCounted


const THEME_FACTORY: Script = preload(
    "res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


static func style_page_title(
    label: Label
) -> void:
    if label == null:
        return

    label.add_theme_color_override(
        "font_color",
        THEME_FACTORY.COLOR_TEXT
    )


static func style_section_title(
    label: Label
) -> void:
    if label == null:
        return

    label.add_theme_color_override(
        "font_color",
        Color(
            0.820,
            0.885,
            1.000,
            1.0
        )
    )


static func style_muted(
    label: Label
) -> void:
    if label == null:
        return

    label.add_theme_color_override(
        "font_color",
        THEME_FACTORY.COLOR_TEXT_MUTED
    )


static func style_success(
    label: Label
) -> void:
    if label == null:
        return

    label.add_theme_color_override(
        "font_color",
        THEME_FACTORY.COLOR_SUCCESS
    )


static func style_danger(
    label: Label
) -> void:
    if label == null:
        return

    label.add_theme_color_override(
        "font_color",
        THEME_FACTORY.COLOR_DANGER
    )


static func create_accent_bar(
    height: float = 3.0
) -> ColorRect:
    var bar: ColorRect = ColorRect.new()
    bar.color = THEME_FACTORY.COLOR_ACCENT
    bar.custom_minimum_size = Vector2(
        0,
        height
    )
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return bar
