extends RefCounted


const ICONS: Script = preload(
	"res://scripts/presentation/PlakoroIconService.gd"
)


static func show_type(
	target: HBoxContainer,
	energy_type: StringName,
	icon_size: int = 24
) -> void:
	_clear(target)
	if target == null:
		return
	var normalized: StringName = StringName(String(energy_type).to_lower())
	if normalized == &"":
		_add_fallback(target)
		return
	_add_icon(target, normalized, icon_size)
	target.tooltip_text = GameContentLocalizationService.localize_type(normalized)


static func show_weaknesses(
	target: HBoxContainer,
	pokemon: Variant,
	icon_size: int = 24
) -> void:
	_clear(target)
	if target == null:
		return
	var weaknesses: Variant = _property(pokemon, &"weaknesses", [])
	if not (weaknesses is Array) or (weaknesses as Array).is_empty():
		_add_fallback(target)
		target.tooltip_text = LocalizationService.tr_key(
			"battle.weakness_none",
			"Weakness: None"
		)
		return

	var tooltip_parts: Array[String] = []
	for raw_weakness: Variant in weaknesses as Array:
		var attack_type: StringName = StringName(
			String(_property(raw_weakness, &"attack_type", "")).to_lower()
		)
		if attack_type == &"":
			continue
		var bonus: int = int(_property(raw_weakness, &"bonus_damage", 0))
		_add_icon(target, attack_type, icon_size)
		_add_bonus(target, bonus, icon_size)
		tooltip_parts.append(
			"%s +%s" % [
				GameContentLocalizationService.localize_type(attack_type),
				LocalizationService.format_integer(bonus)
			]
		)

	if tooltip_parts.is_empty():
		_add_fallback(target)
		target.tooltip_text = LocalizationService.tr_key(
			"battle.weakness_none",
			"Weakness: None"
		)
		return
	target.tooltip_text = LocalizationService.tr_format(
		"battle.weakness_value",
		{"value": ", ".join(tooltip_parts)},
		"Weakness: {value}"
	)


static func _add_icon(
	target: HBoxContainer,
	energy_type: StringName,
	icon_size: int
) -> void:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.texture = ICONS.load_energy_icon(energy_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(icon)
	if icon.texture == null:
		icon.queue_free()
		_add_text(target, ICONS.energy_fallback(energy_type), icon_size)


static func _add_bonus(
	target: HBoxContainer,
	bonus: int,
	icon_size: int
) -> void:
	_add_text(
		target,
		"+%s" % LocalizationService.format_integer(bonus),
		maxi(14, int(round(icon_size * 0.7)))
	)


static func _add_fallback(target: HBoxContainer) -> void:
	_add_text(target, "—", 15)


static func _add_text(
	target: HBoxContainer,
	value: String,
	font_size: int
) -> void:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(label)


static func _clear(target: HBoxContainer) -> void:
	if target == null:
		return
	for child: Node in target.get_children():
		target.remove_child(child)
		child.queue_free()


static func _property(
	value: Variant,
	property_name: StringName,
	default_value: Variant
) -> Variant:
	if value == null:
		return default_value
	if value is Dictionary:
		var dictionary: Dictionary = value as Dictionary
		if dictionary.has(property_name):
			return dictionary[property_name]
		var string_name: String = String(property_name)
		return dictionary.get(string_name, default_value)
	if not value is Object:
		return default_value
	for property_info: Dictionary in value.get_property_list():
		if StringName(property_info.get("name", "")) == property_name:
			return value.get(property_name)
	return default_value
