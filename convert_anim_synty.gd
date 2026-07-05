extends SceneTree

var bone_map = {
	"Hips": "mixamorig_Hips",
	"Spine": "mixamorig_Spine",
	"Chest": "mixamorig_Spine1",
	"UpperChest": "mixamorig_Spine2",
	"Neck": "mixamorig_Neck",
	"Head": "mixamorig_Head",
	
	"LeftUpperArm": "mixamorig_LeftArm",
	"LeftLowerArm": "mixamorig_LeftForeArm",
	"LeftHand": "mixamorig_LeftHand",
	"RightUpperArm": "mixamorig_RightArm",
	"RightLowerArm": "mixamorig_RightForeArm",
	"RightHand": "mixamorig_RightHand",
	
	"LeftUpperLeg": "mixamorig_LeftUpLeg",
	"LeftLowerLeg": "mixamorig_LeftLeg",
	"LeftFoot": "mixamorig_LeftFoot",
	"RightUpperLeg": "mixamorig_RightUpLeg",
	"RightLowerLeg": "mixamorig_RightLeg",
	"RightFoot": "mixamorig_RightFoot",
	
	"LeftShoulder": "mixamorig_LeftShoulder",
	"RightShoulder": "mixamorig_RightShoulder",
	
	"LeftToes": "mixamorig_LeftToeBase",
	"RightToes": "mixamorig_RightToeBase"
}

func _init():
	print("Starting conversion...")
	var anim_path = "res://Assets/Models/Staff/staff_idle3.res"
	var anim = load(anim_path)
	if not anim or not anim is Animation:
		print("Failed to load animation at: ", anim_path)
		quit()
		return
		
	var modified = false
	for i in range(anim.get_track_count()):
		var path = anim.track_get_path(i)
		var path_str = str(path)
		var parts = path_str.split(":")
		if parts.size() == 2:
			var node_path = parts[0]
			var bone_name = parts[1]
			
			if bone_map.has(bone_name):
				var new_bone_name = bone_map[bone_name]
				var new_path = node_path + ":" + new_bone_name
				anim.track_set_path(i, NodePath(new_path))
				print("Converted: ", bone_name, " -> ", new_bone_name)
				modified = true
	
	if modified:
		var err = ResourceSaver.save(anim, anim_path)
		if err == OK:
			print("Successfully saved converted animation to ", anim_path)
		else:
			print("Error saving: ", err)
	else:
		print("No tracks needed conversion or already converted.")
	quit()
