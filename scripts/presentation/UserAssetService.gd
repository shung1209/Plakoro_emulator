extends RefCounted

const MANIFEST: Script = preload(
    "res://scripts/presentation/BuiltinAssetManifest.gd"
)

const BUILTIN_ROOT: String = "res://assets"
const USER_ROOT: String = "user://user_database/assets"

const REQUIRED_DIRECTORIES: Array[String] = [
    "pokemon",
    "pokemon/images",
    "pokemon/models",
    "ui",
    "ui/energy",
    "ui/kyokoro"
]


static func ensure_layout(root_path: String = USER_ROOT) -> bool:
    var root_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(root_path)
    )
    if root_error != OK and root_error != ERR_ALREADY_EXISTS:
        return false

    var directories: Array[String] = REQUIRED_DIRECTORIES.duplicate()
    for manifest_directory: String in MANIFEST.directories():
        if not directories.has(manifest_directory):
            directories.append(manifest_directory)

    for directory: String in directories:
        var path: String = root_path.path_join(directory)
        var error: Error = DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(path)
        )
        if error != OK and error != ERR_ALREADY_EXISTS:
            return false
    return true


static func bootstrap_from_builtin(
    destination_root: String = USER_ROOT,
    source_root: String = BUILTIN_ROOT
) -> Dictionary:
    var result: Dictionary = {
        "success": ensure_layout(destination_root),
        "copied": [],
        "skipped_existing": [],
        "errors": []
    }
    if not bool(result.get("success", false)):
        result["errors"].append("Could not initialize user asset layout.")
        return result

    for relative_path: String in MANIFEST.all_files():
        var source_path: String = source_root.path_join(relative_path)
        var destination_path: String = destination_root.path_join(relative_path)
        _copy_if_missing(source_path, destination_path, result)

    return result


static func resolve(relative_path: String) -> String:
    var normalized: String = relative_path.trim_prefix("/")
    if normalized.is_empty():
        return ""

    var user_path: String = USER_ROOT.path_join(normalized)
    if FileAccess.file_exists(user_path):
        return user_path

    var builtin_path: String = BUILTIN_ROOT.path_join(normalized)
    if ResourceLoader.exists(builtin_path) or FileAccess.file_exists(builtin_path):
        return builtin_path

    return ""


static func load_texture(relative_path: String) -> Texture2D:
    var path: String = resolve(relative_path)
    if path.is_empty():
        return null

    if path.begins_with("user://"):
        return _load_user_texture(path)

    if not ResourceLoader.exists(path):
        return null
    var resource: Resource = load(path)
    if resource is Texture2D:
        return resource as Texture2D
    return null


static func _load_user_texture(path: String) -> Texture2D:
    var image: Image = Image.new()
    var error: Error = image.load(path)
    if error != OK or image.is_empty():
        return null
    return ImageTexture.create_from_image(image)


static func _copy_if_missing(
    source_path: String,
    destination_path: String,
    result: Dictionary
) -> void:
    if FileAccess.file_exists(destination_path):
        result["skipped_existing"].append(destination_path)
        return

    if not FileAccess.file_exists(source_path):
        result["success"] = false
        result["errors"].append("Built-in asset missing: " + source_path)
        return

    var parent: String = destination_path.get_base_dir()
    var make_error: Error = DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(parent)
    )
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        result["success"] = false
        result["errors"].append("Could not create asset directory: " + parent)
        return

    var source: FileAccess = FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        result["success"] = false
        result["errors"].append("Could not read built-in asset: " + source_path)
        return
    var bytes: PackedByteArray = source.get_buffer(source.get_length())
    source.close()

    var destination: FileAccess = FileAccess.open(destination_path, FileAccess.WRITE)
    if destination == null:
        result["success"] = false
        result["errors"].append("Could not create user asset: " + destination_path)
        return
    destination.store_buffer(bytes)
    destination.close()
    result["copied"].append(destination_path)
