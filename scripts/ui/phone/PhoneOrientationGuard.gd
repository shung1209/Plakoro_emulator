extends CanvasLayer


const SHOW_DELAY_MSEC: int = 850
const PANEL_MINIMUM_SIZE: Vector2 = Vector2(520.0, 300.0)


var overlay: ColorRect
var title_label: Label
var message_label: Label
var retry_button: Button
var landscape_since_msec: int = -1


func _ready() -> void:
	layer = 200
	_build_overlay()
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var needs_rotation: bool = should_require_rotation(
		DisplayServer.window_get_size(),
		OS.has_feature("web"),
		DisplayServer.is_touchscreen_available(),
		GameFlow.phone_mode
	)
	if not needs_rotation:
		landscape_since_msec = -1
		overlay.visible = false
		return

	var now_msec: int = Time.get_ticks_msec()
	if landscape_since_msec < 0:
		landscape_since_msec = now_msec
		overlay.visible = false
		return
	overlay.visible = now_msec - landscape_since_msec >= SHOW_DELAY_MSEC


func should_require_rotation(
	display_size: Vector2i,
	web_enabled: bool,
	touchscreen_available: bool,
	phone_enabled: bool
) -> bool:
	return (
		web_enabled
		and touchscreen_available
		and phone_enabled
		and display_size.x > display_size.y
	)


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.name = "PhoneRotateOverlay"
	overlay.color = Color(0.025, 0.04, 0.075, 0.94)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = PANEL_MINIMUM_SIZE
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color("17233a")
	panel_style.border_color = Color("5baef4")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("f4c84a"))
	title_label.add_theme_font_size_override("font_size", 32)
	content.add_child(title_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("f4f7ff"))
	message_label.add_theme_font_size_override("font_size", 20)
	content.add_child(message_label)

	retry_button = Button.new()
	retry_button.custom_minimum_size = Vector2(0.0, 64.0)
	retry_button.add_theme_font_size_override("font_size", 20)
	retry_button.pressed.connect(_on_retry_pressed)
	content.add_child(retry_button)


func _apply_localized_text() -> void:
	title_label.text = LocalizationService.tr_key(
		"phone_mode.rotate_title", "ROTATE YOUR PHONE"
	)
	message_label.text = LocalizationService.tr_key(
		"phone_mode.rotate_message",
		"Turn your phone upright. If it does not rotate automatically, retry fullscreen portrait mode."
	)
	retry_button.text = LocalizationService.tr_key(
		"phone_mode.rotate_retry", "FULLSCREEN & RETRY"
	)


func _on_retry_pressed() -> void:
	landscape_since_msec = Time.get_ticks_msec()
	overlay.visible = false
	GameFlow.request_phone_orientation()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
