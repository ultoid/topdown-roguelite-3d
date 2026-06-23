extends Node
class_name PlayerCombat

@onready var player: CharacterBody3D = get_parent()

func _execute_skill(skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node = null):
	var skill_db = player.get_node_or_null("/root/SkillDB")
	if not skill_db: return
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	var dmg = skill_db.get_skill_val(skill_id, "damages", cur_lvl)
	var dur = skill_db.get_skill_val(skill_id, "effect_durations", cur_lvl)
	var aoe = skill_db.get_skill_val(skill_id, "aoe_radiuses", cur_lvl)
	var crit = skill_db.get_skill_val(skill_id, "crit_chances", cur_lvl)
	
	var el_multiplier = 1.0 + player.elemental_mastery_bonus_pct
	
	var manual_anim_skills = ["aqua_blast", "cyclone_sweep", "fatal_blow", "impact_wave", "fatal_smash", "implosion"]
	if not skill_id in manual_anim_skills:
		player.is_animating_skill = true
		var anim_state = skill_id.capitalize().replace(" ", "")
		var anim_time = player._get_state_length(anim_state, 0.3)
		if skill_id == "seismic_fissure":
			anim_time = player._get_state_length(anim_state, 0.6)
		player.get_tree().create_timer(anim_time).timeout.connect(func(): player.is_animating_skill = false)
	
	var c_name = Global.current_class
	if c_name == "apprentice":
		ApprenticeSkills.execute(player, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "fighter":
		FighterSkills.execute(player, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "scout":
		ScoutSkills.execute(player, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)

func level_up():
	player.player_stats.level_up()


func _use_skill(slot_index: int):
	# Hapus player.is_attacking dari blokir agar skill jadi prioritas
	if player.is_dead or player.is_casting or player.is_dashing or player.is_targeting or player.is_spinning or player.is_animating_skill or not get_node_or_null("/root/Global"): return
	if player.status_manager and not player.status_manager.can_move():
		var effect_name = player.status_manager.get_movement_restriction_name()
		player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
		return
	if player.status_manager and player.status_manager.has_effect("silence"):
		player.spawn_floating_text("Terkena Silence!", Color(0.8, 0.2, 1.0))
		return
	var skill_id = Global.quick_skills[slot_index]
	if skill_id == "": return
	
	# Cek persyaratan senjata untuk skill tertentu
	const BOW_SKILLS = ["falcon_dive", "arrow_rain"]
	if skill_id in BOW_SKILLS:
		var has_bow = false
		var item_db = get_node_or_null("/root/ItemDB")
		if item_db:
			var main_w = Global.equipment.get("main_weapon", "")
			if main_w != "":
				var w_data = item_db.get_item(main_w)
				if typeof(w_data) == TYPE_DICTIONARY:
					if w_data.get("weapon_type", "None") in ["long_bow", "crossbow"]:
						has_bow = true
		if not has_bow:
			player.spawn_floating_text("Butuh Bow/Crossbow!", Color(1, 0.3, 0.2))
			return
	
	if player.active_skill_cooldowns.get(skill_id, 0.0) > 0:
		player.spawn_floating_text("Skill Cooldown!", Color(0.5, 0.5, 1))
		return
		
	if skill_id == "heal" and player.current_health >= player.max_health:
		player.spawn_floating_text("HP Penuh!", Color(0.2, 1.0, 0.2))
		return
		
	if skill_id == "soul_drain":
		var enemies = get_tree().get_nodes_in_group("Enemy")
		var cursed_exists = false
		for e in enemies:
			if e.get("player.status_manager") and e.status_manager.has_effect("curse"):
				cursed_exists = true
				break
		if not cursed_exists:
			player.spawn_floating_text("Tidak ada target curse!", Color(0.8, 0.0, 1.0))
			return
	
	var skill_db = get_node_or_null("/root/SkillDB")
	if not skill_db: return
	
	var data = skill_db.get_skill(skill_id)
	if data.is_empty(): return
	
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	var mp_cost = skill_db.get_skill_val(skill_id, "mp_costs", cur_lvl)
	var ep_cost = skill_db.get_skill_val(skill_id, "ep_costs", cur_lvl)
	
	if player.current_mana < mp_cost:
		player.spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
		return
	if player.current_energy < ep_cost:
		player.spawn_floating_text("EP Tidak Cukup!", Color(1.0, 0.5, 0.2))
		return
		
	# Skill valid, cancel attack jika sedang player.attack(agar skill memprioritaskan attack)
	if player.is_attacking:
		player.is_attacking = false
		if player.sword_hitbox:
			player.sword_hitbox.set_deferred("disabled", true)
		
	var cost = mp_cost # Passed down just in case
	var type = data.get("type", "instant")
	if type in ["target_aoe", "target_single", "target_cone"]:
		player.is_targeting = true
		player.current_targeting_skill = skill_id
		Engine.time_scale = 0.2
		
		var indicator_scene = load("res://Scenes/Skills/target_indicator.tscn")
		if indicator_scene:
			player.target_indicator_node = indicator_scene.instantiate()
			var custom_range = skill_db.get_skill_val(skill_id, "ranges", cur_lvl)
			var custom_aoe = skill_db.get_skill_val(skill_id, "aoe_radiuses", cur_lvl)
			
			if custom_range == 0: 
				if skill_id == "fatal_smash": custom_range = 10.0
				elif skill_id == "fire_bolt": custom_range = 8.0
				elif skill_id == "sonic_boom": custom_range = 5.0
				elif skill_id == "seismic_fissure": custom_range = 10.0
				elif skill_id == "hex": custom_range = 5.0
				else: custom_range = 2.5
			if custom_aoe == 0: 
				if skill_id == "fatal_smash": custom_aoe = 3.0
				elif skill_id == "seismic_fissure": custom_aoe = 2.0
				else: custom_aoe = 0.6
			
			player.target_indicator_node.max_range = float(custom_range)
			player.target_indicator_node.aoe_radius = float(custom_aoe)
			player.target_indicator_node.player_node = player
			if type == "target_single":
				player.target_indicator_node.indicator_type = "single"
			elif type == "target_cone":
				player.target_indicator_node.indicator_type = "cone"
			else:
				player.target_indicator_node.indicator_type = "circle"
			player.add_child(player.target_indicator_node)
	else:
		player._start_cast_skill(skill_id, data, cost, Vector3.ZERO)


func _start_cast_skill(skill_id: String, data: Dictionary, cost: int, t_pos: Vector3, indicator: Node = null):
	player.is_casting = true
	player.casting_skill_id = skill_id
	var cast_cancelled = false
	
	var sm_lvl = Global.unlocked_skills.get("spell_mastery", 0) if get_node_or_null("/root/Global") else 0
	var cdr_pct = sm_lvl * 0.02

	var skill_db = get_node_or_null("/root/SkillDB")
	if skill_db:
		var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
		var cooldown_time = skill_db.get_skill_val(skill_id, "cooldowns", cur_lvl)
		if typeof(cooldown_time) == TYPE_FLOAT or typeof(cooldown_time) == TYPE_INT:
			var final_cd = float(cooldown_time) * (1.0 - cdr_pct)
			var hardcaps = {"aqua_blast": 5.0, "fire_bolt": 5.0, "sonic_boom": 3.0, "seismic_fissure": 15.0, "heal": 5.0, "holy_veil": 10.0, "hex": 10.0, "soul_drain": 5.0}
			if hardcaps.has(skill_id) and final_cd < hardcaps[skill_id]:
				final_cd = hardcaps[skill_id]
			player.active_skill_cooldowns[skill_id] = final_cd
	
	var base_cast_time = 0.0
	skill_db = get_node_or_null("/root/SkillDB")
	if skill_db:
		var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
		base_cast_time = skill_db.get_skill_val(skill_id, "cast_times", cur_lvl)
		if typeof(base_cast_time) != TYPE_FLOAT and typeof(base_cast_time) != TYPE_INT:
			base_cast_time = 0.0
	
	base_cast_time = float(base_cast_time) * (1.0 - cdr_pct)
	var final_cast_time = base_cast_time / player.casting_speed
	
	var max_range = 0.0
	if skill_db:
		var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
		max_range = skill_db.get_skill_val(skill_id, "ranges", cur_lvl)
	if max_range == 0.0:
		if skill_id == "fatal_smash": max_range = 10.0
		elif skill_id == "fire_bolt": max_range = 8.0
		elif skill_id == "sonic_boom": max_range = 5.0
		elif skill_id == "seismic_fissure": max_range = 10.0
		else: max_range = 2.5
	
	# Membuat Casting Bar
	player.cast_bar = ProgressBar.new()
	player.cast_bar.min_value = 0
	player.cast_bar.max_value = final_cast_time
	player.cast_bar.value = 0
	player.cast_bar.show_percentage = false
	player.cast_bar.custom_minimum_size = Vector2(30, 4)
	player.cast_bar.position = Vector2(-15, 12)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1.0, 0.8, 0.2, 1.0)
	player.cast_bar.add_theme_stylebox_override("background", sb_bg)
	player.cast_bar.add_theme_stylebox_override("fill", sb_fg)
	player._get_hud_canvas().add_child(player.cast_bar)
	
	# Visual indikator casting
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(player, "modulate", Color(1, 1, 1, 0.5), 0.2)
	tween.tween_property(player, "modulate", Color(1, 1, 1, 1), 0.2)
	
	var aqua_ind = null
	if skill_id == "aqua_blast":
		var ind_scene = load("res://Scenes/Skills/target_indicator.tscn")
		if ind_scene:
			aqua_ind = ind_scene.instantiate()
			aqua_ind.indicator_type = "circle"
			aqua_ind.frozen = true
			var cur_lvl = Global.unlocked_skills.get("aqua_blast", 0)
			var aoe = 0.8
			var skill_db_node = get_node_or_null("/root/SkillDB")
			if skill_db_node: aoe = skill_db_node.get_skill_val("aqua_blast", "aoe_radiuses", cur_lvl)
			if aoe == 0: aoe = 0.8
			aqua_ind.aoe_radius = float(aoe)
			aqua_ind.max_range = 0.0 # Don't draw the outer circle
			player.add_child(aqua_ind)
	
	var timer = 0.0
	while timer < final_cast_time:
		var dt = get_process_delta_time()
		timer += dt
		if is_instance_valid(player.cast_bar):
			player.cast_bar.value = timer
			
		if not player.is_casting or player.is_dead:
			cast_cancelled = true
			break
			
		if data.get("type", "instant") == "target_aoe" and player.global_position.distance_to(t_pos) > max_range:
			cast_cancelled = true
			player.is_casting = false
			player.spawn_floating_text("Terlalu Jauh!", Color(1, 0.5, 0))
			break
			
		if data.get("type", "instant") == "target_single" and is_instance_valid(indicator):
			var single_tgt = indicator.get("single_target_node")
			if not is_instance_valid(single_tgt) or single_tgt.get("player.is_dead"):
				cast_cancelled = true
				player.is_casting = false
				player.spawn_floating_text("Target Hilang!", Color(1, 0.5, 0))
				break
			
		await get_tree().process_frame
	
	if is_instance_valid(player.cast_bar):
		player.cast_bar.queue_free()
		
	if is_instance_valid(indicator):
		indicator.queue_free()
		
	if is_instance_valid(aqua_ind):
		aqua_ind.queue_free()
	
	if Input.is_action_just_pressed("interact") and Global.current_class == "scout":
		if player.status_manager and player.status_manager.has_effect("shadow_walk"):
			pass # shadow walk handles it
		else:
			# evasive leap
			player.velocity = -player.last_direction * 8.0
			player.is_invincible = true
			player.apply_camera_shake(2.0, 0.1)
			get_tree().create_timer(0.3).timeout.connect(func(): player.is_invincible = false)

	if not is_instance_valid(tween): return
	tween.kill()
	player.modulate = Color(1, 1, 1)
	
	if cast_cancelled:
		if player.active_skill_cooldowns.has(skill_id):
			player.active_skill_cooldowns.erase(skill_id)
		return
	player.is_casting = false
	
	player.current_mana -= cost
	player.emit_signal("mana_changed", player.current_mana, player.max_mana)
	
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	skill_db = get_node_or_null("/root/SkillDB")
	if skill_db:
		var ep_cost = skill_db.get_skill_val(skill_id, "ep_costs", cur_lvl)
		player.current_energy -= ep_cost
		if player.current_energy < 0: player.current_energy = 0
		player.emit_signal("energy_changed", player.current_energy, player.max_energy)

	
	player._execute_skill(skill_id, data, t_pos, indicator)



func attack(is_charge: bool):
	if player.status_manager and not player.status_manager.can_attack(): return
	if player.status_manager and player.status_manager.has_effect("shadow_walk"):
		player.status_manager.remove_effect("shadow_walk")
	player._update_aim_to_mouse(true)
	player.is_attacking = true
	player.is_charge_attacking = is_charge
	
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	var is_dual_wield = false
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
		if w_type == "dagger" and Global.equipment.get("secondary_weapon", "") != "":
			var sec_data = item_db.get_item(Global.equipment["secondary_weapon"])
			if sec_data.get("weapon_type", "None") == "dagger":
				is_dual_wield = true
	
	var is_crit = randf() * 100.0 < player.critical_chance
	player.current_attack_damage = player.physical_attack
	
	player.current_attack_speed = player.attack_speed_multiplier
	
	var should_lunge = true
	
	if is_charge:
		player.current_attack_damage = player.physical_attack * 2
		if w_type == "long_sword":
			player._perform_spin_attack(player.current_attack_damage)
			player.current_attack_speed *= 1.5
			should_lunge = false
		elif w_type == "dagger":
			should_lunge = false
		elif w_type == "gloves":
			player.current_attack_damage = int(player.physical_attack * 1.5)
			player.apply_camera_shake(12.0, 0.2) # Uppercut shake
		elif w_type == "lance":
			player.apply_camera_shake(5.0, 0.15) # Jousting shake
			
		player.current_attack_speed *= 1.5
	else:
		match w_type:
			"long_sword": player.current_attack_speed *= 0.7 
			"gloves": player.current_attack_speed *= 2.0 
			"dagger": player.current_attack_speed *= 1.5 
			
	if is_crit:
		player.current_attack_damage = int(player.current_attack_damage * 2.0)
		print("CRITICAL HIT!")
		
	# Bersihkan hit list SEKARANG agar siap, tapi hitbox baru aktif setelah delay
	if player.sword_hitbox:
		player.sword_hitbox.set_deferred("disabled", true) # Pastikan mati dulu
		var area = player.sword_hitbox.get_parent()
		if area and area.has_method("clear_hit_list"):
			area.clear_hit_list()
			
	if player.status_manager: player.current_attack_speed *= player.status_manager.get_attack_speed_multiplier()
	
	var target_state = player.get_anim_state("HeavyAttack" if is_charge else "Attack")
	if player.animation_tree and player.animation_tree.tree_root is AnimationNodeStateMachine:
		if not player.animation_tree.tree_root.has_node(target_state):
			target_state = player.get_anim_state("Attack")
			
	var actual_len = player._get_state_length(target_state, player.base_attack_duration)
	player.current_anim_speed_ratio = actual_len / player.base_attack_duration
	
	if player.animation_tree:
		player.animation_tree.set("parameters/AttackTimeScale/scale", player.current_attack_speed * player.current_anim_speed_ratio)
	
	if player.state_machine:
		player.state_machine.travel(target_state)
		
	var current_attack_duration = player.base_attack_duration / player.current_attack_speed

	# Bersihkan hit list agar musuh bisa kena hit lagi di serangan berikutnya
	if player.sword_hitbox:
		var area = player.sword_hitbox.get_parent()
		if area and area.has_method("clear_hit_list"):
			area.clear_hit_list()
	# Timing aktif/nonaktif hitbox diatur lewat keyframe animasi (property: disabled)
	# Tambahkan track "CollisionShape3D > disabled" di custom/attack AnimationPlayer

	if is_charge and should_lunge:
		player.charge_lunge_timer = current_attack_duration * 0.2

	if is_dual_wield:
		# Double hit: bersihkan hit list di tengah animasi agar hit kedua bisa detect
		await get_tree().create_timer(current_attack_duration / 2.0).timeout
		if player.sword_hitbox:
			var area = player.sword_hitbox.get_parent()
			if area and area.has_method("clear_hit_list"):
				area.clear_hit_list()
		await get_tree().create_timer(current_attack_duration / 2.0).timeout
	else:
		await get_tree().create_timer(current_attack_duration).timeout

	if player.is_attacking:
		player.attack_finished()


func attack_finished():
	player.is_attacking = false
	player.current_attack_speed = 1.0
	if player.sword_hitbox: player.sword_hitbox.set_deferred("disabled", true)
	if player.state_machine: player.state_machine.travel(player.get_anim_state("Idle"))


func _get_state_length(state_name: String, fallback: float) -> float:
	if not player.animation_tree: return fallback
	if not player.animation_tree.tree_root is AnimationNodeStateMachine: return fallback
	var sm = player.animation_tree.tree_root as AnimationNodeStateMachine
	if not sm.has_node(state_name): return fallback
	var node = sm.get_node(state_name)
	if node is AnimationNodeAnimation:
		var anim_name = node.animation
		var ap_path = player.animation_tree.anim_player
		var ap = player.animation_tree.get_node_or_null(ap_path)
		if ap and ap.has_animation(anim_name):
			return ap.get_animation(anim_name).length
	return fallback


func _perform_spin_attack(dmg: int, is_mana_burst: bool = false):
	if is_mana_burst:
		var max_radius = 2.0
		var duration = 0.2
		
		var burst_vis = CSGCylinder3D.new()
		burst_vis.radius = max_radius
		burst_vis.height = 0.2
		burst_vis.sides = 32
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.0, 0.8, 1.0, 0.5)
		burst_vis.material = mat
		get_tree().current_scene.add_child(burst_vis)
		burst_vis.global_position = player.global_position
		
		player.is_casting = true
		
		var t = get_tree().create_tween()
		burst_vis.scale = Vector3(0.01, 1.0, 0.01)
		t.tween_property(burst_vis, "scale", Vector3(1.0, 1.0, 1.0), duration)
		t.parallel().tween_property(mat, "albedo_color:a", 0.0, duration)
		
		var hit_enemies = []
		var check_timer = Timer.new()
		check_timer.wait_time = 0.05
		check_timer.autostart = true
		check_timer.timeout.connect(func():
			if not is_instance_valid(burst_vis): return
			var current_radius = burst_vis.scale.x * max_radius
			var enemies = get_tree().get_nodes_in_group("Enemy")
			for body in enemies:
				if not hit_enemies.has(body):
					var dist = player.global_position.distance_to(body.global_position)
					if dist <= current_radius:
						hit_enemies.append(body)
						if body.has_method("take_damage"):
							# Call take_damage but pass Vector3.ZERO so it doesn't apply its own 1-meter knockback
							body.take_damage(dmg, Vector3.ZERO)
						if "player.knockback_velocity" in body:
							var push_dir = (body.global_position - player.global_position)
							push_dir.y = 0
							if push_dir == Vector3.ZERO: push_dir = Vector3(0, 0, 1)
							# 7.746 player.velocity with 6.0 friction = ~5 meters distance
							body.knockback_velocity = push_dir.normalized() * 7.746
						elif body.get("player.velocity") != null:
							var push_dir = (body.global_position - player.global_position).normalized()
							body.velocity = push_dir * 1100
		)
		burst_vis.add_child(check_timer)
		
		t.tween_callback(func():
			player.is_casting = false
			if is_instance_valid(burst_vis):
				burst_vis.queue_free()
		)
		return
	else:
		var spin_area = Area3D.new()
		spin_area.collision_layer = 0
		spin_area.collision_mask = 5
		spin_area.position = player.global_position
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 4.5
		shape.height = 1.0
		col.shape = shape
		spin_area.add_child(col)
		
		# Spin player player.sprite
		if player.sprite:
			var t = get_tree().create_tween()
			t.tween_property(player.sprite, "rotation", Vector3(0, PI * 2.0, 0), 0.2).as_relative()
			t.tween_callback(func(): player.sprite.rotation.y = 0)
			
		get_tree().current_scene.add_child(spin_area)
		
		# Small delay to let physics detect
		await get_tree().create_timer(0.05).timeout
		var bodies = spin_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Enemy") and body.has_method("take_damage"):
				body.take_damage(dmg, player.global_position)
				if "player.knockback_velocity" in body:
					var push_dir = (body.global_position - player.global_position)
					push_dir.y = 0
					if push_dir == Vector3.ZERO: push_dir = Vector3(0, 0, 1)
					body.knockback_velocity = push_dir.normalized() * 6.0
				elif body.get("player.velocity") != null:
					var push_dir = (body.global_position - player.global_position).normalized()
					body.velocity = push_dir * 800
		
		if is_instance_valid(spin_area):
			spin_area.queue_free()


func _create_charge_bar():
	player.magic_charge_bar = ProgressBar.new()
	player.magic_charge_bar.min_value = 0
	player.magic_charge_bar.max_value = 2.0
	player.magic_charge_bar.value = 0
	player.magic_charge_bar.show_percentage = false
	player.magic_charge_bar.custom_minimum_size = Vector2(40, 6)
	player.magic_charge_bar.position = Vector2(-20, 20)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.2, 0.8, 1.0, 1.0)
	player.magic_charge_bar.add_theme_stylebox_override("background", sb_bg)
	player.magic_charge_bar.add_theme_stylebox_override("fill", sb_fg)
	player._get_hud_canvas().add_child(player.magic_charge_bar)
	player.magic_charge_timer = 0.01


func _release_magic_charge():
	var charge_time = player.magic_charge_timer
	player.magic_charge_timer = 0.0
	player.is_casting = false
	
	if is_instance_valid(player.magic_charge_bar):
		player.magic_charge_bar.queue_free()
		
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
		
	player.charge_attack_cooldown = 1.0
	
	if w_type == "long_bow":
		player.current_energy -= 30
		if player.current_energy < 0: player.current_energy = 0
		player.emit_signal("energy_changed", player.current_energy, player.max_energy)
		player._fire_projectile("arrow", true, charge_time)
	else:
		player.current_mana -= 30
		if player.current_mana < 0: player.current_mana = 0
		player.emit_signal("mana_changed", player.current_mana, player.max_mana)
		player._fire_projectile("magic_charge", false, charge_time)


func _fire_projectile(type: String, is_charge: bool, charge_time: float = 0.0):
	if type.begins_with("magic") and player.status_manager and not player.status_manager.can_cast(): return
	if not type.begins_with("magic") and player.status_manager and not player.status_manager.can_attack(): return
	if player.status_manager and player.status_manager.has_effect("shadow_walk"):
		player.status_manager.remove_effect("shadow_walk")
	player._update_aim_to_mouse(true)
	player.is_attacking = true
	var fire_dir = player.last_direction
	
	if type.begins_with("magic"):
		player.current_attack_speed = player.casting_speed
	else:
		player.current_attack_speed = player.attack_speed_multiplier
		
	if player.status_manager: player.current_attack_speed *= player.status_manager.get_attack_speed_multiplier()
		
	var target_state = player.get_anim_state("Attack")
	var actual_len = player._get_state_length(target_state, player.base_attack_duration)
	player.current_anim_speed_ratio = actual_len / player.base_attack_duration
	
	if player.animation_tree:
		player.animation_tree.set("parameters/AttackTimeScale/scale", player.current_attack_speed * player.current_anim_speed_ratio)
	if player.state_machine:
		player.state_machine.travel(target_state)
		
	var duration = (player.base_attack_duration / player.current_attack_speed)
	var spawn_delay = duration * 0.5
	
	if player.sword_hitbox_area:
		player.sword_hitbox_area.is_active = false
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(player.sword_hitbox_area):
				player.sword_hitbox_area.is_active = true
		)
	
	await get_tree().create_timer(spawn_delay).timeout
	
	if player.is_dead or not player.is_attacking: return
		
	var proj_scene = load("res://Scenes/Skills/player_projectile.tscn")
	if proj_scene and get_tree().current_scene:
		var spawn_pos = player.global_position + Vector3(0, 0.85, 0)
		
		var w_type = "None"
		if get_node_or_null("/root/ItemDB") and Global.equipment.get("main_weapon", "") != "":
			var w_data = ItemDB.get_item(Global.equipment["main_weapon"])
			w_type = w_data.get("weapon_type", "None")
			
		var max_range = 15.0 # Default for staff
		if w_type == "rod": max_range = 10.0
		var speed_m_s = 60.0 * (1000.0 / 3600.0)
		var custom_lifetime = max_range / speed_m_s

		if type == "magic":
			var proj = proj_scene.instantiate()
			proj.position = spawn_pos
			proj.direction = fire_dir
			proj.damage = player.magic_attack
			proj.speed = speed_m_s
			if "lifetime" in proj: proj.lifetime = custom_lifetime
			var vis = proj.get_node_or_null("Visual")
			if vis: 
				vis.color = Color(0.2, 0.5, 1.0)
				vis.size = Vector3(0.3, 0.3, 0.3)
			get_tree().current_scene.add_child(proj)
			
		elif type == "magic_charge":
			var proj = proj_scene.instantiate()
			proj.position = spawn_pos
			proj.direction = fire_dir
			
			var multiplier = 1.0 + charge_time # Max charge_time is 2.0, so multiplier is up to 3.0
			proj.damage = int(player.magic_attack * multiplier)
			proj.speed = speed_m_s
			if "lifetime" in proj: proj.lifetime = custom_lifetime
			if "is_piercing" in proj: proj.is_piercing = true
			
			var vis = proj.get_node_or_null("Visual")
			if vis:
				vis.color = Color(0.2, 0.5, 1.0)
				vis.size = Vector3(0.3 * multiplier, 0.3 * multiplier, 0.3 * multiplier)
			
			get_tree().current_scene.add_child(proj)
			
		elif type == "mana_burst":
			player._perform_spin_attack(int(player.magic_attack * 1.5), true)
			
		elif type == "bolt":
			var arrow_scene = load("res://Scenes/Skills/arrow_projectile.tscn")
			if not arrow_scene: arrow_scene = proj_scene
			
			if is_charge:
				# Rapid fire 5 bolts
				for i in range(5):
					if not is_instance_valid(player): return
					var proj = arrow_scene.instantiate()
					proj.position = spawn_pos
					proj.direction = fire_dir.rotated(Vector3.UP, randf_range(-0.1, 0.1))
					proj.damage = int(player.physical_attack * 0.5)
					proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
					get_tree().current_scene.add_child(proj)
					await get_tree().create_timer(0.1).timeout
			else:
				var proj = arrow_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir
				proj.damage = player.physical_attack
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
				
		elif type == "dagger":
			for angle_offset in [-0.4, 0.0, 0.4]:
				var proj = proj_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir.rotated(Vector3.UP, angle_offset)
				proj.damage = int(player.physical_attack * 0.7) 
				proj.speed = 600.0
				var vis = proj.get_node_or_null("Visual")
				if vis: 
					vis.color = Color(0.4, 0.4, 0.4)
					vis.size = Vector3(0.3, 0.05, 0.1)
					vis.position = Vector3(-0.15, 0, 0)
					proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
				
		elif type == "arrow":
			var arrow_scene = load("res://Scenes/Skills/arrow_projectile.tscn")
			if not arrow_scene: arrow_scene = proj_scene
			
			if is_charge:
				# Piercing Shot (High damage, very fast)
				var proj = arrow_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir
				var multiplier = 1.0 + (charge_time / 2.0)
				proj.damage = int(player.physical_attack * 2.0 * multiplier) 
				if "player.atk_elements" in proj:
					proj.atk_elements = player.atk_elements.duplicate()
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
			else:
				var proj = arrow_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir
				proj.damage = player.physical_attack
				if "player.atk_elements" in proj:
					proj.atk_elements = player.atk_elements.duplicate()
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
				
	await get_tree().create_timer(duration - spawn_delay).timeout
	if player.is_attacking:
		player.is_attacking = false
		if player.state_machine: player.state_machine.travel(player.get_anim_state("Idle"))


func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, attack_element: String = "netral", kb_force: float = 200.0):
	if player.is_dead or player.is_dashing or player.is_invincible: return
	
	player.apply_camera_shake(5.0, 0.15)
	
	if player.is_casting:
		player.is_casting = false
		player.spawn_floating_text("Batal!", Color(1, 0.5, 0))
		
	var final_damage = amount - player.physical_defense
	if final_damage < 1: final_damage = 1
		
	if player.status_manager and player.status_manager.has_effect("holy_veil"):
		var hv_data = player.status_manager.get_effect_data("holy_veil")
		var shield = hv_data.get("shield", 0)
		if shield >= final_damage:
			shield -= final_damage
			hv_data["shield"] = shield
			player.spawn_floating_text("Absorbed!", Color(1.0, 1.0, 0.5))
			return
		else:
			final_damage -= shield
			player.status_manager.remove_effect("holy_veil")
			
	if player.status_manager:
		final_damage = int(final_damage * player.status_manager.get_damage_taken_multiplier())
		player.status_manager.handle_damage_taken()
		
	# Elemental Multiplier (Attack vs Defense Element)
	var current_def_element = player.def_element
	if player.status_manager and player.status_manager.has_effect("holy_veil"):
		current_def_element = "cahaya"
	var element_multiplier = Global.get_element_multiplier([attack_element], current_def_element)
	final_damage = int(final_damage * element_multiplier)
		
	# Elemental Resistance Logic
	var resist = 0.0
	if player.def_resistances.has(attack_element):
		resist = player.def_resistances[attack_element] / 100.0
		
	final_damage = int(final_damage * (1.0 - resist))
	
	if final_damage <= 0 and resist >= 1.0:
		player.spawn_floating_text("Immune!", Color(0.8, 0.8, 0.8))
		return
		
	player.current_health -= final_damage
	player.emit_signal("health_changed", player.current_health, player.max_health)
	
	var dmg_color = Color(1, 0.2, 0.2)
	if resist >= 0.5: dmg_color = Color(0.6, 0.6, 0.6) # Gray for resisted
	player.spawn_damage_text(final_damage, dmg_color)
	
	if knockback_source != Vector3.ZERO and not player.is_charge_attacking and not player.falcon_dive_active:
		var knockback_direction = (player.global_position - knockback_source)
		knockback_direction.y = 0 # Jangan pantulkan ke atas/bawah agar tidak menembus tanah
		knockback_direction = knockback_direction.normalized()
		var knockback_strength = 40.0 # 40^2 / (2 * 800) = 1 meter
		player.knockback_velocity = knockback_direction * knockback_strength
		
	player.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	player.modulate = Color(1, 1, 1)
	
	if player.current_health <= 0: player.die()


func spawn_damage_text(amount: int, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 64
	label.outline_size = 12
	label.text = str(amount)
	label.modulate = color
	label.position = player.global_position + Vector3(0, 0.5, 0)
	 
	get_tree().current_scene.add_child(label)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)


func spawn_floating_text(msg: String, color: Color):
	if not is_inside_tree(): return
	print("--- SPAWN TEXT: ", msg, " ---")
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 64
	label.outline_size = 12
	label.text = msg
	label.modulate = color
	get_tree().current_scene.add_child(label)
	label.position = player.global_position + Vector3(0, 0.5, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)


func die():
	if player.is_dead: return
	player.is_dead = true
	if player.sword_hitbox: player.sword_hitbox.set_deferred("disabled", true)
	if player.animation_tree: player.animation_tree.active = false
	if player.animation_player:
		player.animation_player.play("Death")
		await player.animation_player.animation_finished
	player.emit_signal("player_died", player.survival_time, player.enemies_killed, player.level, player.coins)
	
	var go_scene = load("res://Scenes/UI/game_over_hud.tscn")
	if go_scene and get_tree().current_scene:
		var go = go_scene.instantiate()
		get_tree().current_scene.add_child(go)
		if go.has_method("show_game_over"):
			go.show_game_over(player.survival_time, player.enemies_killed, player.level, player.coins)


func add_coin(amount: int):
	player.coins += amount
	if get_node_or_null("/root/Global"): Global.coins = player.coins
	player.emit_signal("coin_changed", player.coins)


func add_exp(amount: int):
	player.current_exp += amount
	if get_node_or_null("/root/Global"): 
		Global.current_exp = player.current_exp
		
		# Class EXP
		var cls = Global.current_class
		Global.class_exp[cls] += amount
		while Global.class_exp[cls] >= Global.class_max_exp[cls]:
			Global.class_levels[cls] += 1
			Global.class_exp[cls] -= Global.class_max_exp[cls]
			Global.class_max_exp[cls] = int(Global.class_max_exp[cls] * 1.5)
			Global.class_skill_points[cls] += 1
			player.spawn_floating_text("Class Level Up!", Color(1.0, 0.8, 0.2))
			
	player.emit_signal("exp_changed", player.current_exp, player.max_exp, player.level)
	
	while player.current_exp >= player.max_exp:
		player.level_up()


func restore_hp(amount: int):
	if player.is_dead: return
	player.current_health += amount
	if player.current_health > player.max_health: player.current_health = player.max_health
	player.emit_signal("health_changed", player.current_health, player.max_health)


func restore_mp(amount: int):
	if player.is_dead: return
	player.current_mana += amount
	if player.current_mana > player.max_mana: player.current_mana = player.max_mana
	player.emit_signal("mana_changed", player.current_mana, player.max_mana)



func _process(delta):
	if player.is_dead: return
	
	var has_endure = player.status_manager and player.status_manager.has_effect("endure")
	var has_holy_veil = player.status_manager and player.status_manager.has_effect("holy_veil")
	
	if has_holy_veil:
		player.modulate = Color(1.5, 1.5, 0.8)
	elif has_endure:
		player.modulate = Color(1.0, 0.8, 0.2)
	else:
		if player.modulate == Color(1.0, 0.8, 0.2) or player.modulate == Color(1.5, 1.5, 0.8):
			player.modulate = Color(1, 1, 1)
	
	if player.is_spinning:
		player.spin_timer -= delta
		if is_instance_valid(player.spin_bar):
			player.spin_bar.value = player.spin_timer
		var t = Engine.get_frames_drawn()
		if player.sprite:
			player.sprite.rotation.y += 15.0 * delta # visual spin
		if t % 15 == 0:
			var enemies = get_tree().get_nodes_in_group("Enemy")
			var sweep_radius = 3.0 # Radius putaran pedang
			for e in enemies:
				if e.global_position.distance_to(player.global_position) <= sweep_radius:
					if e.has_method("take_damage"):
						e.take_damage(player.physical_attack * 0.5, player.global_position)
		if player.spin_timer <= 0:
			player.is_spinning = false
			if player.sprite: player.sprite.rotation.y = 0
			if is_instance_valid(player.spin_bar):
				player.spin_bar.queue_free()
