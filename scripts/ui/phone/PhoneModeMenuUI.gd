extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var story_button: Button = %StoryButton
@onready var delete_save_button: Button = %DeleteSaveButton
@onready var free_button: Button = %FreeButton
@onready var local_battle_button: Button = %LocalBattleButton
@onready var online_battle_button: Button = %OnlineBattleButton
@onready var back_button: Button = %BackButton
@onready var delete_save_confirmation: ConfirmationDialog = %DeleteSaveConfirmation
@onready var delete_save_error: AcceptDialog = %DeleteSaveError


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	story_button.pressed.connect(GameFlow.start_phone_story_mode)
	delete_save_button.pressed.connect(_request_delete_save)
	delete_save_confirmation.confirmed.connect(_confirm_delete_save)
	free_button.pressed.connect(GameFlow.open_phone_free_mode)
	local_battle_button.pressed.connect(GameFlow.open_phone_local_battle)
	online_battle_button.pressed.connect(GameFlow.open_phone_online_battle)
	back_button.pressed.connect(GameFlow.exit_phone_mode)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()
	_refresh_save_actions()
	story_button.grab_focus()


func _apply_localized_text() -> void:
	title_label.text = LocalizationService.tr_key(
		"phone_mode.menu_title", "PHONE MODE"
	)
	subtitle_label.text = LocalizationService.tr_key(
		"phone_mode.menu_subtitle",
		"A focused portrait layout for playing on your phone."
	)
	story_button.text = LocalizationService.tr_key(
		(
			"phone_mode.story_continue"
			if PlayerProgress.has_profile()
			else "phone_mode.story_new"
		),
		"STORY MODE  |  CONTINUE"
		if PlayerProgress.has_profile()
		else "STORY MODE  |  NEW GAME"
	)
	delete_save_button.text = ""
	delete_save_button.tooltip_text = LocalizationService.tr_key(
		"main_menu.delete_save", "Delete Save File"
	)
	delete_save_confirmation.title = LocalizationService.tr_key(
		"delete_save.title", "Delete Save File?"
	)
	delete_save_confirmation.dialog_text = LocalizationService.tr_key(
		"delete_save.message",
		"All battle progress, unlocked Plakoro, levels, Moves, Energy, and the player loadout will be permanently deleted. Content Studio data will be kept."
	)
	delete_save_confirmation.ok_button_text = LocalizationService.tr_key(
		"delete_save.confirm", "Delete Save"
	)
	delete_save_confirmation.cancel_button_text = LocalizationService.tr_key(
		"common.cancel", "Cancel"
	)
	free_button.text = LocalizationService.tr_key(
		"phone_mode.free_mode", "FREE MODE"
	)
	local_battle_button.text = LocalizationService.tr_key(
		"phone_mode.local_battle", "LOCAL VS"
	)
	online_battle_button.text = LocalizationService.tr_key(
		"phone_mode.online_battle", "ONLINE VS"
	)
	back_button.text = LocalizationService.tr_key(
		"phone_mode.back", "BACK"
	)


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
	_refresh_save_actions()


func _request_delete_save() -> void:
	delete_save_confirmation.popup_centered()


func _confirm_delete_save() -> void:
	delete_save_button.disabled = true
	var result: Dictionary = PlayerProgress.delete_profile()
	if not bool(result.get("success", false)):
		delete_save_error.dialog_text = LocalizationService.tr_format(
			"delete_save.failed",
			{"path": String(result.get("failed_path", ""))},
			"Could not delete the save file: {path}"
		)
		delete_save_error.popup_centered()
		delete_save_button.disabled = false
		return
	_apply_localized_text()
	_refresh_save_actions()
	story_button.grab_focus()


func _refresh_save_actions() -> void:
	delete_save_button.visible = PlayerProgress.has_profile()
	delete_save_button.disabled = false
