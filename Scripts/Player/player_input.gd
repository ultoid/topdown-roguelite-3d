extends Node
class_name PlayerInput

@onready var player: CharacterBody3D = get_parent()

func _unhandled_input(event):
	if player.is_farming_targeting:
		if event.is_action_pressed("basic_attack"):
			player._confirm_farming()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") or event.is_action_pressed("charge_attack"): # Cancel
			player._cancel_farming_targeting()
			get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("basic_attack") and not player.is_targeting and not player.is_farming_targeting:
		if not player.is_attacking and not player.is_jumping and not player.is_casting and player.magic_charge_timer == 0.0 and not player.is_animating_skill and not player.is_spinning and not player.is_dashing:
			if player.status_manager and not player.status_manager.can_move():
				var effect_name = player.status_manager.get_movement_restriction_name()
				player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
			else:
				var item_db = get_node_or_null("/root/ItemDB")
				var w_type = "None"
				if item_db and Global.equipment.get("main_weapon", "") != "":
					var w_data = item_db.get_item(Global.equipment["main_weapon"])
					w_type = w_data.get("weapon_type", "None")
				
				match w_type:
					"staff", "rod":
						player._fire_projectile("magic", false)
					"long_bow", "crossbow":
						player._fire_projectile("arrow", false)
					"dagger":
						# Dual hit logic will be inside player.attack
						player.attack(false)
					_:
						player.attack(false)
			get_viewport().set_input_as_handled()
			return

	if player.is_targeting:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				player.target_pos = player.get_mouse_3d_pos()
				if player.current_targeting_skill != "":
					var skill_db = get_node_or_null("/root/SkillDB")
					if skill_db:
						var data = skill_db.get_skill(player.current_targeting_skill)
						var cur_lvl_r = Global.unlocked_skills.get(player.current_targeting_skill, 0) if get_node_or_null("/root/Global") else 0
						var max_range = skill_db.get_skill_val(player.current_targeting_skill, "ranges", cur_lvl_r)
						if max_range <= 0: 
							if player.current_targeting_skill == "fatal_smash": max_range = 10.0
							elif player.current_targeting_skill == "fire_bolt": max_range = 8.0
							elif player.current_targeting_skill == "sonic_boom": max_range = 5.0
							elif player.current_targeting_skill == "seismic_fissure": max_range = 10.0
							elif player.current_targeting_skill == "hex": max_range = 5.0
							else: max_range = 2.5
						if player.global_position.distance_to(player.target_pos) > max_range:
							player.target_pos = player.global_position + (player.target_pos - player.global_position).normalized() * max_range
				
				_end_targeting(true)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_end_targeting(false)
				get_viewport().set_input_as_handled()


func _end_targeting(confirm: bool):
	Engine.time_scale = 1.0
	
	var indicator = player.target_indicator_node
	player.target_indicator_node = null
	
	if confirm and player.current_targeting_skill != "":
		var is_valid_target = true
		if is_instance_valid(indicator) and indicator.get("indicator_type") == "single":
			if not is_instance_valid(indicator.get("single_target_node")):
				is_valid_target = false
				player.spawn_floating_text("Tidak ada target!", Color(1, 0.5, 0))
				indicator.queue_free()
				
		if is_valid_target:
			if is_instance_valid(indicator):
				indicator.start_casting(player.target_pos)
				
			var skill_db = get_node_or_null("/root/SkillDB")
			if skill_db:
				var data = skill_db.get_skill(player.current_targeting_skill)
				var cur_lvl = Global.unlocked_skills.get(player.current_targeting_skill, 0) if get_node_or_null("/root/Global") else 0
				var cost = skill_db.get_skill_val(player.current_targeting_skill, "mp_costs", cur_lvl)
				player._start_cast_skill(player.current_targeting_skill, data, cost, player.target_pos, indicator)
	else:
		if is_instance_valid(indicator):
			indicator.queue_free()

	player.targeting_cancel_cooldown = 0.2
	player.charge_input_consumed = true
	player.is_targeting = false


func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			print("DEBUG: Level Up +1")
			player.level_up()
		elif event.physical_keycode == KEY_F2:
			print("DEBUG: Koin +1000")
			player.add_coin(1000)
		elif event.physical_keycode == KEY_F3:
			print("DEBUG: Class Level +1")
			if get_node_or_null("/root/Global"):
				var cls = Global.current_class
				Global.class_levels[cls] = Global.class_levels.get(cls, 1) + 1
				Global.class_skill_points[cls] = Global.class_skill_points.get(cls, 0) + 1
				player.spawn_floating_text("Class Lv UP!", Color(1, 0.8, 0.2))

	if event.is_action_pressed("open_inventory"):
		player._open_inventory()
	elif event.is_action_pressed("open_menu"):
		player.toggle_menu()
	elif event.is_action_pressed("open_skill_menu"):
		player._open_skill_menu()
	elif event.is_action_pressed("open_crafting"):
		player._open_crafting_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("item_1"):
		_use_quick_item(0)
	elif event.is_action_pressed("item_2"):
		_use_quick_item(1)
	elif event.is_action_pressed("item_3"):
		_use_quick_item(2)
	elif event.is_action_pressed("item_4"):
		_use_quick_item(3)
	elif event.is_action_pressed("skill_1"):
		player._use_skill(0)
	elif event.is_action_pressed("skill_2"):
		player._use_skill(1)
	elif event.is_action_pressed("skill_3"):
		player._use_skill(2)
	elif event.is_action_pressed("skill_4"):
		player._use_skill(3)
	elif event.is_action_pressed("skill_5"):
		player._use_skill(4)
	elif event.is_action_pressed("skill_6"):
		player._use_skill(5)
	elif event.is_action_pressed("skill_7"):
		player._use_skill(6)
	elif event.is_action_pressed("skill_8"):
		player._use_skill(7)
	elif event.is_action_pressed("interact"):
		if player.is_doing_life_skill:
			player._cancel_life_skill()
		else:
			player._try_interact()
		get_viewport().set_input_as_handled()



func _use_quick_item(slot_index: int):
	if player.is_dead or not get_node_or_null("/root/Global"): return
	if player.status_manager and not player.status_manager.can_move():
		var effect_name = player.status_manager.get_movement_restriction_name()
		player.spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
		return
	var item_id = Global.quick_items[slot_index]
	if item_id != "" and Global.inventory.get(item_id, 0) > 0:
		var heal_amt = 50
		var effect_type = "heal_hp"
		
		if get_node_or_null("/root/ItemDB"):
			var item_data = ItemDB.get_item(item_id)
			if item_data.has("effect_amount"):
				heal_amt = item_data["effect_amount"]
			if item_data.has("effect_type"):
				effect_type = item_data["effect_type"]
		
		if effect_type == "heal_hp":
			if player.current_health >= player.max_health:
				player.spawn_floating_text("HP Penuh!", Color(1, 0.2, 0.2))
				return
			player.spawn_floating_text("HP +" + str(heal_amt), Color(0.2, 1.0, 0.2))
			player.restore_hp(heal_amt)
		elif effect_type == "heal_mp":
			if player.current_mana >= player.max_mana:
				player.spawn_floating_text("MP Penuh!", Color(0.2, 0.5, 1.0))
				return
			player.spawn_floating_text("MP +" + str(heal_amt), Color(0.2, 0.5, 1.0))
			player.restore_mp(heal_amt)
		elif effect_type == "heal_ep":
			if player.current_energy >= player.max_energy:
				player.spawn_floating_text("EP Penuh!", Color(1, 1, 0.2))
				return
			player.current_energy += heal_amt
			if player.current_energy > player.max_energy: player.current_energy = player.max_energy
			player.emit_signal("energy_changed", player.current_energy, player.max_energy)
			player.spawn_floating_text("EP +" + str(heal_amt), Color(1, 1, 0))
		elif effect_type == "unlock_recipe":
			var recipe_id = ""
			if get_node_or_null("/root/ItemDB"):
				var data = ItemDB.get_item(item_id)
				recipe_id = data.get("recipe_id", "")
			if recipe_id != "" and not Global.unlocked_recipes.has(recipe_id):
				Global.unlocked_recipes.append(recipe_id)
				player.spawn_floating_text("Resep dipelajari!", Color(1, 1, 0))
			else:
				player.spawn_floating_text("Sudah dipelajari!", Color(0.7, 0.7, 0.7))
				return # Prevent item consumption
				
		Global.inventory[item_id] -= 1
		
		var hud = get_node_or_null("/root/PlayerHUD")
		if hud and hud.has_method("_update_quick_items"):
			hud._update_quick_items()


