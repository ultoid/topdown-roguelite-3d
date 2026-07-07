@tool
extends EditorScript

# Peta terjemahan dari tulang Explosive LLC ke tulang Synty (Unreal Engine)
var bone_map = {
	"B_Pelvis": "pelvis",
	"B_Spine": "spine_01",
	"B_Spine1": "spine_02",
	"B_Spine2": "spine_03",
	"B_Neck": "neck_01",
	"B_Head": "head",
	
	"B_L_Clavicle": "clavicle_l",
	"B_L_UpperArm": "upperarm_l",
	"B_L_Forearm": "lowerarm_l",
	"B_L_Hand": "hand_l",
	"B_L_Thigh": "thigh_l",
	"B_L_Calf": "calf_l",
	"B_L_Foot": "foot_l",
	"B_L_Toe0": "ball_l",
	
	"B_R_Clavicle": "clavicle_r",
	"B_R_UpperArm": "upperarm_r",
	"B_R_Forearm": "lowerarm_r",
	"B_R_Hand": "hand_r",
	"B_R_Thigh": "thigh_r",
	"B_R_Calf": "calf_r",
	"B_R_Foot": "foot_r",
	"B_R_Toe0": "ball_r",
	
	"B_L_Finger0": "thumb_01_l",
	"B_L_Finger01": "thumb_02_l",
	"B_L_Finger02": "thumb_03_l",
	"B_L_Finger1": "index_01_l",
	"B_L_Finger11": "index_02_l",
	"B_L_Finger12": "index_03_l",
	"B_L_Finger2": "middle_01_l",
	"B_L_Finger21": "middle_02_l",
	"B_L_Finger22": "middle_03_l",
	"B_L_Finger3": "ring_01_l",
	"B_L_Finger31": "ring_02_l",
	"B_L_Finger32": "ring_03_l",
	"B_L_Finger4": "pinky_01_l",
	"B_L_Finger41": "pinky_02_l",
	"B_L_Finger42": "pinky_03_l",
	
	"B_R_Finger0": "thumb_01_r",
	"B_R_Finger01": "thumb_02_r",
	"B_R_Finger02": "thumb_03_r",
	"B_R_Finger1": "index_01_r",
	"B_R_Finger11": "index_02_r",
	"B_R_Finger12": "index_03_r",
	"B_R_Finger2": "middle_01_r",
	"B_R_Finger21": "middle_02_r",
	"B_R_Finger22": "middle_03_r",
	"B_R_Finger3": "ring_01_r",
	"B_R_Finger31": "ring_02_r",
	"B_R_Finger32": "ring_03_r",
	"B_R_Finger4": "pinky_01_r",
	"B_R_Finger41": "pinky_02_r",
	"B_R_Finger42": "pinky_03_r"
}

func _run():
	var source_file = "res://sample/ExplosiveLCC_Swordsman@Idle.FBX"
	var target_file = "res://sample/Swordsman_Idle_Synty.tres"
	var skeleton_node_name = "%GeneralSkeleton" # Sesuaikan jika path-nya berbeda
	
	print("Membaca animasi dari: ", source_file)
	# Load scene
	var scene = ResourceLoader.load(source_file)
	if not scene:
		print("Gagal membaca FBX. Pastikan file ada.")
		return
		
	var anim_player = scene.instantiate().get_node("AnimationPlayer")
	if not anim_player or not anim_player.has_animation("Take 001"):
		print("Gagal mencari animasi Take 001")
		return
		
	var source_anim = anim_player.get_animation("Take 001")
	var new_anim = source_anim.duplicate(true)
	new_anim.resource_name = "Explosive_Idle_Synty"
	
	var track_count = new_anim.get_track_count()
	var renamed_count = 0
	
	for i in range(track_count):
		var path = new_anim.track_get_path(i)
		var path_str = str(path)
		
		# Ekstrak nama node asli (mengabaikan properti seperti :position atau :rotation)
		var node_path_str = path_str.split(":")[0]
		var parts = node_path_str.split("/")
		var actual_bone_name = parts[parts.size() - 1]
		
		if bone_map.has(actual_bone_name):
			var new_bone_name = bone_map[actual_bone_name]
			# Rakit ulang path-nya agar menunjuk ke %GeneralSkeleton
			var new_path = NodePath(skeleton_node_name + ":" + new_bone_name)
			new_anim.track_set_path(i, new_path)
			renamed_count += 1
		else:
			# Opsional: Jika ada track sisa yang tidak dikenali, biarkan saja atau bisa dihapus
			pass
			
	print("Berhasil menerjemahkan ", renamed_count, " track tulang.")
	
	var err = ResourceSaver.save(new_anim, target_file)
	if err == OK:
		print("SUKSES! Animasi baru disimpan di: ", target_file)
		EditorInterface.get_resource_filesystem().scan()
	else:
		print("GAGAL menyimpan file: ", err)
