@tool
extends SceneTree

func _init():
	var path = "res://Assets/Models/CharacterCustomization/Meshes/Species/Humans/SK_HUMN_BASE_07_02HAIR_HU01.fbx"
	var scene = ResourceLoader.load(path)
	var inst = scene.instantiate()
	_print_tree(inst, "")
	quit()

func _print_tree(node: Node, indent: String):
	var t = ""
	if node is Node3D:
		t = str(node.transform)
	print(indent + node.name + " (" + node.get_class() + ") transform: " + t)
	for child in node.get_children():
		_print_tree(child, indent + "  ")
