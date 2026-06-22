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
var charge_attack_cooldown: float = 0.0
var charge_lunge_timer: float = 0.0
var last_direction: Vector3 = Vector3(0, 0, 1)

var is_dead: bool = false
var is_invincible: bool = false
var casting_skill_id: String = ""

var hud_canvas: CanvasLayer = null

@onready var player_ui = $PlayerUIManager
@onready var player_combat = $PlayerCombat
var active_skill_cooldowns: Dictionary = {}
var cast_bar: ProgressBar = null

var interaction_prompt: Label:
	get: return player_ui.interaction_prompt

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
@onready var life_skills = $PlayerLifeSkill
var is_doing_life_skill: bool:
	get: return life_skills.is_doing_life_skill
	set(v): life_skills.is_doing_life_skill = v
var life_skill_target: Node:
	get: return life_skills.life_skill_target
var life_skill_type: String:
	get: return life_skills.life_skill_type
var life_skill_progress: int:
	get: return life_skills.life_skill_progress
var life_skill_max_progress: int:
	get: return life_skills.life_skill_max_progress
var life_skill_bar: ProgressBar:
	get: return life_skills.life_skill_bar

var is_farming_targeting: bool:
	get: return life_skills.is_farming_targeting
	set(v): life_skills.is_farming_targeting = v
var farming_zone_ref: Node:
	get: return life_skills.farming_zone_ref
var farming_indicator: MeshInstance3D:
	get: return life_skills.farming_indicator

var is_auto_walking: bool:
	get: return life_skills.is_auto_walking
var auto_walk_target: Vector3:
	get: return life_skills.auto_walk_target
var auto_walk_callback: Callable:
	get: return life_skills.auto_walk_callback




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
@onready var player_stats = $PlayerStats

func get_equipment_bonuses() -> Dictionary:
	return player_stats.get_equipment_bonuses()

func recalculate_stats():
	player_stats.recalculate_stats()

func _recalculate_elemental_stats():
	player_stats._recalculate_elemental_stats()

func _ready():
	add_to_group("Player")
	status_manager = StatusEffectManager.new()
	add_child(status_manager)
	status_manager.setup(self)
	
	life_skills.setup(self)
	player_stats.setup(self)
	player_ui.setup(self)


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
	player_combat._use_skill(slot_index)
func _start_cast_skill(skill_id: String, data: Dictionary, cost: int, t_pos: Vector3, indicator: Node = null):
	player_combat._start_cast_skill(skill_id, data, cost, t_pos, indicator)
func _execute_skill(skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node = null):
	player_combat._execute_skill(skill_id, data, t_pos, indicator)
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
	player_combat.attack(is_charge)
func attack_finished():
	player_combat.attack_finished()
func _get_state_length(state_name: String, fallback: float) -> float:
	return player_combat._get_state_length(state_name, fallback)
func _perform_spin_attack(dmg: int, is_mana_burst: bool = false):
	player_combat._perform_spin_attack(dmg, is_mana_burst)
func _create_charge_bar():
	player_combat._create_charge_bar()
func _release_magic_charge():
	player_combat._release_magic_charge()
func _fire_projectile(type: String, is_charge: bool, charge_time: float = 0.0):
	player_combat._fire_projectile(type, is_charge, charge_time)
func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, attack_element: String = "netral", kb_force: float = 200.0):
	player_combat.take_damage(amount, knockback_source, attack_element, kb_force)
func spawn_damage_text(amount: int, color: Color):
	player_combat.spawn_damage_text(amount, color)
func spawn_floating_text(msg: String, color: Color):
	player_combat.spawn_floating_text(msg, color)
func die():
	player_combat.die()
func add_coin(amount: int):
	player_combat.add_coin(amount)
func add_exp(amount: int):
	player_combat.add_exp(amount)
func restore_hp(amount: int):
	player_combat.restore_hp(amount)
func restore_mp(amount: int):
	player_combat.restore_mp(amount)
func level_up():
	player_combat.level_up()
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
	life_skills._cancel_life_skill()

func start_life_skill(target_node: Node, required_cycles: int, skill_type: String = ""):
	life_skills.start_life_skill(target_node, required_cycles, skill_type)

func start_farming_targeting(zone):
	life_skills.start_farming_targeting(zone)

func _cancel_farming_targeting():
	life_skills._cancel_farming_targeting()

func _confirm_farming():
	life_skills._confirm_farming()

func start_auto_walk(target_pos: Vector3, callback: Callable):
	life_skills.start_auto_walk(target_pos, callback)

func _cancel_auto_walk():
	life_skills._cancel_auto_walk()

func _complete_auto_walk():
	life_skills._complete_auto_walk()


func _update_interaction_prompt():
	player_ui._update_interaction_prompt()

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
