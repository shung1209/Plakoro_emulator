extends Node

const BUILTIN_DIR: String = "res://language/content"
const USER_DIR: String = "user://user_database/language/content"
const DEFAULT_LOCALE: String = "en_US"
const SCHEMA_VERSION: String = "1.0"

var current_locale: String = DEFAULT_LOCALE
var current_entries: Dictionary = {}
var fallback_entries: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(USER_DIR))
	if LocalizationService != null:
		LocalizationService.locale_changed.connect(_on_locale_changed)
		set_locale(LocalizationService.get_current_locale())


func _on_locale_changed(locale: String) -> void:
	set_locale(locale)


func set_locale(locale: String) -> void:
	current_locale = locale if not locale.strip_edges().is_empty() else DEFAULT_LOCALE
	current_entries = _load_merged_entries(current_locale)
	fallback_entries = {}
	if current_locale != DEFAULT_LOCALE:
		fallback_entries = _load_merged_entries(DEFAULT_LOCALE)


func localize_pokemon(document: Variant) -> String:
	if document == null:
		return ""
	return text(
		"pokemon",
		String(document.species_id),
		"name",
		String(document.display_name)
	)


func localize_move(document: Variant) -> String:
	if document == null:
		return ""
	return text(
		"move",
		String(document.move_name_id),
		"name",
		String(document.display_name)
	)


func localize_move_description(document: Variant) -> String:
	if document == null:
		return ""

	var fallback: String = ""
	if document.get("source") is Dictionary:
		fallback = String(
			(document.get("source") as Dictionary).get("raw_text", "")
		)

	# Some Pokemon share the same move_name_id while their printed card
	# effects differ (for example Charmander/Moltres Flamethrower and
	# Pikachu/Zapdos Thunder Shock). Prefer an exact card translation first
	# and only fall back to the shared move-name translation when no
	# card-specific entry exists.
	var card_id: String = String(document.id) if _has_property(document, "id") else ""
	if not card_id.is_empty():
		var card_description: String = text(
			"move_card",
			card_id,
			"description",
			""
		)
		if not card_description.is_empty():
			return card_description

	return text(
		"move",
		String(document.move_name_id),
		"description",
		fallback
	)


func localize_type(type_id: Variant) -> String:
	var id: String = String(type_id)
	return text("type", id, "name", id.capitalize())


func localize_effect_text(move_document: Variant, outcome_index: int, fallback: String = "") -> String:
	if move_document == null:
		return fallback

	var card_id: String = String(
		move_document.id
	) if _has_property(move_document, "id") else ""
	if not card_id.is_empty():
		var card_value: String = text(
			"move_card",
			card_id,
			"effect_%d" % outcome_index,
			""
		)
		if not card_value.is_empty():
			return card_value

	return text(
		"move",
		String(move_document.move_name_id),
		"effect_%d" % outcome_index,
		fallback
	)


func localize_move_effect_text(
	move_document: Variant,
	effect_index: int,
	fallback: String = ""
) -> String:
	if move_document == null:
		return fallback
	var card_id: String = String(
		move_document.id
	) if _has_property(move_document, "id") else ""
	if not card_id.is_empty():
		var card_value: String = text(
			"move_card",
			card_id,
			"move_effect_%d" % effect_index,
			""
		)
		if not card_value.is_empty():
			return _strip_move_effect_prefix(card_value)
	return _strip_move_effect_prefix(text(
		"move",
		String(move_document.move_name_id),
		"move_effect_%d" % effect_index,
		fallback
	))


func _strip_move_effect_prefix(value: String) -> String:
	var result: String = value.strip_edges()
	for prefix: String in [
		"Move Effect:",
		"Move Effect：",
		"招式效果：",
		"招式效果:",
		"わざ効果：",
		"わざ効果:",
		"ワザ効果：",
		"ワザ効果:",
		"Efecto del movimiento:",
		"Efecto del movimiento：",
	]:
		if result.begins_with(prefix):
			return result.trim_prefix(prefix).strip_edges()
	return result


func _has_property(source: Variant, property_name: String) -> bool:
	if source == null:
		return false
	if source is Dictionary:
		return (source as Dictionary).has(property_name)
	for property: Dictionary in source.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func text(kind: String, content_id: String, field: String, fallback: String = "") -> String:
	var key: String = _key(kind, content_id, field)
	if current_entries.has(key):
		return _normalize(String(current_entries[key]))
	if fallback_entries.has(key):
		return _normalize(String(fallback_entries[key]))
	return fallback


func _key(kind: String, content_id: String, field: String) -> String:
	return kind + "." + content_id + "." + field


func _load_merged_entries(locale: String) -> Dictionary:
	var merged: Dictionary = {}

	# Merge every fragment whose declared locale matches. File names are not
	# semantically significant, so packs can be split by content domain:
	# zh_TW.json, zh_TW_moves.json, zh_TW_custom_terms.json, etc.
	_merge_locale_documents(
		merged,
		BUILTIN_DIR,
		locale,
		true
	)
	_merge_locale_documents(
		merged,
		USER_DIR,
		locale,
		false
	)

	return merged


func _merge_locale_documents(
	target: Dictionary,
	directory_path: String,
	locale: String,
	override_existing: bool
) -> void:
	var dir: DirAccess = DirAccess.open(
		directory_path
	)
	if dir == null:
		return

	var files: PackedStringArray = dir.get_files()
	files.sort()

	for file_name: String in files:
		if (
			not file_name.ends_with(".json")
			or file_name.begins_with("_")
		):
			continue

		var document: Dictionary = _read_document(
			directory_path.path_join(
				file_name
			)
		)
		if (
			String(
				document.get(
					"locale",
					""
				)
			) != locale
		):
			continue

		var entries: Dictionary = (
			document.get(
				"entries",
				{}
			) as Dictionary
		)
		var document_overrides: bool = (
			override_existing
			or bool(document.get("override_builtin", false))
		)
		for raw_key: Variant in entries.keys():
			var key: String = String(raw_key)
			if document_overrides or not target.has(key):
				target[key] = entries[raw_key]


func _read_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var doc: Dictionary = parsed as Dictionary
	if String(doc.get("schema_version", "")) != SCHEMA_VERSION:
		return {}
	if not doc.get("entries", null) is Dictionary:
		return {}
	return doc


func _normalize(value: String) -> String:
	return value.replace("\\n", "\n").replace("\\t", "\t")
