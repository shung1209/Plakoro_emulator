extends PanelContainer


@onready var title_label: Label = %TitleLabel
@onready var content: VBoxContainer = %Content


func set_title(
    value: String
) -> void:
    if not is_node_ready():
        await ready

    title_label.text = value


func get_content() -> VBoxContainer:
    return content
