@tool
extends SceneTree

func _init():
	print("Starting modification...")
	var packed_scene = load("res://Scenes/Entities/player.tscn")
	if not packed_scene:
		print("Failed to load scene.")
		quit(1)
		return

	var scene_root = packed_scene.instantiate()
	var anim_tree = scene_root.get_node_or_null("AnimationTree")
	if not anim_tree:
		print("No AnimationTree found.")
		quit(1)
		return

	var old_root = anim_tree.tree_root
	if old_root is AnimationNodeBlendTree:
		print("Already a BlendTree.")
		quit(0)
		return

	if not old_root is AnimationNodeStateMachine:
		print("Old root is not a StateMachine.")
		quit(1)
		return

	print("Converting to BlendTree...")
	var blend_tree = AnimationNodeBlendTree.new()
	
	# Add the old StateMachine to the BlendTree
	blend_tree.add_node("BaseStateMachine", old_root)
	
	# Add Blend2 for maskable animation
	var blend2 = AnimationNodeBlend2.new()
	blend2.filter_enabled = true
	blend_tree.add_node("Blend2", blend2)
	
	# Add an empty StateMachine for the upper body
	var upper_sm = AnimationNodeStateMachine.new()
	blend_tree.add_node("UpperStateMachine", upper_sm)
	
	# Connect them
	blend_tree.connect_node("Blend2", 0, "BaseStateMachine")
	blend_tree.connect_node("Blend2", 1, "UpperStateMachine")
	blend_tree.connect_node("output", 0, "Blend2")

	anim_tree.tree_root = blend_tree

	var err = PackedScene.new()
	err.pack(scene_root)
	ResourceSaver.save(err, "res://Scenes/Entities/player.tscn")

	print("Modification successful.")
	quit(0)
