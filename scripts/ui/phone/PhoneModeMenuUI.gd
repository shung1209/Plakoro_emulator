extends Control


const PLAKORO_THEME: Script = preload(
	"res://scripts/ui/theme/PlakoroThemeFactory.gd"
)


@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var story_button: Button = %StoryButton
@onready var free_button: Button = %FreeButton
@onready var local_battle_button: Button = %LocalBattleButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	PLAKORO_THEME.apply_to(self)
	story_button.pressed.connect(GameFlow.start_phone_story_mode)
	free_button.pressed.connect(GameFlow.open_phone_free_mode)
	local_battle_button.pressed.connect(GameFlow.open_phone_local_battle)
	back_button.pressed.connect(GameFlow.exit_phone_mode)
	LocalizationService.locale_changed.connect(_on_locale_changed)
	_apply_localized_text()
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
	free_button.text = LocalizationService.tr_key(
		"phone_mode.free_mode", "FREE MODE"
	)
	local_battle_button.text = LocalizationService.tr_key(
		"phone_mode.local_battle", "LOCAL VS"
	)
	back_button.text = LocalizationService.tr_key(
		"phone_mode.back", "BACK"
	)


func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()
