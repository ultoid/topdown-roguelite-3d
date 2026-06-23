extends Node
class_name PlayerLifeSkill

@onready var player: CharacterBody3D = get_parent()

func _get_closest_interactable() -> Node:
	if player.is_dead or player.is_casting or player.is_attacking or player.is_dashing or player.is_targeting: return null
	
	var interactables = get_tree().get_nodes_in_group("Interactable")
	var closest_dist = 50.0
	
	var valid_nodes = []
	for node in interactables:
		if not is_instance_valid(node) or not node.is_inside_tree(): continue
		
		var dist = player.global_position.distance_to(node.global_position)
		if dist < closest_dist or (node is Area3D and node.overlaps_body(player)):
			valid_nodes.append({"node": node, "dist": dist})
			
	if valid_nodes.size() > 0:
		valid_nodes.sort_custom(func(a, b): return a["dist"] < b["dist"])
		for item in valid_nodes:
			var node = item["node"]
			if not "FarmingZone" in node.name and not "FarmingZone" in node.get_parent().name:
				return node
		return valid_nodes[0]["node"]
			
	return null


func _get_interactable_at_mouse() -> Node:
	if player.is_dead or player.is_casting or player.is_attacking or player.is_dashing or player.is_targeting: return null
	
	var mouse_pos = player.get_mouse_3d_pos()
	var interactables = get_tree().get_nodes_in_group("Interactable")
	
	var valid_nodes = []
	for col in interactables:
		if col and col.has_method("on_interact"):
			if "FarmingZone" in col.name or (col.get_parent() and "FarmingZone" in col.get_parent().name):
				continue
			
			var dist_to_mouse = mouse_pos.distance_to(col.global_position)
			if dist_to_mouse <= 25.0: # Toleransi klik
				var dist = player.global_position.distance_to(col.global_position)
				if dist <= 120.0 or (col.has_method("overlaps_body") and col.overlaps_body(player)):
					valid_nodes.append(col)
				
	if valid_nodes.size() > 0:
		return valid_nodes[0]
		
	return null


func _try_interact():
	var closest_node = player._get_closest_interactable()
	if closest_node and closest_node.has_method("on_interact"):
		closest_node.on_interact(player)



func _cancel_life_skill():
	player.is_doing_life_skill = false
	if is_instance_valid(player.life_skill_bar):
		player.life_skill_bar.queue_free()
	if player.life_skill_target and is_instance_valid(player.life_skill_target) and player.life_skill_target.has_method("on_cancel"):
		player.life_skill_target.on_cancel()
	player.life_skill_target = null


func start_life_skill(target_node: Node, required_cycles: int, skill_type: String = ""):
	if player.is_doing_life_skill or player.is_attacking or player.is_dashing or player.is_casting: return
	player.is_doing_life_skill = true
	player.life_skill_target = target_node
	player.life_skill_type = skill_type
	player.life_skill_max_progress = required_cycles
	player.life_skill_progress = 0
	
	player.life_skill_bar = ProgressBar.new()
	player.life_skill_bar.min_value = 0
	player.life_skill_bar.max_value = required_cycles
	player.life_skill_bar.value = 0
	player.life_skill_bar.show_percentage = false
	player.life_skill_bar.custom_minimum_size = Vector2(40, 6)
	player.life_skill_bar.position = Vector2(-20, -30)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	player.life_skill_bar.add_theme_stylebox_override("background", sb_bg)
	player.life_skill_bar.add_theme_stylebox_override("fill", sb_fg)
	player._get_hud_canvas().add_child(player.life_skill_bar)
	
	player._life_skill_loop()


func _life_skill_loop():
	while player.is_doing_life_skill and is_instance_valid(player.life_skill_target):
		var target_dir = (player.life_skill_target.global_position - player.global_position).normalized()
		
		# Snap to 4-way direction to prevent animation blend issues (player.sprite disappearing)
		var anim_dir = target_dir
		if abs(anim_dir.x) > abs(anim_dir.z):
			anim_dir.z = 0
		else:
			anim_dir.x = 0
		anim_dir = anim_dir.normalized()
		
		player.last_direction = anim_dir
		
		player.is_attacking = true
		player.current_attack_speed = 1.0
		
		var actual_len = player._get_state_length("Attack", player.base_attack_duration)
		player.current_anim_speed_ratio = actual_len / player.base_attack_duration
		
		if player.animation_tree:
			player.animation_tree.set("parameters/AttackTimeScale/scale", 1.0 * player.current_anim_speed_ratio)
			
		if player.state_machine:
			player.state_machine.travel("Attack")
			
		var duration = player.base_attack_duration
		await get_tree().create_timer(duration).timeout
		
		player.is_attacking = false
		if player.state_machine: player.state_machine.travel("Idle")
		
		if not player.is_doing_life_skill or not is_instance_valid(player.life_skill_target):
			break
			
		player.life_skill_progress += 1
		if is_instance_valid(player.life_skill_bar):
			player.life_skill_bar.value = player.life_skill_progress
			
		if player.life_skill_progress >= player.life_skill_max_progress:
			var target = player.life_skill_target
			player._cancel_life_skill() # Bersihkan UI
			if target and is_instance_valid(target) and target.has_method("on_complete"):
				target.on_complete(player)
			player.spawn_floating_text("Selesai!", Color(0.2, 1, 0.2))
			break



func start_farming_targeting(zone):
	if player.is_farming_targeting or player.is_doing_life_skill or player.is_targeting: return
	player.is_farming_targeting = true
	player.farming_zone_ref = zone
	
	player.farming_indicator = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(20, 20)
	player.farming_indicator.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	player.farming_indicator.material_override = mat
	
	get_parent().add_child(player.farming_indicator)


func _cancel_farming_targeting():
	set_deferred("player.is_farming_targeting", false)
	if is_instance_valid(player.farming_indicator):
		player.farming_indicator.queue_free()
	player.farming_zone_ref = null


func _confirm_farming():
	var pos = player.farming_indicator.global_position
	var zone = player.farming_zone_ref
	
	if zone and zone.has_method("is_valid_plot_pos"):
		if not zone.is_valid_plot_pos(pos):
			player.spawn_floating_text("Posisi tidak valid!", Color(1, 0.2, 0.2))
			return
			
	player._cancel_farming_targeting()
	
	if zone and is_instance_valid(zone):
		player.start_auto_walk(pos, func():
			zone.target_pos = pos
			player.start_life_skill(zone, 1, "farming")
		)


func start_auto_walk(target_pos: Vector3, callback: Callable):
	player.is_auto_walking = true
	player.auto_walk_target = target_pos
	player.auto_walk_callback = callback
	if player.nav_agent:
		player.nav_agent.target_position = target_pos


func _cancel_auto_walk():
	player.is_auto_walking = false
	player.auto_walk_callback = Callable()


func _complete_auto_walk():
	player.is_auto_walking = false
	if player.auto_walk_callback.is_valid():
		player.auto_walk_callback.call()
	player.auto_walk_callback = Callable()
