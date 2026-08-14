extends RefCounted


const BATTLE_REPLAY_DATA: Script = preload(
    "res://scripts/replay/data/BattleReplayData.gd"
)


static func to_json(
    replay: Variant
) -> String:
    if replay == null:
        return ""

    return JSON.stringify(
        replay.to_dictionary(),
        "  "
    )


static func from_json(
    text: String
) -> Variant:
    var json: JSON = JSON.new()
    var error_code: Error = json.parse(text)

    if error_code != OK:
        push_error(
            "BattleReplaySerializer: JSON parse error at line %d: %s"
            % [
                json.get_error_line(),
                json.get_error_message()
            ]
        )
        return null

    if not json.data is Dictionary:
        push_error(
            "BattleReplaySerializer: root must be an object."
        )
        return null

    return BATTLE_REPLAY_DATA.from_dictionary(
        json.data as Dictionary
    )


static func save_to_file(
    replay: Variant,
    file_path: String
) -> bool:
    var file: FileAccess = FileAccess.open(
        file_path,
        FileAccess.WRITE
    )

    if file == null:
        push_error(
            "BattleReplaySerializer: could not open '%s'."
            % file_path
        )
        return false

    file.store_string(to_json(replay))
    file.close()
    return true


static func load_from_file(
    file_path: String
) -> Variant:
    if not FileAccess.file_exists(file_path):
        return null

    var file: FileAccess = FileAccess.open(
        file_path,
        FileAccess.READ
    )

    if file == null:
        return null

    var text: String = file.get_as_text()
    file.close()

    return from_json(text)
