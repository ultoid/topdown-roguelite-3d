extends Node

var skills = {}

func _ready():
	_build_database()

func _build_database():
	skills.clear()
	_traverse_node(self)

func _traverse_node(node: Node):
	for child in node.get_children():
		if child is CanvasItem:
			child.hide()
		if child is SkillData:
			var data = {
				"name": child.skill_name,
				"description": child.description,
				"type": child.type,
				"class_owner": child.class_owner,
				"max_level": child.max_level,
				"prerequisite_skill": child.prerequisite_skill,
				"prerequisite_level": child.prerequisite_level,
				"ep_costs": child.ep_costs.duplicate(),
				"mp_costs": child.mp_costs.duplicate(),
				"cooldowns": child.cooldowns.duplicate(),
				"cast_times": child.cast_times.duplicate(),
				"damages": child.damages.duplicate(),
				"effect_durations": child.effect_durations.duplicate(),
				"crit_chances": child.crit_chances.duplicate(),
				"aoe_radiuses": child.aoe_radiuses.duplicate(),
				"ranges": child.ranges.duplicate(),
				"icon_color": child.icon_color,
				"icon_frame": child.frame,
				"texture": child.texture.resource_path if child.texture else "",
				"hframes": child.hframes,
				"vframes": child.vframes
			}
			skills[child.name.to_lower()] = data
		_traverse_node(child)

func get_skill(id: String) -> Dictionary:
	if skills.has(id.to_lower()):
		return skills[id.to_lower()]
	return {}

func get_skill_icon(id: String):
	var data = get_skill(id)
	if data.is_empty() or data["texture"] == "": return null
	
	var tex = load(data["texture"])
	if tex:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		var w = tex.get_width() / data["hframes"]
		var h = tex.get_height() / data["vframes"]
		var x = (data["icon_frame"] % data["hframes"]) * w
		var y = int(data["icon_frame"] / data["hframes"]) * h
		atlas.region = Rect2(x, y, w, h)
		return atlas
	return null

func get_skill_val(skill_id: String, stat: String, level: int):
	var data = get_skill(skill_id)
	if data.is_empty(): return 0
	
	if data.has(stat):
		var arr = data[stat]
		if arr is Array:
			if arr.size() == 0: return 0
			var idx = clamp(level - 1, 0, arr.size() - 1)
			return arr[idx]
	return 0
