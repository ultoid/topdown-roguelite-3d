extends SceneTree
func _init():
    var f = FileAccess.open("user://anim_nodes.txt", FileAccess.WRITE)
    var scene = load("res://Scenes/Entities/player.tscn")
    if scene:
        var inst = scene.instantiate()
        var at = inst.find_child("AnimationTree", true, false)
        if at and at.tree_root is AnimationNodeBlendTree:
            f.store_line("BlendTree nodes:")
            for node_name in at.tree_root.nodes:
                f.store_line("- " + str(node_name) + " (" + str(at.tree_root.get_node(node_name).get_class()) + ")")
    f.close()
    quit()
