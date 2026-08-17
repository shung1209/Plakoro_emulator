extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var play_button: Button = %PlayButton
@onready var content_studio_button: Button = %ContentStudioButton
@onready var unsealed_label: Label = %UnsealedLabel
@onready var quit_button: Button = %QuitButton
@onready var delete_save_button: Button = %DeleteSaveButton
@onready var delete_status_label: Label = %DeleteStatusLabel
@onready var version_label: Label = %VersionLabel
@onready var quit_confirmation: ConfirmationDialog = %QuitConfirmation
@onready var delete_save_confirmation: ConfirmationDialog = %DeleteSaveConfirmation


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	play_button.pressed.connect(GameFlow.start_game)
	content_studio_button.pressed.connect(
		GameFlow.open_content_studio_from_main_menu
	)
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
	play_button.grab_focus()


func _apply_localized_text() -> void:
	title_label.text = LocalizationService.tr_key(
		"main_menu.title",
		"PLAKORO"
	)
	subtitle_label.text = LocalizationService.tr_key(
		"main_menu.subtitle",
		"Build your dice. Choose your moves. Enter the arena."
	)
	play_button.text = LocalizationService.tr_key(
		"main_menu.continue"
		if PlayerProgress.has_profile()
		else "main_menu.new_game",
		"CONTINUE"
		if PlayerProgress.has_profile()
		else "NEW GAME"
	)
	content_studio_button.text = LocalizationService.tr_key(
		"main_menu.content_studio",
		"Content Studio"
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
	version_label.text = LocalizationService.tr_key(
		"main_menu.version",
		"V2 FOUNDATION"
	)
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


func _request_quit() -> void:
	quit_confirmation.popup_centered()


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
	unsealed_label.visible = unlocked


func _on_content_studio_unsealed() -> void:
	_refresh_content_studio_access()
	unsealed_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(unsealed_label, "modulate:a", 1.0, 0.25)


func _refresh_save_actions() -> void:
	delete_save_button.visible = PlayerProgress.has_profile()
	delete_save_button.disabled = false
