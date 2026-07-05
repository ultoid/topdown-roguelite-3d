@tool
extends EditorScript
func _run():
	var anim = load("res://Assets/Models/Staff/staff_idle3.res")
	var types = []
	for i in range(min(5, anim.get_track_count())):
		types.append(anim.track_get_type(i))
	var f = FileAccess.open("res://track_types.txt", FileAccess.WRITE)
	f.store_string(str(types))
	f.close()
