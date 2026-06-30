extends Node

var parts = {
	"Hair": {},
	"Beard": {}
}

func _ready():
	_build_database()

func _build_database():
	parts["Hair"].clear()
	parts["Beard"].clear()
	_traverse_children(self)

func _traverse_children(parent_node: Node):
	for child in parent_node.get_children():
		if child is CustomizationData:
			var data = {
				"name": child.part_name,
				"type": child.part_type,
				"mesh_path": child.mesh_path,
				"species": child.species,
				"position_offset": child.position_offset,
				"rotation_offset": child.rotation_offset,
				"scale_offset": child.scale_offset
			}
			var p_id = child.name.to_lower()
			
			if not parts.has(child.part_type):
				parts[child.part_type] = {}
				
			parts[child.part_type][p_id] = data
		elif child.get_child_count() > 0:
			_traverse_children(child)

func get_hair_list() -> Array:
	if parts.has("Hair"):
		return parts["Hair"].keys()
	return []

func get_beard_list() -> Array:
	if parts.has("Beard"):
		var list = parts["Beard"].keys()
		return list
	return []

func get_part_data(part_type: String, part_id: String) -> Dictionary:
	if parts.has(part_type) and parts[part_type].has(part_id):
		return parts[part_type][part_id]
	return {}

func get_part_path(part_type: String, part_id: String) -> String:
	var data = get_part_data(part_type, part_id)
	if data.has("mesh_path"):
		return data["mesh_path"]
	return ""
