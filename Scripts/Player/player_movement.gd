extends Node
class_name PlayerMovement

@onready var player: CharacterBody3D = get_parent()

func _physics_process(delta):
	player._update_interaction_prompt()
	
	if not Input.is_action_pressed("charge_attack"):
		player.charge_input_consumed = false

	if player.is_farming_targeting and is_instance_valid(player.farming_indicator):
		player.farming_indicator.global_position = player.get_mouse_3d_pos()
		if player.farming_zone_ref and player.farming_zone_ref.has_method("is_valid_plot_pos"):
			if player.farming_zone_ref.is_valid_plot_pos(player.farming_indicator.global_position):
				player.farming_indicator.modulate = Color(1, 1, 1, 0.5)
			else:
				player.farming_indicator.modulate = Color(1, 0.2, 0.2, 0.8)

	if player.is_dead: return
	if player.is_doing_life_skill:
		player.velocity = Vector3.ZERO
		return
	
	if player.animation_tree:
		if player.status_manager and (player.status_manager.has_effect("freeze") or player.status_manager.has_effect("sleep")):
			player.animation_tree.active = false
		else:
			player.animation_tree.active = true
	
	if player.status_manager and not player.status_manager.can_move():
		pass # Can't move if frozen
		
	if player.current_dash_cooldown > 0: player.current_dash_cooldown -= delta
	if player.charge_attack_cooldown > 0: player.charge_attack_cooldown -= delta
	if player.targeting_cancel_cooldown > 0: player.targeting_cancel_cooldown -= delta
	if player.jump_cooldown > 0: player.jump_cooldown -= delta
	for key in player.active_skill_cooldowns.keys():
		if player.active_skill_cooldowns[key] > 0:
			player.active_skill_cooldowns[key] -= delta
	
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
		
	var is_hold_weapon = w_type in ["staff", "long_bow"]
	
	if is_hold_weapon and not player.is_dead and not player.is_targeting and not player.is_dashing and not player.is_jumping and player.targeting_cancel_cooldown <= 0.0 and (not player.is_casting or player.magic_charge_timer > 0.0) and not player.charge_input_consumed and not player.is_animating_skill and not player.is_spinning:
		if Input.is_action_pressed("charge_attack"):
			if player.status_manager and not player.status_manager.can_move():
				if Input.is_action_just_pressed("charge_attack"):
					var effect_name = player.status_manager.get_movement_restriction_name()
					player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
			elif player.magic_charge_timer == 0.0 and not player.is_attacking and not player.is_casting:
				if player.charge_attack_cooldown <= 0:
					if player.current_mana < 30:
						if Input.is_action_just_pressed("charge_attack"):
							player.spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
					else:
						player.is_casting = true
						player._create_charge_bar()
					
			if player.magic_charge_timer > 0.0:
				player._update_aim_to_mouse(true)
				player.magic_charge_timer += delta
				if player.magic_charge_timer > 2.0: player.magic_charge_timer = 2.0
				if is_instance_valid(player.magic_charge_bar):
					player.magic_charge_bar.value = player.magic_charge_timer
		else:
			if player.magic_charge_timer > 0.0:
				player._release_magic_charge()
	elif player.magic_charge_timer > 0.0:
		player.magic_charge_timer = 0.0
		player.is_casting = false
		if is_instance_valid(player.magic_charge_bar):
			player.magic_charge_bar.queue_free()
	

	# Handle Run (Hold Shift + Direction)
	var move_keys = ["move_up", "move_down", "move_left", "move_right"]
	var is_any_move_pressed = false
	for key in move_keys:
		if Input.is_action_pressed(key):
			is_any_move_pressed = true
			
	if is_any_move_pressed and Input.is_action_pressed("run") and not player.is_spinning and player.magic_charge_timer == 0.0:
		player.is_running_from_double_tap = true
	else:
		player.is_running_from_double_tap = false
				
	# --- DIRECTIONAL DASH ---
	# Trigger: Spasi ditekan (jump)
	var should_trigger_dash = Input.is_action_just_pressed("jump")

	if should_trigger_dash:
		# player.is_casting diizinkan jika itu state aim/charge ranged (player.magic_charge_timer > 0)
		# bukan casting skill biasa (player.magic_charge_timer == 0)
		var casting_blocks_dash = player.is_casting and player.magic_charge_timer == 0.0
		# player.is_attacking boleh diinterupsi oleh dash (kombinasi klik + arah + Shift)
		if not player.is_dashing and not casting_blocks_dash and not player.is_animating_skill and not player.is_spinning:
			if player.current_dash_cooldown <= 0:
				if player.status_manager and not player.status_manager.can_move():
					var effect_name = player.status_manager.get_movement_restriction_name()
					player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
				elif player.current_energy >= 20.0:
					# Cancel animasi player.attack jika sedang player.attack saat dash
					if player.is_attacking:
						player.is_attacking = false
						if player.sword_hitbox:
							player.sword_hitbox.set_deferred("disabled", true)
					# Cancel aim/charge jika sedang aim saat dash
					if player.magic_charge_timer > 0.0:
						player.magic_charge_timer = 0.0
						player.is_casting = false
						if is_instance_valid(player.magic_charge_bar):
							player.magic_charge_bar.queue_free()
					player.current_energy -= 20.0
					player.emit_signal("energy_changed", player.current_energy, player.max_energy)
					player.is_dashing = true
					if player.state_machine: player.state_machine.travel(player.get_anim_state("Dash"))
					player.dash_timer = player.dash_duration / player.global_movement_scale
					player.current_dash_cooldown = player.dash_cooldown
					# Hitung arah dash dari input saat ini
					var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
					var input_z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
					var dir = Vector3(input_x, 0, input_z).normalized()
					# Jika tidak ada tombol arah -> dash ke arah hadap karakter
					if dir == Vector3.ZERO:
						dir = player.last_direction
					if dir == Vector3.ZERO:
						dir = Vector3(0, 0, 1) # Fallback
					# Karakter menghadap ke arah dash
					player.last_direction = dir
					player.velocity = dir * player.dash_speed
					var enemies = get_tree().get_nodes_in_group("Enemy")
					for e in enemies:
						if is_instance_valid(e) and e is CollisionObject3D:
							player.add_collision_exception_with(e)
				else:
					player.spawn_floating_text("EP Tidak Cukup!", Color(1, 0.5, 0))
			else:
				player.spawn_floating_text("Masih Cooldown!", Color(0.4, 0.6, 1))
		
	if player.is_dashing:
		var speed_multiplier = (player.dash_timer / player.dash_duration) * 2.0
		player.velocity = player.last_direction * (player.dash_speed * speed_multiplier * player.global_movement_scale)
		player.dash_timer -= delta
		player.move_and_slide()
		player.modulate.a = 0.5
		if player.animation_tree:
			# Sesuaikan animasi pas dengan durasi dash
			var req_speed = (player.dash_anim_length / player.dash_duration) * player.global_movement_scale
			var extra_advance = delta * (req_speed - 1.0)
			if extra_advance != 0.0:
				player.animation_tree.advance(extra_advance)
		if player.dash_timer <= 0:
			player.is_dashing = false
			player.modulate.a = 1.0
			var enemies = get_tree().get_nodes_in_group("Enemy")
			for e in enemies:
				if is_instance_valid(e) and e is CollisionObject3D:
					player.remove_collision_exception_with(e)
		return
	
	# --- FATAL SMASH: gerak karakter ke titik target via smoothstep ---
	if player.is_smashing:
		player.smash_elapsed += delta
		var t = clamp(player.smash_elapsed / player.smash_total_dur, 0.0, 1.0)
		# Smoothstep: easing in-out natural
		var s = t * t * (3.0 - 2.0 * t)
		player.global_position = player.smash_start_pos.lerp(player.smash_target_pos, s)
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		if t >= 1.0:
			player.is_smashing = false
		return
		
	if player.is_jumping:
		player.jump_timer -= delta
		if player.sprite:
			var progress = 1.0 - (player.jump_timer / player.jump_duration)
			player.sprite.position.y = player.base_y_offset - sin(progress * PI) * player.jump_height
			
		player.move_and_slide() # Still sliding based on player.velocity
		
		if player.jump_timer <= 0:
			player.is_jumping = false
			if player.sprite: player.sprite.position.y = player.base_y_offset
		return

	if player.knockback_velocity != Vector3.ZERO:
		player.velocity = player.knockback_velocity
		player.knockback_velocity = player.knockback_velocity.move_toward(Vector3.ZERO, 800 * delta)
		player.move_and_slide()
		return
		
	var raw_input = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	if player.is_auto_walking:
		if raw_input != Vector3.ZERO:
			player._cancel_auto_walk()
		else:
			var dist = player.global_position.distance_to(player.auto_walk_target)
			if dist <= 25.0:
				player._complete_auto_walk()
			else:
				if player.nav_agent and not player.nav_agent.is_navigation_finished():
					var next_pos = player.nav_agent.get_next_path_position()
					if player.global_position.distance_to(next_pos) < 2.0:
						raw_input = (player.auto_walk_target - player.global_position).normalized()
					else:
						raw_input = (next_pos - player.global_position).normalized()
				else:
					raw_input = (player.auto_walk_target - player.global_position).normalized()
					
	var input_direction = raw_input.normalized() if not player.is_auto_walking else raw_input
	
	if player.status_manager:
		if not player.status_manager.can_move() or player.is_animating_skill:
			input_direction = Vector3.ZERO
		elif input_direction != Vector3.ZERO or player.status_manager.has_effect("fear") or player.status_manager.has_effect("confuse"):
			input_direction = player.status_manager.get_override_movement(input_direction)

	if player.is_attacking:
		if player.animation_tree:
			var total_speed = player.current_attack_speed * player.current_anim_speed_ratio
			if total_speed != 1.0:
				player.animation_tree.advance(delta * (total_speed - 1.0))
		
		if player.is_charge_attacking and player.charge_lunge_timer > 0:
			player.charge_lunge_timer -= delta
			player.velocity = player.last_direction * player.dash_speed
		else:
			# Saat menyerang, karakter tidak bisa berlari/berjalan (diam di tempat)
			player.velocity.x = 0
			player.velocity.z = 0
			
		player.move_and_slide()
		return
	
	var current_speed = player.walk_speed
	var anim_stride = 1.6
	
	if player.is_casting:
		player._update_aim_to_mouse(false)
		current_speed = player.walk_speed * 0.5
	elif player.is_running_from_double_tap and player.current_energy > 0:
		current_speed = player.run_speed
		anim_stride = 4.8
		
	if player.status_manager:
		current_speed *= player.status_manager.get_speed_multiplier()
		
	current_speed *= player.global_movement_scale
	var anim_speed = current_speed / anim_stride
			
	if player.animation_player:
		if not player.is_attacking and not player.is_casting and not player.is_dashing and not player.is_jumping and not player.is_spinning:
			player.animation_player.speed_scale = anim_speed
		else:
			player.animation_player.speed_scale = 1.0
		
	if input_direction != Vector3.ZERO:
		var physical_speed = current_speed
		player.velocity = input_direction * physical_speed
		
		# Selalu simpan arah terakhir agar dash/player.attack yang dilakukan saat diam mengarah ke arah yang benar
		player.last_direction = input_direction
		
		if player.sprite and not player.is_attacking and not player.is_casting and not player.is_spinning:
			var target_angle = atan2(-input_direction.z, input_direction.x)
			player.sprite.rotation.y = lerp_angle(player.sprite.rotation.y, target_angle - PI/2.0, 15.0 * delta)
			if is_instance_valid(player.sword_hitbox_area):
				player.sword_hitbox_area.rotation.y = player.sprite.rotation.y
		
		if player.state_machine and not player.is_attacking:
			if player.is_running_from_double_tap and player.current_energy > 0:
				player.state_machine.travel(player.get_anim_state("Run"))
			else:
				player.state_machine.travel(player.get_anim_state("Walk"))
	else:
		player.velocity = Vector3.ZERO
		if player.state_machine and not player.is_attacking:
			player.state_machine.travel(player.get_anim_state("Idle"))
		
	player.move_and_slide()
		

	if Input.is_action_just_pressed("charge_attack") and not player.charge_input_consumed and not player.is_attacking and not player.is_jumping and not player.is_casting and not player.is_targeting and not player.is_farming_targeting and player.targeting_cancel_cooldown <= 0.0 and player.magic_charge_timer == 0.0 and not player.is_animating_skill and not player.is_spinning and not player.is_dashing:
		if player.status_manager and not player.status_manager.can_move():
			var effect_name = player.status_manager.get_movement_restriction_name()
			player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
		elif player.charge_attack_cooldown <= 0:
			var is_tap_weapon = w_type in ["long_sword", "sword", "gloves", "lance", "rod", "crossbow", "dagger"]
			if is_tap_weapon or w_type == "None":
				var cost = 30
				var can_cast = false
				
				if w_type == "rod":
					if player.current_mana >= cost:
						player.current_mana -= cost
						player.emit_signal("mana_changed", player.current_mana, player.max_mana)
						can_cast = true
					else:
						player.spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
				else:
					if player.current_energy >= cost:
						player.current_energy -= cost
						player.emit_signal("energy_changed", player.current_energy, player.max_energy)
						can_cast = true
					else:
						player.spawn_floating_text("EP Tidak Cukup!", Color(1, 0.5, 0))
						
				if can_cast:
					player.charge_attack_cooldown = 2.0
					if w_type == "crossbow" or w_type == "rod":
						player.charge_attack_cooldown = 1.0
					
					match w_type:
						"rod":
							player._fire_projectile("mana_burst", true)
						"crossbow":
							player._fire_projectile("bolt", true)
						"dagger":
							player._fire_projectile("dagger", true)
						_:
							player.attack(true)
		else:
			player.spawn_floating_text("Masih Cooldown!", Color(0.4, 0.6, 1))


func _process(delta):
	if player.is_dead: return
	var is_running_now = false
	if player.is_running_from_double_tap and not player.is_attacking and not player.is_dashing and not player.is_jumping:
		var input_dir = Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		if input_dir != Vector3.ZERO:
			is_running_now = true
			
	if is_running_now and player.current_energy > 0:
		player.current_energy -= 10.0 * delta # Mengurangi 10 EP per detik
		if player.current_energy < 0: player.current_energy = 0
		player.emit_signal("energy_changed", player.current_energy, player.max_energy)
	elif not player.is_running_from_double_tap and player.current_energy < player.max_energy:
		player.current_energy += player.energy_regen * delta
		if player.current_energy > player.max_energy: player.current_energy = player.max_energy
		player.emit_signal("energy_changed", player.current_energy, player.max_energy)
