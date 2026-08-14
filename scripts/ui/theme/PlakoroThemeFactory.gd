extends RefCounted


const COLOR_BACKGROUND: Color = Color(
    0.027,
    0.034,
    0.050,
    1.0
)

const COLOR_SURFACE: Color = Color(
    0.055,
    0.067,
    0.092,
    0.98
)

const COLOR_SURFACE_ELEVATED: Color = Color(
    0.075,
    0.089,
    0.120,
    0.99
)

const COLOR_BORDER: Color = Color(
    0.235,
    0.278,
    0.350,
    1.0
)

const COLOR_BORDER_HOVER: Color = Color(
    0.400,
    0.475,
    0.590,
    1.0
)

const COLOR_TEXT: Color = Color(
    0.965,
    0.970,
    0.985,
    1.0
)

const COLOR_TEXT_MUTED: Color = Color(
    0.690,
    0.720,
    0.790,
    1.0
)

const COLOR_ACCENT: Color = Color(
    0.300,
    0.680,
    0.950,
    1.0
)

const COLOR_SUCCESS: Color = Color(
    0.330,
    0.800,
    0.530,
    1.0
)

const COLOR_DANGER: Color = Color(
    0.920,
    0.390,
    0.400,
    1.0
)


static func create_theme() -> Theme:
    var theme: Theme = Theme.new()

    _configure_default_font_colors(
        theme
    )
    _configure_panels(
        theme
    )
    _configure_buttons(
        theme
    )
    _configure_line_edits(
        theme
    )
    _configure_progress_bars(
        theme
    )
    _configure_separators(
        theme
    )
    _configure_scrollbars(
        theme
    )
    _configure_tooltips(
        theme
    )

    return theme


static func apply_to(
    control: Control
) -> void:
    if control == null:
        return

    control.theme = create_theme()


static func _configure_default_font_colors(
    theme: Theme
) -> void:
    theme.set_color(
        "font_color",
        "Label",
        COLOR_TEXT
    )
    theme.set_color(
        "font_disabled_color",
        "Label",
        COLOR_TEXT_MUTED
    )

    theme.set_color(
        "font_color",
        "Button",
        COLOR_TEXT
    )
    theme.set_color(
        "font_hover_color",
        "Button",
        Color.WHITE
    )
    theme.set_color(
        "font_pressed_color",
        "Button",
        Color.WHITE
    )
    theme.set_color(
        "font_disabled_color",
        "Button",
        Color(
            COLOR_TEXT_MUTED,
            0.55
        )
    )


static func _configure_panels(
    theme: Theme
) -> void:
    theme.set_stylebox(
        "panel",
        "PanelContainer",
        _panel_style(
            COLOR_SURFACE,
            COLOR_BORDER,
            10,
            12
        )
    )


static func _configure_buttons(
    theme: Theme
) -> void:
    theme.set_stylebox(
        "normal",
        "Button",
        _panel_style(
            COLOR_SURFACE_ELEVATED,
            COLOR_BORDER,
            8,
            10
        )
    )

    theme.set_stylebox(
        "hover",
        "Button",
        _panel_style(
            Color(
                0.095,
                0.125,
                0.170,
                1.0
            ),
            COLOR_BORDER_HOVER,
            8,
            10
        )
    )

    theme.set_stylebox(
        "pressed",
        "Button",
        _panel_style(
            Color(
                0.070,
                0.105,
                0.150,
                1.0
            ),
            COLOR_ACCENT,
            8,
            10
        )
    )

    theme.set_stylebox(
        "disabled",
        "Button",
        _panel_style(
            Color(
                COLOR_SURFACE,
                0.55
            ),
            Color(
                COLOR_BORDER,
                0.35
            ),
            8,
            10
        )
    )

    theme.set_constant(
        "outline_size",
        "Button",
        0
    )


static func _configure_line_edits(
    theme: Theme
) -> void:
    theme.set_stylebox(
        "normal",
        "LineEdit",
        _panel_style(
            Color(
                0.035,
                0.043,
                0.062,
                1.0
            ),
            COLOR_BORDER,
            7,
            9
        )
    )
    theme.set_stylebox(
        "focus",
        "LineEdit",
        _panel_style(
            Color(
                0.040,
                0.050,
                0.072,
                1.0
            ),
            COLOR_ACCENT,
            7,
            9
        )
    )
    theme.set_color(
        "font_color",
        "LineEdit",
        COLOR_TEXT
    )
    theme.set_color(
        "font_uneditable_color",
        "LineEdit",
        COLOR_TEXT_MUTED
    )


static func _configure_progress_bars(
    theme: Theme
) -> void:
    theme.set_stylebox(
        "background",
        "ProgressBar",
        _panel_style(
            Color(
                0.035,
                0.042,
                0.058,
                1.0
            ),
            Color(
                COLOR_BORDER,
                0.55
            ),
            6,
            2
        )
    )

    var fill: StyleBoxFlat = StyleBoxFlat.new()
    fill.bg_color = COLOR_ACCENT
    fill.corner_radius_top_left = 6
    fill.corner_radius_top_right = 6
    fill.corner_radius_bottom_left = 6
    fill.corner_radius_bottom_right = 6

    theme.set_stylebox(
        "fill",
        "ProgressBar",
        fill
    )
    theme.set_color(
        "font_color",
        "ProgressBar",
        COLOR_TEXT
    )


static func _configure_separators(
    theme: Theme
) -> void:
    var separator: StyleBoxLine = StyleBoxLine.new()
    separator.color = Color(
        COLOR_BORDER,
        0.65
    )
    separator.thickness = 1

    theme.set_stylebox(
        "separator",
        "HSeparator",
        separator
    )


static func _configure_scrollbars(
    theme: Theme
) -> void:
    var grabber: StyleBoxFlat = StyleBoxFlat.new()
    grabber.bg_color = Color(
        COLOR_BORDER_HOVER,
        0.72
    )
    grabber.corner_radius_top_left = 5
    grabber.corner_radius_top_right = 5
    grabber.corner_radius_bottom_left = 5
    grabber.corner_radius_bottom_right = 5

    var grabber_hover: StyleBoxFlat = (
        grabber.duplicate()
    )
    grabber_hover.bg_color = COLOR_ACCENT

    var scroll: StyleBoxFlat = StyleBoxFlat.new()
    scroll.bg_color = Color(
        0.020,
        0.026,
        0.038,
        0.72
    )
    scroll.corner_radius_top_left = 5
    scroll.corner_radius_top_right = 5
    scroll.corner_radius_bottom_left = 5
    scroll.corner_radius_bottom_right = 5

    theme.set_stylebox(
        "scroll",
        "VScrollBar",
        scroll
    )
    theme.set_stylebox(
        "grabber",
        "VScrollBar",
        grabber
    )
    theme.set_stylebox(
        "grabber_highlight",
        "VScrollBar",
        grabber_hover
    )
    theme.set_stylebox(
        "grabber_pressed",
        "VScrollBar",
        grabber_hover
    )

    theme.set_stylebox(
        "scroll",
        "HScrollBar",
        scroll
    )
    theme.set_stylebox(
        "grabber",
        "HScrollBar",
        grabber
    )
    theme.set_stylebox(
        "grabber_highlight",
        "HScrollBar",
        grabber_hover
    )
    theme.set_stylebox(
        "grabber_pressed",
        "HScrollBar",
        grabber_hover
    )


static func _configure_tooltips(
    theme: Theme
) -> void:
    theme.set_stylebox(
        "panel",
        "TooltipPanel",
        _panel_style(
            Color(
                0.020,
                0.025,
                0.035,
                0.995
            ),
            COLOR_BORDER_HOVER,
            8,
            12
        )
    )

    theme.set_color(
        "font_color",
        "TooltipLabel",
        COLOR_TEXT
    )
    theme.set_font_size(
        "font_size",
        "TooltipLabel",
        16
    )


static func _panel_style(
    background: Color,
    border: Color,
    radius: int,
    padding: int
) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()

    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)

    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius

    style.content_margin_left = padding
    style.content_margin_right = padding
    style.content_margin_top = padding
    style.content_margin_bottom = padding

    return style
