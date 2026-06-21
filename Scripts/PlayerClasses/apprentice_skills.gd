class_name ApprenticeSkills
extends RefCounted

static func execute(p: Node3D, skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node, cur_lvl: int, dmg: int, dur: float, aoe: float, crit: float, el_multiplier: float):
	if skill_id == "heal":
		var actual_heal = min(dmg + int(p.magic_attack * 0.5), p.max_health - p.current_health)
		if actual_heal < 0: actual_heal = 0
		p.restore_hp(dmg + int(p.magic_attack * 0.5))
		p.spawn_floating_text("+" + str(actual_heal) + " HP", Color(0.2, 1, 0.2))
		var flash_tween = p.get_tree().create_tween()
		p.modulate = Color(2.0, 2.0, 2.0)
		flash_tween.tween_property(p, "scale", Color(1.0, 1.0, 1.0), 0.3)
		
	elif skill_id == "aqua_blast":
		var final_dmg = int((p.magic_attack * 1.5 + dmg) * el_multiplier)
		var wave = Area3D.new()
		wave.position = p.global_position
		wave.set_script(load("res://Scripts/Skills/aqua_blast_wave.gd"))
		wave.damage = final_dmg
		wave.max_radius = 5.0
		wave.duration = 0.5
		p.get_tree().current_scene.add_child(wave)
		p.apply_camera_shake(10.0, 0.2)

	elif skill_id == "fire_bolt":
		var fb_scene = load("res://Scenes/Skills/fire_bolt.tscn")
		if fb_scene and p.get_tree().current_scene:
			var fb = fb_scene.instantiate()
			fb.position = p.global_position
			fb.damage = int((p.magic_attack * 2.0 + dmg) * el_multiplier)
			fb.elements = ["api"]
			
			var target = null
			if indicator and indicator.get("single_target_node") != null:
				target = indicator.single_target_node
			else:
				var min_dist = 9999.0
				var enemies = p.get_tree().get_nodes_in_group("Enemy")
				for e in enemies:
					var dist = e.global_position.distance_to(p.global_position)
					if dist < min_dist and dist <= 8.0:
						target = e
						min_dist = dist
			fb.target = target
			p.get_tree().current_scene.add_child(fb)

	elif skill_id == "sonic_boom":
		var final_dmg = int((p.magic_attack * 1.2 + dmg) * el_multiplier)
		var elements = ["udara"]
		var cone = Area3D.new()
		cone.position = p.global_position
		var l_dir = (t_pos - p.global_position).normalized() if t_pos != Vector3.ZERO else p.last_direction
		if l_dir == Vector3.ZERO: l_dir = Vector3.BACK
		
		var angle = atan2(l_dir.x, l_dir.z)
		cone.rotation.y = angle
		
		var poly = CollisionPolygon3D.new()
		poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(-2.07, 5.0), Vector2(2.07, 5.0)])
		poly.rotation.x = deg_to_rad(90)
		cone.add_child(poly)
		
		var visual = CSGPolygon3D.new()
		visual.polygon = poly.polygon
		visual.rotation.x = deg_to_rad(90)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		visual.material = mat
		cone.add_child(visual)
		p.get_tree().current_scene.add_child(cone)
		
		var tween = p.get_tree().create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
		tween.tween_callback(cone.queue_free)
		
		var hit_enemies = {}
		var apply_dmg = func(body):
			if body.is_in_group("Enemy") and not hit_enemies.has(body):
				hit_enemies[body] = true
				if body.has_method("take_damage"):
					body.take_damage(final_dmg, p.global_position, elements)
				if body.get("status_manager") != null:
					var stun_dur = clamp(2.0 + (cur_lvl - 1) * 1.0, 2.0, 5.0)
					body.status_manager.apply_effect("stun", stun_dur)
		cone.body_entered.connect(apply_dmg)
		cone.area_entered.connect(func(area):
			if area.get_parent(): apply_dmg.call(area.get_parent())
		)

	elif skill_id == "seismic_fissure":
		var final_dmg = int((p.magic_attack * 1.8 + dmg) * el_multiplier)
		var elements = ["tanah"]
		var l_dir = (t_pos - p.global_position).normalized() if t_pos != Vector3.ZERO else p.last_direction
		if l_dir == Vector3.ZERO: l_dir = Vector3.BACK
		var p_pos = p.global_position
		
		var dist = p.global_position.distance_to(t_pos)
		var steps = max(1, int(dist))
		
		for i in range(steps):
			p.get_tree().create_timer(i * 0.1).timeout.connect(func():
				var hazard = load("res://Scenes/Skills/seismic_fissure_hazard.tscn")
				if hazard and p.get_tree().current_scene:
					var h = hazard.instantiate()
					h.position = p_pos + l_dir * (1.0 + i * 1.0)
					h.damage = final_dmg
					h.elements = elements
					h.slow_duration = dur
					p.get_tree().current_scene.add_child(h)
			)
		p.get_tree().create_timer(steps * 0.1).timeout.connect(func():
			var hazard = load("res://Scenes/Skills/seismic_fissure_hazard.tscn")
			if hazard and p.get_tree().current_scene:
				var h = hazard.instantiate()
				h.position = t_pos
				h.damage = final_dmg
				h.elements = elements
				h.slow_duration = dur
				h.is_circle = true
				h.radius = 2.0
				p.get_tree().current_scene.add_child(h)
		)

	elif skill_id == "holy_veil":
		var final_shield = int((p.magic_attack * 2.0 + dmg) * el_multiplier)
		if p.status_manager:
			p.status_manager.apply_effect("holy_veil", dur, {"shield": final_shield})
		p.spawn_floating_text("Holy Veil!", Color(1.0, 1.0, 0.5))

	elif skill_id == "hex":
		var target = null
		if is_instance_valid(indicator) and is_instance_valid(indicator.get("single_target_node")):
			target = indicator.get("single_target_node")
		else:
			var enemies = p.get_tree().get_nodes_in_group("Enemy")
			var min_dist = 999.0
			for e in enemies:
				if not e.is_dead:
					var dist = p.global_position.distance_to(e.global_position)
					if dist < 5.0 and dist < min_dist:
						target = e
						min_dist = dist
		
		if target and target.get("status_manager") != null:
			target.status_manager.apply_effect("curse", dur)
			p.spawn_floating_text("Hex!", Color(0.3, 0.0, 0.4))
			var vis = CSGSphere3D.new()
			vis.radius = 0.5
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.0, 0.6, 0.8)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vis.material = mat
			target.add_child(vis)
			vis.position = Vector3(0, 1.0, 0)
			var tw = p.get_tree().create_tween()
			tw.tween_property(vis, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
			tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
			tw.tween_callback(vis.queue_free)

	elif skill_id == "soul_drain":
		var final_dmg = int((p.magic_attack * 1.5 + dmg) * el_multiplier)
		var elements = ["kegelapan"]
		var enemies = p.get_tree().get_nodes_in_group("Enemy")
		var total_heal = 0
		var drained = false
		for e in enemies:
			if e.get("status_manager") != null and e.status_manager.has_effect("curse"):
				drained = true
				if e.has_method("take_damage"):
					e.take_damage(final_dmg, p.global_position, elements)
				total_heal += final_dmg
				var soul = CSGSphere3D.new()
				soul.radius = 0.2
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.6, 0.0, 0.8, 0.8)
				mat.emission_enabled = true
				mat.emission = Color(0.6, 0.0, 0.8)
				mat.emission_energy = 2.0
				soul.material = mat
				p.get_tree().current_scene.add_child(soul)
				soul.global_position = e.global_position + Vector3(0, 1.0, 0)
				var tw = p.get_tree().create_tween()
				tw.tween_property(soul, "global_position", p.global_position + Vector3(0, 1.0, 0), 0.4).set_ease(Tween.EASE_IN_OUT)
				tw.tween_callback(soul.queue_free)
		if drained and total_heal > 0:
			p.get_tree().create_timer(0.4).timeout.connect(func():
				p.restore_hp(total_heal)
				p.spawn_floating_text("Soul Drain!", Color(0.5, 0.0, 0.5))
			)
			
	elif skill_id == "fireball":
		var fb_scene = load("res://Scenes/Skills/fireball.tscn")
		if fb_scene and p.get_tree().current_scene:
			var fb = fb_scene.instantiate()
			fb.position = t_pos
			fb.damage = int(p.magic_attack * 1.5) + dmg
			fb.aoe_radius = aoe
			p.get_tree().current_scene.add_child(fb)
