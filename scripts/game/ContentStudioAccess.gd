extends Node


signal content_studio_unsealed


const UNSEAL_SEQUENCE: Array[Key] = [
	KEY_UP,
	KEY_UP,
	KEY_DOWN,
	KEY_DOWN,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_B,
	KEY_A
]


var sequence_index: int = 0
var unsealed: bool = false


func _input(event: InputEvent) -> void:
	if unsealed or not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		sequence_index = 0
		return

	accept_keycode(key_event.keycode)


func accept_keycode(keycode: Key) -> void:
	if unsealed:
		return

	if keycode == UNSEAL_SEQUENCE[sequence_index]:
		sequence_index += 1
		if sequence_index >= UNSEAL_SEQUENCE.size():
			unsealed = true
			sequence_index = 0
			content_studio_unsealed.emit()
		return

	sequence_index = 1 if keycode == UNSEAL_SEQUENCE[0] else 0


func is_unsealed() -> bool:
	return unsealed
