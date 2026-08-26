extends Control


const DISPLAY_VERSION: String = "V2.3"

const QUIT_DIALOG_LAYOUT: Script = preload(
	"res://scripts/ui/QuitConfirmationLayout.gd"
)


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)
const TITLE_WARM: Texture2D = preload(
	"res://assets/ui/brand/plakoro_adventures_warm.png"
)
const TITLE_DARK: Texture2D = preload(
	"res://assets/ui/brand/plakoro_adventures_dark.png"
)


@onready var title_label: TextureRect = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var theme_option: OptionButton = %ThemeOption
@onready var play_button: Button = %PlayButton
@onready var content_studio_button: Button = %ContentStudioButton
@onready var free_mode_button: Button = %FreeModeButton
@onready var phone_mode_button: Button = %PhoneModeButton
@onready var unsealed_label: Label = %UnsealedLabel
@onready var quit_button: Button = %QuitButton
@onready var delete_save_button: Button = %DeleteSaveButton
@onready var delete_status_label: Label = %DeleteStatusLabel
@onready var version_label: Label = %VersionLabel
@onready var quit_confirmation: ConfirmationDialog = %QuitConfirmation
@onready var delete_save_confirmation: ConfirmationDialog = %DeleteSaveConfirmation
@onready var top_bar: HBoxContainer = $TopBar
@onready var center: CenterContainer = $Center
@onready var menu_panel: PanelContainer = $Center/MenuPanel
@onready var menu_margin: MarginContainer = $Center/MenuPanel/Margin
@onready var menu: VBoxContainer = $Center/MenuPanel/Margin/Menu
@onready var accent: ColorRect = $Center/MenuPanel/Margin/Menu/Accent
@onready var menu_spacer: Control = $Center/MenuPanel/Margin/Menu/Spacer
@onready var footer_spacer: Control = $Center/MenuPanel/Margin/Menu/FooterSpacer
@onready var language_option: OptionButton = (
	$TopBar/LanguageSelector/LanguageOption
)


var leaving_menu: bool = false


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	_setup_theme_option()
	_setup_web_controls()
	play_button.pressed.connect(_start_story_mode)
	content_studio_button.pressed.connect(_open_content_studio)
	free_mode_button.pressed.connect(_start_free_mode)
	phone_mode_button.pressed.connect(_start_phone_mode)
	quit_button.pressed.connect(_request_quit)
	delete_save_button.pressed.connect(_request_delete_save)
	quit_confirmation.confirmed.connect(_confirm_quit)
	delete_save_confirmation.confirmed.connect(_confirm_delete_save)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	ContentStudioAccess.content_studio_unsealed.connect(
		_on_content_studio_unsealed
	)
	_apply_localized_text()
	_refresh_save_actions()
	_refresh_content_studio_access()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	play_button.grab_focus()


func _apply_responsive_layout() -> void:
	if leaving_menu:
		return
	var display_size: Vector2i = DisplayServer.window_get_size()
	_apply_web_main_menu_scale(
		display_size,
		OS.has_feature("web"),
		DisplayServer.is_touchscreen_available()
	)
	var viewport_size: Vector2 = get_viewport_rect().size
	var handheld: bool = (
		OS.has_feature("mobile")
		or DisplayServer.is_touchscreen_available()
		or viewport_size.x < 760.0
	)
	_apply_main_menu_layout(
		viewport_size,
		handheld and display_size.x > display_size.y,
		OS.has_feature("web")
	)


func _apply_web_main_menu_scale(
	display_size: Vector2i,
	web_enabled: bool,
	touchscreen_available: bool
) -> void:
	if not web_enabled:
		return
	var target_size: Vector2i = Vector2i(1920, 1080)
	if display_size.y > display_size.x:
		target_size = Vector2i(480, 900)
	elif touchscreen_available:
		target_size = Vector2i(900, 480)
	var window: Window = get_window()
	if window == null or window.content_scale_size == target_size:
		return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = target_size


func _apply_main_menu_layout(
	viewport_size: Vector2,
	compact_landscape: bool,
	web_touch_style: bool = false
) -> void:
	var narrow_portrait: bool = (
		not compact_landscape
		and viewport_size.x < 760.0
	)
	var short_web_portrait: bool = (
		web_touch_style
		and narrow_portrait
		and viewport_size.y < 760.0
	)
	var horizontal_margin: int = 58
	var vertical_margin: int = 38
	var panel_size: Vector2 = Vector2(560, 590)
	var title_height: float = 78.0
	var menu_separation: int = 13
	var show_supporting_text: bool = true

	if compact_landscape:
		horizontal_margin = 24
		vertical_margin = 16
		panel_size = Vector2(
			minf(760.0, viewport_size.x - 32.0),
			minf(380.0, viewport_size.y - 72.0)
		)
		title_height = 50.0
		menu_separation = 7
		show_supporting_text = false
		_set_full_rect_offsets(center, 16.0, 58.0, -16.0, -10.0)
		_set_full_rect_offsets(top_bar, 16.0, 12.0, -16.0, 52.0)
	elif narrow_portrait:
		horizontal_margin = 28
		vertical_margin = 28
		panel_size = Vector2(
			maxf(320.0, viewport_size.x - 28.0),
			minf(620.0, viewport_size.y - 118.0)
		)
		title_height = 68.0
		menu_separation = 11
		_set_full_rect_offsets(center, 14.0, 72.0, -14.0, -24.0)
		_set_full_rect_offsets(top_bar, 14.0, 14.0, -14.0, 58.0)
	else:
		_set_full_rect_offsets(center, 24.0, 82.0, -24.0, -58.0)
		_set_full_rect_offsets(top_bar, 28.0, 24.0, -28.0, 70.0)

	if web_touch_style and not compact_landscape:
		horizontal_margin = 28 if narrow_portrait else 32
		vertical_margin = 34
		panel_size.x = (
			maxf(300.0, minf(440.0, viewport_size.x - 40.0))
			if narrow_portrait
			else 560.0
		)
		panel_size.y = minf(
			650.0 if narrow_portrait else 720.0,
			viewport_size.y - 118.0
		)
		title_height = 68.0 if narrow_portrait else 78.0
		menu_separation = 18 if narrow_portrait else 16
	if short_web_portrait:
		horizontal_margin = 22
		vertical_margin = 20
		panel_size.y = maxf(420.0, viewport_size.y - 100.0)
		title_height = 54.0
		menu_separation = 10
		show_supporting_text = false

	menu_panel.custom_minimum_size = panel_size
	menu_margin.add_theme_constant_override("margin_left", horizontal_margin)
	menu_margin.add_theme_constant_override("margin_top", vertical_margin)
	menu_margin.add_theme_constant_override("margin_right", horizontal_margin)
	menu_margin.add_theme_constant_override("margin_bottom", vertical_margin)
	menu.add_theme_constant_override("separation", menu_separation)
	accent.custom_minimum_size.y = 6.0 if web_touch_style else 5.0
	title_label.custom_minimum_size.y = title_height
	subtitle_label.visible = show_supporting_text
	menu_spacer.visible = show_supporting_text
	footer_spacer.visible = show_supporting_text
	version_label.visible = show_supporting_text

	var primary_height: float = (
		44.0
		if compact_landscape
		else (58.0 if short_web_portrait else (74.0 if web_touch_style else 68.0))
	)
	var secondary_height: float = (
		42.0
		if compact_landscape
		else (58.0 if short_web_portrait else (74.0 if web_touch_style else 58.0))
	)
	play_button.custom_minimum_size.y = primary_height
	play_button.add_theme_font_size_override(
		"font_size",
		19 if compact_landscape else 24
	)
	if compact_landscape or web_touch_style:
		for button: Button in [
			content_studio_button,
			free_mode_button,
			phone_mode_button,
			quit_button
		]:
			button.custom_minimum_size.y = secondary_height
			button.add_theme_font_size_override(
				"font_size",
				16 if compact_landscape else 21
			)
	else:
		content_studio_button.custom_minimum_size.y = 54.0
		content_studio_button.add_theme_font_size_override("font_size", 18)
		free_mode_button.custom_minimum_size.y = 58.0
		free_mode_button.add_theme_font_size_override("font_size", 20)
		phone_mode_button.custom_minimum_size.y = 58.0
		phone_mode_button.add_theme_font_size_override("font_size", 20)
		quit_button.custom_minimum_size.y = 54.0
		quit_button.add_theme_font_size_override("font_size", 18)
	delete_save_button.custom_minimum_size.y = (
		40.0
		if compact_landscape
		else (48.0 if short_web_portrait else (58.0 if web_touch_style else 48.0))
	)
	delete_save_button.add_theme_font_size_override(
		"font_size",
		16 if compact_landscape else (18 if web_touch_style else 16)
	)
	if compact_landscape:
		theme_option.custom_minimum_size = Vector2(148, 40)
		language_option.custom_minimum_size = Vector2(158, 40)
	elif web_touch_style:
		var selector_height: float = 44.0 if short_web_portrait else 50.0
		theme_option.custom_minimum_size = Vector2(160, selector_height)
		language_option.custom_minimum_size = Vector2(170, selector_height)
	else:
		theme_option.custom_minimum_size = Vector2(138, 0)
		language_option.custom_minimum_size = Vector2(150, 36)


func _set_full_rect_offsets(
	control: Control,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _apply_localized_text() -> void:
	_refresh_theme_option_text()
	_apply_brand_title()
	subtitle_label.text = LocalizationService.tr_key(
		"main_menu.subtitle",
		"Build your dice. Choose your moves. Enter the arena."
	)
	play_button.text = LocalizationService.tr_key(
		"main_menu.story_continue"
		if PlayerProgress.has_profile()
		else "main_menu.story_new",
		"STORY MODE  |  CONTINUE"
		if PlayerProgress.has_profile()
		else "STORY MODE  |  NEW GAME"
	)
	content_studio_button.text = LocalizationService.tr_key(
		"main_menu.content_studio",
		"Content Studio"
	)
	free_mode_button.text = LocalizationService.tr_key(
		"main_menu.free_mode",
		"FREE MODE"
	)
	phone_mode_button.text = LocalizationService.tr_key(
		"main_menu.phone_mode",
		"PHONE MODE  |  PORTRAIT"
	)
	unsealed_label.text = LocalizationService.tr_key(
		"main_menu.content_studio_unsealed",
		"CONTENT STUDIO UNSEALED"
	)
	quit_button.text = LocalizationService.tr_key(
		"main_menu.quit",
		"Quit"
	)
	delete_save_button.text = LocalizationService.tr_key(
		"main_menu.delete_save",
		"Delete Save File"
	)
	# Product version metadata must not be replaced by an older user language
	# override copied from a previous release.
	version_label.text = DISPLAY_VERSION + " HOTFIX"
	quit_confirmation.title = LocalizationService.tr_key(
		"global_quit.title",
		"Exit PLAKORO?"
	)
	quit_confirmation.dialog_text = LocalizationService.tr_key(
		"global_quit.message",
		"Are you sure you want to close the game?"
	)
	quit_confirmation.ok_button_text = LocalizationService.tr_key(
		"global_quit.exit",
		"Exit"
	)
	quit_confirmation.cancel_button_text = LocalizationService.tr_key(
		"common.cancel",
		"Cancel"
	)
	QUIT_DIALOG_LAYOUT.apply(quit_confirmation)
	delete_save_confirmation.title = LocalizationService.tr_key(
		"delete_save.title",
		"Delete Save File?"
	)
	delete_save_confirmation.dialog_text = LocalizationService.tr_key(
		"delete_save.message",
		"All battle progress, unlocked Plakoro, levels, Moves, Energy, and the player loadout will be permanently deleted. Content Studio data will be kept."
	)
	delete_save_confirmation.ok_button_text = LocalizationService.tr_key(
		"delete_save.confirm",
		"Delete Save"
	)
	delete_save_confirmation.cancel_button_text = LocalizationService.tr_key(
		"common.cancel",
		"Cancel"
	)


func _apply_brand_title() -> void:
	if title_label == null:
		return
	title_label.texture = (
		TITLE_WARM
		if PLAKORO_THEME.is_warm_theme()
		else TITLE_DARK
	)


func _setup_web_controls() -> void:
	# itch.io / hosting page owns fullscreen controls. Do not request browser
	# fullscreen from gameplay navigation or first-click events.
	quit_button.visible = not OS.has_feature("web")
	phone_mode_button.visible = OS.has_feature("web")
	if OS.has_feature("web"):
		# Match the cleaner Phone Mode card on the browser build while leaving
		# the native desktop menu unchanged.
		menu_panel.remove_theme_stylebox_override("panel")
		$ArenaGlow.visible = false


func _start_story_mode() -> void:
	_begin_navigation()
	GameFlow.start_game()


func _start_free_mode() -> void:
	_begin_navigation()
	GameFlow.open_free_mode()


func _start_phone_mode() -> void:
	_begin_navigation()
	GameFlow.start_phone_mode()


func _open_content_studio() -> void:
	_begin_navigation()
	GameFlow.open_content_studio_from_main_menu()


func _begin_navigation() -> void:
	leaving_menu = true
	var viewport: Viewport = get_viewport()
	if viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.disconnect(_apply_responsive_layout)


func _setup_theme_option() -> void:
	theme_option.item_selected.connect(_on_theme_selected)
	_refresh_theme_option_text()


func _refresh_theme_option_text() -> void:
	if theme_option == null:
		return
	var selected_mode: String = PLAKORO_THEME.get_theme_mode()
	theme_option.clear()
	theme_option.add_item(LocalizationService.tr_key(
		"theme.warm",
		"Warm"
	))
	theme_option.set_item_metadata(0, PLAKORO_THEME.THEME_WARM)
	theme_option.add_item(LocalizationService.tr_key(
		"theme.dark",
		"Dark"
	))
	theme_option.set_item_metadata(1, PLAKORO_THEME.THEME_DARK)
	theme_option.select(
		0 if selected_mode == PLAKORO_THEME.THEME_WARM else 1
	)
	theme_option.tooltip_text = LocalizationService.tr_key(
		"theme.label",
		"Interface Theme"
	)


func _on_theme_selected(index: int) -> void:
	var selected_mode: String = str(
		theme_option.get_item_metadata(index)
	)
	if selected_mode == PLAKORO_THEME.get_theme_mode():
		return
	PLAKORO_THEME.set_theme_mode(selected_mode)
	call_deferred("_reload_for_theme")


func _reload_for_theme() -> void:
	get_tree().reload_current_scene()


func _request_quit() -> void:
	QUIT_DIALOG_LAYOUT.popup(quit_confirmation)


func _confirm_quit() -> void:
	get_tree().quit()


func _request_delete_save() -> void:
	delete_status_label.text = ""
	delete_save_confirmation.popup_centered()


func _confirm_delete_save() -> void:
	delete_save_button.disabled = true
	var result: Dictionary = PlayerProgress.delete_profile()
	if not bool(result.get("success", false)):
		delete_status_label.text = LocalizationService.tr_format(
			"delete_save.failed",
			{"path": String(result.get("failed_path", ""))},
			"Could not delete the save file: {path}"
		)
		delete_save_button.disabled = false
		return
	delete_status_label.text = LocalizationService.tr_key(
		"delete_save.success",
		"Save file deleted. You can now start a new game."
	)
	_apply_localized_text()
	_refresh_save_actions()
	play_button.grab_focus()


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
	_refresh_save_actions()


func _refresh_content_studio_access() -> void:
	var unlocked: bool = ContentStudioAccess.is_unsealed()
	content_studio_button.visible = unlocked
	unsealed_label.visible = false


func _on_content_studio_unsealed() -> void:
	_refresh_content_studio_access()
	content_studio_button.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(content_studio_button, "modulate:a", 1.0, 0.25)
	content_studio_button.grab_focus()


func _refresh_save_actions() -> void:
	delete_save_button.visible = PlayerProgress.has_profile()
	delete_save_button.disabled = false
