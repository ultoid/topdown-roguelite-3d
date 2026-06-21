extends CharacterBody3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

signal health_changed(current_health: int, max_health: int)
signal mana_changed(current_mana: int, max_mana: int)
signal energy_changed(current_energy: float, max_energy: float)
signal player_died(survival_time: float, enemies_killed: int, level: int, coins: int)
signal coin_changed(coins: int)
signal exp_changed(current_exp: int, max_exp: int, level: int)

@export var max_health: int = 100
@export var base_attack_duration: float = 0.6 

var current_health: int
var current_mana: int
var max_mana: int = 50

var current_energy: float = 100.0
var max_energy: float = 100.0
var energy_regen: float = 7.5
var mana_regen_accumulator: float = 0.0
var elemental_mastery_bonus_pct: float = 0.0 # Regen 7.5 energy / sec

var knockback_velocity: Vector3 = Vector3.ZERO

# 6 Base Stats
var stat_str: int = 1
var stat_vit: int = 1
var stat_int: int = 1
var stat_luk: int = 1
var stat_agi: int = 1
var stat_dex: int = 1
var stat_points: int = 0

# Derived stats
var physical_attack: int = 10
var magic_attack: int = 10
var casting_speed: float = 1.0
var physical_defense: int = 0
var magic_defense: int = 0
var critical_chance: float = 0.0
var walk_speed: float = 5.0 * (1000.0 / 3600.0) # 5 km/h
var run_speed: float = 20.0 * (1000.0 / 3600.0) # 20 km/h
var attack_speed_multiplier: float = 1.0
var accuracy: float = 1.0

var current_attack_damage: int = 10

# Elemental Stats
var atk_elements: Array = ["netral"]
var def_element: String = "netral"
var def_resistances: Dictionary = {}
var element_dmg_bonus: Dictionary = {}

var coins: int = 0
var level: int = 1
var current_exp: int = 0
var max_exp: int = 10

var is_attacking: bool = false
var current_attack_speed: float = 1.0
var current_anim_speed_ratio: float = 1.0
var is_charge_attacking: bool = false
var last_direction: Vector3 = Vector3(0, 0, 1)

var is_dead: bool = false
var is_invincible: bool = false
var casting_skill_id: String = ""

var interaction_prompt: Label = null

var survival_time: float = 0.0
var enemies_killed: int = 0

var is_fishing: bool = false

var falcon_dive_active: bool = false
var mirage_strike_charges: int = 0

var is_dashing: bool = false
var is_casting: bool = false
var is_animating_skill: bool = false

var magic_charge_timer: float = 0.0
var magic_charge_bar: ProgressBar = null


var is_farming_targeting: bool = false
var farming_indicator: MeshInstance3D = null
var farming_zone_ref: Node = null
var is_targeting: bool = false
var targeting_cancel_cooldown: float = 0.0
var charge_input_consumed: bool = false
var current_targeting_skill: String = ""
var target_pos: Vector3 = Vector3.ZERO
var target_indicator_node: Node3D = null

var dash_timer: float = 0.0
var dash_duration: float = 0.4
var dash_anim_length: float = 1.0
var dash_speed: float = 15.0
var dash_cooldown: float = 3.0
var current_dash_cooldown: float = 0.0

var global_movement_scale: float = 1.0

var last_tap_key: String = ""
var last_tap_time: float = 0.0
var is_running_from_double_tap: bool = false

var is_jumping: bool = false
var jump_timer: float = 0.0
var jump_duration: float = 0.5
var jump_height: float = 15.0
var base_y_offset: float = 0.0
var jump_cooldown: float = 0.0

# Fatal Smash state (position dihandle di _physics_process)
var is_smashing: bool = false
var smash_start_pos: Vector3 = Vector3.ZERO
var smash_target_pos: Vector3 = Vector3.ZERO
var smash_elapsed: float = 0.0
var smash_total_dur: float = 0.6


var status_manager: StatusEffectManager = null

# Life Skill States
var is_doing_life_skill: bool = false
var life_skill_target: Node = null
var life_skill_type: String = ""
var life_skill_progress: int = 0
var life_skill_max_progress: int = 0
var life_skill_bar: ProgressBar = null


var cast_bar: ProgressBar = null

var active_skill_cooldowns: Dictionary = {}
var charge_attack_cooldown: float = 0.0
var charge_lunge_timer: float = 0.0

var is_auto_walking: bool = false
var auto_walk_target: Vector3 = Vector3.ZERO
var auto_walk_callback: Callable

var hud_canvas: CanvasLayer = null

func _get_hud_canvas() -> CanvasLayer:
	if is_instance_valid(hud_canvas):
		return hud_canvas
	hud_canvas = get_tree().current_scene.get_node_or_null("PlayerHUDCanvas")
	if not is_instance_valid(hud_canvas):
		hud_canvas = CanvasLayer.new()
		hud_canvas.name = "PlayerHUDCanvas"
		hud_canvas.layer = 10
		get_tree().current_scene.add_child(hud_canvas)
	return hud_canvas

@onready var animation_tree = get_node_or_null("AnimationTree")
@onready var state_machine = animation_tree.get("parameters/playback") if animation_tree else null
@onready var sword_hitbox = get_node_or_null("SwordHitBox/CollisionShape3D")
@onready var sword_hitbox_area = get_node_or_null("SwordHitBox") # Area3D — untuk rotasi
@onready var nav_agent = get_node_or_null("NavigationAgent3D")
@onready var animation_player = get_node_or_null("AnimationPlayer")
@onready var sprite = get_node_or_null("Visuals") # To offset jump

func get_equipment_bonuses() -> Dictionary:
	var bonuses = {
		"str": 0, "vit": 0, "int": 0, "luk": 0, "agi": 0, "dex": 0,
		"p_atk": 0, "m_atk": 0, "p_def": 0, "m_def": 0,
		"max_hp": 0, "max_mp": 0
	}
	
	if not get_node_or_null("/root/Global"): return bonuses
	var item_db = get_node_or_null("/root/ItemDB")
	if not item_db: return bonuses
	
	for slot in Global.equipment.keys():
		var item_id = Global.equipment[slot]
		if item_id != "":
			var data = item_db.get_item(item_id)
			bonuses["str"] += data.get("bonus_str", 0)
			bonuses["vit"] += data.get("bonus_vit", 0)
			bonuses["int"] += data.get("bonus_int", 0)
			bonuses["luk"] += data.get("bonus_luk", 0)
			bonuses["agi"] += data.get("bonus_agi", 0)
			bonuses["dex"] += data.get("bonus_dex", 0)
			bonuses["p_atk"] += data.get("bonus_p_atk", 0)
			bonuses["m_atk"] += data.get("bonus_m_atk", 0)
			bonuses["p_def"] += data.get("bonus_p_def", 0)
			bonuses["m_def"] += data.get("bonus_m_def", 0)
			bonuses["max_hp"] += data.get("bonus_max_hp", 0)
			bonuses["max_mp"] += data.get("bonus_max_mp", 0)
			
	return bonuses

func recalculate_stats():
	var bonuses = get_equipment_bonuses()
	var old_max_hp = max_health
	var old_max_mp = max_mana
	var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
	var base_stats = {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}
	if get_node_or_null("/root/Global") and Global.CLASS_BASE_STATS.has(cls):
		base_stats = Global.CLASS_BASE_STATS[cls]
		
	var t_str = base_stats["str"] + stat_str + bonuses["str"]
	var t_vit = base_stats["vit"] + stat_vit + bonuses["vit"]
	var t_int = base_stats["int"] + stat_int + bonuses["int"]
	var t_luk = base_stats["luk"] + stat_luk + bonuses["luk"]
	var t_agi = base_stats["agi"] + stat_agi + bonuses["agi"]
	var t_dex = base_stats["dex"] + stat_dex + bonuses["dex"]
	
	var wp_level = Global.unlocked_skills.get("weapon_mastery", 0) if get_node_or_null("/root/Global") else 0
	var wp_bonus = SkillDB.get_skill_val("weapon_mastery", "damages", wp_level) if wp_level > 0 and get_node_or_null("/root/SkillDB") else 0
	var vit_level = Global.unlocked_skills.get("vitality_mastery", 0) if get_node_or_null("/root/Global") else 0
	var vit_bonus = SkillDB.get_skill_val("vitality_mastery", "damages", vit_level) if vit_level > 0 and get_node_or_null("/root/SkillDB") else 0

	var el_mastery_lvl = Global.unlocked_skills.get("elemental_mastery", 0) if get_node_or_null("/root/Global") else 0
	var el_mp_bonus = SkillDB.get_skill_val("elemental_mastery", "mp_costs", el_mastery_lvl) if el_mastery_lvl > 0 and get_node_or_null("/root/SkillDB") else 0
	var el_dmg_bonus = SkillDB.get_skill_val("elemental_mastery", "damages", el_mastery_lvl) if el_mastery_lvl > 0 and get_node_or_null("/root/SkillDB") else 0
	elemental_mastery_bonus_pct = float(el_dmg_bonus) / 100.0

	max_health = 50 + (t_vit * 10) + bonuses["max_hp"]
	max_mana = 20 + (t_int * 5) + bonuses["max_mp"] + el_mp_bonus
	max_energy = 50.0 + (t_str * 10.0)
	
	physical_defense = t_vit + bonuses["p_def"] + vit_bonus
	magic_defense = int(t_vit / 2.0 + t_int / 2.0) + bonuses["m_def"] + vit_bonus
	
	if max_health > old_max_hp:
		current_health += (max_health - old_max_hp)
	if max_mana > old_max_mp:
		current_mana += (max_mana - old_max_mp)
		
	walk_speed = (10.0 * 1000.0 / 3600.0) + (t_agi * 0.04)
	run_speed = walk_speed * 2.0
	attack_speed_multiplier = 1.0 + (t_agi * 0.05)
	energy_regen = 5.0 + (t_agi * 0.5)
	
	physical_attack = 10 + (t_str * 2) + bonuses["p_atk"] + wp_bonus
	magic_attack = 10 + (t_int * 2) + bonuses["m_atk"]
	casting_speed = 1.0 + (t_dex * 0.05)
	critical_chance = t_luk * 1.0
	accuracy = 1.0 + (t_dex * 0.05)
	
	if get_node_or_null("/root/Global"):
		Global.perm_stat_str = stat_str
		Global.perm_stat_vit = stat_vit
		Global.perm_stat_int = stat_int
		Global.perm_stat_luk = stat_luk
		Global.perm_stat_agi = stat_agi
		Global.perm_stat_dex = stat_dex

	_recalculate_elemental_stats()

func _recalculate_elemental_stats():
	atk_elements.clear()
	def_element = "netral"
	def_resistances.clear()
	element_dmg_bonus.clear()
	
	if not get_node_or_null("/root/Global"): return
	var item_db = get_node_or_null("/root/ItemDB")
	if not item_db: return
	
	# Get main weapon for attack element
	var main_wp_id = Global.equipment.get("main_weapon", "")
	if main_wp_id != "":
		var data = item_db.get_item(main_wp_id)
		var w_elem = data.get("weapon_element", "netral")
		if w_elem != "netral" and w_elem != "":
			atk_elements.append(w_elem)
	
	if atk_elements.is_empty():
		atk_elements.append("netral")
		
	# Get artifact for defense element
	var artifact_id = Global.equipment.get("artifact", "")
	if artifact_id != "":
		var data = item_db.get_item(artifact_id)
		var d_elem = data.get("defense_element", "netral")
		if d_elem != "netral" and d_elem != "":
			def_element = d_elem
		
	# Get resistances and dmg bonuses from ALL equipment
	for slot in Global.equipment.keys():
		var item_id = Global.equipment.get(slot, "")
		if item_id != "":
			var data = item_db.get_item(item_id)
			
			var resists = data.get("resistances", {})
			for k in resists.keys():
				if not def_resistances.has(k):
					if def_resistances.size() < 3: # Max 3 types
						def_resistances[k] = 0.0
				if def_resistances.has(k):
					def_resistances[k] += resists[k]
					if def_resistances[k] > 100.0: def_resistances[k] = 100.0
					
			var dmg_bonus = data.get("dmg_bonus", {})
			for k in dmg_bonus.keys():
				if not element_dmg_bonus.has(k): element_dmg_bonus[k] = 0.0
				element_dmg_bonus[k] += dmg_bonus[k]
	
	emit_signal("health_changed", current_health, max_health)

func _ready():
	add_to_group("Player")
	status_manager = StatusEffectManager.new()
	add_child(status_manager)
	status_manager.setup(self)
	


	# Strip X/Z translation from the dash animation to prevent the visual mesh from moving away from the root collision shape
	var ap = get_node_or_null("Visuals/HeroModel/AnimationPlayer")
	if ap:
		var dash_anim_name = ""
		for anim_name in ap.get_animation_list():
			if "dash" in anim_name.to_lower():
				dash_anim_name = anim_name
				break
				
		if dash_anim_name != "":
			var anim = ap.get_animation(dash_anim_name)
			dash_anim_length = anim.length
			var track_idx = anim.find_track("Skeleton3D:mixamorig_Hips", Animation.TYPE_POSITION_3D)
			if track_idx != -1:
				for i in range(anim.track_get_key_count(track_idx)):
					var val = anim.track_get_key_value(track_idx, i)
					anim.track_set_key_value(track_idx, i, Vector3(0, val.y, 0))
	
	if get_node_or_null("/root/Global"):
		coins = Global.coins
		level = Global.level
		current_exp = Global.current_exp
		max_exp = Global.max_exp
		stat_str = Global.perm_stat_str
		stat_vit = Global.perm_stat_vit
		stat_int = Global.perm_stat_int
		stat_luk = Global.perm_stat_luk
		stat_agi = Global.perm_stat_agi
		stat_dex = Global.perm_stat_dex
		
	recalculate_stats()
	if get_node_or_null("/root/Global") and Global.current_health > 0:
		current_health = min(Global.current_health, max_health)
		current_mana = min(Global.current_mana, max_mana)
		current_energy = min(Global.current_energy, max_energy)
	else:
		current_health = max_health
		current_mana = max_mana
		current_energy = max_energy
	if sprite:
		base_y_offset = sprite.position.y
		
	if sword_hitbox:
		sword_hitbox.set_deferred("disabled", true)
	if animation_tree:
		animation_tree.active = true
		
	call_deferred("emit_signal", "health_changed", current_health, max_health)
	call_deferred("emit_signal", "mana_changed", current_mana, max_mana)
	call_deferred("emit_signal", "energy_changed", current_energy, max_energy)
	call_deferred("emit_signal", "coin_changed", coins)
	call_deferred("emit_signal", "exp_changed", current_exp, max_exp, level)
func _exit_tree():
	if get_node_or_null("/root/Global"):
		Global.current_health = current_health
		Global.current_mana = current_mana
		Global.current_energy = current_energy

func _unhandled_input(event):
	if is_farming_targeting:
		if event.is_action_pressed("basic_attack"):
			_confirm_farming()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact") or event.is_action_pressed("charge_attack"): # Cancel
			_cancel_farming_targeting()
			get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("basic_attack") and not is_targeting and not is_farming_targeting:
		if not is_attacking and not is_jumping and not is_casting and magic_charge_timer == 0.0 and not is_animating_skill and not is_spinning and not is_dashing:
			if status_manager and not status_manager.can_move():
				var effect_name = status_manager.get_movement_restriction_name()
				spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
			else:
				var item_db = get_node_or_null("/root/ItemDB")
				var w_type = "None"
				if item_db and Global.equipment.get("main_weapon", "") != "":
					var w_data = item_db.get_item(Global.equipment["main_weapon"])
					w_type = w_data.get("weapon_type", "None")
				
				match w_type:
					"staff", "rod":
						_fire_projectile("magic", false)
					"long_bow", "crossbow":
						_fire_projectile("arrow", false)
					"dagger":
						# Dual hit logic will be inside attack
						attack(false)
					_:
						attack(false)
			get_viewport().set_input_as_handled()
			return

	if is_targeting:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				target_pos = get_mouse_3d_pos()
				if current_targeting_skill != "":
					var skill_db = get_node_or_null("/root/SkillDB")
					if skill_db:
						var data = skill_db.get_skill(current_targeting_skill)
						var cur_lvl_r = Global.unlocked_skills.get(current_targeting_skill, 0) if get_node_or_null("/root/Global") else 0
						var max_range = skill_db.get_skill_val(current_targeting_skill, "ranges", cur_lvl_r)
						if max_range <= 0: 
							if current_targeting_skill == "fatal_smash": max_range = 10.0
							elif current_targeting_skill == "fire_bolt": max_range = 8.0
							elif current_targeting_skill == "sonic_boom": max_range = 5.0
							elif current_targeting_skill == "seismic_fissure": max_range = 10.0
							elif current_targeting_skill == "hex": max_range = 5.0
							else: max_range = 2.5
						if global_position.distance_to(target_pos) > max_range:
							target_pos = global_position + (target_pos - global_position).normalized() * max_range
				
				_end_targeting(true)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_end_targeting(false)
				get_viewport().set_input_as_handled()

func _end_targeting(confirm: bool):
	Engine.time_scale = 1.0
	
	var indicator = target_indicator_node
	target_indicator_node = null
	
	if confirm and current_targeting_skill != "":
		var is_valid_target = true
		if is_instance_valid(indicator) and indicator.get("indicator_type") == "single":
			if not is_instance_valid(indicator.get("single_target_node")):
				is_valid_target = false
				spawn_floating_text("Tidak ada target!", Color(1, 0.5, 0))
				indicator.queue_free()
				
		if is_valid_target:
			if is_instance_valid(indicator):
				indicator.start_casting(target_pos)
				
			var skill_db = get_node_or_null("/root/SkillDB")
			if skill_db:
				var data = skill_db.get_skill(current_targeting_skill)
				var cur_lvl = Global.unlocked_skills.get(current_targeting_skill, 0) if get_node_or_null("/root/Global") else 0
				var cost = skill_db.get_skill_val(current_targeting_skill, "mp_costs", cur_lvl)
				_start_cast_skill(current_targeting_skill, data, cost, target_pos, indicator)
	else:
		if is_instance_valid(indicator):
			indicator.queue_free()

	targeting_cancel_cooldown = 0.2
	charge_input_consumed = true
	is_targeting = false

func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			print("DEBUG: Level Up +1")
			level_up()
		elif event.physical_keycode == KEY_F2:
			print("DEBUG: Koin +1000")
			add_coin(1000)
		elif event.physical_keycode == KEY_F3:
			print("DEBUG: Class Level +1")
			if get_node_or_null("/root/Global"):
				var cls = Global.current_class
				Global.class_levels[cls] = Global.class_levels.get(cls, 1) + 1
				Global.class_skill_points[cls] = Global.class_skill_points.get(cls, 0) + 1
				spawn_floating_text("Class Lv UP!", Color(1, 0.8, 0.2))

	if event.is_action_pressed("open_inventory"):
		_open_inventory()
	elif event.is_action_pressed("open_menu"):
		toggle_menu()
	elif event.is_action_pressed("open_skill_menu"):
		_open_skill_menu()
	elif event.is_action_pressed("open_crafting"):
		_open_crafting_menu()
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
		_use_skill(0)
	elif event.is_action_pressed("skill_2"):
		_use_skill(1)
	elif event.is_action_pressed("skill_3"):
		_use_skill(2)
	elif event.is_action_pressed("skill_4"):
		_use_skill(3)
	elif event.is_action_pressed("skill_5"):
		_use_skill(4)
	elif event.is_action_pressed("skill_6"):
		_use_skill(5)
	elif event.is_action_pressed("skill_7"):
		_use_skill(6)
	elif event.is_action_pressed("skill_8"):
		_use_skill(7)
	elif event.is_action_pressed("interact"):
		if is_doing_life_skill:
			_cancel_life_skill()
		else:
			_try_interact()
		get_viewport().set_input_as_handled()


func _use_quick_item(slot_index: int):
	if is_dead or not get_node_or_null("/root/Global"): return
	if status_manager and not status_manager.can_move():
		var effect_name = status_manager.get_movement_restriction_name()
		spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
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
			if current_health >= max_health:
				spawn_floating_text("HP Penuh!", Color(1, 0.2, 0.2))
				return
			spawn_floating_text("HP +" + str(heal_amt), Color(0.2, 1.0, 0.2))
			restore_hp(heal_amt)
		elif effect_type == "heal_mp":
			if current_mana >= max_mana:
				spawn_floating_text("MP Penuh!", Color(0.2, 0.5, 1.0))
				return
			spawn_floating_text("MP +" + str(heal_amt), Color(0.2, 0.5, 1.0))
			restore_mp(heal_amt)
		elif effect_type == "heal_ep":
			if current_energy >= max_energy:
				spawn_floating_text("EP Penuh!", Color(1, 1, 0.2))
				return
			current_energy += heal_amt
			if current_energy > max_energy: current_energy = max_energy
			emit_signal("energy_changed", current_energy, max_energy)
			spawn_floating_text("EP +" + str(heal_amt), Color(1, 1, 0))
		elif effect_type == "unlock_recipe":
			var recipe_id = ""
			if get_node_or_null("/root/ItemDB"):
				var data = ItemDB.get_item(item_id)
				recipe_id = data.get("recipe_id", "")
			if recipe_id != "" and not Global.unlocked_recipes.has(recipe_id):
				Global.unlocked_recipes.append(recipe_id)
				spawn_floating_text("Resep dipelajari!", Color(1, 1, 0))
			else:
				spawn_floating_text("Sudah dipelajari!", Color(0.7, 0.7, 0.7))
				return # Prevent item consumption
				
		Global.inventory[item_id] -= 1
		
		var hud = get_node_or_null("/root/PlayerHUD")
		if hud and hud.has_method("_update_quick_items"):
			hud._update_quick_items()

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
			menu.setup(self)
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
			menu.setup(self)
			get_tree().paused = true

func _use_skill(slot_index: int):
	# Hapus is_attacking dari blokir agar skill jadi prioritas
	if is_dead or is_casting or is_dashing or is_targeting or is_spinning or is_animating_skill or not get_node_or_null("/root/Global"): return
	if status_manager and not status_manager.can_move():
		var effect_name = status_manager.get_movement_restriction_name()
		spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
		return
	if status_manager and status_manager.has_effect("silence"):
		spawn_floating_text("Terkena Silence!", Color(0.8, 0.2, 1.0))
		return
	var skill_id = Global.quick_skills[slot_index]
	if skill_id == "": return
	
	if active_skill_cooldowns.get(skill_id, 0.0) > 0:
		spawn_floating_text("Skill Cooldown!", Color(0.5, 0.5, 1))
		return
		
	if skill_id == "heal" and current_health >= max_health:
		spawn_floating_text("HP Penuh!", Color(0.2, 1.0, 0.2))
		return
		
	if skill_id == "soul_drain":
		var enemies = get_tree().get_nodes_in_group("Enemy")
		var cursed_exists = false
		for e in enemies:
			if e.get("status_manager") and e.status_manager.has_effect("curse"):
				cursed_exists = true
				break
		if not cursed_exists:
			spawn_floating_text("Tidak ada target curse!", Color(0.8, 0.0, 1.0))
			return
	
	var skill_db = get_node_or_null("/root/SkillDB")
	if not skill_db: return
	
	var data = skill_db.get_skill(skill_id)
	if data.is_empty(): return
	
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	var mp_cost = skill_db.get_skill_val(skill_id, "mp_costs", cur_lvl)
	var ep_cost = skill_db.get_skill_val(skill_id, "ep_costs", cur_lvl)
	
	if current_mana < mp_cost:
		spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
		return
	if current_energy < ep_cost:
		spawn_floating_text("EP Tidak Cukup!", Color(1.0, 0.5, 0.2))
		return
		
	# Skill valid, cancel attack jika sedang attack (agar skill memprioritaskan attack)
	if is_attacking:
		is_attacking = false
		if sword_hitbox:
			sword_hitbox.set_deferred("disabled", true)
		
	var cost = mp_cost # Passed down just in case
	var type = data.get("type", "instant")
	if type in ["target_aoe", "target_single", "target_cone"]:
		is_targeting = true
		current_targeting_skill = skill_id
		Engine.time_scale = 0.2
		
		var indicator_scene = load("res://Scenes/Skills/target_indicator.tscn")
		if indicator_scene:
			target_indicator_node = indicator_scene.instantiate()
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
			
			target_indicator_node.max_range = float(custom_range)
			target_indicator_node.aoe_radius = float(custom_aoe)
			target_indicator_node.player_node = self
			if type == "target_single":
				target_indicator_node.indicator_type = "single"
			elif type == "target_cone":
				target_indicator_node.indicator_type = "cone"
			else:
				target_indicator_node.indicator_type = "circle"
			add_child(target_indicator_node)
	else:
		_start_cast_skill(skill_id, data, cost, Vector3.ZERO)

func _start_cast_skill(skill_id: String, data: Dictionary, cost: int, t_pos: Vector3, indicator: Node = null):
	is_casting = true
	casting_skill_id = skill_id
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
			active_skill_cooldowns[skill_id] = final_cd
	
	var base_cast_time = 0.0
	skill_db = get_node_or_null("/root/SkillDB")
	if skill_db:
		var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
		base_cast_time = skill_db.get_skill_val(skill_id, "cast_times", cur_lvl)
		if typeof(base_cast_time) != TYPE_FLOAT and typeof(base_cast_time) != TYPE_INT:
			base_cast_time = 0.0
	
	base_cast_time = float(base_cast_time) * (1.0 - cdr_pct)
	var final_cast_time = base_cast_time / casting_speed
	
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
	cast_bar = ProgressBar.new()
	cast_bar.min_value = 0
	cast_bar.max_value = final_cast_time
	cast_bar.value = 0
	cast_bar.show_percentage = false
	cast_bar.custom_minimum_size = Vector2(30, 4)
	cast_bar.position = Vector2(-15, 12)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(1.0, 0.8, 0.2, 1.0)
	cast_bar.add_theme_stylebox_override("background", sb_bg)
	cast_bar.add_theme_stylebox_override("fill", sb_fg)
	_get_hud_canvas().add_child(cast_bar)
	
	# Visual indikator casting
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
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
			add_child(aqua_ind)
	
	var timer = 0.0
	while timer < final_cast_time:
		var dt = get_process_delta_time()
		timer += dt
		if is_instance_valid(cast_bar):
			cast_bar.value = timer
			
		if not is_casting or is_dead:
			cast_cancelled = true
			break
			
		if data.get("type", "instant") == "target_aoe" and global_position.distance_to(t_pos) > max_range:
			cast_cancelled = true
			is_casting = false
			spawn_floating_text("Terlalu Jauh!", Color(1, 0.5, 0))
			break
			
		if data.get("type", "instant") == "target_single" and is_instance_valid(indicator):
			var single_tgt = indicator.get("single_target_node")
			if not is_instance_valid(single_tgt) or single_tgt.get("is_dead"):
				cast_cancelled = true
				is_casting = false
				spawn_floating_text("Target Hilang!", Color(1, 0.5, 0))
				break
			
		await get_tree().process_frame
	
	if is_instance_valid(cast_bar):
		cast_bar.queue_free()
		
	if is_instance_valid(indicator):
		indicator.queue_free()
		
	if is_instance_valid(aqua_ind):
		aqua_ind.queue_free()
	
	if Input.is_action_just_pressed("interact") and Global.current_class == "scout":
		if status_manager and status_manager.has_effect("shadow_walk"):
			pass # shadow walk handles it
		else:
			# evasive leap
			velocity = -last_direction * 8.0
			is_invincible = true
			apply_camera_shake(2.0, 0.1)
			get_tree().create_timer(0.3).timeout.connect(func(): is_invincible = false)

	if not is_instance_valid(tween): return
	tween.kill()
	modulate = Color(1, 1, 1)
	
	if cast_cancelled:
		if active_skill_cooldowns.has(skill_id):
			active_skill_cooldowns.erase(skill_id)
		return
	is_casting = false
	
	current_mana -= cost
	emit_signal("mana_changed", current_mana, max_mana)
	
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	skill_db = get_node_or_null("/root/SkillDB")
	if skill_db:
		var ep_cost = skill_db.get_skill_val(skill_id, "ep_costs", cur_lvl)
		current_energy -= ep_cost
		if current_energy < 0: current_energy = 0
		emit_signal("energy_changed", current_energy, max_energy)

	
	_execute_skill(skill_id, data, t_pos, indicator)

var is_spinning = false
var spin_timer = 0.0
var max_spin_time = 0.0
var spin_bar: ProgressBar = null

func _execute_skill(skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node = null):
	var skill_db = get_node_or_null("/root/SkillDB")
	if not skill_db: return
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	var dmg = skill_db.get_skill_val(skill_id, "damages", cur_lvl)
	var dur = skill_db.get_skill_val(skill_id, "effect_durations", cur_lvl)
	var aoe = skill_db.get_skill_val(skill_id, "aoe_radiuses", cur_lvl)
	var crit = skill_db.get_skill_val(skill_id, "crit_chances", cur_lvl)
	
	var el_multiplier = 1.0 + elemental_mastery_bonus_pct
	
	var manual_anim_skills = ["aqua_blast", "cyclone_sweep", "fatal_blow", "impact_wave", "fatal_smash", "implosion"]
	if not skill_id in manual_anim_skills:
		is_animating_skill = true
		var anim_time = 0.3
		if skill_id == "seismic_fissure":
			anim_time = 0.6
		get_tree().create_timer(anim_time).timeout.connect(func(): is_animating_skill = false)
	
	var c_name = Global.current_class
	if c_name == "apprentice":
		ApprenticeSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "fighter":
		FighterSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "scout":
		ScoutSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)

func _process(delta):
	if not is_dead:
		survival_time += delta
		
		var has_endure = status_manager and status_manager.has_effect("endure")
		var has_holy_veil = status_manager and status_manager.has_effect("holy_veil")
		
		if has_holy_veil:
			modulate = Color(1.5, 1.5, 0.8)
		elif has_endure:
			modulate = Color(1.0, 0.8, 0.2)
		else:
			if modulate == Color(1.0, 0.8, 0.2) or modulate == Color(1.5, 1.5, 0.8):
				modulate = Color(1, 1, 1)
		
		if is_spinning:
			spin_timer -= delta
			if is_instance_valid(spin_bar):
				spin_bar.value = spin_timer
			var t = Engine.get_frames_drawn()
			sprite.rotation.y += 15.0 * delta # visual spin
			if t % 15 == 0:
				var enemies = get_tree().get_nodes_in_group("Enemy")
				var sweep_radius = 3.0 # Radius putaran pedang
				for e in enemies:
					if e.global_position.distance_to(global_position) <= sweep_radius:
						if e.has_method("take_damage"):
							e.take_damage(physical_attack * 0.5, global_position)
			if spin_timer <= 0:
				is_spinning = false
				sprite.rotation.y = 0
				if is_instance_valid(spin_bar):
					spin_bar.queue_free()

		
		var sm_lvl = Global.unlocked_skills.get("spell_mastery", 0) if get_node_or_null("/root/Global") else 0
		if sm_lvl > 0 and current_mana < max_mana:
			mana_regen_accumulator += float(sm_lvl) * delta
			if mana_regen_accumulator >= 1.0:
				var heal_mp = int(mana_regen_accumulator)
				mana_regen_accumulator -= float(heal_mp)
				current_mana += heal_mp
				if current_mana > max_mana: current_mana = max_mana
				emit_signal("mana_changed", current_mana, max_mana)
				
		var is_running_now = false
		
		if is_running_from_double_tap and not is_attacking and not is_dashing and not is_jumping:
			var input_dir = Vector3(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			)
			if input_dir != Vector3.ZERO:
				is_running_now = true
				
		if is_running_now and current_energy > 0:
			current_energy -= 10.0 * delta # Mengurangi 10 EP per detik
			if current_energy < 0: current_energy = 0
			emit_signal("energy_changed", current_energy, max_energy)
		elif not is_running_from_double_tap and current_energy < max_energy:
			current_energy += energy_regen * delta
			if current_energy > max_energy: current_energy = max_energy
			emit_signal("energy_changed", current_energy, max_energy)

		var cam = get_viewport().get_camera_3d()
		if cam:
			var screen_pos = cam.unproject_position(global_position + Vector3(0, 2.0, 0))
			if is_instance_valid(cast_bar): cast_bar.position = screen_pos + Vector2(-15, -40)
			if is_instance_valid(spin_bar): spin_bar.position = screen_pos + Vector2(-15, -40)
			if is_instance_valid(magic_charge_bar): magic_charge_bar.position = screen_pos + Vector2(-20, -50)
			if is_instance_valid(life_skill_bar): life_skill_bar.position = screen_pos + Vector2(-20, -60)
			if is_instance_valid(interaction_prompt): interaction_prompt.position = screen_pos + Vector2(-100, -80)

func _physics_process(delta):
	_update_interaction_prompt()
	
	if not Input.is_action_pressed("charge_attack"):
		charge_input_consumed = false

	if is_farming_targeting and is_instance_valid(farming_indicator):
		farming_indicator.global_position = get_mouse_3d_pos()
		if farming_zone_ref and farming_zone_ref.has_method("is_valid_plot_pos"):
			if farming_zone_ref.is_valid_plot_pos(farming_indicator.global_position):
				farming_indicator.modulate = Color(1, 1, 1, 0.5)
			else:
				farming_indicator.modulate = Color(1, 0.2, 0.2, 0.8)

	if is_dead: return
	if is_doing_life_skill:
		velocity = Vector3.ZERO
		return
	
	if animation_tree:
		if status_manager and (status_manager.has_effect("freeze") or status_manager.has_effect("sleep")):
			animation_tree.active = false
		else:
			animation_tree.active = true
	
	if status_manager and not status_manager.can_move():
		pass # Can't move if frozen
		
	if current_dash_cooldown > 0: current_dash_cooldown -= delta
	if charge_attack_cooldown > 0: charge_attack_cooldown -= delta
	if targeting_cancel_cooldown > 0: targeting_cancel_cooldown -= delta
	if jump_cooldown > 0: jump_cooldown -= delta
	for key in active_skill_cooldowns.keys():
		if active_skill_cooldowns[key] > 0:
			active_skill_cooldowns[key] -= delta
	
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
		
	var is_hold_weapon = w_type in ["staff", "long_bow"]
	
	if is_hold_weapon and not is_dead and not is_targeting and not is_dashing and not is_jumping and targeting_cancel_cooldown <= 0.0 and (not is_casting or magic_charge_timer > 0.0) and not charge_input_consumed and not is_animating_skill and not is_spinning:
		if Input.is_action_pressed("charge_attack"):
			if status_manager and not status_manager.can_move():
				if Input.is_action_just_pressed("charge_attack"):
					var effect_name = status_manager.get_movement_restriction_name()
					spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
			elif magic_charge_timer == 0.0 and not is_attacking and not is_casting:
				if charge_attack_cooldown <= 0:
					if current_mana < 30:
						if Input.is_action_just_pressed("charge_attack"):
							spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
					else:
						is_casting = true
						_create_charge_bar()
					
			if magic_charge_timer > 0.0:
				_update_aim_to_mouse(true)
				magic_charge_timer += delta
				if magic_charge_timer > 2.0: magic_charge_timer = 2.0
				if is_instance_valid(magic_charge_bar):
					magic_charge_bar.value = magic_charge_timer
		else:
			if magic_charge_timer > 0.0:
				_release_magic_charge()
	elif magic_charge_timer > 0.0:
		magic_charge_timer = 0.0
		is_casting = false
		if is_instance_valid(magic_charge_bar):
			magic_charge_bar.queue_free()
	

	# Handle Run (Hold Shift + Direction)
	var move_keys = ["move_up", "move_down", "move_left", "move_right"]
	var is_any_move_pressed = false
	for key in move_keys:
		if Input.is_action_pressed(key):
			is_any_move_pressed = true
			
	if is_any_move_pressed and Input.is_action_pressed("run") and not is_spinning and magic_charge_timer == 0.0:
		is_running_from_double_tap = true
	else:
		is_running_from_double_tap = false
				
	# --- DIRECTIONAL DASH ---
	# Trigger: Spasi ditekan (jump)
	var should_trigger_dash = Input.is_action_just_pressed("jump")

	if should_trigger_dash:
		# is_casting diizinkan jika itu state aim/charge ranged (magic_charge_timer > 0)
		# bukan casting skill biasa (magic_charge_timer == 0)
		var casting_blocks_dash = is_casting and magic_charge_timer == 0.0
		# is_attacking boleh diinterupsi oleh dash (kombinasi klik + arah + Shift)
		if not is_dashing and not casting_blocks_dash and not is_animating_skill and not is_spinning:
			if current_dash_cooldown <= 0:
				if status_manager and not status_manager.can_move():
					var effect_name = status_manager.get_movement_restriction_name()
					spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
				elif current_energy >= 20.0:
					# Cancel animasi attack jika sedang attack saat dash
					if is_attacking:
						is_attacking = false
						if sword_hitbox:
							sword_hitbox.set_deferred("disabled", true)
					# Cancel aim/charge jika sedang aim saat dash
					if magic_charge_timer > 0.0:
						magic_charge_timer = 0.0
						is_casting = false
						if is_instance_valid(magic_charge_bar):
							magic_charge_bar.queue_free()
					current_energy -= 20.0
					emit_signal("energy_changed", current_energy, max_energy)
					is_dashing = true
					if state_machine: state_machine.travel("Dash")
					dash_timer = dash_duration / global_movement_scale
					current_dash_cooldown = dash_cooldown
					# Hitung arah dash dari input saat ini
					var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
					var input_z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
					var dir = Vector3(input_x, 0, input_z).normalized()
					# Jika tidak ada tombol arah -> dash ke arah hadap karakter
					if dir == Vector3.ZERO:
						dir = last_direction
					if dir == Vector3.ZERO:
						dir = Vector3(0, 0, 1) # Fallback
					# Karakter menghadap ke arah dash
					last_direction = dir
					velocity = dir * dash_speed
					var enemies = get_tree().get_nodes_in_group("Enemy")
					for e in enemies:
						if is_instance_valid(e) and e is CollisionObject3D:
							add_collision_exception_with(e)
				else:
					spawn_floating_text("EP Tidak Cukup!", Color(1, 0.5, 0))
			else:
				spawn_floating_text("Masih Cooldown!", Color(0.4, 0.6, 1))
		
	if is_dashing:
		var speed_multiplier = (dash_timer / dash_duration) * 2.0
		velocity = last_direction * (dash_speed * speed_multiplier * global_movement_scale)
		dash_timer -= delta
		move_and_slide()
		modulate.a = 0.5
		if animation_tree:
			# Sesuaikan animasi pas dengan durasi dash
			var req_speed = (dash_anim_length / dash_duration) * global_movement_scale
			var extra_advance = delta * (req_speed - 1.0)
			if extra_advance != 0.0:
				animation_tree.advance(extra_advance)
		if dash_timer <= 0:
			is_dashing = false
			modulate.a = 1.0
			var enemies = get_tree().get_nodes_in_group("Enemy")
			for e in enemies:
				if is_instance_valid(e) and e is CollisionObject3D:
					remove_collision_exception_with(e)
		return
	
	# --- FATAL SMASH: gerak karakter ke titik target via smoothstep ---
	if is_smashing:
		smash_elapsed += delta
		var t = clamp(smash_elapsed / smash_total_dur, 0.0, 1.0)
		# Smoothstep: easing in-out natural
		var s = t * t * (3.0 - 2.0 * t)
		global_position = smash_start_pos.lerp(smash_target_pos, s)
		velocity = Vector3.ZERO
		move_and_slide()
		if t >= 1.0:
			is_smashing = false
		return
		
	if is_jumping:
		jump_timer -= delta
		if sprite:
			var progress = 1.0 - (jump_timer / jump_duration)
			sprite.position.y = base_y_offset - sin(progress * PI) * jump_height
			
		move_and_slide() # Still sliding based on velocity
		
		if jump_timer <= 0:
			is_jumping = false
			if sprite: sprite.position.y = base_y_offset
		return

	if knockback_velocity != Vector3.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 800 * delta)
		move_and_slide()
		return
		
	var raw_input = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0, Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	if is_auto_walking:
		if raw_input != Vector3.ZERO:
			_cancel_auto_walk()
		else:
			var dist = global_position.distance_to(auto_walk_target)
			if dist <= 25.0:
				_complete_auto_walk()
			else:
				if nav_agent and not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					if global_position.distance_to(next_pos) < 2.0:
						raw_input = (auto_walk_target - global_position).normalized()
					else:
						raw_input = (next_pos - global_position).normalized()
				else:
					raw_input = (auto_walk_target - global_position).normalized()
					
	var input_direction = raw_input.normalized() if not is_auto_walking else raw_input
	
	if status_manager:
		if not status_manager.can_move() or is_animating_skill:
			input_direction = Vector3.ZERO
		elif input_direction != Vector3.ZERO or status_manager.has_effect("fear") or status_manager.has_effect("confuse"):
			input_direction = status_manager.get_override_movement(input_direction)

	if is_attacking:
		if animation_tree:
			var total_speed = current_attack_speed * current_anim_speed_ratio
			if total_speed != 1.0:
				animation_tree.advance(delta * (total_speed - 1.0))
		
		if is_charge_attacking and charge_lunge_timer > 0:
			charge_lunge_timer -= delta
			velocity = last_direction * dash_speed
		else:
			# Saat menyerang, karakter tidak bisa berlari/berjalan (diam di tempat)
			velocity.x = 0
			velocity.z = 0
			
		move_and_slide()
		return
	
	var current_speed = walk_speed
	var anim_stride = 1.6
	
	if is_casting:
		_update_aim_to_mouse(false)
		current_speed = walk_speed * 0.5
	elif is_running_from_double_tap and current_energy > 0:
		current_speed = run_speed
		anim_stride = 4.8
		
	if status_manager:
		current_speed *= status_manager.get_speed_multiplier()
		
	current_speed *= global_movement_scale
	var anim_speed = current_speed / anim_stride
			
	if animation_player:
		if not is_attacking and not is_casting and not is_dashing and not is_jumping and not is_spinning:
			animation_player.speed_scale = anim_speed
		else:
			animation_player.speed_scale = 1.0
		
	if input_direction != Vector3.ZERO:
		var physical_speed = current_speed
		velocity = input_direction * physical_speed
		
		# Selalu simpan arah terakhir agar dash/attack yang dilakukan saat diam mengarah ke arah yang benar
		last_direction = input_direction
		
		if sprite and not is_attacking and not is_casting and not is_spinning:
			var target_angle = atan2(-input_direction.z, input_direction.x)
			sprite.rotation.y = lerp_angle(sprite.rotation.y, target_angle - PI/2.0, 15.0 * delta)
			if is_instance_valid(sword_hitbox_area):
				sword_hitbox_area.rotation.y = sprite.rotation.y
		
		if state_machine and not is_attacking:
			if is_running_from_double_tap and current_energy > 0:
				state_machine.travel("Run")
			else:
				state_machine.travel("Walk")
	else:
		velocity = Vector3.ZERO
		if state_machine and not is_attacking:
			state_machine.travel("Idle")
		
	move_and_slide()
		

	if Input.is_action_just_pressed("charge_attack") and not charge_input_consumed and not is_attacking and not is_jumping and not is_casting and not is_targeting and not is_farming_targeting and targeting_cancel_cooldown <= 0.0 and magic_charge_timer == 0.0 and not is_animating_skill and not is_spinning and not is_dashing:
		if status_manager and not status_manager.can_move():
			var effect_name = status_manager.get_movement_restriction_name()
			spawn_floating_text("Terkena " + effect_name + "!", Color(1, 0.2, 0.2))
		elif charge_attack_cooldown <= 0:
			var is_tap_weapon = w_type in ["long_sword", "sword", "gloves", "lance", "rod", "crossbow", "dagger"]
			if is_tap_weapon or w_type == "None":
				var cost = 30
				var can_cast = false
				
				if w_type == "rod":
					if current_mana >= cost:
						current_mana -= cost
						emit_signal("mana_changed", current_mana, max_mana)
						can_cast = true
					else:
						spawn_floating_text("MP Tidak Cukup!", Color(0.2, 0.5, 1))
				else:
					if current_energy >= cost:
						current_energy -= cost
						emit_signal("energy_changed", current_energy, max_energy)
						can_cast = true
					else:
						spawn_floating_text("EP Tidak Cukup!", Color(1, 0.5, 0))
						
				if can_cast:
					charge_attack_cooldown = 2.0
					if w_type == "crossbow" or w_type == "rod":
						charge_attack_cooldown = 1.0
					
					match w_type:
						"rod":
							_fire_projectile("mana_burst", true)
						"crossbow":
							_fire_projectile("bolt", true)
						"dagger":
							_fire_projectile("dagger", true)
						_:
							attack(true)
		else:
			spawn_floating_text("Masih Cooldown!", Color(0.4, 0.6, 1))

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
			menu.setup(self)
			get_tree().paused = true

func _update_aim_to_mouse(instant: bool = false):
	var aim_dir = (get_mouse_3d_pos() - global_position)
	aim_dir.y = 0
	aim_dir = aim_dir.normalized()
	if aim_dir != Vector3.ZERO:
		last_direction = aim_dir
		
		if sprite:
			var target_angle = atan2(-aim_dir.z, aim_dir.x)
			if instant:
				sprite.rotation.y = target_angle - PI/2.0
			else:
				sprite.rotation.y = lerp_angle(sprite.rotation.y, target_angle - PI/2.0, 15.0 * get_physics_process_delta_time())
			if is_instance_valid(sword_hitbox_area):
				sword_hitbox_area.rotation.y = sprite.rotation.y

func attack(is_charge: bool):
	if status_manager and not status_manager.can_attack(): return
	_update_aim_to_mouse(true)
	is_attacking = true
	is_charge_attacking = is_charge
	
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
	
	var is_crit = randf() * 100.0 < critical_chance
	current_attack_damage = physical_attack
	
	current_attack_speed = attack_speed_multiplier
	
	var should_lunge = true
	
	if is_charge:
		current_attack_damage = physical_attack * 2
		if w_type == "long_sword":
			_perform_spin_attack(current_attack_damage)
			current_attack_speed *= 1.5
			should_lunge = false
		elif w_type == "dagger":
			should_lunge = false
		elif w_type == "gloves":
			current_attack_damage = int(physical_attack * 1.5)
			apply_camera_shake(12.0, 0.2) # Uppercut shake
		elif w_type == "lance":
			apply_camera_shake(5.0, 0.15) # Jousting shake
			
		current_attack_speed *= 1.5
	else:
		match w_type:
			"long_sword": current_attack_speed *= 0.7 
			"gloves": current_attack_speed *= 2.0 
			"dagger": current_attack_speed *= 1.5 
			
	if is_crit:
		current_attack_damage = int(current_attack_damage * 2.0)
		print("CRITICAL HIT!")
		
	# Bersihkan hit list SEKARANG agar siap, tapi hitbox baru aktif setelah delay
	if sword_hitbox:
		sword_hitbox.set_deferred("disabled", true) # Pastikan mati dulu
		var area = sword_hitbox.get_parent()
		if area and area.has_method("clear_hit_list"):
			area.clear_hit_list()
			
	if status_manager: current_attack_speed *= status_manager.get_attack_speed_multiplier()
	
	var target_state = "HeavyAttack" if is_charge else "Attack"
	if animation_tree and animation_tree.tree_root is AnimationNodeStateMachine:
		if not animation_tree.tree_root.has_node(target_state):
			target_state = "Attack"
			
	var actual_len = _get_state_length(target_state, base_attack_duration)
	current_anim_speed_ratio = actual_len / base_attack_duration
	
	if animation_tree:
		animation_tree.set("parameters/AttackTimeScale/scale", current_attack_speed * current_anim_speed_ratio)
	
	if state_machine:
		state_machine.travel(target_state)
		
	var current_attack_duration = base_attack_duration / current_attack_speed

	# Bersihkan hit list agar musuh bisa kena hit lagi di serangan berikutnya
	if sword_hitbox:
		var area = sword_hitbox.get_parent()
		if area and area.has_method("clear_hit_list"):
			area.clear_hit_list()
	# Timing aktif/nonaktif hitbox diatur lewat keyframe animasi (property: disabled)
	# Tambahkan track "CollisionShape3D > disabled" di custom/attack AnimationPlayer

	if is_charge and should_lunge:
		charge_lunge_timer = current_attack_duration * 0.2

	if is_dual_wield:
		# Double hit: bersihkan hit list di tengah animasi agar hit kedua bisa detect
		await get_tree().create_timer(current_attack_duration / 2.0).timeout
		if sword_hitbox:
			var area = sword_hitbox.get_parent()
			if area and area.has_method("clear_hit_list"):
				area.clear_hit_list()
		await get_tree().create_timer(current_attack_duration / 2.0).timeout
	else:
		await get_tree().create_timer(current_attack_duration).timeout

	if is_attacking:
		attack_finished()

func attack_finished():
	is_attacking = false
	current_attack_speed = 1.0
	if sword_hitbox: sword_hitbox.set_deferred("disabled", true)
	if state_machine: state_machine.travel("Idle")

func _get_state_length(state_name: String, fallback: float) -> float:
	if not animation_tree: return fallback
	if not animation_tree.tree_root is AnimationNodeStateMachine: return fallback
	var sm = animation_tree.tree_root as AnimationNodeStateMachine
	if not sm.has_node(state_name): return fallback
	var node = sm.get_node(state_name)
	if node is AnimationNodeAnimation:
		var anim_name = node.animation
		var ap_path = animation_tree.anim_player
		var ap = animation_tree.get_node_or_null(ap_path)
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
		burst_vis.global_position = global_position
		
		is_casting = true
		
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
					var dist = global_position.distance_to(body.global_position)
					if dist <= current_radius:
						hit_enemies.append(body)
						if body.has_method("take_damage"):
							# Call take_damage but pass Vector3.ZERO so it doesn't apply its own 1-meter knockback
							body.take_damage(dmg, Vector3.ZERO)
						if "knockback_velocity" in body:
							var push_dir = (body.global_position - global_position)
							push_dir.y = 0
							if push_dir == Vector3.ZERO: push_dir = Vector3(0, 0, 1)
							# 7.746 velocity with 6.0 friction = ~5 meters distance
							body.knockback_velocity = push_dir.normalized() * 7.746
						elif body.get("velocity") != null:
							var push_dir = (body.global_position - global_position).normalized()
							body.velocity = push_dir * 1100
		)
		burst_vis.add_child(check_timer)
		
		t.tween_callback(func():
			is_casting = false
			if is_instance_valid(burst_vis):
				burst_vis.queue_free()
		)
		return
	else:
		var spin_area = Area3D.new()
		spin_area.collision_layer = 0
		spin_area.collision_mask = 5
		spin_area.position = global_position
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 4.5
		shape.height = 1.0
		col.shape = shape
		spin_area.add_child(col)
		
		# Spin player sprite
		if sprite:
			var t = get_tree().create_tween()
			t.tween_property(sprite, "rotation", Vector3(0, PI * 2.0, 0), 0.2).as_relative()
			t.tween_callback(func(): sprite.rotation.y = 0)
			
		get_tree().current_scene.add_child(spin_area)
		
		# Small delay to let physics detect
		await get_tree().create_timer(0.05).timeout
		var bodies = spin_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Enemy") and body.has_method("take_damage"):
				body.take_damage(dmg, global_position)
				if "knockback_velocity" in body:
					var push_dir = (body.global_position - global_position)
					push_dir.y = 0
					if push_dir == Vector3.ZERO: push_dir = Vector3(0, 0, 1)
					body.knockback_velocity = push_dir.normalized() * 6.0
				elif body.get("velocity") != null:
					var push_dir = (body.global_position - global_position).normalized()
					body.velocity = push_dir * 800
		
		if is_instance_valid(spin_area):
			spin_area.queue_free()

func _create_charge_bar():
	magic_charge_bar = ProgressBar.new()
	magic_charge_bar.min_value = 0
	magic_charge_bar.max_value = 2.0
	magic_charge_bar.value = 0
	magic_charge_bar.show_percentage = false
	magic_charge_bar.custom_minimum_size = Vector2(40, 6)
	magic_charge_bar.position = Vector2(-20, 20)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.2, 0.8, 1.0, 1.0)
	magic_charge_bar.add_theme_stylebox_override("background", sb_bg)
	magic_charge_bar.add_theme_stylebox_override("fill", sb_fg)
	_get_hud_canvas().add_child(magic_charge_bar)
	magic_charge_timer = 0.01

func _release_magic_charge():
	var charge_time = magic_charge_timer
	magic_charge_timer = 0.0
	is_casting = false
	
	if is_instance_valid(magic_charge_bar):
		magic_charge_bar.queue_free()
		
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
		
	charge_attack_cooldown = 1.0
	
	if w_type == "long_bow":
		current_energy -= 30
		if current_energy < 0: current_energy = 0
		emit_signal("energy_changed", current_energy, max_energy)
		_fire_projectile("arrow", true, charge_time)
	else:
		current_mana -= 30
		if current_mana < 0: current_mana = 0
		emit_signal("mana_changed", current_mana, max_mana)
		_fire_projectile("magic_charge", false, charge_time)

func _fire_projectile(type: String, is_charge: bool, charge_time: float = 0.0):
	if type.begins_with("magic") and status_manager and not status_manager.can_cast(): return
	if not type.begins_with("magic") and status_manager and not status_manager.can_attack(): return
	_update_aim_to_mouse(true)
	is_attacking = true
	var fire_dir = last_direction
	
	if type.begins_with("magic"):
		current_attack_speed = casting_speed
	else:
		current_attack_speed = attack_speed_multiplier
		
	if status_manager: current_attack_speed *= status_manager.get_attack_speed_multiplier()
		
	var actual_len = _get_state_length("Attack", base_attack_duration)
	current_anim_speed_ratio = actual_len / base_attack_duration
	
	if animation_tree:
		animation_tree.set("parameters/AttackTimeScale/scale", current_attack_speed * current_anim_speed_ratio)
	if state_machine:
		state_machine.travel("Attack")
		
	var duration = (base_attack_duration / current_attack_speed)
	var spawn_delay = duration * 0.5
	
	if sword_hitbox_area:
		sword_hitbox_area.is_active = false
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(sword_hitbox_area):
				sword_hitbox_area.is_active = true
		)
	
	await get_tree().create_timer(spawn_delay).timeout
	
	if is_dead or not is_attacking: return
		
	var proj_scene = load("res://Scenes/Skills/player_projectile.tscn")
	if proj_scene and get_tree().current_scene:
		var spawn_pos = global_position + Vector3(0, 0.85, 0)
		
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
			proj.damage = magic_attack
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
			proj.damage = int(magic_attack * multiplier)
			proj.speed = speed_m_s
			if "lifetime" in proj: proj.lifetime = custom_lifetime
			if "is_piercing" in proj: proj.is_piercing = true
			
			var vis = proj.get_node_or_null("Visual")
			if vis:
				vis.color = Color(0.2, 0.5, 1.0)
				vis.size = Vector3(0.3 * multiplier, 0.3 * multiplier, 0.3 * multiplier)
			
			get_tree().current_scene.add_child(proj)
			
		elif type == "mana_burst":
			_perform_spin_attack(int(magic_attack * 1.5), true)
			
		elif type == "bolt":
			var arrow_scene = load("res://Scenes/Skills/arrow_projectile.tscn")
			if not arrow_scene: arrow_scene = proj_scene
			
			if is_charge:
				# Rapid fire 5 bolts
				for i in range(5):
					if not is_instance_valid(self): return
					var proj = arrow_scene.instantiate()
					proj.position = spawn_pos
					proj.direction = fire_dir.rotated(Vector3.UP, randf_range(-0.1, 0.1))
					proj.damage = int(physical_attack * 0.5)
					proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
					get_tree().current_scene.add_child(proj)
					await get_tree().create_timer(0.1).timeout
			else:
				var proj = arrow_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir
				proj.damage = physical_attack
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
				
		elif type == "dagger":
			for angle_offset in [-0.4, 0.0, 0.4]:
				var proj = proj_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir.rotated(Vector3.UP, angle_offset)
				proj.damage = int(physical_attack * 0.7) 
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
				proj.damage = int(physical_attack * 2.0 * multiplier) 
				if "atk_elements" in proj:
					proj.atk_elements = atk_elements.duplicate()
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
			else:
				var proj = arrow_scene.instantiate()
				proj.position = spawn_pos
				proj.direction = fire_dir
				proj.damage = physical_attack
				if "atk_elements" in proj:
					proj.atk_elements = atk_elements.duplicate()
				proj.rotation.y = atan2(-proj.direction.z, proj.direction.x)
				get_tree().current_scene.add_child(proj)
				
	await get_tree().create_timer(duration - spawn_delay).timeout
	if is_attacking:
		is_attacking = false
		if state_machine: state_machine.travel("Idle")

func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, attack_element: String = "netral", kb_force: float = 200.0):
	if is_dead or is_dashing or is_invincible: return
	
	apply_camera_shake(5.0, 0.15)
	
	if is_casting:
		is_casting = false
		spawn_floating_text("Batal!", Color(1, 0.5, 0))
		
	var final_damage = amount - physical_defense
	if final_damage < 1: final_damage = 1
		
	if status_manager and status_manager.has_effect("holy_veil"):
		var hv_data = status_manager.get_effect_data("holy_veil")
		var shield = hv_data.get("shield", 0)
		if shield >= final_damage:
			shield -= final_damage
			hv_data["shield"] = shield
			spawn_floating_text("Absorbed!", Color(1.0, 1.0, 0.5))
			return
		else:
			final_damage -= shield
			status_manager.remove_effect("holy_veil")
			
	if status_manager:
		final_damage = int(final_damage * status_manager.get_damage_taken_multiplier())
		status_manager.handle_damage_taken()
		
	# Elemental Multiplier (Attack vs Defense Element)
	var current_def_element = def_element
	if status_manager and status_manager.has_effect("holy_veil"):
		current_def_element = "cahaya"
	var element_multiplier = Global.get_element_multiplier([attack_element], current_def_element)
	final_damage = int(final_damage * element_multiplier)
		
	# Elemental Resistance Logic
	var resist = 0.0
	if def_resistances.has(attack_element):
		resist = def_resistances[attack_element] / 100.0
		
	final_damage = int(final_damage * (1.0 - resist))
	
	if final_damage <= 0 and resist >= 1.0:
		spawn_floating_text("Immune!", Color(0.8, 0.8, 0.8))
		return
		
	current_health -= final_damage
	emit_signal("health_changed", current_health, max_health)
	
	var dmg_color = Color(1, 0.2, 0.2)
	if resist >= 0.5: dmg_color = Color(0.6, 0.6, 0.6) # Gray for resisted
	spawn_damage_text(final_damage, dmg_color)
	
	if knockback_source != Vector3.ZERO and not is_charge_attacking and not falcon_dive_active:
		var knockback_direction = (global_position - knockback_source)
		knockback_direction.y = 0 # Jangan pantulkan ke atas/bawah agar tidak menembus tanah
		knockback_direction = knockback_direction.normalized()
		var knockback_strength = 40.0 # 40^2 / (2 * 800) = 1 meter
		knockback_velocity = knockback_direction * knockback_strength
		
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0: die()

func spawn_damage_text(amount: int, color: Color):
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 64
	label.outline_size = 12
	label.text = str(amount)
	label.modulate = color
	label.global_position = global_position + Vector3(0, 0.5, 0)
	 
	get_tree().current_scene.add_child(label)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

func spawn_floating_text(msg: String, color: Color):
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
	label.global_position = global_position + Vector3(0, 0.5, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.5, 0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

func die():
	if is_dead: return
	is_dead = true
	if sword_hitbox: sword_hitbox.set_deferred("disabled", true)
	if animation_tree: animation_tree.active = false
	if animation_player:
		animation_player.play("Death")
		await animation_player.animation_finished
	emit_signal("player_died", survival_time, enemies_killed, level, coins)
	
	var go_scene = load("res://Scenes/UI/game_over_hud.tscn")
	if go_scene and get_tree().current_scene:
		var go = go_scene.instantiate()
		get_tree().current_scene.add_child(go)
		if go.has_method("show_game_over"):
			go.show_game_over(survival_time, enemies_killed, level, coins)

func add_coin(amount: int):
	coins += amount
	if get_node_or_null("/root/Global"): Global.coins = coins
	emit_signal("coin_changed", coins)

func add_exp(amount: int):
	current_exp += amount
	if get_node_or_null("/root/Global"): 
		Global.current_exp = current_exp
		
		# Class EXP
		var cls = Global.current_class
		Global.class_exp[cls] += amount
		while Global.class_exp[cls] >= Global.class_max_exp[cls]:
			Global.class_levels[cls] += 1
			Global.class_exp[cls] -= Global.class_max_exp[cls]
			Global.class_max_exp[cls] = int(Global.class_max_exp[cls] * 1.5)
			Global.class_skill_points[cls] += 1
			spawn_floating_text("Class Level Up!", Color(1.0, 0.8, 0.2))
			
	emit_signal("exp_changed", current_exp, max_exp, level)
	
	while current_exp >= max_exp:
		level_up()

func restore_hp(amount: int):
	if is_dead: return
	current_health += amount
	if current_health > max_health: current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func restore_mp(amount: int):
	if is_dead: return
	current_mana += amount
	if current_mana > max_mana: current_mana = max_mana
	emit_signal("mana_changed", current_mana, max_mana)

func level_up():
	level += 1
	current_exp -= max_exp
	max_exp = int(max_exp * 1.5)
	stat_points += 1
	spawn_floating_text("LEVEL UP!", Color(1.0, 1.0, 0.0))
	
	if get_node_or_null("/root/Global"):
		Global.level = level
		Global.current_exp = current_exp
		Global.max_exp = max_exp
		
	emit_signal("exp_changed", current_exp, max_exp, level)

func apply_camera_shake(intensity: float, duration: float):
	var cam3d = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam3d:
		var tween = get_tree().create_tween()
		var shake_count = max(1, int(duration / 0.05))
		for i in range(shake_count):
			var h_off = randf_range(-intensity, intensity) * 0.02
			var v_off = randf_range(-intensity, intensity) * 0.02
			tween.tween_property(cam3d, "h_offset", h_off, 0.025)
			tween.parallel().tween_property(cam3d, "v_offset", v_off, 0.025)
			tween.tween_property(cam3d, "h_offset", 0.0, 0.025)
			tween.parallel().tween_property(cam3d, "v_offset", 0.0, 0.025)
		tween.tween_property(cam3d, "h_offset", 0.0, 0.01)
		tween.parallel().tween_property(cam3d, "v_offset", 0.0, 0.01)
		return
		
	var cam2d = get_node_or_null("Camera2D")
	if cam2d:
		var tween = get_tree().create_tween()
		var shake_count = max(1, int(duration / 0.05))
		for i in range(shake_count):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tween.tween_property(cam2d, "offset", offset, 0.025)
			tween.tween_property(cam2d, "offset", Vector2.ZERO, 0.025)
		tween.tween_property(cam2d, "offset", Vector2.ZERO, 0.01)



func _get_closest_interactable() -> Node:
	if is_dead or is_casting or is_attacking or is_dashing or is_targeting: return null
	
	var interactables = get_tree().get_nodes_in_group("Interactable")
	var closest_dist = 50.0
	
	var valid_nodes = []
	for node in interactables:
		if not is_instance_valid(node) or not node.is_inside_tree(): continue
		
		var dist = global_position.distance_to(node.global_position)
		if dist < closest_dist or (node is Area3D and node.overlaps_body(self)):
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
	if is_dead or is_casting or is_attacking or is_dashing or is_targeting: return null
	
	var mouse_pos = get_mouse_3d_pos()
	var interactables = get_tree().get_nodes_in_group("Interactable")
	
	var valid_nodes = []
	for col in interactables:
		if col and col.has_method("on_interact"):
			if "FarmingZone" in col.name or (col.get_parent() and "FarmingZone" in col.get_parent().name):
				continue
			
			var dist_to_mouse = mouse_pos.distance_to(col.global_position)
			if dist_to_mouse <= 25.0: # Toleransi klik
				var dist = global_position.distance_to(col.global_position)
				if dist <= 120.0 or (col.has_method("overlaps_body") and col.overlaps_body(self)):
					valid_nodes.append(col)
				
	if valid_nodes.size() > 0:
		return valid_nodes[0]
		
	return null

func _try_interact():
	var closest_node = _get_closest_interactable()
	if closest_node and closest_node.has_method("on_interact"):
		closest_node.on_interact(self)


func _cancel_life_skill():
	is_doing_life_skill = false
	if is_instance_valid(life_skill_bar):
		life_skill_bar.queue_free()
	if life_skill_target and is_instance_valid(life_skill_target) and life_skill_target.has_method("on_cancel"):
		life_skill_target.on_cancel()
	life_skill_target = null

func start_life_skill(target_node: Node, required_cycles: int, skill_type: String = ""):
	if is_doing_life_skill or is_attacking or is_dashing or is_casting: return
	is_doing_life_skill = true
	life_skill_target = target_node
	life_skill_type = skill_type
	life_skill_max_progress = required_cycles
	life_skill_progress = 0
	
	life_skill_bar = ProgressBar.new()
	life_skill_bar.min_value = 0
	life_skill_bar.max_value = required_cycles
	life_skill_bar.value = 0
	life_skill_bar.show_percentage = false
	life_skill_bar.custom_minimum_size = Vector2(40, 6)
	life_skill_bar.position = Vector2(-20, -30)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	life_skill_bar.add_theme_stylebox_override("background", sb_bg)
	life_skill_bar.add_theme_stylebox_override("fill", sb_fg)
	_get_hud_canvas().add_child(life_skill_bar)
	
	_life_skill_loop()

func _life_skill_loop():
	while is_doing_life_skill and is_instance_valid(life_skill_target):
		var target_dir = (life_skill_target.global_position - global_position).normalized()
		
		# Snap to 4-way direction to prevent animation blend issues (sprite disappearing)
		var anim_dir = target_dir
		if abs(anim_dir.x) > abs(anim_dir.z):
			anim_dir.z = 0
		else:
			anim_dir.x = 0
		anim_dir = anim_dir.normalized()
		
		last_direction = anim_dir
		
		is_attacking = true
		current_attack_speed = 1.0
		
		var actual_len = _get_state_length("Attack", base_attack_duration)
		current_anim_speed_ratio = actual_len / base_attack_duration
		
		if animation_tree:
			animation_tree.set("parameters/AttackTimeScale/scale", 1.0 * current_anim_speed_ratio)
			
		if state_machine:
			state_machine.travel("Attack")
			
		var duration = base_attack_duration
		await get_tree().create_timer(duration).timeout
		
		is_attacking = false
		if state_machine: state_machine.travel("Idle")
		
		if not is_doing_life_skill or not is_instance_valid(life_skill_target):
			break
			
		life_skill_progress += 1
		if is_instance_valid(life_skill_bar):
			life_skill_bar.value = life_skill_progress
			
		if life_skill_progress >= life_skill_max_progress:
			var target = life_skill_target
			_cancel_life_skill() # Bersihkan UI
			if target and is_instance_valid(target) and target.has_method("on_complete"):
				target.on_complete(self)
			spawn_floating_text("Selesai!", Color(0.2, 1, 0.2))
			break


func start_farming_targeting(zone):
	if is_farming_targeting or is_doing_life_skill or is_targeting: return
	is_farming_targeting = true
	farming_zone_ref = zone
	
	farming_indicator = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(20, 20)
	farming_indicator.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	farming_indicator.material_override = mat
	
	get_parent().add_child(farming_indicator)

func _cancel_farming_targeting():
	set_deferred("is_farming_targeting", false)
	if is_instance_valid(farming_indicator):
		farming_indicator.queue_free()
	farming_zone_ref = null

func _confirm_farming():
	var pos = farming_indicator.global_position
	var zone = farming_zone_ref
	
	if zone and zone.has_method("is_valid_plot_pos"):
		if not zone.is_valid_plot_pos(pos):
			spawn_floating_text("Posisi tidak valid!", Color(1, 0.2, 0.2))
			return
			
	_cancel_farming_targeting()
	
	if zone and is_instance_valid(zone):
		start_auto_walk(pos, func():
			zone.target_pos = pos
			start_life_skill(zone, 1, "farming")
		)

func start_auto_walk(target_pos: Vector3, callback: Callable):
	is_auto_walking = true
	auto_walk_target = target_pos
	auto_walk_callback = callback
	if nav_agent:
		nav_agent.target_position = target_pos

func _cancel_auto_walk():
	is_auto_walking = false
	auto_walk_callback = Callable()

func _complete_auto_walk():
	is_auto_walking = false
	if auto_walk_callback.is_valid():
		auto_walk_callback.call()
	auto_walk_callback = Callable()


func _update_interaction_prompt():
	var closest = _get_closest_interactable()
	
	if closest and not is_doing_life_skill and not is_farming_targeting:
		if not is_instance_valid(interaction_prompt):
			interaction_prompt = Label.new()
			interaction_prompt.add_theme_font_size_override("font_size", 12)
			interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			interaction_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			interaction_prompt.add_theme_constant_override("outline_size", 2)
			interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			interaction_prompt.position = Vector2(-100, -50)
			interaction_prompt.custom_minimum_size = Vector2(200, 0)
			add_child(interaction_prompt)
			
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


func get_mouse_3d_pos() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera: return global_position
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	if ray_dir.y == 0: return global_position
	var t = -ray_origin.y / ray_dir.y
	return ray_origin + ray_dir * t
