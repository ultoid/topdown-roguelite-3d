extends CharacterBody3D
@onready var player_combat = get_node_or_null("PlayerCombat")
@onready var player_stats = get_node_or_null("PlayerStats")
@onready var player_life_skill = get_node_or_null("PlayerLifeSkill")
@onready var player_ui_manager = get_node_or_null("PlayerUIManager")
@onready var player_movement = get_node_or_null("PlayerMovement")
@onready var player_input = get_node_or_null("PlayerInput")

@onready var animation_tree = get_node_or_null("AnimationTree")
@onready var state_machine = animation_tree.get("parameters/playback") if animation_tree else null
var sword_hitbox_area: Area3D:
	get:
		var item_db = get_node_or_null("/root/ItemDB")
		var w_type = "None"
		if item_db and Global.equipment.get("main_weapon", "") != "":
			var w_data = item_db.get_item(Global.equipment["main_weapon"])
			w_type = w_data.get("weapon_type", "None")
			
		var rh = find_child("RightHandHitBox", true, false)
		# Gunakan hitbox di tangan kanan untuk senjata jarak dekat DAN pukulan tangan kosong (base)
		if w_type in ["long_sword", "dagger", "lance", "axe", "mace", "None", ""] and is_instance_valid(rh):
			return rh
			
		# Fallback ke hitbox kuno jika belum punya RightHandHitBox
		var hb = find_child("HitBox", true, false)
		if is_instance_valid(hb): return hb
		return find_child("SwordHitBox", true, false)

var sword_hitbox: CollisionShape3D:
	get:
		var area = sword_hitbox_area
		return area.get_node_or_null("CollisionShape3D") if area else null
@onready var nav_agent = get_node_or_null("NavigationAgent3D")
@onready var animation_player = get_node_or_null("AnimationPlayer")
@onready var sprite = get_node_or_null("Visuals")

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

var is_damaged: bool = false

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

var combo_step: int = 1
var last_attack_time: float = 0.0

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

var is_spinning: bool = false
var spin_timer: float = 0.0
var max_spin_time: float = 0.0
var spin_bar: ProgressBar = null

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
var attack_lunge_timer: float = 0.0
var attack_lunge_speed: float = 0.0

var is_auto_walking: bool = false
var auto_walk_target: Vector3 = Vector3.ZERO
var auto_walk_callback: Callable

var hud_canvas: CanvasLayer = null

func _get_hud_canvas() -> CanvasLayer:
	return player_ui_manager._get_hud_canvas()
func get_equipment_bonuses() -> Dictionary:
	return player_stats.get_equipment_bonuses()
func recalculate_stats():
	player_stats.recalculate_stats()
func _recalculate_elemental_stats():
	player_stats._recalculate_elemental_stats()
func update_equipped_weapon():
	var attachment = find_child("BoneAttachment3D", true, false)
	if not attachment: return
	
	# Bersihkan senjata lama yang di-instantiate (selain SkSenuaSword dummy kalau ada)
	for child in attachment.get_children():
		if child.name != "SkSenuaSword":
			child.queue_free()
		else:
			child.visible = false
			
	var item_db = get_node_or_null("/root/ItemDB")
	if item_db and get_node_or_null("/root/Global") and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		if w_data and w_data.get("weapon_scene_path", "") != "":
			var weapon_scene = load(w_data["weapon_scene_path"])
			if weapon_scene:
				var weapon_instance = weapon_scene.instantiate()
				attachment.add_child(weapon_instance)

func _ready():
	add_to_group("Player")
	status_manager = StatusEffectManager.new()
	add_child(status_manager)
	status_manager.setup(self)
	
	update_equipped_weapon()


	# Strip X/Z translation from the dash animation to prevent the visual mesh from moving away from the root collision shape
	var ap = get_node_or_null("Visuals/HeroModel/AnimationPlayer")
	if ap:
		for anim_name in ap.get_animation_list():
			var lower_name = anim_name.to_lower()
			if "dash" in lower_name or "attack" in lower_name:
				var anim = ap.get_animation(anim_name)
				if "dash" in lower_name:
					dash_anim_length = anim.length # Fallback
					
				var track_idx = -1
				for j in range(anim.get_track_count()):
					if anim.track_get_type(j) == Animation.TYPE_POSITION_3D:
						var path_str = str(anim.track_get_path(j))
						if path_str.ends_with(":Hips") or path_str.ends_with(":mixamorig_Hips"):
							track_idx = j
							break
				
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
		
	if sword_hitbox_area and sword_hitbox_area.has_method("deactivate"):
		sword_hitbox_area.deactivate()
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

func _open_inventory():
	player_ui_manager._open_inventory()
func _open_skill_menu():
	player_ui_manager._open_skill_menu()
func _use_skill(slot_index: int):
	player_combat._use_skill(slot_index)
func _start_cast_skill(skill_id: String, data: Dictionary, cost: int, t_pos: Vector3, indicator: Node = null):
	player_combat._start_cast_skill(skill_id, data, cost, t_pos, indicator)
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
		var anim_state = skill_id.capitalize().replace(" ", "")
		var anim_time = _get_state_length(anim_state, 0.3)
		if skill_id == "seismic_fissure":
			anim_time = _get_state_length(anim_state, 0.6)
		get_tree().create_timer(anim_time).timeout.connect(func(): is_animating_skill = false)
	
	var c_name = Global.current_class
	if c_name == "apprentice":
		ApprenticeSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "fighter":
		FighterSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "scout":
		ScoutSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)

func toggle_menu():
	player_ui_manager.toggle_menu()
func attack(is_charge: bool):
	player_combat.attack(is_charge)
func attack_finished():
	player_combat.attack_finished()
func _get_state_length(state_name: String, fallback: float) -> float:
	return player_combat._get_state_length(state_name, fallback)

func get_anim_state(base_state: String) -> String:
	var item_db = get_node_or_null("/root/ItemDB")
	var w_type = "None"
	if item_db and Global.equipment.get("main_weapon", "") != "":
		var w_data = item_db.get_item(Global.equipment["main_weapon"])
		w_type = w_data.get("weapon_type", "None")
	
	if w_type == "None" or w_type == "":
		return base_state
		
	var specific_state = w_type.replace("_", "") + "_" + base_state
	
	if animation_tree and animation_tree.tree_root is AnimationNodeStateMachine:
		if animation_tree.tree_root.has_node(specific_state):
			return specific_state
			
		var lower_state = specific_state.to_lower()
		if animation_tree.tree_root.has_node(lower_state):
			return lower_state
	
	return base_state
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

func _get_closest_interactable() -> Node:
	return player_life_skill._get_closest_interactable()
func _get_interactable_at_mouse() -> Node:
	return player_life_skill._get_interactable_at_mouse()
func _try_interact():
	player_life_skill._try_interact()
func _cancel_life_skill():
	player_life_skill._cancel_life_skill()
func start_life_skill(target_node: Node, required_cycles: int, skill_type: String = ""):
	player_life_skill.start_life_skill(target_node, required_cycles, skill_type)
func _life_skill_loop():
	player_life_skill._life_skill_loop()
func start_farming_targeting(zone):
	player_life_skill.start_farming_targeting(zone)
func _cancel_farming_targeting():
	player_life_skill._cancel_farming_targeting()
func _confirm_farming():
	player_life_skill._confirm_farming()
func start_auto_walk(target_pos: Vector3, callback: Callable):
	player_life_skill.start_auto_walk(target_pos, callback)
func _cancel_auto_walk():
	player_life_skill._cancel_auto_walk()
func _complete_auto_walk():
	player_life_skill._complete_auto_walk()
func _update_interaction_prompt():
	player_ui_manager._update_interaction_prompt()
func _open_crafting_menu():
	player_ui_manager._open_crafting_menu()

func get_mouse_3d_pos() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera: return global_position
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	if ray_dir.y == 0: return global_position
	var t = -ray_origin.y / ray_dir.y
	return ray_origin + ray_dir * t

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
				var is_bone_attached = false
				var curr_parent = sword_hitbox_area.get_parent()
				while curr_parent:
					if curr_parent is BoneAttachment3D:
						is_bone_attached = true
						break
					curr_parent = curr_parent.get_parent()
				
				if not is_bone_attached:
					sword_hitbox_area.rotation.y = sprite.rotation.y

func activate_weapon_hitbox():
	if is_charge_attacking:
		var item_db = get_node_or_null("/root/ItemDB")
		if item_db and Global.equipment.get("main_weapon", "") != "":
			var w_data = item_db.get_item(Global.equipment["main_weapon"])
			var w_type = w_data.get("weapon_type", "") if w_data else ""
			if w_type == "long_sword":
				_perform_spin_attack_aoe()
				return
			elif w_type == "rune":
				_perform_spin_attack(current_attack_damage * 2, true)
				return
				
	if sword_hitbox_area and sword_hitbox_area.has_method("clear_hit_list"):
		sword_hitbox_area.clear_hit_list()
	
	# --- DIRECT DAMAGE FALLBACK untuk long_sword ---
	# Karena sistem hitbox melalui BoneAttachment tidak reliable,
	# kita langsung hitung jarak musuh dari posisi player.
	var _item_db = get_node_or_null("/root/ItemDB")
	var _w_type = "None"
	if _item_db and Global.equipment.get("main_weapon", "") != "":
		var _w_data = _item_db.get_item(Global.equipment["main_weapon"])
		if _w_data: _w_type = _w_data.get("weapon_type", "None")
	
	if _w_type == "long_sword":
		var _hit_radius = 3.5
		var _enemies = get_tree().get_nodes_in_group("Enemy")
		for _e in _enemies:
			if is_instance_valid(_e) and _e.has_method("take_damage"):
				var _d = Vector2(global_position.x, global_position.z).distance_to(
					Vector2(_e.global_position.x, _e.global_position.z))
				if _d <= _hit_radius:
					var _el = atk_elements.duplicate()
					if status_manager:
						var _ov = status_manager.get_override_element()
						if _ov != "": _el = [_ov]
					_e.take_damage(current_attack_damage, global_position, _el, 6.0)
					apply_camera_shake(3.0, 0.1)
	elif _w_type == "rune":
		var is_third_attack = (combo_step == 1)
		var proj_scene = load("res://Scenes/Skills/player_projectile.tscn")
		if proj_scene:
			var proj = proj_scene.instantiate()
			proj.damage = current_attack_damage
			if is_third_attack:
				proj.damage *= 2
				proj.scale = Vector3(2.5, 2.5, 2.5)
				apply_camera_shake(5.0, 0.15)
			else:
				apply_camera_shake(2.0, 0.1)
				
			var _el = atk_elements.duplicate()
			if status_manager:
				var _ov = status_manager.get_override_element()
				if _ov != "": _el = [_ov]
			proj.atk_elements = _el
			
			var fire_dir = last_direction
			if fire_dir.length_squared() < 0.1:
				fire_dir = -global_transform.basis.z
			proj.direction = fire_dir.normalized()
			proj.speed = 20.0
			proj.lifetime = 0.75
			
			get_parent().add_child(proj)
			proj.global_position = global_position + Vector3(0, 1.0, 0) + fire_dir.normalized() * 1.0


func _perform_spin_attack_aoe():
	var kb_force = 6.0 # 3 meter knockback
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 3.5:
			if e.has_method("take_damage"):
				var final_atk_elements = atk_elements.duplicate()
				if status_manager:
					var override = status_manager.get_override_element()
					if override != "":
						final_atk_elements = [override]
				e.take_damage(current_attack_damage, global_position, final_atk_elements, kb_force)
				
	if has_method("apply_camera_shake"):
		apply_camera_shake(8.0, 0.2)

func deactivate_weapon_hitbox():
	if sword_hitbox_area and sword_hitbox_area.has_method("deactivate"):
		sword_hitbox_area.deactivate()
