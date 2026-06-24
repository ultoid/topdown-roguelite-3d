extends Node

var coins: int = 0
var level: int = 1
var current_exp: int = 0
var max_exp: int = 10

var current_health: float = -1.0
var current_mana: float = -1.0
var current_energy: float = -1.0

# Class Job System
var current_class: String = ""
var class_levels: Dictionary = {"fighter": 1, "apprentice": 1, "scout": 1}
var class_exp: Dictionary = {"fighter": 0, "apprentice": 0, "scout": 0}
var class_max_exp: Dictionary = {"fighter": 10, "apprentice": 10, "scout": 10}
var class_skill_points: Dictionary = {"fighter": 0, "apprentice": 0, "scout": 0}

const CLASS_BASE_STATS = {
	"fighter": {"str": 9, "agi": 3, "vit": 6, "int": 1, "dex": 1, "luk": 5},
	"apprentice": {"str": 1, "agi": 2, "vit": 2, "int": 9, "dex": 6, "luk": 5},
	"scout": {"str": 4, "agi": 8, "vit": 2, "int": 1, "dex": 5, "luk": 5}
}

# Stats Tambahan (didapat dari stat points saat level up)
var perm_stat_str: int = 0
var perm_stat_vit: int = 0
var perm_stat_int: int = 0
var perm_stat_luk: int = 0
var perm_stat_agi: int = 0
var perm_stat_dex: int = 0

# Inventory Dictionary [item_id: jumlah]
var inventory: Dictionary = {
	"potion": 5,
	"ether": 5,
	"pickaxe": 1,
	"axe": 1,
	"hoe": 1,
	"watering_can": 1,
	"practice_long_sword": 1,
	"practice_sword": 1,
	"practice_gloves": 1,
	"practice_lance": 1,
	"practice_staff": 1,
	"practice_rod": 1,
	"practice_long_bow": 1,
	"practice_crossbow": 1,
	"practice_dagger": 2
}

var equipment: Dictionary = {
	"main_weapon": "",
	"secondary_weapon": "",
	"helm": "",
	"armor": "",
	"boots": "",
	"accessory1": "",
	"accessory2": "",
	"artifact": ""
}

var quick_items = ["", "", "", ""] # item_id slot 1 to 4

var unlocked_skills: Dictionary = {} # ID skill : level
var quick_skills = ["", "", "", "", "", "", "", ""] # skill slot 1 to 8

var unlocked_recipes: Array = [""]
	
var farm_plots: Dictionary = {}

var is_crafting: bool = false
var craft_timer: float = 0.0
var craft_duration: float = 0.0
var craft_recipe_id: String = ""

var CRAFTING_RECIPES: Dictionary = {}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_debug_setup_fighter()

func _debug_setup_apprentice():
	# === DEBUG: Apprentice Level 40 ===
	level = 40
	current_exp = 0
	max_exp = 9999
	
	# Set class to Apprentice level 40
	current_class = "apprentice"
	class_levels["apprentice"] = 40
	class_exp["apprentice"] = 0
	class_max_exp["apprentice"] = 9999
	class_skill_points["apprentice"] = 0
	
	# Unlock ALL apprentice skills at their actual max level (only the ones in the skill tree)
	unlocked_skills = {
		"heal": 10,
		"spell_mastery": 10,
		"elemental_mastery": 10,
		"aqua_blast": 5,
		"fire_bolt": 5,
		"sonic_boom": 5,
		"seismic_fissure": 1,
		"holy_veil": 1,
		"hex": 10,
		"soul_drain": 1,
	}
	
	# Assign apprentice skills to quick slots (8 slots)
	quick_skills = [
		"heal",
		"aqua_blast",
		"fire_bolt",
		"sonic_boom",
		"seismic_fissure",
		"holy_veil",
		"hex",
		"soul_drain",
	]

func _debug_setup_fighter():
	# === DEBUG: Fighter Level 40 ===
	level = 40
	current_exp = 0
	max_exp = 9999
	
	# Set class to Fighter level 40
	current_class = "fighter"
	class_levels["fighter"] = 40
	class_exp["fighter"] = 0
	class_max_exp["fighter"] = 9999
	class_skill_points["fighter"] = 0
	
	# Unlock ALL fighter skills at their actual max level
	unlocked_skills = {
		"dash": 1,           # max_level = 1 (default)
		"heavy": 1,          # max_level = 1 (default)
		"weapon_mastery": 10,
		"vitality_mastery": 10,
		"cyclone_sweep": 5,
		"fatal_blow": 10,
		"impact_wave": 5,
		"fatal_smash": 1,    # max_level = 1 (default)
		"endure": 10,
		"provoke": 5,
		"implosion": 1,      # max_level = 1 (default)
	}
	
	# Assign fighter skills to quick slots (8 slots)
	quick_skills = [
		"cyclone_sweep",
		"fatal_blow",
		"impact_wave",
		"fatal_smash",
		"endure",
		"provoke",
		"implosion",
		"",
	]

func _debug_setup_scout():
	# === DEBUG: Scout Level 40 ===
	level = 40
	current_exp = 0
	max_exp = 9999
	
	# Set class to Scout level 40
	current_class = "scout"
	class_levels["scout"] = 40
	class_exp["scout"] = 0
	class_max_exp["scout"] = 9999
	class_skill_points["scout"] = 0
	
	# Unlock ALL scout skills at their actual max level
	unlocked_skills = {
		"dodge": 1,
		"evasion_mastery": 10,
		"agility_mastery": 10,
		"hunters_mark": 5,
		"falcon_dive": 5,
		"arrow_rain": 5,
		"haste": 5,
		"mirage_strike": 5,
		"poison_weapon": 5,
		"shadow_walk": 5,
		"thief": 1,
		"phantom_strike": 5,
		"phantom_flurry": 1,
	}
	
	# Assign scout skills to quick slots (8 slots)
	quick_skills = [
		"falcon_dive",
		"arrow_rain",
		"hunters_mark",
		"phantom_strike",
		"shadow_walk",
		"mirage_strike",
		"poison_weapon",
		"haste",
	]

func _process(delta):
	# Farming
	for plot_id in farm_plots.keys():
		var data = farm_plots[plot_id]
		# State.PLANTED is 1
		if data["state"] == 1:
			if data["watered_time_left"] > 0:
				data["watered_time_left"] -= delta
				data["growth_time"] += delta
				if data["growth_time"] >= data["max_growth_time"]:
					data["state"] = 2 # State.READY
					data["watered_time_left"] = 0
					
	# Crafting
	if is_crafting:
		craft_timer += delta
		if craft_timer >= craft_duration:
			_finish_crafting()

func _finish_crafting():
	is_crafting = false
	
	var item_name = craft_recipe_id.capitalize()
	var item_db = get_node_or_null("/root/ItemDB")
	if item_db:
		var db_data = item_db.get_item(craft_recipe_id)
		if db_data.has("name"): item_name = db_data["name"]
	
	if not inventory.has(craft_recipe_id):
		inventory[craft_recipe_id] = 0
	inventory[craft_recipe_id] += 1
	
	# Try to notify player
	var current_scene = get_tree().current_scene
	if current_scene:
		var player = current_scene.get_node_or_null("Player")
		if player and player.has_method("spawn_floating_text"):
			player.spawn_floating_text("+1 " + item_name + " (Crafted)", Color(0.2, 1.0, 0.2))

func _setup_inputs():
	var inputs = {
		"move_up": KEY_W,
		"move_down": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"run": KEY_SHIFT,
		"jump": KEY_SPACE,
		"interact": KEY_Q,
		"open_menu": KEY_C,
		"open_inventory": KEY_B,
		"open_skill_menu": KEY_K,
		"open_crafting": KEY_J,
		"skill_1": KEY_1,
		"skill_2": KEY_2,
		"skill_3": KEY_3,
		"skill_4": KEY_4,
		"skill_5": KEY_5,
		"skill_6": KEY_6,
		"skill_7": KEY_7,
		"skill_8": KEY_8,
		"item_1": KEY_9,
		"item_2": KEY_0,
		"item_3": KEY_MINUS,
		"item_4": KEY_EQUAL
	}
	
	for action in inputs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev = InputEventKey.new()
		ev.physical_keycode = inputs[action]
		InputMap.action_add_event(action, ev)
		
	# Mouse inputs
	if not InputMap.has_action("basic_attack"):
		InputMap.add_action("basic_attack")
		var ev_left = InputEventMouseButton.new()
		ev_left.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("basic_attack", ev_left)
		
	if not InputMap.has_action("charge_attack"):
		InputMap.add_action("charge_attack")
		var ev_right = InputEventMouseButton.new()
		ev_right.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("charge_attack", ev_right)

func reset_dungeon_run():
	# Dipanggil setiap kali mati
	# Koin, level, exp, dan perm_stats TIDAK direset!
	pass

const ELEMENT_MULTIPLIERS = {
	"api": {"api": 0.5, "air": 0.5, "tanah": 2.0, "es": 2.0, "besi": 2.0},
	"air": {"api": 2.0, "air": 0.5, "tanah": 0.5},
	"tanah": {"api": 0.5, "tanah": 0.5, "udara": 2.0, "listrik": 2.0},
	"udara": {"air": 2.0, "tanah": 0.0, "udara": 0.5},
	"listrik": {"air": 2.0, "tanah": 0.0, "listrik": 0.5, "es": 0.0, "besi": 2.0},
	"es": {"api": 0.5, "listrik": 2.0, "es": 0.5, "suara": 0.5},
	"besi": {"api": 0.5, "listrik": 0.5, "besi": 0.5, "suara": 2.0},
	"suara": {"es": 2.0, "besi": 0.0, "suara": 0.5},
	"cahaya": {"cahaya": 0.5, "kegelapan": 2.0},
	"kegelapan": {"cahaya": 2.0, "kegelapan": 0.5}
}

func get_element_multiplier(atk_elements: Array, def_element: String) -> float:
	if atk_elements.is_empty():
		atk_elements = ["netral"]
		
	var best_multiplier = 0.0
	var found_any = false
	
	for atk in atk_elements:
		if atk == "netral" or atk == "":
			if 1.0 > best_multiplier: best_multiplier = 1.0
			found_any = true
			continue
			
		if ELEMENT_MULTIPLIERS.has(atk):
			if ELEMENT_MULTIPLIERS[atk].has(def_element):
				var m = ELEMENT_MULTIPLIERS[atk][def_element]
				if m > best_multiplier: best_multiplier = m
				found_any = true
			else:
				# Neutral interaction
				if 1.0 > best_multiplier: best_multiplier = 1.0
				found_any = true
				
	if not found_any:
		return 1.0
		
	return best_multiplier

func flash_red_3d(node: Node3D):
	if not is_instance_valid(node): return
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1, 0, 0)
	red_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	red_mat.blend_mode = StandardMaterial3D.BLEND_MODE_ADD
	for m in meshes:
		if is_instance_valid(m) and m.material_overlay == null:
			m.material_overlay = red_mat
	
	await node.get_tree().create_timer(0.15).timeout
	
	if is_instance_valid(node):
		for m in meshes:
			if is_instance_valid(m) and m.material_overlay == red_mat:
				m.material_overlay = null

func spawn_hit_spark(global_pos: Vector3, parent_scene: Node):
	if not is_instance_valid(parent_scene): return
	var p = GPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 15
	p.lifetime = 0.25
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 0.08, 0.08)
	mesh.material = mat
	p.draw_pass_1 = mesh
	
	var process_mat = ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_mat.emission_sphere_radius = 0.2
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 4.0
	process_mat.initial_velocity_max = 8.0
	process_mat.gravity = Vector3(0, -8, 0)
	p.process_material = process_mat
	
	p.global_position = global_pos
	parent_scene.add_child(p)
	p.emitting = true
	
	parent_scene.get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())
