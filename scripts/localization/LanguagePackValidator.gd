extends RefCounted


const UI_SCHEMA_VERSION: String = "1.0"
const CONTENT_SCHEMA_VERSION: String = "1.0"
const BUILTIN_UI_DIR: String = "res://language"
const USER_UI_DIR: String = "user://user_database/language"
const BUILTIN_CONTENT_DIR: String = "res://language/content"
const USER_CONTENT_DIR: String = "user://user_database/language/content"


static func validate_all() -> Dictionary:
	var ui_report: Dictionary = validate_ui_packs()
	var content_report: Dictionary = validate_content_packs()
	return {
		"success": bool(ui_report.get("success", false))
			and bool(content_report.get("success", false)),
		"ui": ui_report,
		"content": content_report
	}


static func validate_ui_packs() -> Dictionary:
	var reference: Dictionary = _read_json(
		BUILTIN_UI_DIR.path_join("en_US.json")
	)
	var reference_strings: Dictionary = (
		reference.get("strings", {}) as Dictionary
	)

	var reports: Array[Dictionary] = []
	_collect_pack_reports(
		BUILTIN_UI_DIR,
		"ui",
		"builtin",
		UI_SCHEMA_VERSION,
		reference_strings,
		reports
	)
	_collect_pack_reports(
		USER_UI_DIR,
		"ui",
		"user",
		UI_SCHEMA_VERSION,
		reference_strings,
		reports,
		true
	)

	_validate_declared_fallbacks(
		reports,
		"ui"
	)
	return _summarize(reports)


static func validate_content_packs() -> Dictionary:
	var reference: Dictionary = _read_json(
		BUILTIN_CONTENT_DIR.path_join("en_US.json")
	)
	var reference_entries: Dictionary = (
		reference.get("entries", {}) as Dictionary
	)

	var reports: Array[Dictionary] = []
	_collect_pack_reports(
		BUILTIN_CONTENT_DIR,
		"content",
		"builtin",
		CONTENT_SCHEMA_VERSION,
		reference_entries,
		reports
	)
	_collect_pack_reports(
		USER_CONTENT_DIR,
		"content",
		"user",
		CONTENT_SCHEMA_VERSION,
		reference_entries,
		reports,
		true
	)

	_validate_declared_fallbacks(
		reports,
		"content"
	)
	return _summarize(reports)


static func validate_document(
	document: Dictionary,
	pack_kind: String,
	source: String,
	path: String,
	schema_version: String,
	reference_entries: Dictionary
) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var missing_keys: Array[String] = []
	var empty_keys: Array[String] = []
	var unknown_keys: Array[String] = []
	var placeholder_mismatches: Array[Dictionary] = []

	if String(document.get("schema_version", "")) != schema_version:
		errors.append(
			"schema_version must be "
			+ schema_version
		)

	var locale: String = String(
		document.get("locale", "")
	).strip_edges()
	if locale.is_empty():
		errors.append("locale is required")

	var display_name: String = String(
		document.get("display_name", "")
	).strip_edges()
	if display_name.is_empty():
		errors.append("display_name is required")

	var field_name: String = (
		"strings"
		if pack_kind == "ui"
		else "entries"
	)
	var values_variant: Variant = document.get(
		field_name,
		null
	)
	if not values_variant is Dictionary:
		errors.append(
			field_name + " must be an object"
		)
		values_variant = {}

	var values: Dictionary = (
		values_variant as Dictionary
	)

	var fallback: String = String(
		document.get("fallback", "")
	).strip_edges()
	if (
		not fallback.is_empty()
		and fallback == locale
	):
		errors.append(
			"fallback cannot equal locale"
		)

	for raw_key: Variant in reference_entries.keys():
		var key: String = String(raw_key)
		if not values.has(key):
			missing_keys.append(key)
			continue

		var translated: Variant = values[key]
		if (
			not translated is String
			or String(translated).strip_edges().is_empty()
		):
			empty_keys.append(key)
			continue

		var source_text: String = String(
			reference_entries[raw_key]
		)
		var translated_text: String = String(
			translated
		)
		var source_placeholders: Array[String] = (
			_extract_placeholders(source_text)
		)
		var translated_placeholders: Array[String] = (
			_extract_placeholders(translated_text)
		)

		if source_placeholders != translated_placeholders:
			placeholder_mismatches.append({
				"key": key,
				"expected": source_placeholders,
				"actual": translated_placeholders
			})

	for raw_key: Variant in values.keys():
		var key: String = String(raw_key)
		if not reference_entries.has(key):
			unknown_keys.append(key)

	if source == "builtin":
		if not missing_keys.is_empty():
			if fallback.is_empty():
				errors.append(
					"builtin pack is missing "
					+ str(missing_keys.size())
					+ " reference keys and has no fallback"
				)
			else:
				warnings.append(
					"builtin pack omits "
					+ str(missing_keys.size())
					+ " keys; fallback "
					+ fallback
					+ " must provide them"
				)
		if not unknown_keys.is_empty():
			warnings.append(
				"builtin pack has "
				+ str(unknown_keys.size())
				+ " unknown keys"
			)
	else:
		if not missing_keys.is_empty():
			warnings.append(
				"user pack omits "
				+ str(missing_keys.size())
				+ " keys; fallback/merge will supply them"
			)
		if not unknown_keys.is_empty():
			warnings.append(
				"user pack has "
				+ str(unknown_keys.size())
				+ " keys not present in the current reference pack"
			)

	if not empty_keys.is_empty():
		errors.append(
			str(empty_keys.size())
			+ " translation values are empty"
		)

	if not placeholder_mismatches.is_empty():
		errors.append(
			str(placeholder_mismatches.size())
			+ " placeholder mismatch(es)"
		)

	missing_keys.sort()
	empty_keys.sort()
	unknown_keys.sort()

	return {
		"success": errors.is_empty(),
		"kind": pack_kind,
		"source": source,
		"path": path,
		"locale": locale,
		"display_name": display_name,
		"fallback": fallback,
		"errors": errors,
		"warnings": warnings,
		"missing_keys": missing_keys,
		"empty_keys": empty_keys,
		"unknown_keys": unknown_keys,
		"placeholder_mismatches": placeholder_mismatches,
		"key_count": values.size()
	}


static func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(
		"Language Pack Validation: "
		+ (
			"PASS"
			if bool(report.get("success", false))
			else "FAIL"
		)
	)

	for section_name: String in ["ui", "content"]:
		var section: Dictionary = report.get(
			section_name,
			{}
		)
		lines.append("")
		lines.append(
			(
				"UI Language Packs"
				if section_name == "ui"
				else "Game Content Language Packs"
			)
			+ ": "
			+ (
				"PASS"
				if bool(section.get("success", false))
				else "FAIL"
			)
		)

		for raw_pack: Variant in section.get(
			"packs",
			[]
		):
			var pack: Dictionary = raw_pack
			lines.append(
				"- "
				+ String(pack.get("locale", "?"))
				+ " ["
				+ String(pack.get("source", "?"))
				+ "] "
				+ (
					"PASS"
					if bool(pack.get("success", false))
					else "FAIL"
				)
				+ " — "
				+ String(pack.get("path", ""))
			)

			for error: String in pack.get(
				"errors",
				[]
			):
				lines.append(
					"    ERROR: " + error
				)

			for warning: String in pack.get(
				"warnings",
				[]
			):
				lines.append(
					"    WARN: " + warning
				)

			var mismatches: Array = pack.get(
				"placeholder_mismatches",
				[]
			)
			for raw_mismatch: Variant in mismatches:
				var mismatch: Dictionary = raw_mismatch
				lines.append(
					"    PLACEHOLDER: "
					+ String(mismatch.get("key", ""))
					+ " expected "
					+ str(mismatch.get("expected", []))
					+ " got "
					+ str(mismatch.get("actual", []))
				)

	return "\n".join(lines)


static func _collect_pack_reports(
	path: String,
	pack_kind: String,
	source: String,
	schema_version: String,
	reference_entries: Dictionary,
	reports: Array[Dictionary],
	allow_missing_dir: bool = false
) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		if allow_missing_dir:
			return
		reports.append({
			"success": false,
			"kind": pack_kind,
			"source": source,
			"path": path,
			"locale": "",
			"display_name": "",
			"fallback": "",
			"errors": ["directory is unavailable"],
			"warnings": [],
			"missing_keys": [],
			"empty_keys": [],
			"unknown_keys": [],
			"placeholder_mismatches": [],
			"key_count": 0
		})
		return

	var files: PackedStringArray = (
		directory.get_files()
	)
	files.sort()

	for file_name: String in files:
		if (
			not file_name.ends_with(".json")
			or file_name.begins_with("_")
			or file_name == "LANGUAGE_TEMPLATE.json"
		):
			continue

		var full_path: String = path.path_join(
			file_name
		)
		var document: Dictionary = _read_json(
			full_path
		)

		if document.is_empty():
			reports.append({
				"success": false,
				"kind": pack_kind,
				"source": source,
				"path": full_path,
				"locale": "",
				"display_name": "",
				"fallback": "",
				"errors": ["JSON could not be parsed"],
				"warnings": [],
				"missing_keys": [],
				"empty_keys": [],
				"unknown_keys": [],
				"placeholder_mismatches": [],
				"key_count": 0
			})
			continue

		reports.append(
			validate_document(
				document,
				pack_kind,
				source,
				full_path,
				schema_version,
				reference_entries
			)
		)


static func _validate_declared_fallbacks(
	reports: Array[Dictionary],
	pack_kind: String
) -> void:
	var locales: Dictionary = {}
	for report: Dictionary in reports:
		var locale: String = String(
			report.get(
				"locale",
				""
			)
		)
		if not locale.is_empty():
			locales[locale] = true

	for report: Dictionary in reports:
		var fallback: String = String(
			report.get(
				"fallback",
				""
			)
		).strip_edges()
		if fallback.is_empty():
			continue
		if not locales.has(fallback):
			(report["errors"] as Array).append(
				"fallback locale is unavailable: "
				+ fallback
			)
			report["success"] = false


static func _summarize(
	reports: Array[Dictionary]
) -> Dictionary:
	var success: bool = true
	var error_count: int = 0
	var warning_count: int = 0

	for report: Dictionary in reports:
		success = (
			success
			and bool(
				report.get(
					"success",
					false
				)
			)
		)
		error_count += (
			report.get(
				"errors",
				[]
			) as Array
		).size()
		warning_count += (
			report.get(
				"warnings",
				[]
			) as Array
		).size()

	return {
		"success": success,
		"packs": reports,
		"error_count": error_count,
		"warning_count": warning_count
	}


static func _extract_placeholders(
	text: String
) -> Array[String]:
	var regex: RegEx = RegEx.new()
	regex.compile(
		"\\{([A-Za-z0-9_]+)\\}"
	)

	var result: Array[String] = []
	for match: RegExMatch in regex.search_all(
		text
	):
		var name: String = match.get_string(1)
		if not result.has(name):
			result.append(name)

	result.sort()
	return result


static func _read_json(
	path: String
) -> Dictionary:
	if not FileAccess.file_exists(path):
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
