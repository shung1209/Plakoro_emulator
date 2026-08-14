extends Node


var launch_config: Variant = null


func set_launch_config(
    config: Variant
) -> void:
    launch_config = config


func get_launch_config() -> Variant:
    return launch_config


func clear() -> void:
    launch_config = null
