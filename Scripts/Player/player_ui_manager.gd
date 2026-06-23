extends Node
class_name PlayerUIManager

@onready var player: CharacterBody3D = get_parent()

func _get_hud_canvas() -> CanvasLayer:
	if is_instance_valid(player.hud_canvas):
		return player.hud_canvas
	player.hud_canvas = get_tree().current_scene.get_node_or_null("PlayerHUDCanvas")
	if not is_instance_valid(player.hud_canvas):
		player.hud_canvas = CanvasLayer.new()
		player.hud_canvas.name = "PlayerHUDCanvas"
		player.hud_canvas.layer = 10
		get_tree().current_scene.add_child(player.hud_canvas)
	return player.hud_canvas



func _open_inventory():
	var existing = get_tree().current_scene.get_node_or_null("InventoryMenu")
	if existing:
		existing.queue_free()
		get_tree().paused = false
	else:
		var scene = load("res://Scenes/UI/inventory_menu.tscn")
		if scene and get_tree().current_scene:
			var menu = scene.instantiate()
			get_tree().current_scene.add_child(menu)
			menu.setup(player)
			get_tree().paused = true


func _open_skill_menu():
	var existing = get_tree().current_scene.get_node_or_null("SkillMenu")
	if existing:
		existing.queue_free()
		get_tree().paused = false
	else:
		var scene = load("res://Scenes/UI/skill_menu.tscn")
		if scene and get_tree().current_scene:
			var menu = scene.instantiate()
			get_tree().current_scene.add_child(menu)
			menu.setup(player)
			get_tree().paused = true


func toggle_menu():
	var existing_menu = get_tree().current_scene.get_node_or_null("CharacterMenu")
	if existing_menu:
		existing_menu.queue_free()
		get_tree().paused = false
	else:
		var char_scene = load("res://Scenes/UI/character_menu.tscn")
		if char_scene and get_tree().current_scene:
			var menu = char_scene.instantiate()
			get_tree().current_scene.add_child(menu)
			menu.setup(player)
			get_tree().paused = true


func _update_interaction_prompt():
	var closest = player._get_closest_interactable()
	
	if closest and not player.is_doing_life_skill and not player.is_farming_targeting:
		if not is_instance_valid(player.interaction_prompt):
			player.interaction_prompt = Label.new()
			player.interaction_prompt.add_theme_font_size_override("font_size", 12)
			player.interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			player.interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			player.interaction_prompt.add_theme_constant_override("outline_size", 2)
			player.interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			player.interaction_prompt.position = Vector2(-100, -50)
			player.interaction_prompt.custom_minimum_size = Vector2(200, 0)
			player.add_child(player.interaction_prompt)
			
		var action_text = "interaksi"
		if closest.name.begins_with("ResourceNode"):
			var yield_item = closest.get("yield_item")
			if yield_item == "wood":
				action_text = "menebang kayu"
			else:
				action_text = "menambang"
		elif closest.name.begins_with("ForagingNode"):
			action_text = "memungut"
		elif closest.name.begins_with("FarmingZone"):
			action_text = "menyiapkan lahan"
		elif closest.name.begins_with("CropPlot"):
			action_text = "mengelola lahan"
			
		player.interaction_prompt.text = "[Q] untuk " + action_text
		player.interaction_prompt.show()
	else:
		if is_instance_valid(player.interaction_prompt):
			player.interaction_prompt.hide()


func _open_crafting_menu():
	var existing = get_tree().current_scene.get_node_or_null("CraftingMenu")
	if existing:
		existing.queue_free()
		get_tree().paused = false
	else:
		var scene = load("res://Scenes/UI/crafting_menu.tscn")
		if scene and get_tree().current_scene:
			var menu = scene.instantiate()
			get_tree().current_scene.add_child(menu)




func _process(delta):
	if player.is_dead: return
	var cam = get_viewport().get_camera_3d()
	if cam:
		var screen_pos = cam.unproject_position(player.global_position + Vector3(0, 2.0, 0))
		if is_instance_valid(player.cast_bar): player.cast_bar.position = screen_pos + Vector2(-15, -40)
		if is_instance_valid(player.spin_bar): player.spin_bar.position = screen_pos + Vector2(-15, -40)
		if is_instance_valid(player.magic_charge_bar): player.magic_charge_bar.position = screen_pos + Vector2(-20, -50)
		if is_instance_valid(player.life_skill_bar): player.life_skill_bar.position = screen_pos + Vector2(-20, -60)
		if is_instance_valid(player.interaction_prompt): player.interaction_prompt.position = screen_pos + Vector2(-100, -80)
