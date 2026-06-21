extends "res://Scripts/Enemy/enemy.gd"

func _ready():
	super._ready()
	# Mewarnai model menjadi merah
	var meshes = find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mat = m.get_active_material(0)
		if mat == null and m.mesh:
			mat = m.mesh.surface_get_material(0)
		if mat:
			var new_mat = mat.duplicate()
			new_mat.albedo_color = Color(1.0, 0.2, 0.2)
			m.set_surface_override_material(0, new_mat)
