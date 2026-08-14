extends RefCounted

const MODE_QUICK: StringName = &"quick"
const MODE_STEP_BY_STEP: StringName = &"step_by_step"
static var _mode: StringName = MODE_QUICK

static func set_mode(mode: StringName) -> void:
	_mode = MODE_STEP_BY_STEP if mode == MODE_STEP_BY_STEP else MODE_QUICK

static func get_mode() -> StringName:
	return _mode

static func is_step_by_step() -> bool:
	return _mode == MODE_STEP_BY_STEP

static func display_name() -> String:
	return "Step-by-step" if is_step_by_step() else "Quick"
