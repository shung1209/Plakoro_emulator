extends CanvasLayer


const SHOW_DELAY_MSEC: int = 850
const PANEL_MINIMUM_SIZE: Vector2 = Vector2(520.0, 300.0)
const NOTO_SANS_JP: Font = preload(
	"res://assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf"
)
const NOTO_SANS_TC: Font = preload(
	"res://assets/fonts/NotoSansTC/NotoSansTC-Regular.ttf"
)


var overlay: ColorRect
var warning_panel: PanelContainer
var title_label: Label
var message_label: Label
var retry_button: Button
var mismatch_since_msec: int = -1
var required_orientation: StringName = &""


func _ready() -> void:
	layer = 200
	_build_overlay()
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var next_requirement: StringName = get_required_orientation(
		DisplayServer.window_get_size(),
		OS.has_feature("web"),
		DisplayServer.is_touchscreen_available(),
		GameFlow.phone_mode,
		GameFlow.landscape_mode
	)
	if next_requirement != required_orientation:
		required_orientation = next_requirement
		mismatch_since_msec = -1
		_apply_localized_text()
	if required_orientation == &"":
		mismatch_since_msec = -1
		overlay.visible = false
		return

	var now_msec: int = Time.get_ticks_msec()
	if mismatch_since_msec < 0:
		mismatch_since_msec = now_msec
		overlay.visible = false
		return
	_fit_warning_panel(DisplayServer.window_get_size())
	overlay.visible = now_msec - mismatch_since_msec >= SHOW_DELAY_MSEC


func should_require_rotation(
	display_size: Vector2i,
	web_enabled: bool,
	touchscreen_available: bool,
	phone_enabled: bool,
	landscape_enabled: bool = false
) -> bool:
	return get_required_orientation(
		display_size,
		web_enabled,
		touchscreen_available,
		phone_enabled,
		landscape_enabled
	) != &""


func get_required_orientation(
	display_size: Vector2i,
	web_enabled: bool,
	touchscreen_available: bool,
	phone_enabled: bool,
	landscape_enabled: bool
) -> StringName:
	if not web_enabled or not touchscreen_available:
		return &""
	if phone_enabled and display_size.x > display_size.y:
		return &"portrait"
	if landscape_enabled and display_size.y > display_size.x:
		return &"landscape"
	return &""


func _fit_warning_panel(display_size: Vector2i) -> void:
	if warning_panel == null:
		return
	warning_panel.custom_minimum_size = Vector2(
		minf(PANEL_MINIMUM_SIZE.x, maxf(300.0, display_size.x - 40.0)),
		minf(PANEL_MINIMUM_SIZE.y, maxf(240.0, display_size.y - 40.0))
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

	warning_panel = PanelContainer.new()
	warning_panel.custom_minimum_size = PANEL_MINIMUM_SIZE
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color("17233a")
	panel_style.border_color = Color("5baef4")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	warning_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(warning_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 32)
	warning_panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("f4c84a"))
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_font_override("font", _localized_font())
	content.add_child(title_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("f4f7ff"))
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_font_override("font", _localized_font())
	content.add_child(message_label)

	retry_button = Button.new()
	retry_button.custom_minimum_size = Vector2(0.0, 64.0)
	retry_button.add_theme_font_size_override("font_size", 20)
	retry_button.add_theme_font_override("font", _localized_font())
	retry_button.pressed.connect(_on_retry_pressed)
	content.add_child(retry_button)


func _apply_localized_text() -> void:
	if title_label == null or message_label == null or retry_button == null:
		return
	var landscape_required: bool = required_orientation == &"landscape"
	title_label.text = LocalizationService.tr_key(
		"landscape_mode.rotate_title"
		if landscape_required
		else "phone_mode.rotate_title",
		"ROTATE TO LANDSCAPE"
		if landscape_required
		else "ROTATE YOUR PHONE"
	)
	message_label.text = LocalizationService.tr_key(
		"landscape_mode.rotate_message"
		if landscape_required
		else "phone_mode.rotate_message",
		"Turn your phone sideways. If it does not rotate automatically, retry fullscreen landscape mode."
		if landscape_required
		else "Turn your phone upright. If it does not rotate automatically, retry fullscreen portrait mode."
	)
	retry_button.text = LocalizationService.tr_key(
		"landscape_mode.rotate_retry"
		if landscape_required
		else "phone_mode.rotate_retry",
		"FULLSCREEN & LANDSCAPE"
		if landscape_required
		else "FULLSCREEN & RETRY"
	)
	var font: Font = _localized_font()
	for control: Control in [title_label, message_label, retry_button]:
		control.add_theme_font_override("font", font)


func _on_retry_pressed() -> void:
	mismatch_since_msec = Time.get_ticks_msec()
	overlay.visible = false
	GameFlow.request_current_orientation()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()


func _localized_font() -> Font:
	return (
		NOTO_SANS_JP
		if LocalizationService.get_current_locale() == "ja_JP"
		else NOTO_SANS_TC
	)
