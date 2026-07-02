@tool
extends SceneTree

func _init():
	print("--- SCRIPT RUNNING IN HEADLESS ---")
	var scene = load("res://Scenes/Entities/player.tscn")
	if not scene:
		print("Failed to load player.tscn")
		quit()
		return
		
	var instance = scene.instantiate()
	var pv = instance.get_node_or_null("Visuals/PlayerVisual")
	if not pv:
		print("PlayerVisual not found")
		quit()
		return
		
	print("PlayerVisual found!")
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(pv, meshes)
	print("Found meshes: ", meshes.size())
	for m in meshes:
		print("- ", m.name)
		
	quit()

func _collect_meshes(node: Node, result: Array):
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children(true):
		_collect_meshes(child, result)
