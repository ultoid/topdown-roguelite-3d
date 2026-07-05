@tool
extends EditorScript
func _run():
	var state = load("res://Assets/Models/Staff/Mage@Attack1.FBX")
	var instance = state.instantiate()
	var anim_player = instance.get_node("AnimationPlayer")
	var anim = anim_player.get_animation(anim_player.get_animation_list()[0])
	var names = []
	for i in range(anim.get_track_count()):
		var path = anim.track_get_path(i)
		var bone = str(path).split(":")[-1]
		if not names.has(bone):
			names.append(bone)
	print("Raw bones:", names)
	var f = FileAccess.open("res://bones_dump.txt", FileAccess.WRITE)
	f.store_string(str(names))
	f.close()
