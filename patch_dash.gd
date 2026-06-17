@tool
extends SceneTree

func _init():
	print("Starting animation patch...")
	var anim = load("res://Assets/Models/dash.res") as Animation
	if not anim:
		print("Failed to load dash.res")
		quit()
		return
		
	var path_to_hips = "Skeleton3D:mixamorig_Hips"
	var track_idx = anim.find_track(NodePath(path_to_hips), Animation.TYPE_POSITION_3D)
	if track_idx != -1:
		print("Found position track for hips!")
		var key_count = anim.track_get_key_count(track_idx)
		for i in range(key_count):
			var key_val = anim.track_get_key_value(track_idx, i)
			# Keep Y (bounce), zero out X and Z (horizontal movement)
			# Actually, we might want to keep the starting X and Z offset if there is one, but let's just use 0
			var new_val = Vector3(0, key_val.y, 0)
			anim.track_set_key_value(track_idx, i, new_val)
			
		var err = ResourceSaver.save(anim, "res://Assets/Models/dash.res")
		if err == OK:
			print("Successfully patched dash.res!")
		else:
			print("Failed to save dash.res: ", err)
	else:
		print("Could not find position track for hips.")
		
	quit()
