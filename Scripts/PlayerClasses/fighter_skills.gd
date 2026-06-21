class_name FighterSkills
extends RefCounted

static func execute(p: Node3D, skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node, cur_lvl: int, dmg: int, dur: float, aoe: float, crit: float, el_multiplier: float):
	if skill_id == "cyclone_sweep":
		p.is_spinning = true
		p.is_running_from_double_tap = false
		p.spin_timer = dur
		p.max_spin_time = dur
		
		if is_instance_valid(p.spin_bar):
			p.spin_bar.queue_free()
			
		p.spin_bar = ProgressBar.new()
		p.spin_bar.min_value = 0
		p.spin_bar.max_value = p.max_spin_time
		p.spin_bar.value = p.max_spin_time
		p.spin_bar.show_percentage = false
		p.spin_bar.custom_minimum_size = Vector2(30, 4)
		p.spin_bar.position = Vector2(-15, 12)
		
		var sb_bg = StyleBoxFlat.new()
		sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		var sb_fg = StyleBoxFlat.new()
		sb_fg.bg_color = Color(1.0, 0.4, 0.0, 1.0)
		p.spin_bar.add_theme_stylebox_override("background", sb_bg)
		p.spin_bar.add_theme_stylebox_override("fill", sb_fg)
		p._get_hud_canvas().add_child(p.spin_bar)
		
	elif skill_id == "fatal_blow":
		p.current_attack_damage = p.physical_attack + dmg
		var old_crit = p.critical_chance
		p.critical_chance = crit * 100.0
		
		var m_pos = p.get_mouse_3d_pos()
		var dir = (m_pos - p.global_position)
		dir.y = 0
		if dir.length() > 0.01:
			dir = dir.normalized()
			p.last_direction = dir
			if p.sprite:
				var target_angle = atan2(-dir.z, dir.x)
				p.sprite.rotation.y = target_angle - PI/2.0
				if is_instance_valid(p.sword_hitbox_area):
					p.sword_hitbox_area.rotation.y = p.sprite.rotation.y
		else:
			dir = p.last_direction
		
		var original_pos = p.global_position
		var stab_pos = p.global_position + dir * 5.0
		var stab_tween = p.get_tree().create_tween()
		
		p.is_attacking = true
		
		if p.animation_tree:
			p.animation_tree.set("parameters/AttackTimeScale/scale", 2.5)
		if p.state_machine:
			p.state_machine.travel("Attack")
		
		stab_tween.tween_property(p, "global_position", stab_pos, 0.1).set_ease(Tween.EASE_OUT)
		stab_tween.tween_callback(func():
			p.apply_camera_shake(15.0, 0.2)
			var enemies = p.get_tree().get_nodes_in_group("Enemy")
			for e in enemies:
				if e.global_position.distance_to(p.global_position) <= 5.0:
					if e.has_method("take_damage"):
						e.take_damage(p.physical_attack + dmg, p.global_position)
						if e.get("velocity") != null:
							var push_dir = (e.global_position - p.global_position).normalized()
							e.velocity = push_dir * 800
		)
		stab_tween.tween_property(p, "global_position", original_pos, 0.15).set_ease(Tween.EASE_IN).set_delay(0.1)
		stab_tween.tween_callback(func(): 
			p.critical_chance = old_crit
			p.is_attacking = false
			if p.state_machine:
				p.state_machine.travel("Idle")
		)
		
	elif skill_id == "impact_wave":
		p.attack(false)
		var wave_dmg = dmg
		var p_attack = p.physical_attack
		var p_pos = p.global_position
		var l_dir = p.last_direction
		var c_lvl = cur_lvl
		var slow_dur = dur if dur > 0 else 3.0
		
		p.get_tree().create_timer(0.15).timeout.connect(func():
			var wave = Node3D.new()
			var start_pos = p_pos + l_dir * 1.0
			wave.position = start_pos
			wave.rotation.y = atan2(-l_dir.z, l_dir.x)
			
			var visual = CSGPolygon3D.new()
			var pts = PackedVector2Array([
				Vector2(0.0, -1.5), Vector2(0.4, -1.5), Vector2(1.0, 0.0),
				Vector2(0.4, 1.5), Vector2(0.0, 1.5), Vector2(0.6, 0.0)
			])
			visual.polygon = pts
			visual.mode = CSGPolygon3D.MODE_DEPTH
			visual.depth = 0.1
			visual.rotation.x = deg_to_rad(-90)
			visual.position.y = 0.5
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.1, 0.8, 0.9, 0.9)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			visual.material = mat
			wave.add_child(visual)
			p.get_tree().current_scene.add_child(wave)
			
			var dest = start_pos + l_dir * 4.0
			var tween = p.get_tree().create_tween()
			tween.set_parallel(true)
			tween.tween_property(wave, "global_position", dest, 0.4)
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
			tween.set_parallel(false)
			tween.tween_callback(wave.queue_free)
			
			var hit_enemies = {}
			var elapsed = 0.0
			var hit_radius = 2.0
			
			while elapsed < 0.4:
				await p.get_tree().physics_frame
				elapsed += p.get_physics_process_delta_time()
				if not is_instance_valid(wave):
					break
				var wave_pos = wave.global_position
				var all_enemies = p.get_tree().get_nodes_in_group("Enemy")
				for enemy in all_enemies:
					if not is_instance_valid(enemy): continue
					if hit_enemies.has(enemy): continue
					var dist = wave_pos.distance_to(enemy.global_position)
					if dist <= hit_radius:
						hit_enemies[enemy] = true
						if enemy.has_method("take_damage"):
							enemy.take_damage(p_attack + wave_dmg, p_pos)
						if enemy.get("status_manager") != null:
							enemy.status_manager.apply_effect("slow", slow_dur)
		)
		
	elif skill_id == "fatal_smash":
		p.is_invincible = true
		p.is_animating_skill = true
		p.is_smashing = true
		var smash_radius = aoe if aoe > 0 else 3.0
		p.smash_total_dur = 0.6
		p.smash_elapsed = 0.0
		p.smash_start_pos = p.global_position
		p.smash_target_pos = Vector3(t_pos.x, p.global_position.y, t_pos.z)
		
		var rise_dur = p.smash_total_dur * 0.4
		var fall_dur = p.smash_total_dur * 0.6
		var jump_peak = p.base_y_offset + 5.0
		
		if p.sprite:
			var original_scale = p.sprite.scale
			var arc_tween = p.get_tree().create_tween()
			arc_tween.tween_property(p.sprite, "position:y", jump_peak, rise_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			arc_tween.tween_property(p.sprite, "position:y", p.base_y_offset, fall_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			
			var scale_tween = p.get_tree().create_tween()
			scale_tween.tween_property(p.sprite, "scale", original_scale * 1.2, rise_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			scale_tween.tween_property(p.sprite, "scale", original_scale, fall_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
		p.get_tree().create_timer(p.smash_total_dur).timeout.connect(func():
			p.is_invincible = false
			p.is_animating_skill = false
			p.velocity = Vector3.ZERO
			p.apply_camera_shake(30.0, 0.5)
			
			var ring = CSGCylinder3D.new()
			ring.radius = 0.2
			ring.height = 0.12
			ring.sides = 48
			var ring_mat = StandardMaterial3D.new()
			ring_mat.albedo_color = Color(1.0, 0.4, 0.05, 1.0)
			ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ring.material = ring_mat
			var ring_node = Node3D.new()
			ring_node.position = p.global_position
			ring_node.add_child(ring)
			p.get_tree().current_scene.add_child(ring_node)
			
			var ring_tween = p.get_tree().create_tween()
			ring_tween.set_parallel(true)
			ring_tween.tween_property(ring, "radius", smash_radius, 0.4).set_ease(Tween.EASE_OUT)
			ring_tween.tween_property(ring_mat, "albedo_color:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
			ring_tween.set_parallel(false)
			ring_tween.tween_callback(ring_node.queue_free)
			
			var old_crit = p.critical_chance
			p.critical_chance = crit * 100.0
			var enemies = p.get_tree().get_nodes_in_group("Enemy")
			for e in enemies:
				if e.global_position.distance_to(p.global_position) <= smash_radius:
					if e.has_method("take_damage"):
						e.take_damage(p.physical_attack + dmg, p.global_position)
						if e.get("velocity") != null:
							var push_dir = (e.global_position - p.global_position).normalized()
							e.velocity = push_dir * 1500
			p.critical_chance = old_crit
			p.spawn_floating_text("SMASH!", Color(1, 0.2, 0))
		)
		
	elif skill_id == "endure":
		if p.status_manager:
			p.status_manager.apply_effect("endure", dur)
		p.spawn_floating_text("Endure!", Color(1, 0.8, 0))
		
	elif skill_id == "provoke":
		var prov_radius = 5.0
		var enemies = p.get_tree().get_nodes_in_group("Enemy")
		for e in enemies:
			if e.global_position.distance_to(p.global_position) <= prov_radius:
				if e.has_method("set_target"):
					e.set_target(p)
				if e.get("status_manager") != null:
					e.status_manager.apply_effect("taunt", dur)
					
		var circle = CSGCylinder3D.new()
		circle.radius = prov_radius
		circle.height = 0.1
		circle.sides = 48
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.2, 0.2, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circle.material = mat
		var visual_node = Node3D.new()
		visual_node.position = p.global_position
		visual_node.add_child(circle)
		p.get_tree().current_scene.add_child(visual_node)
		
		var visual_tween = p.get_tree().create_tween()
		visual_tween.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)
		visual_tween.tween_callback(visual_node.queue_free)
		p.spawn_floating_text("Provoke!", Color(1, 0.5, 0))
		
	elif skill_id == "implosion":
		p.is_invincible = true
		p.is_animating_skill = true
		p.get_tree().create_timer(0.8).timeout.connect(func(): p.is_invincible = false; p.is_animating_skill = false)
		
		var jump_tween = p.get_tree().create_tween()
		var start_y = p.base_y_offset if p.sprite else 0.0
		jump_tween.tween_property(p.sprite, "position:y", start_y + 3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		jump_tween.tween_property(p.sprite, "position:y", start_y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		
		var imp_radius = 5.0
		var circle = CSGCylinder3D.new()
		circle.radius = imp_radius
		circle.height = 0.05
		circle.sides = 32
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.0, 0.8, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circle.material = mat
		var visual_node = Node3D.new()
		visual_node.position = p.global_position
		visual_node.add_child(circle)
		p.get_tree().current_scene.add_child(visual_node)
		
		var visual_tween = p.get_tree().create_tween()
		visual_tween.tween_property(circle, "radius", 0.01, 0.6).set_ease(Tween.EASE_IN)
		visual_tween.tween_callback(visual_node.queue_free)
		
		var enemies = p.get_tree().get_nodes_in_group("Enemy")
		var pulled_enemies = []
		for e in enemies:
			if e.global_position.distance_to(p.global_position) <= imp_radius:
				pulled_enemies.append(e)
				var tween = p.get_tree().create_tween()
				tween.set_loops(4)
				var random_offset = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				tween.tween_property(e, "global_position", p.global_position + random_offset, 0.1)
				tween.tween_interval(0.05)
				
		jump_tween.tween_callback(func():
			p.apply_camera_shake(15.0, 0.3)
			for e in pulled_enemies:
				if is_instance_valid(e) and e.get("status_manager") != null:
					e.status_manager.apply_effect("stun", 2.0)
		)
		p.spawn_floating_text("Implosion!", Color(0.5, 0, 1))
