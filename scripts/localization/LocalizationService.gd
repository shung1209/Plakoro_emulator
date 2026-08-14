extends Node


signal locale_changed(locale: String)


const USER_LANGUAGE_DIR: String = (
	"user://user_database/language"
)
const SETTINGS_PATH: String = (
	USER_LANGUAGE_DIR + "/_settings.json"
)
const BUILTIN_LANGUAGE_DIR: String = (
	"res://language"
)
const DEFAULT_LOCALE: String = "en_US"
const SCHEMA_VERSION: String = "1.0"


var current_locale: String = DEFAULT_LOCALE
var current_strings: Dictionary = {}
var fallback_strings: Dictionary = {}
var available_languages: Array[Dictionary] = []


func _ready() -> void:
	_ensure_user_language_directory()
	reload_languages()

	var configured_locale: String = _load_selected_locale()
	if configured_locale.is_empty():
		configured_locale = _initial_locale()

	set_locale(
		configured_locale,
		false
	)


func reload_languages() -> void:
	available_languages.clear()

	var locale_map: Dictionary = {}

	_collect_language_directory(
		BUILTIN_LANGUAGE_DIR,
		"builtin",
		locale_map
	)
	_collect_language_directory(
		USER_LANGUAGE_DIR,
		"user",
		locale_map
	)

	var locales: Array[String] = []
	for raw_locale: Variant in locale_map.keys():
		locales.append(
			String(raw_locale)
		)
	locales.sort()

	for locale: String in locales:
		available_languages.append(
			(locale_map[locale] as Dictionary).duplicate(true)
		)


func get_available_languages() -> Array[Dictionary]:
	return available_languages.duplicate(true)


func get_current_locale() -> String:
	return current_locale


func set_locale(
	locale: String,
	persist: bool = true
) -> bool:
	var normalized: String = locale.strip_edges()
	if normalized.is_empty():
		normalized = DEFAULT_LOCALE

	var document: Dictionary = _load_language_document(
		normalized
	)

	if document.is_empty():
		push_warning(
			"LocalizationService: locale not found: "
			+ normalized
			+ "; falling back to "
			+ DEFAULT_LOCALE
		)

		normalized = DEFAULT_LOCALE
		document = _load_language_document(
			normalized
		)

	if document.is_empty():
		push_error(
			"LocalizationService: built-in fallback language is missing."
		)
		return false

	current_locale = normalized
	current_strings = (
		document.get(
			"strings",
			{}
		) as Dictionary
	).duplicate(true)

	var fallback_locale: String = String(
		document.get(
			"fallback",
			DEFAULT_LOCALE
		)
	).strip_edges()

	if (
		fallback_locale.is_empty()
		or fallback_locale == current_locale
	):
		fallback_locale = (
			""
			if current_locale == DEFAULT_LOCALE
			else DEFAULT_LOCALE
		)

	fallback_strings.clear()

	if not fallback_locale.is_empty():
		var fallback_document: Dictionary = (
			_load_language_document(
				fallback_locale
			)
		)

		if not fallback_document.is_empty():
			fallback_strings = (
				fallback_document.get(
					"strings",
					{}
				) as Dictionary
			).duplicate(true)

	if (
		current_locale != DEFAULT_LOCALE
		and fallback_locale != DEFAULT_LOCALE
	):
		var english_document: Dictionary = (
			_load_language_document(
				DEFAULT_LOCALE
			)
		)

		if not english_document.is_empty():
			for raw_key: Variant in (
				english_document.get(
					"strings",
					{}
				) as Dictionary
			).keys():
				var key: String = String(raw_key)
				if not fallback_strings.has(key):
					fallback_strings[key] = (
						english_document["strings"][raw_key]
					)

	if persist:
		_save_selected_locale()

	locale_changed.emit(
		current_locale
	)
	return true


func tr_key(
	key: String,
	default_text: String = ""
) -> String:
	var result: String = ""

	if current_strings.has(key):
		result = str(
			current_strings[key]
		)
	elif fallback_strings.has(key):
		result = str(
			fallback_strings[key]
		)
	elif not default_text.is_empty():
		result = default_text
	else:
		result = key

	return _normalize_translation_text(
		result
	)


func _normalize_translation_text(
	text: String
) -> String:
	# Compatibility for legacy user:// language packs whose parsed value
	# still contains a literal backslash followed by n/t.
	return text.replace(
		"\\n",
		"\n"
	).replace(
		"\\t",
		"\t"
	)


func tr_format(
	key: String,
	parameters: Dictionary = {},
	default_text: String = ""
) -> String:
	var result: String = tr_key(
		key,
		default_text
	)

	for raw_name: Variant in parameters.keys():
		var name: String = String(raw_name)
		result = result.replace(
			"{" + name + "}",
			str(parameters[raw_name])
		)

	return result


func format_integer(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(absi(value))
	var grouped: String = ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	grouped = digits + grouped
	return ("-" if negative else "") + grouped


func format_decimal(
	value: float,
	decimals: int = 1
) -> String:
	var safe_decimals: int = maxi(0, decimals)
	var raw: String = ("%.*f" % [safe_decimals, value])
	# Current supported locales both use a period decimal separator.
	# Keeping this behind the service prevents UI code from owning that rule.
	return raw


func format_percent(
	ratio: float,
	decimals: int = 0
) -> String:
	return tr_format(
		"format.percent",
		{
			"value": format_decimal(
				ratio * 100.0,
				decimals
			)
		},
		"{value}%"
	)


func format_signed_integer(
	value: int
) -> String:
	return (
		"+" + format_integer(value)
		if value >= 0
		else format_integer(value)
	)


func format_count(
	singular_key: String,
	plural_key: String,
	count: int,
	singular_default: String,
	plural_default: String
) -> String:
	var key: String = (
		singular_key
		if count == 1
		else plural_key
	)
	var fallback: String = (
		singular_default
		if count == 1
		else plural_default
	)
	return tr_format(
		key,
		{"count": format_integer(count)},
		fallback
	)


func has_key(
	key: String
) -> bool:
	return (
		current_strings.has(key)
		or fallback_strings.has(key)
	)


func validate_language_document(
	document: Dictionary
) -> Dictionary:
	var errors: Array[String] = []

	if String(
		document.get(
			"schema_version",
			""
		)
	) != SCHEMA_VERSION:
		errors.append(
			"schema_version must be "
			+ SCHEMA_VERSION
			+ "."
		)

	var locale: String = String(
		document.get(
			"locale",
			""
		)
	).strip_edges()

	if locale.is_empty():
		errors.append(
			"locale is required."
		)

	var display_name: String = String(
		document.get(
			"display_name",
			""
		)
	).strip_edges()

	if display_name.is_empty():
		errors.append(
			"display_name is required."
		)

	if not (
		document.get(
			"strings",
			null
		)
		is Dictionary
	):
		errors.append(
			"strings must be an object."
		)

	return {
		"success": errors.is_empty(),
		"errors": errors
	}


func _load_language_document(
	locale: String
) -> Dictionary:
	# Built-in locale content provides the evolving default key set.
	var builtin_path: String = (
		BUILTIN_LANGUAGE_DIR
		+ "/"
		+ locale
		+ ".json"
	)

	var builtin_document: Dictionary = (
		_read_json_dictionary(
			builtin_path
		)
	)

	if (
		not builtin_document.is_empty()
		and not bool(
			validate_language_document(
				builtin_document
			).get(
				"success",
				false
			)
		)
	):
		builtin_document = {}

	# User files are free-form filenames and override the matching locale by
	# locale metadata. Merge user strings over bundled strings so newly-added
	# application keys still exist after an update without overwriting the
	# user's JSON file on disk.
	var user_document: Dictionary = (
		_find_language_document_in_directory(
			USER_LANGUAGE_DIR,
			locale
		)
	)

	if user_document.is_empty():
		return builtin_document

	if builtin_document.is_empty():
		return user_document

	var merged: Dictionary = builtin_document.duplicate(true)
	var merged_strings: Dictionary = (
		merged.get(
			"strings",
			{}
		) as Dictionary
	).duplicate(true)
	var user_strings: Dictionary = (
		user_document.get(
			"strings",
			{}
		) as Dictionary
	)

	for raw_key: Variant in user_strings.keys():
		merged_strings[String(raw_key)] = user_strings[raw_key]

	merged["strings"] = merged_strings
	merged["display_name"] = String(
		user_document.get(
			"display_name",
			merged.get(
				"display_name",
				locale
			)
		)
	)
	merged["fallback"] = String(
		user_document.get(
			"fallback",
			merged.get(
				"fallback",
				""
			)
		)
	)
	merged["locale"] = locale
	return merged


func _find_language_document_in_directory(
	path: String,
	locale: String
) -> Dictionary:
	var directory: DirAccess = DirAccess.open(
		path
	)

	if directory == null:
		return {}

	var files: PackedStringArray = directory.get_files()
	files.sort()

	for file_name: String in files:
		if (
			not file_name.ends_with(".json")
			or file_name.begins_with("_")
		):
			continue

		var document: Dictionary = _read_json_dictionary(
			path.path_join(file_name)
		)

		if document.is_empty():
			continue

		var validation: Dictionary = validate_language_document(
			document
		)

		if not bool(validation.get("success", false)):
			continue

		if String(document.get("locale", "")) == locale:
			return document

	return {}


func _collect_language_directory(
	path: String,
	source: String,
	target: Dictionary
) -> void:
	var directory: DirAccess = DirAccess.open(
		path
	)

	if directory == null:
		return

	var files: PackedStringArray = (
		directory.get_files()
	)
	files.sort()

	for file_name: String in files:
		if (
			not file_name.ends_with(
				".json"
			)
			or file_name.begins_with(
				"_"
			)
		):
			continue

		var document: Dictionary = (
			_read_json_dictionary(
				path.path_join(
					file_name
				)
			)
		)

		if document.is_empty():
			continue

		var validation: Dictionary = (
			validate_language_document(
				document
			)
		)

		if not bool(
			validation.get(
				"success",
				false
			)
		):
			push_warning(
				"LocalizationService: invalid language file "
				+ path.path_join(file_name)
				+ ": "
				+ "; ".join(
					validation.get(
						"errors",
						[]
					)
				)
			)
			continue

		var locale: String = String(
			document.get(
				"locale",
				""
			)
		)

		target[locale] = {
			"locale": locale,
			"display_name": String(
				document.get(
					"display_name",
					locale
				)
			),
			"source": source,
			"path": path.path_join(
				file_name
			)
		}


func _read_json_dictionary(
	path: String
) -> Dictionary:
	if not FileAccess.file_exists(
		path
	):
		return {}

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if parsed is Dictionary:
		return parsed

	return {}


func _ensure_user_language_directory() -> void:
	var error: Error = (
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(
				USER_LANGUAGE_DIR
			)
		)
	)

	if (
		error != OK
		and error != ERR_ALREADY_EXISTS
	):
		push_warning(
			"LocalizationService: could not create "
			+ USER_LANGUAGE_DIR
		)


func _load_selected_locale() -> String:
	var settings: Dictionary = (
		_read_json_dictionary(
			SETTINGS_PATH
		)
	)

	return String(
		settings.get(
			"locale",
			""
		)
	).strip_edges()


func _save_selected_locale() -> void:
	var file: FileAccess = FileAccess.open(
		SETTINGS_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_warning(
			"LocalizationService: could not save language settings."
		)
		return

	file.store_string(
		JSON.stringify(
			{
				"locale": current_locale
			},
			"  "
		)
	)
	file.close()


func _initial_locale() -> String:
	var os_locale: String = OS.get_locale()

	if os_locale.begins_with(
		"zh"
	):
		if not _load_language_document(
			"zh_TW"
		).is_empty():
			return "zh_TW"

	return DEFAULT_LOCALE
