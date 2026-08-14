extends RefCounted
const JSON_LOADER: Script = preload("res://scripts/database/JsonLoader.gd")
const RULES_DATA: Script = preload("res://scripts/data/RulesData.gd")
const PATH: String = "res://database/rules/battle_rules.json"
static func load_rules() -> Variant:
	var raw: Dictionary = JSON_LOADER.load_dictionary(PATH)
	if raw.is_empty(): return null
	var result: Variant = RULES_DATA.new()
	result.required_selected_move_cards = int(raw.get("required_selected_move_cards", 4))
	result.same_move_name_allowed = bool(raw.get("same_move_name_allowed", false))
	result.base_energy_dice_count = int(raw.get("base_energy_dice_count", 3))
	result.move_cooldown_turns = int(raw.get("move_cooldown_turns", 1))
	result.default_weakness_bonus = int(raw.get("default_weakness_bonus", 20))
	result.outcome_match_mode = StringName(raw.get("outcome_match_mode", "zero_or_one"))
	result.outcome_action_execution = StringName(raw.get("outcome_action_execution", "sequential"))
	if result.required_selected_move_cards <= 0 or result.base_energy_dice_count <= 0: return null
	return result
