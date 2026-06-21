class_name ScoutSkills
extends RefCounted

static func execute(p: Node3D, skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node, cur_lvl: int, dmg: int, dur: float, aoe: float, crit: float, el_multiplier: float):
	if skill_id == "hunters_mark":
		if is_instance_valid(indicator) and indicator.get("single_target_node") != null and is_instance_valid(indicator.single_target_node):
			var enemy = indicator.single_target_node
			if enemy.get("status_manager"):
				enemy.status_manager.apply_effect("hunters_mark", dur)
				p.spawn_floating_text("Target Marked!", Color(1.0, 0.2, 0.2))
				
	elif skill_id == "falcon_dive":
		var target_enemy = indicator.single_target_node if is_instance_valid(indicator) and indicator.get("single_target_node") != null and is_instance_valid(indicator.single_target_node) else null
		if target_enemy == null:
			p.spawn_floating_text("No target!", Color(1, 0.5, 0))
			return
		
		var proj_scene = load("res://Scenes/Skills/player_projectile.tscn")
		if proj_scene:
			p.falcon_dive_active = true
			
			for i in range(4):
				if not is_instance_valid(target_enemy) or target_enemy.get("is_dead") or p.is_dead: break
				
				p.last_direction = (target_enemy.global_position - p.global_position).normalized()
				var anim_dir = Vector2(p.last_direction.x, -p.last_direction.z)
				if abs(anim_dir.x) > abs(anim_dir.y):
					anim_dir.y = 0
				else:
					anim_dir.x = 0
				anim_dir = anim_dir.normalized()
				if p.animation_tree:
					p.animation_tree.set("parameters/Attack/blend_position", anim_dir)
					
				if p.state_machine: p.state_machine.travel("Attack")
				p.apply_camera_shake(3.0, 0.1)
				
				var proj = proj_scene.instantiate()
				proj.damage = int(dmg * 0.5)
				proj.atk_elements = p.atk_elements
				proj.position = p.global_position
				proj.direction = (target_enemy.global_position - p.global_position).normalized()
				
				var vis = proj.get_node_or_null("Visual")
				if vis:
					vis.color = Color(0.8, 0.5, 0.2)
					
				p.get_tree().current_scene.add_child(proj)
				
				await p.get_tree().create_timer(0.5, false, false, true).timeout
				
			if is_instance_valid(target_enemy) and not target_enemy.get("is_dead") and not p.is_dead:
				Engine.time_scale = 0.3
				
				var tween = p.get_tree().create_tween().set_ignore_time_scale(true)
				tween.tween_property(p.sprite, "position:y", p.base_y_offset - 0.4, 0.1).set_ease(Tween.EASE_OUT)
				tween.tween_property(p.sprite, "position:y", p.base_y_offset, 0.1).set_ease(Tween.EASE_IN)
				
				if p.state_machine: p.state_machine.travel("Attack")
				
				await p.get_tree().create_timer(0.3, false, false, true).timeout
				
				Engine.time_scale = 1.0
				p.apply_camera_shake(6.0, 0.2)
				
				if is_instance_valid(target_enemy):
					var proj = proj_scene.instantiate()
					if randf() < 0.8:
						proj.damage = int(dmg * 1.5)
						proj.scale = Vector3(2.5, 2.5, 2.5)
					else:
						proj.damage = dmg
						proj.scale = Vector3(2.0, 2.0, 2.0)
					proj.atk_elements = p.atk_elements
					proj.position = p.global_position
					proj.direction = (target_enemy.global_position - p.global_position).normalized()
						
					p.get_tree().current_scene.add_child(proj)
					
			p.falcon_dive_active = false
			
	elif skill_id == "arrow_rain":
		var scene = load("res://Scenes/Skills/arrow_rain.tscn")
		if scene:
			Engine.time_scale = 0.3
			if p.animation_tree:
				p.animation_tree.set("parameters/Attack/blend_position", Vector2(0, -1))
			if p.state_machine: p.state_machine.travel("Attack")
			
			var tween = p.get_tree().create_tween().set_ignore_time_scale(true).set_parallel(true)
			tween.tween_property(p.sprite, "position:y", p.base_y_offset - 0.5, 0.2).set_ease(Tween.EASE_OUT)
			tween.tween_property(p.sprite, "rotation:y", deg_to_rad(360), 0.4)
			tween.chain().tween_property(p.sprite, "position:y", p.base_y_offset, 0.2).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(p.sprite, "rotation:y", deg_to_rad(0), 0.0)
			
			await p.get_tree().create_timer(0.4, false, false, true).timeout
			Engine.time_scale = 1.0
			
			var inst = scene.instantiate()
			inst.position = t_pos
			inst.damage = dmg
			inst.aoe_radius = float(aoe)
			inst.duration = dur
			if inst.duration <= 0: inst.duration = 5.0
			inst.elements = p.atk_elements
			p.get_tree().current_scene.add_child(inst)
			
	elif skill_id == "haste":
		if p.status_manager:
			p.status_manager.apply_effect("haste", dur)
			p.spawn_floating_text("Haste!", Color(1.0, 1.0, 0.5))
			
	elif skill_id == "mirage_strike":
		p.mirage_strike_charges = 3
		if p.status_manager:
			p.status_manager.apply_effect("mirage_strike", dur)
		p.spawn_floating_text("Mirage Strike!", Color(0.5, 0.8, 1.0))
		
	elif skill_id == "poison_weapon":
		if p.status_manager:
			p.status_manager.apply_effect("poison_weapon", dur)
		p.spawn_floating_text("Poison Weapon!", Color(0.3, 0.8, 0.3))
			
	elif skill_id == "shadow_walk":
		if p.status_manager:
			p.status_manager.apply_effect("shadow_walk", dur)
		p.spawn_floating_text("Shadow Walk", Color(0.3, 0.3, 0.3))
		
	elif skill_id == "thief":
		if not p.status_manager.has_effect("shadow_walk"):
			p.spawn_floating_text("Harus Stealth!", Color(1, 0.5, 0))
		else:
			var enemies = p.get_tree().get_nodes_in_group("Enemy")
			var stole = false
			for e in enemies:
				if p.global_position.distance_to(e.global_position) < 0.5:
					if e.has_method("drop_loot"):
						e.drop_loot()
					p.spawn_floating_text("Item Stolen!", Color(1, 1, 0))
					stole = true
					break
			if not stole:
				p.spawn_floating_text("Missed!", Color(0.5, 0.5, 0.5))
				
	elif skill_id == "phantom_strike":
		var target_enemy = indicator.single_target_node if is_instance_valid(indicator) and indicator.get("single_target_node") != null and is_instance_valid(indicator.single_target_node) else null
		if target_enemy == null:
			p.spawn_floating_text("No target!", Color(1, 0.5, 0))
		else:
			var dir = (target_enemy.global_position - p.global_position).normalized()
			p.global_position = target_enemy.global_position + dir * 0.3
			target_enemy.take_damage(dmg * 2, p.global_position, p.atk_elements)
			p.spawn_floating_text("Phantom Strike!", Color(0.6, 0.2, 0.8))
			p.apply_camera_shake(8.0, 0.2)
			
	elif skill_id == "phantom_flurry":
		var target_enemy = indicator.single_target_node if is_instance_valid(indicator) and indicator.get("single_target_node") != null and is_instance_valid(indicator.single_target_node) else null
		if target_enemy == null:
			p.spawn_floating_text("No target!", Color(1, 0.5, 0))
		else:
			p.is_invincible = true
			for i in range(10):
				if not is_instance_valid(target_enemy) or target_enemy.get("is_dead"):
					break
				var offset = Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
				p.global_position = target_enemy.global_position + offset
				target_enemy.take_damage(int(dmg * 0.1), p.global_position, p.atk_elements)
				p.apply_camera_shake(3.0, 0.1)
				await p.get_tree().create_timer(0.1).timeout
			p.is_invincible = false
