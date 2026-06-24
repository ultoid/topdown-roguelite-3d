extends Node

var items = {}

func _ready():
	_build_database()

func _build_database():
	items.clear()
	_traverse_children(self)

func _traverse_children(parent_node: Node):
	for child in parent_node.get_children():
		if child is CanvasItem:
			child.hide()
		if child is ItemData:
			var data = {
				"name": child.item_name,
				"description": child.description,
				"type": child.type,
				"rarity": child.rarity,
				"price": child.price,
				"weapon_type": child.weapon_type,
				"weapon_scene_path": child.weapon_scene_path,
				"icon_frame": child.frame,
				"texture": child.texture.resource_path if child.texture else "",
				"hframes": child.hframes,
				"vframes": child.vframes,
				"equipment_slot": child.equipment_slot
			}
			if child.effect_type != "None" and child.effect_type != "":
				data["effect_type"] = child.effect_type
				data["effect_amount"] = child.effect_amount
				if child.get("recipe_id") != null:
					data["recipe_id"] = child.recipe_id
			if child.bonus_p_atk > 0: data["bonus_p_atk"] = child.bonus_p_atk
			if child.bonus_p_def > 0: data["bonus_p_def"] = child.bonus_p_def
			if child.bonus_str > 0: data["bonus_str"] = child.bonus_str
			if child.bonus_int > 0: data["bonus_int"] = child.bonus_int
			if child.bonus_max_hp > 0: data["bonus_max_hp"] = child.bonus_max_hp
			if child.bonus_max_mp > 0: data["bonus_max_mp"] = child.bonus_max_mp
			
			data["weapon_element"] = child.weapon_element
			data["defense_element"] = child.defense_element
			
			var resistances = {}
			if child.resist_api > 0: resistances["api"] = child.resist_api
			if child.resist_air > 0: resistances["air"] = child.resist_air
			if child.resist_tanah > 0: resistances["tanah"] = child.resist_tanah
			if child.resist_udara > 0: resistances["udara"] = child.resist_udara
			if child.resist_listrik > 0: resistances["listrik"] = child.resist_listrik
			if child.resist_es > 0: resistances["es"] = child.resist_es
			if child.resist_besi > 0: resistances["besi"] = child.resist_besi
			if child.resist_suara > 0: resistances["suara"] = child.resist_suara
			if child.resist_cahaya > 0: resistances["cahaya"] = child.resist_cahaya
			if child.resist_kegelapan > 0: resistances["kegelapan"] = child.resist_kegelapan
			data["resistances"] = resistances
			
			var dmg_bonus = {}
			if child.bonus_dmg_api > 0: dmg_bonus["api"] = child.bonus_dmg_api
			if child.bonus_dmg_air > 0: dmg_bonus["air"] = child.bonus_dmg_air
			if child.bonus_dmg_tanah > 0: dmg_bonus["tanah"] = child.bonus_dmg_tanah
			if child.bonus_dmg_udara > 0: dmg_bonus["udara"] = child.bonus_dmg_udara
			if child.bonus_dmg_listrik > 0: dmg_bonus["listrik"] = child.bonus_dmg_listrik
			if child.bonus_dmg_es > 0: dmg_bonus["es"] = child.bonus_dmg_es
			if child.bonus_dmg_besi > 0: dmg_bonus["besi"] = child.bonus_dmg_besi
			if child.bonus_dmg_suara > 0: dmg_bonus["suara"] = child.bonus_dmg_suara
			if child.bonus_dmg_cahaya > 0: dmg_bonus["cahaya"] = child.bonus_dmg_cahaya
			if child.bonus_dmg_kegelapan > 0: dmg_bonus["kegelapan"] = child.bonus_dmg_kegelapan
			data["dmg_bonus"] = dmg_bonus
			
			var item_id = child.name.to_lower()
			items[item_id] = data
			
			if child.is_craftable and get_node_or_null("/root/Global"):
				var mats = {}
				if child.req_mat_1 != "" and child.req_amount_1 > 0: mats[child.req_mat_1] = child.req_amount_1
				if child.req_mat_2 != "" and child.req_amount_2 > 0: mats[child.req_mat_2] = child.req_amount_2
				if child.req_mat_3 != "" and child.req_amount_3 > 0: mats[child.req_mat_3] = child.req_amount_3
				
				if mats.size() > 0:
					Global.CRAFTING_RECIPES[item_id] = {
						"materials": mats,
						"time": child.craft_time
					}
		elif child.get_child_count() > 0:
			_traverse_children(child)

func get_item(item_id: String) -> Dictionary:
	if items.has(item_id):
		return items[item_id]
	return {}

func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item(item_id)
	if data.is_empty(): return null
	
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

func get_rarity_color(rarity_id: String) -> Color:
	match rarity_id.to_lower():
		"common": return Color(0.8, 0.8, 0.8, 0.8) # Putih/Abu-abu
		"rare": return Color(0.2, 0.5, 1.0, 0.8) # Biru
		"epic": return Color(0.6, 0.2, 0.8, 0.8) # Ungu
		"legendary": return Color(1.0, 0.8, 0.1, 0.8) # Emas
		"mythic": return Color(1.0, 0.2, 0.2, 0.8) # Merah
	return Color(0.2, 0.2, 0.2, 0.8) # Default gelap
