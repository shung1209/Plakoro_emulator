extends RefCounted
var required_selected_move_cards: int = 4
var same_move_name_allowed: bool = false
var base_energy_dice_count: int = 3
var move_cooldown_turns: int = 1
var default_weakness_bonus: int = 20
var outcome_match_mode: StringName = &"zero_or_one"
var outcome_action_execution: StringName = &"sequential"
