@tool
extends Node3D

@export_group("Body Shapes")

@export_range(0.0, 1.0) var masculine_feminine: float = 0.0:
	set(value):
		masculine_feminine = value
		_update_all_blend_shapes()

@export_range(0.0, 1.0) var slim_heavy: float = 0.0:
	set(value):
		slim_heavy = value
		_update_all_blend_shapes()

@export_range(0.0, 1.0) var buff_muscular: float = 0.0:
	set(value):
		buff_muscular = value
		_update_all_blend_shapes()

@export_range(0.0, 1.0) var skinny: float = 0.0:
	set(value):
		skinny = value
		_update_all_blend_shapes()


# Fungsi ini akan dipanggil otomatis setiap kali slider digeser
func _update_all_blend_shapes():
	# Jangan jalankan jika belum siap / tidak ada anak node
	if not is_inside_tree():
		return
		
	# Ambil semua anak node bertipe MeshInstance3D
	var meshes = _get_all_mesh_instances(self)
	
	for mesh_inst in meshes:
		# Kata kunci pencarian disesuaikan dengan akhiran nama Blend Shape dari Synty
		_apply_blend_shape_by_keyword(mesh_inst, "masculineFemi", masculine_feminine)
		_apply_blend_shape_by_keyword(mesh_inst, "defaultHeavy", slim_heavy)
		_apply_blend_shape_by_keyword(mesh_inst, "defaultBuff", buff_muscular)
		_apply_blend_shape_by_keyword(mesh_inst, "defaultSkinny", skinny)

# Fungsi untuk mencari nama Blend Shape yang mengandung kata kunci
func _apply_blend_shape_by_keyword(mesh_inst: MeshInstance3D, keyword: String, value: float):
	if mesh_inst.mesh == null:
		return
		
	var shape_count = mesh_inst.mesh.get_blend_shape_count()
	for i in range(shape_count):
		var shape_name = mesh_inst.mesh.get_blend_shape_name(i)
		# Jika nama blend shape mengandung kata kunci (contoh: mengandung kata "Heavy")
		if keyword.nocasecmp_to(shape_name) == 0 or shape_name.contains(keyword):
			mesh_inst.set_blend_shape_value(i, value)

# Fungsi rekursif untuk mencari SEMUA MeshInstance3D di dalam node ini (termasuk armor, rambut, dll)
func _get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		# Cari lagi ke dalam anak-anaknya
		result.append_array(_get_all_mesh_instances(child))
	return result
