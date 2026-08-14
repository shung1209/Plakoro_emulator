extends HBoxContainer


@onready var language_option: OptionButton = %LanguageOption


var locale_by_index: Dictionary = {}
var suppress_selection: bool = false


func _ready() -> void:
	add_theme_constant_override(
		"separation",
		6
	)

	language_option.item_selected.connect(
		_on_language_selected
	)

	LocalizationService.locale_changed.connect(
		_on_locale_changed
	)

	_rebuild_options()


func _rebuild_options() -> void:
	suppress_selection = true
	language_option.clear()
	locale_by_index.clear()

	var languages: Array[Dictionary] = (
		LocalizationService.get_available_languages()
	)

	for language: Dictionary in languages:
		var locale: String = String(
			language.get(
				"locale",
				""
			)
		)
		var display_name: String = String(
			language.get(
				"display_name",
				locale
			)
		)

		if locale.is_empty():
			continue

		var index: int = language_option.item_count
		language_option.add_item(
			display_name
		)
		language_option.set_item_tooltip(
			index,
			locale
		)
		locale_by_index[index] = locale

		if (
			locale
			== LocalizationService.get_current_locale()
		):
			language_option.select(
				index
			)

	suppress_selection = false


func _on_language_selected(
	index: int
) -> void:
	if suppress_selection:
		return

	var locale: String = String(
		locale_by_index.get(
			index,
			""
		)
	)

	if locale.is_empty():
		return

	LocalizationService.set_locale(
		locale
	)


func _on_locale_changed(
	_locale: String
) -> void:
	_rebuild_options()
