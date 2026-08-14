class_name GLTFRuntimeImporter
extends RefCounted

func load_scene(path: String) -> Node:
    var doc := GLTFDocument.new()
    var state := GLTFState.new()
    var err: Error = doc.append_from_file(path, state)
    if err != OK:
        return null
    return doc.generate_scene(state)
