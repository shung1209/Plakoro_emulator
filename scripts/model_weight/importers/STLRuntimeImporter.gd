class_name STLRuntimeImporter
extends RefCounted

func load_mesh(path: String) -> ArrayMesh:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var bytes := f.get_buffer(f.get_length())
    if bytes.size() < 84:
        return _load_ascii(bytes.get_string_from_utf8())
    # Binary STL: uint32 triangle count at byte 80; exact length = 84 + n*50.
    var n: int = bytes.decode_u32(80)
    if 84 + int(n) * 50 <= bytes.size():
        return _load_binary(bytes, n)
    return _load_ascii(bytes.get_string_from_utf8())

func _load_binary(bytes: PackedByteArray, n: int) -> ArrayMesh:
    var verts := PackedVector3Array()
    var normals := PackedVector3Array()
    verts.resize(n * 3)
    normals.resize(n * 3)
    var off: int = 84
    for i in range(n):
        var normal := Vector3(
            bytes.decode_float(off),
            bytes.decode_float(off + 4),
            bytes.decode_float(off + 8)
        )
        off += 12
        for j in range(3):
            var v := Vector3(
                bytes.decode_float(off),
                bytes.decode_float(off + 4),
                bytes.decode_float(off + 8)
            )
            off += 12
            verts[i*3+j] = v
            normals[i*3+j] = normal
        off += 2
    return _make_mesh(verts, normals)

func _load_ascii(text: String) -> ArrayMesh:
    var verts := PackedVector3Array()
    var normals := PackedVector3Array()
    var current_normal := Vector3.ZERO
    for raw in text.split("\n"):
        var line := raw.strip_edges()
        if line.begins_with("facet normal "):
            var p := line.split(" ", false)
            if p.size() >= 5:
                current_normal = Vector3(float(p[2]), float(p[3]), float(p[4]))
        elif line.begins_with("vertex "):
            var p := line.split(" ", false)
            if p.size() >= 4:
                verts.append(Vector3(float(p[1]), float(p[2]), float(p[3])))
                normals.append(current_normal)
    if verts.is_empty():
        return null
    return _make_mesh(verts, normals)

func _make_mesh(verts: PackedVector3Array, normals: PackedVector3Array) -> ArrayMesh:
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh
