class_name OBJRuntimeImporter
extends RefCounted

func load_mesh(path: String) -> ArrayMesh:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var src: Array[Vector3] = []
    var out := PackedVector3Array()
    while not f.eof_reached():
        var line := f.get_line().strip_edges()
        if line.begins_with("v "):
            var p := line.split(" ", false)
            if p.size() >= 4:
                src.append(Vector3(float(p[1]), float(p[2]), float(p[3])))
        elif line.begins_with("f "):
            var p := line.split(" ", false)
            var ids: Array[int] = []
            for i in range(1, p.size()):
                var token := p[i].split("/")[0]
                var idx: int = int(token)
                if idx < 0: idx = src.size() + idx
                else: idx -= 1
                if idx >= 0 and idx < src.size():
                    ids.append(idx)
            # fan triangulation
            for i in range(1, ids.size()-1):
                out.append(src[ids[0]])
                out.append(src[ids[i]])
                out.append(src[ids[i+1]])
    if out.is_empty():
        return null
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for v in out:
        st.set_normal(Vector3.ZERO)
        st.add_vertex(v)
    st.generate_normals()
    return st.commit()
