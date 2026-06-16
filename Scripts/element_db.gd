extends Node

var elements = {}

func _ready():
	_build_database()

func _build_database():
	elements.clear()
	for child in get_children():
		if child is Sprite2D:
			var data = {
				"name": child.name.to_lower(),
				"texture": child.texture.resource_path if child.texture else "",
				"hframes": child.hframes,
				"vframes": child.vframes,
				"icon_frame": child.frame
			}
			elements[child.name.to_lower()] = data

func get_element_icon(element_id: String) -> Texture2D:
	if elements.has(element_id):
		var data = elements[element_id]
		if data.has("texture") and data["texture"] != "":
			var atlas = AtlasTexture.new()
			atlas.atlas = load(data["texture"])
			
			var hf = data.get("hframes", 1)
			var vf = data.get("vframes", 1)
			var frame = data.get("icon_frame", 0)
			
			if atlas.atlas and hf > 0 and vf > 0:
				var size = Vector2(atlas.atlas.get_width() / hf, atlas.atlas.get_height() / vf)
				var x = (frame % hf) * size.x
				var y = int(frame / hf) * size.y
				atlas.region = Rect2(Vector2(x, y), size)
				return atlas
	return null

func get_element_color(element_id: String) -> Color:
	match element_id.to_lower():
		"api": return Color(1.0, 0.4, 0.2)
		"air": return Color(0.2, 0.6, 1.0)
		"tanah": return Color(0.6, 0.4, 0.2)
		"udara": return Color(0.6, 0.8, 0.8)
		"listrik": return Color(0.8, 0.8, 0.2)
		"es": return Color(0.6, 0.9, 1.0)
		"besi": return Color(0.7, 0.7, 0.7)
		"suara": return Color(0.8, 0.2, 0.8)
		"cahaya": return Color(1.0, 1.0, 0.6)
		"kegelapan": return Color(0.3, 0.1, 0.4)
		"netral": return Color(0.9, 0.9, 0.9)
	return Color(0.5, 0.5, 0.5)
