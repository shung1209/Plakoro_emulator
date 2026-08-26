extends Node

const QUIT_DIALOG_LAYOUT: Script = preload(
    "res://scripts/ui/QuitConfirmationLayout.gd"
)

var confirmation: ConfirmationDialog = null


func _ready() -> void:
    get_tree().auto_accept_quit = false

    confirmation = ConfirmationDialog.new()
    confirmation.name = "GlobalQuitConfirmation"
    confirmation.exclusive = true
    add_child(confirmation)

    confirmation.confirmed.connect(
        _confirm_quit
    )
    LocalizationService.locale_changed.connect(
        _on_locale_changed
    )
    _apply_localized_text()


func _notification(what: int) -> void:
    if what != NOTIFICATION_WM_CLOSE_REQUEST:
        return
    if confirmation == null or confirmation.visible:
        return
    _apply_localized_text()
    QUIT_DIALOG_LAYOUT.popup(confirmation)


func _apply_localized_text() -> void:
    if confirmation == null:
        return

    confirmation.title = LocalizationService.tr_key(
        "global_quit.title",
        "Exit PLAKORO?"
    )
    confirmation.dialog_text = LocalizationService.tr_key(
        "global_quit.message",
        "Are you sure you want to close the game?"
    )
    confirmation.ok_button_text = LocalizationService.tr_key(
        "global_quit.exit",
        "Exit"
    )
    confirmation.cancel_button_text = LocalizationService.tr_key(
        "common.cancel",
        "Cancel"
    )
    QUIT_DIALOG_LAYOUT.apply(confirmation)


func _on_locale_changed(
    _locale: String
) -> void:
    _apply_localized_text()


func _confirm_quit() -> void:
    get_tree().quit()
