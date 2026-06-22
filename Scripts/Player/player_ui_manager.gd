extends Node
class_name PlayerUIManager

var player: CharacterBody3D
var interaction_prompt: Label

func setup(p_player: CharacterBody3D):
	player = p_player

func spawn_damage_text(amount: int, color: Color):
	if not player.is_inside_tree(): return
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 64
	label.outline_size = 12
	label.text = str(amount)
	label.modulate = color
	label.global_position = player.global_position + Vector3(0, 0.5, 0)
	 
	player.get_tree().current_scene.add_child(label)
	var tween = player.get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

func spawn_floating_text(msg: String, color: Color):
	if not player.is_inside_tree(): return
	print("--- SPAWN TEXT: ", msg, " ---")
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 64
	label.outline_size = 12
	label.text = msg
	label.modulate = color
	player.get_tree().current_scene.add_child(label)
	label.global_position = player.global_position + Vector3(0, 0.5, 0)
	var tween = player.get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

func show_game_over():
	var go_scene = load("res://Scenes/UI/game_over_hud.tscn")
	if go_scene and player.get_tree().current_scene:
		var go = go_scene.instantiate()
		player.get_tree().current_scene.add_child(go)
		if go.has_method("show_game_over"):
			go.show_game_over(player.survival_time, player.enemies_killed, player.level, player.coins)

func _update_interaction_prompt():
	var closest = player._get_closest_interactable()
	
	if closest and not player.is_doing_life_skill and not player.is_farming_targeting:
		if not is_instance_valid(interaction_prompt):
			interaction_prompt = Label.new()
			interaction_prompt.add_theme_font_size_override("font_size", 12)
			interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			interaction_prompt.add_theme_constant_override("outline_size", 2)
			interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			interaction_prompt.position = Vector2(-100, -50)
			interaction_prompt.custom_minimum_size = Vector2(200, 0)
			player.add_child(interaction_prompt)
			
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
			
		interaction_prompt.text = "[Q] untuk " + action_text
		interaction_prompt.show()
	else:
		if is_instance_valid(interaction_prompt):
			interaction_prompt.hide()
