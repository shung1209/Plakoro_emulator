extends RefCounted


const THEME_WARM: String = "warm"
const THEME_DARK: String = "dark"
const SETTINGS_PATH: String = "user://ui_preferences.cfg"

# Dark palette intentionally uses stronger luminance separation between
# the canvas, panels, raised controls, and interactive states.  This keeps
# Dark Mode readable without turning the whole interface into one blue-black
# block.
const COLOR_BACKGROUND: Color = Color("090e18")
const COLOR_SURFACE: Color = Color("141d2d")
const COLOR_SURFACE_ELEVATED: Color = Color("22304a")
const COLOR_BORDER: Color = Color("425474")
const COLOR_BORDER_HOVER: Color = Color("7892bd")
const COLOR_TEXT: Color = Color("f3f7ff")
const COLOR_TEXT_MUTED: Color = Color("a9b6cc")
const COLOR_ACCENT: Color = Color("4da9ff")
const COLOR_HIGHLIGHT: Color = Color("f2c14e")
const COLOR_SUCCESS: Color = Color("4ed58a")
const COLOR_DANGER: Color = Color("ff6878")

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
const ENERKORO_COLOR_TYPES: Array[String] = [
	"fire",
	"water",
	"grass",
	"electric",
	"psychic",
	"fighting",
	"dark",
	"steel",
	"flying",
]
const DEFAULT_ENERKORO_COLORS: Array[String] = ["fire", "water", "grass"]

static var _enerkoro_colors_loaded: bool = false
static var _enerkoro_color_types: Array[String] = ["fire", "water", "grass"]


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


static func _load_enerkoro_color_preferences() -> void:
	if _enerkoro_colors_loaded:
		return
	_enerkoro_colors_loaded = true
	_enerkoro_color_types = DEFAULT_ENERKORO_COLORS.duplicate()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for index: int in range(3):
		var saved: String = str(
			config.get_value(
				"interface",
				"enerkoro_%d_color" % (index + 1),
				DEFAULT_ENERKORO_COLORS[index]
			)
		)
		if saved in ENERKORO_COLOR_TYPES:
			_enerkoro_color_types[index] = saved


static func get_enerkoro_color_type(index: int) -> String:
	_load_enerkoro_color_preferences()
	if index < 0 or index >= 3:
		return DEFAULT_ENERKORO_COLORS[0]
	return _enerkoro_color_types[index]


static func get_enerkoro_color_types() -> Array[String]:
	_load_enerkoro_color_preferences()
	return _enerkoro_color_types.duplicate()


static func set_enerkoro_color_type(index: int, color_type: String) -> void:
	if index < 0 or index >= 3:
		return
	if color_type not in ENERKORO_COLOR_TYPES:
		return
	_load_enerkoro_color_preferences()
	_enerkoro_color_types[index] = color_type
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(
		"interface",
		"enerkoro_%d_color" % (index + 1),
		color_type
	)
	config.save(SETTINGS_PATH)


static func get_enerkoro_background_color(color_type: StringName) -> Color:
	# Dark, saturated colors keep white Energy labels readable and match the
	# physical dice color shown by the battle roll presentation.
	match color_type:
		&"fire":
			return Color("7a2434")
		&"water":
			return Color("17517f")
		&"grass":
			return Color("265f3b")
		&"electric":
			return Color("6b5714")
		&"psychic":
			return Color("70275f")
		&"fighting":
			return Color("7b431f")
		&"dark":
			return Color("342a4f")
		&"steel":
			return Color("4f596b")
		&"flying":
			return Color("275b6b")
	return get_color("surface_elevated")


static func get_free_mode_allow_repeated_fixed_energy() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return false
	return bool(config.get_value("free_mode", "allow_repeated_fixed_energy", false))


static func set_free_mode_allow_repeated_fixed_energy(enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("free_mode", "allow_repeated_fixed_energy", enabled)
	config.save(SETTINGS_PATH)


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
			return WARM_HIGHLIGHT if warm else COLOR_HIGHLIGHT
		"success":
			return WARM_SUCCESS if warm else COLOR_SUCCESS
		"danger":
			return WARM_DANGER if warm else COLOR_DANGER
	return WARM_TEXT if warm else COLOR_TEXT


static func create_theme() -> Theme:
	var theme := Theme.new()
	if ThemeDB.fallback_font != null:
		theme.default_font = ThemeDB.fallback_font
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
	else:
		_apply_dark_scene_overrides(control)


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
		hover = Color("2d4162")
		pressed = Color("183858")
	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox(
			"normal", type_name,
			_panel_style(normal, get_color("border"), 10, 10)
		)
		var hover_style: StyleBoxFlat = _panel_style(
			hover, get_color("border_hover"), 10, 10
		)
		theme.set_stylebox("hover", type_name, hover_style)
		# Godot falls back to its built-in focus box when no focus style is
		# supplied, which creates a bright white rectangle after mouse,
		# keyboard, or gamepad focus. Reuse the normal hover treatment so
		# focus stays visible without adding a separate white outline.
		theme.set_stylebox("focus", type_name, hover_style.duplicate())
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
			theme, &"SecondaryButton", WARM_SURFACE_ELEVATED, WARM_TEXT
		)
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
	else:
		_configure_button_variant(
			theme, &"SecondaryButton", COLOR_SURFACE_ELEVATED, COLOR_TEXT
		)
		_configure_button_variant(
			theme, &"PrimaryButton", Color("245f9c"), COLOR_TEXT
		)
		_configure_button_variant(
			theme, &"BlueButton", Color("2b6fa8"), COLOR_TEXT
		)
		_configure_button_variant(
			theme, &"GreenButton", Color("287052"), COLOR_TEXT
		)
		_configure_button_variant(
			theme, &"YellowButton", Color("8a6b24"), COLOR_TEXT
		)
		_configure_button_variant(
			theme, &"DangerButton", Color("8f3848"), COLOR_TEXT
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
	# Focus uses the same visual language as hover instead of a separate
	# thick focus border, preventing the distracting white-frame effect.
	theme.set_stylebox(
		"focus", variation,
		_variant_button_style(background.lightened(0.09), true)
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
	var border_color: Color = WARM_TEXT if is_warm_theme() else COLOR_BORDER_HOVER
	var style: StyleBoxFlat = _panel_style(
		background, border_color, 12, 10
	)
	style.set_border_width_all(border_width)
	if with_shadow:
		style.shadow_color = (
			Color(WARM_TEXT, 0.48)
			if is_warm_theme()
			else Color(0.0, 0.0, 0.0, 0.48)
		)
		style.shadow_size = 2
		style.shadow_offset = Vector2(0, 3)
	return style


static func _configure_line_edits(theme: Theme) -> void:
	var normal: Color = get_color("surface") if is_warm_theme() else Color("0d1422")
	var focus: Color = get_color("surface_elevated") if is_warm_theme() else Color("17263d")
	theme.set_stylebox("normal", "LineEdit", _panel_style(normal, get_color("border"), 9, 9))
	theme.set_stylebox("focus", "LineEdit", _panel_style(focus, get_color("accent"), 9, 9))
	theme.set_color("font_color", "LineEdit", get_color("text"))
	theme.set_color("font_uneditable_color", "LineEdit", get_color("text_muted"))
	theme.set_color("caret_color", "LineEdit", get_color("accent"))
	theme.set_color("selection_color", "LineEdit", Color(get_color("accent"), 0.28))


static func _configure_progress_bars(theme: Theme) -> void:
	var track: Color = Color("c8c1b4") if is_warm_theme() else Color("0d1422")
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
	grabber.bg_color = Color(get_color("border_hover"), 0.58)
	grabber.set_corner_radius_all(5)
	var grabber_hover: StyleBoxFlat = grabber.duplicate()
	grabber_hover.bg_color = Color(get_color("accent"), 0.78)
	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(get_color("border"), 0.12)
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


static func _apply_dark_scene_overrides(node: Node) -> void:
	# Older scenes contain local dark StyleBox/ColorRect overrides.  Refresh
	# those local values into the new palette so they do not bypass the theme.
	if node is ColorRect:
		_apply_dark_color_rect(node as ColorRect)
	if node is PanelContainer:
		_apply_dark_panel(node as PanelContainer)
	if node is Label:
		_apply_dark_label(node as Label)
	if node is Button and not node is OptionButton:
		_apply_dark_button_role(node as Button)
	for child in node.get_children():
		_apply_dark_scene_overrides(child)


static func _apply_dark_color_rect(rect: ColorRect) -> void:
	var node_name: String = rect.name.to_lower()
	if "accent" in node_name:
		rect.color = COLOR_ACCENT
	elif "glow" in node_name:
		rect.color = Color(COLOR_ACCENT, 0.16)
	elif rect.color.get_luminance() < 0.16:
		rect.color = COLOR_BACKGROUND


static func _apply_dark_panel(panel: PanelContainer) -> void:
	if not panel.has_theme_stylebox_override("panel"):
		return
	var source: StyleBox = panel.get_theme_stylebox("panel")
	if not source is StyleBoxFlat:
		return
	var style: StyleBoxFlat = source.duplicate()
	if style.bg_color.get_luminance() >= 0.30:
		return
	var node_name: String = panel.name.to_lower()
	# Main windows stay on the middle surface; cards/popups sit one step higher.
	if _name_has_any(node_name, ["card", "popup", "window", "result", "status"]):
		style.bg_color = COLOR_SURFACE_ELEVATED
	else:
		style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_BORDER
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = maxi(style.shadow_size, 12)
	panel.add_theme_stylebox_override("panel", style)


static func _apply_dark_label(label: Label) -> void:
	if not label.has_theme_color_override("font_color"):
		return
	var original: Color = label.get_theme_color("font_color")
	var node_name: String = label.name.to_lower()
	if "brand" in node_name:
		label.add_theme_color_override("font_color", COLOR_ACCENT)
	elif original.get_luminance() > 0.72:
		label.add_theme_color_override("font_color", COLOR_TEXT)
	elif original.get_luminance() > 0.35:
		label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)


static func _apply_dark_button_role(button: Button) -> void:
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
