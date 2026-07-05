extends SceneTree
func _init():
    var f = FileAccess.open("anim_len.txt", FileAccess.WRITE)
    var scene = load("res://Scenes/Entities/player.tscn")
    if not scene:
        f.store_line("scene failed")
        quit()
        return
    var inst = scene.instantiate()
    var ap = inst.find_child("AnimationPlayer", true, false)
    if not ap:
        f.store_line("no ap")
    else:
        var found = false
        for lib_name in ap.get_animation_library_list():
            var lib = ap.get_animation_library(lib_name)
            for anim_name in lib.get_animation_list():
                if "damage" in anim_name.to_lower() or "hit" in anim_name.to_lower():
                    var anim = lib.get_animation(anim_name)
                    f.store_line(anim_name + ": " + str(anim.length))
                    found = true
        if not found:
            f.store_line("no hit anim")
    f.close()
    quit()
