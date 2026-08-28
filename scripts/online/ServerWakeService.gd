extends Node


const SERVER_SETTING: String = "online/server_url"
const REQUEST_TIMEOUT_SECONDS: float = 10.0


var request_started: bool = false


func _ready() -> void:
    call_deferred("_wake_server_once")


func _wake_server_once() -> void:
    if request_started:
        return
    request_started = true

    var websocket_url: String = String(
        ProjectSettings.get_setting(
            SERVER_SETTING,
            ""
        )
    ).strip_edges()
    var health_url: String = _health_url_from_websocket(websocket_url)
    if health_url.is_empty():
        return

    var request := HTTPRequest.new()
    request.name = "RenderWakeRequest"
    request.timeout = REQUEST_TIMEOUT_SECONDS
    add_child(request)
    request.request_completed.connect(
        func(
            _result: int,
            _response_code: int,
            _headers: PackedStringArray,
            _body: PackedByteArray
        ) -> void:
            request.queue_free()
    )
    var error: Error = request.request(health_url)
    if error != OK:
        request.queue_free()


func _health_url_from_websocket(websocket_url: String) -> String:
    if websocket_url.is_empty():
        return ""
    var result: String = websocket_url
    if result.begins_with("wss://"):
        result = "https://" + result.trim_prefix("wss://")
    elif result.begins_with("ws://"):
        result = "http://" + result.trim_prefix("ws://")
    elif not result.begins_with("https://") and not result.begins_with("http://"):
        return ""
    if result.ends_with("/ws"):
        result = result.left(result.length() - 3)
    return result.trim_suffix("/") + "/health"
