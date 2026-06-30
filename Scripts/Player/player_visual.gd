@tool
extends Node3D

## PlayerVisual.gd
## Auto-merge tulang dari rambut/jenggot di Base_Hair dan Cust_Beard
## ke dalam GeneralSkeleton utama, termasuk physics bones yang kurang.

func _ready() -> void:
	call_deferred("merge_all_hair_bones")

func merge_all_hair_bones() -> void:
	var gen_skeleton := get_node_or_null("SK_BaseModel/GeneralSkeleton") as Skeleton3D
	if not is_instance_valid(gen_skeleton):
		push_warning("PlayerVisual: GeneralSkeleton tidak ditemukan!")
		return

	print("PlayerVisual: Memulai merge bones...")

	var containers := [
		get_node_or_null("SK_BaseModel/GeneralSkeleton/Base_Hair"),
		get_node_or_null("SK_BaseModel/GeneralSkeleton/Cust_Beard"),
	]

	for container in containers:
		if not is_instance_valid(container):
			continue
		# Kumpulkan semua Skeleton3D dari dalam container (rekursif manual)
		var src_skeletons: Array[Skeleton3D] = []
		_collect_skeletons(container, gen_skeleton, src_skeletons)

		print("PlayerVisual: Ditemukan %d source skeleton di '%s'" % [src_skeletons.size(), container.name])

		# Merge semua skeleton yang ditemukan
		for src_skel in src_skeletons:
			_merge_bones(src_skel, gen_skeleton)

		# Redirect semua MeshInstance3D di container ke GeneralSkeleton
		var all_meshes: Array[MeshInstance3D] = []
		_collect_meshes(container, all_meshes)
		print("PlayerVisual: Ditemukan %d mesh di '%s'" % [all_meshes.size(), container.name])
		for mesh in all_meshes:
			mesh.skeleton = mesh.get_path_to(gen_skeleton)
			# Fallback: tambah bone yang ada di Skin tapi belum ada di GeneralSkeleton
			_fix_missing_skin_bones(mesh, gen_skeleton)

	print("PlayerVisual: Merge selesai! GeneralSkeleton sekarang punya %d bones." % gen_skeleton.get_bone_count())

## Kumpulkan semua Skeleton3D secara rekursif, kecuali GeneralSkeleton utama
func _collect_skeletons(node: Node, exclude: Skeleton3D, result: Array[Skeleton3D]) -> void:
	for child in node.get_children():
		if child is Skeleton3D and child != exclude:
			result.append(child as Skeleton3D)
		_collect_skeletons(child, exclude, result)

## Kumpulkan semua MeshInstance3D secara rekursif
func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, result)

## Merge bones dari source skeleton ke target skeleton (3 pass)
func _merge_bones(source: Skeleton3D, target: Skeleton3D) -> void:
	var newly_added: Array[int] = []

	# Pass 1: Tambah tulang yang belum ada + set rest pose
	for i in range(source.get_bone_count()):
		var b_name := source.get_bone_name(i)
		if target.find_bone(b_name) == -1:
			target.add_bone(b_name)
			var new_idx := target.find_bone(b_name)
			target.set_bone_rest(new_idx, source.get_bone_rest(i))
			newly_added.append(new_idx)
			print("PlayerVisual: [merge_bones] Menambah tulang '%s'" % b_name)

	if newly_added.is_empty():
		return

	# Pass 2: Set parent (setelah semua tulang ada)
	for i in range(source.get_bone_count()):
		var b_name := source.get_bone_name(i)
		var target_idx := target.find_bone(b_name)
		if target_idx not in newly_added:
			continue
		var p_src_idx := source.get_bone_parent(i)
		if p_src_idx != -1:
			var p_name := source.get_bone_name(p_src_idx)
			var p_target_idx := target.find_bone(p_name)
			if p_target_idx != -1:
				target.set_bone_parent(target_idx, p_target_idx)

	# Pass 3: Reset pose = rest agar tidak jatuh ke origin
	for new_idx in newly_added:
		target.reset_bone_pose(new_idx)

## Fallback: tambah tulang yang ada di Skin tapi belum ada di GeneralSkeleton
## Berguna jika MeshInstance3D tidak punya source Skeleton3D (mesh diekstrak tanpa skeleton)
func _fix_missing_skin_bones(mesh_inst: MeshInstance3D, gen_skeleton: Skeleton3D) -> void:
	var skin := mesh_inst.skin
	if not skin:
		return

	var head_idx := gen_skeleton.find_bone("Head")
	var newly_added: Array[int] = []

	for i in range(skin.get_bind_count()):
		var b_name := skin.get_bind_name(i)
		if b_name.is_empty() or gen_skeleton.find_bone(b_name) != -1:
			continue

		# Bone ada di Skin tapi tidak di GeneralSkeleton
		gen_skeleton.add_bone(b_name)
		var new_idx := gen_skeleton.find_bone(b_name)

		# Ambil posisi dari inverse bind matrix (lebih akurat)
		# get_bind_pose = inverse bind matrix → inverse-nya = world transform saat bind
		var bind_world := skin.get_bind_pose(i).affine_inverse()

		if head_idx != -1:
			gen_skeleton.set_bone_parent(new_idx, head_idx)
			var head_global := gen_skeleton.get_bone_global_rest(head_idx)
			gen_skeleton.set_bone_rest(new_idx, head_global.affine_inverse() * bind_world)
		else:
			gen_skeleton.set_bone_rest(new_idx, bind_world)

		newly_added.append(new_idx)
		print("PlayerVisual: [fix_skin] Menambah tulang '%s' dari Skin" % b_name)

	for new_idx in newly_added:
		gen_skeleton.reset_bone_pose(new_idx)
