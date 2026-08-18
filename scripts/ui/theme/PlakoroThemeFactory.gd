extends RefCounted


const THEME_WARM: String = "warm"
const THEME_DARK: String = "dark"
const SETTINGS_PATH: String = "user://ui_preferences.cfg"

# Legacy dark constants are kept for older custom widgets.
const COLOR_BACKGROUND: Color = Color(0.027, 0.034, 0.050, 1.0)
const COLOR_SURFACE: Color = Color(0.055, 0.067, 0.092, 0.98)
const COLOR_SURFACE_ELEVATED: Color = Color(0.075, 0.089, 0.120, 0.99)
const COLOR_BORDER: Color = Color(0.235, 0.278, 0.350, 1.0)
const COLOR_BORDER_HOVER: Color = Color(0.400, 0.475, 0.590, 1.0)
const COLOR_TEXT: Color = Color(0.965, 0.970, 0.985, 1.0)
const COLOR_TEXT_MUTED: Color = Color(0.690, 0.720, 0.790, 1.0)
const COLOR_ACCENT: Color = Color(0.300, 0.680, 0.950, 1.0)
const COLOR_SUCCESS: Color = Color(0.330, 0.800, 0.530, 1.0)
const COLOR_DANGER: Color = Color(0.920, 0.390, 0.400, 1.0)

const WARM_BACKGROUND: Color = Color("d8d2c5")
const WARM_SURFACE: Color = Color("ebe6dc")
const WARM_SURFACE_ELEVATED: Color = Color("e1d9c7")
const WARM_BORDER: Color = Color("b8ae9b")
const WARM_BORDER_HOVER: Color = Color("9da8b8")
const WARM_TEXT: Color = Color("273047")
const WARM_TEXT_MUTED: Color = Color("596176")
const WARM_ACCENT: Color = Color("326b9f")
const WARM_HIGHLIGHT: Color = Color("d8ae22")
const WARM_SUCCESS: Color = Color("468b66")
const WARM_DANGER: Color = Color("c94a42")

static var _theme_mode: String = ""


static func get_theme_mode() -> String:
	if _theme_mode.is_empty():
		_theme_mode = THEME_WARM
		var config := ConfigFile.new()
		if config.load(SETTINGS_PATH) == OK:
			var saved_mode: String = str(
				config.get_value("interface", "theme", THEME_WARM)
			)
			if saved_mode in [THEME_WARM, THEME_DARK]:
				_theme_mode = saved_mode
	return _theme_mode


static func set_theme_mode(mode: String) -> void:
	if mode not in [THEME_WARM, THEME_DARK]:
		return
	_theme_mode = mode
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("interface", "theme", mode)
	config.save(SETTINGS_PATH)


static func is_warm_theme() -> bool:
	return get_theme_mode() == THEME_WARM


static func get_color(color_name: String) -> Color:
	var warm: bool = is_warm_theme()
	match color_name:
		"background":
			return WARM_BACKGROUND if warm else COLOR_BACKGROUND
		"surface":
			return WARM_SURFACE if warm else COLOR_SURFACE
		"surface_elevated":
			return WARM_SURFACE_ELEVATED if warm else COLOR_SURFACE_ELEVATED
		"border":
			return WARM_BORDER if warm else COLOR_BORDER
		"border_hover":
			return WARM_BORDER_HOVER if warm else COLOR_BORDER_HOVER
		"text":
			return WARM_TEXT if warm else COLOR_TEXT
		"text_muted":
			return WARM_TEXT_MUTED if warm else COLOR_TEXT_MUTED
		"accent":
			return WARM_ACCENT if warm else COLOR_ACCENT
		"highlight":
			return WARM_HIGHLIGHT if warm else COLOR_ACCENT
		"success":
			return WARM_SUCCESS if warm else COLOR_SUCCESS
		"danger":
			return WARM_DANGER if warm else COLOR_DANGER
	return WARM_TEXT if warm else COLOR_TEXT


static func create_theme() -> Theme:
	var theme := Theme.new()
	_configure_default_font_colors(theme)
	_configure_panels(theme)
	_configure_buttons(theme)
	_configure_line_edits(theme)
	_configure_progress_bars(theme)
	_configure_separators(theme)
	_configure_scrollbars(theme)
	_configure_tooltips(theme)
	return theme


static func apply_to(control: Control) -> void:
	if control == null:
		return
	control.theme = create_theme()
	if is_warm_theme():
		_apply_warm_scene_overrides(control)


static func _configure_default_font_colors(theme: Theme) -> void:
	var text_color: Color = get_color("text")
	var muted_color: Color = get_color("text_muted")
	for type_name in ["Label", "RichTextLabel", "Button", "OptionButton", "CheckBox"]:
		theme.set_color("font_color", type_name, text_color)
		theme.set_color("font_disabled_color", type_name, Color(muted_color, 0.58))
	for type_name in ["Button", "OptionButton", "CheckBox"]:
		theme.set_color("font_hover_color", type_name, text_color)
		theme.set_color("font_pressed_color", type_name, text_color)
		theme.set_color("font_focus_color", type_name, text_color)


static func _configure_panels(theme: Theme) -> void:
	var dialog_panel: StyleBoxFlat = _panel_style(
		get_color("surface"), get_color("border"), 12, 16
	)
	for type_name in ["AcceptDialog", "ConfirmationDialog"]:
		theme.set_stylebox("panel", type_name, dialog_panel)
	theme.set_stylebox(
		"panel", "PanelContainer",
		_panel_style(get_color("surface"), get_color("border"), 12, 12)
	)
	theme.set_stylebox(
		"panel", "PopupPanel",
		_panel_style(get_color("surface"), get_color("border"), 12, 12)
	)


static func _configure_buttons(theme: Theme) -> void:
	var normal: Color = get_color("surface_elevated")
	var hover: Color
	var pressed: Color
	if is_warm_theme():
		hover = Color("d7cdaF")
		pressed = Color("cbbd98")
	else:
		hover = Color(0.095, 0.125, 0.170, 1.0)
		pressed = Color(0.070, 0.105, 0.150, 1.0)
	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox(
			"normal", type_name,
			_panel_style(normal, get_color("border"), 10, 10)
		)
		theme.set_stylebox(
			"hover", type_name,
			_panel_style(hover, get_color("border_hover"), 10, 10)
		)
		theme.set_stylebox(
			"pressed", type_name,
			_panel_style(pressed, get_color("accent"), 10, 10)
		)
		theme.set_stylebox(
			"disabled", type_name,
			_panel_style(
				Color(get_color("surface"), 0.58),
				Color(get_color("border"), 0.55), 10, 10
			)
		)
		theme.set_constant("outline_size", type_name, 0)
	if is_warm_theme():
		_configure_button_variant(
			theme, &"PrimaryButton", Color("c9574f"), Color.WHITE
		)
		_configure_button_variant(
			theme, &"BlueButton", Color("477ead"), Color.WHITE
		)
		_configure_button_variant(
			theme, &"GreenButton", Color("558a6e"), Color.WHITE
		)
		_configure_button_variant(
			theme, &"YellowButton", Color("c5a23b"), WARM_TEXT
		)
		_configure_button_variant(
			theme, &"DangerButton", Color("a94b55"), Color.WHITE
		)


static func _configure_button_variant(
	theme: Theme,
	variation: StringName,
	background: Color,
	text_color: Color
) -> void:
	theme.set_type_variation(variation, &"Button")
	theme.set_stylebox(
		"normal", variation,
		_variant_button_style(background, true)
	)
	theme.set_stylebox(
		"hover", variation,
		_variant_button_style(background.lightened(0.09), true)
	)
	theme.set_stylebox(
		"pressed", variation,
		_variant_button_style(background.darkened(0.10), false)
	)
	theme.set_stylebox(
		"focus", variation,
		_variant_button_style(background.lightened(0.06), true, 3)
	)
	for color_name in [
		"font_color", "font_hover_color", "font_pressed_color",
		"font_focus_color"
	]:
		theme.set_color(color_name, variation, text_color)
	theme.set_color(
		"font_disabled_color", variation,
		Color(text_color, 0.48)
	)


static func _variant_button_style(
	background: Color,
	with_shadow: bool,
	border_width: int = 2
) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel_style(
		background, WARM_TEXT, 12, 10
	)
	style.set_border_width_all(border_width)
	if with_shadow:
		style.shadow_color = Color(WARM_TEXT, 0.48)
		style.shadow_size = 2
		style.shadow_offset = Vector2(0, 3)
	return style


static func _configure_line_edits(theme: Theme) -> void:
	var normal: Color = get_color("surface") if is_warm_theme() else Color(0.035, 0.043, 0.062, 1.0)
	var focus: Color = get_color("surface_elevated") if is_warm_theme() else Color(0.040, 0.050, 0.072, 1.0)
	theme.set_stylebox("normal", "LineEdit", _panel_style(normal, get_color("border"), 9, 9))
	theme.set_stylebox("focus", "LineEdit", _panel_style(focus, get_color("accent"), 9, 9))
	theme.set_color("font_color", "LineEdit", get_color("text"))
	theme.set_color("font_uneditable_color", "LineEdit", get_color("text_muted"))
	theme.set_color("caret_color", "LineEdit", get_color("accent"))
	theme.set_color("selection_color", "LineEdit", Color(get_color("accent"), 0.28))


static func _configure_progress_bars(theme: Theme) -> void:
	var track: Color = Color("c8c1b4") if is_warm_theme() else Color(0.035, 0.042, 0.058, 1.0)
	theme.set_stylebox(
		"background", "ProgressBar",
		_panel_style(track, Color(get_color("border"), 0.7), 7, 2)
	)
	var fill := StyleBoxFlat.new()
	fill.bg_color = get_color("accent")
	fill.set_corner_radius_all(7)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_color("font_color", "ProgressBar", get_color("text"))


static func _configure_separators(theme: Theme) -> void:
	var separator := StyleBoxLine.new()
	separator.color = Color(get_color("border"), 0.85)
	separator.thickness = 1
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_stylebox("separator", "VSeparator", separator)


static func _configure_scrollbars(theme: Theme) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(get_color("border_hover"), 0.9)
	grabber.set_corner_radius_all(5)
	var grabber_hover: StyleBoxFlat = grabber.duplicate()
	grabber_hover.bg_color = get_color("accent")
	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(get_color("border"), 0.38)
	scroll.set_corner_radius_all(5)
	for type_name in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type_name, scroll)
		theme.set_stylebox("grabber", type_name, grabber)
		theme.set_stylebox("grabber_highlight", type_name, grabber_hover)
		theme.set_stylebox("grabber_pressed", type_name, grabber_hover)


static func _configure_tooltips(theme: Theme) -> void:
	theme.set_stylebox(
		"panel", "TooltipPanel",
		_panel_style(get_color("surface"), get_color("border_hover"), 10, 12)
	)
	theme.set_color("font_color", "TooltipLabel", get_color("text"))
	theme.set_font_size("font_size", "TooltipLabel", 16)


static func _apply_warm_scene_overrides(node: Node) -> void:
	if node is ColorRect:
		_apply_warm_color_rect(node as ColorRect)
	if node is PanelContainer:
		_apply_warm_panel(node as PanelContainer)
	if node is Label:
		_apply_warm_label(node as Label)
	if node is Button and not node is OptionButton:
		_apply_warm_button_role(node as Button)
	for child in node.get_children():
		_apply_warm_scene_overrides(child)


static func _apply_warm_color_rect(rect: ColorRect) -> void:
	var node_name: String = rect.name.to_lower()
	if "accent" in node_name:
		rect.color = WARM_HIGHLIGHT
	elif "glow" in node_name:
		rect.color = Color(0.73, 0.64, 0.34, 0.24)
	elif rect.color.get_luminance() < 0.22:
		rect.color = WARM_BACKGROUND


static func _apply_warm_panel(panel: PanelContainer) -> void:
	if not panel.has_theme_stylebox_override("panel"):
		return
	var source: StyleBox = panel.get_theme_stylebox("panel")
	if not source is StyleBoxFlat:
		return
	var style: StyleBoxFlat = source.duplicate()
	if style.bg_color.get_luminance() >= 0.35:
		return
	style.bg_color = WARM_SURFACE
	style.border_color = WARM_BORDER
	style.shadow_color = Color(0.11, 0.15, 0.25, 0.12)
	style.shadow_size = mini(style.shadow_size, 10)
	panel.add_theme_stylebox_override("panel", style)


static func _apply_warm_label(label: Label) -> void:
	if not label.has_theme_color_override("font_color"):
		return
	var original: Color = label.get_theme_color("font_color")
	var node_name: String = label.name.to_lower()
	if "brand" in node_name:
		label.add_theme_color_override("font_color", WARM_ACCENT)
	elif original.get_luminance() > 0.82:
		label.add_theme_color_override("font_color", WARM_TEXT)
	elif original.b > 0.55 and original.get_luminance() > 0.42:
		label.add_theme_color_override("font_color", WARM_TEXT_MUTED)


static func _apply_warm_button_role(button: Button) -> void:
	var node_name: String = button.name.to_lower()
	if _name_has_any(node_name, [
		"start", "play", "continue", "confirm", "apply", "encounters"
	]):
		button.theme_type_variation = &"PrimaryButton"
	elif _name_has_any(node_name, [
		"edit", "save", "newbutton", "add", "free"
	]):
		button.theme_type_variation = &"GreenButton"
	elif _name_has_any(node_name, [
		"configure", "setup", "open", "load", "preparation",
		"contentstudio"
	]):
		button.theme_type_variation = &"BlueButton"
	elif _name_has_any(node_name, [
		"refresh", "reset", "restart", "rematch", "validate",
		"duplicate", "restore"
	]):
		button.theme_type_variation = &"YellowButton"
	elif _name_has_any(node_name, [
		"delete", "remove", "discard", "clear", "quit"
	]):
		button.theme_type_variation = &"DangerButton"


static func _name_has_any(node_name: String, needles: Array) -> bool:
	for needle: String in needles:
		if needle in node_name:
			return true
	return false


static func _panel_style(
	background: Color,
	border: Color,
	radius: int,
	padding: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style
