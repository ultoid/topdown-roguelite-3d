extends SceneTree

func _init():
    var f = FileAccess.open("anim_output.txt", FileAccess.WRITE)
    var anim = ResourceLoader.load("res://Assets/Models/Sword/sword_heavyattack.res") as Animation
    if not anim:
        f.store_line("Failed to load animation")
        quit()
        return
        
    f.store_line("Anim length: " + str(anim.length))
    for i in range(anim.get_track_count()):
        var track_name = str(anim.track_get_path(i))
        if track_name.ends_with(":Hips") or track_name.ends_with(":Root") or track_name.ends_with(":mixamorig_Hips") or track_name.ends_with(":pelvis"):
            if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
                f.store_line("Found root position track: " + track_name)
                var key_count = anim.track_get_key_count(i)
                if key_count > 0:
                    var first_pos = anim.track_get_key_value(i, 0)
                    var last_pos = anim.track_get_key_value(i, key_count - 1)
                    f.store_line("First pos: " + str(first_pos))
                    f.store_line("Last pos: " + str(last_pos))
                    var dist = first_pos.distance_to(last_pos)
                    var z_dist = last_pos.z - first_pos.z
                    var x_dist = last_pos.x - first_pos.x
                    f.store_line("Total distance: " + str(dist))
                    f.store_line("Z distance: " + str(z_dist))
                    f.store_line("X distance: " + str(x_dist))
    f.close()
    quit()
