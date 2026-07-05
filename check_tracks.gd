@tool
extends EditorScript
func _run():
	var anim = load("res://Assets/Models/Staff/staff_attack.res")
	if anim:
		for i in range(min(10, anim.get_track_count())):
			print(anim.track_get_path(i))
