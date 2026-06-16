extends Node

var coins: int = 0
var level: int = 100
var current_exp: int = 0
var max_exp: int = 10

var current_health: float = -1.0
var current_mana: float = -1.0
var current_energy: float = -1.0

# Class Job System
var current_class: String = "scout"
var class_levels: Dictionary = {"fighter": 100, "apprentice": 100, "scout": 100}
var class_exp: Dictionary = {"fighter": 0, "apprentice": 0, "scout": 0}
var class_max_exp: Dictionary = {"fighter": 10, "apprentice": 10, "scout": 10}
var class_skill_points: Dictionary = {"fighter": 0, "apprentice": 0, "scout": 99}

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
	"iron_sword": 1,
	"leather_armor": 1,
	"ruby_ring": 1,
	"holy_sword": 1,
	"leather_helmet" : 1,
	"leather_boots" : 1,
	"fire_sword" : 1,
	"pickaxe": 1,
	"axe": 1,
	"hoe": 1,
	"watering_can": 1,
	"potion_recipe": 1,
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

var unlocked_skills: Dictionary = {
	"dash": 1, 
	"heavy": 1, 
	"heal": 10, 
	"fireball": 1,
	"weapon_mastery": 10,
	"vitality_mastery": 10,
	"cyclone_sweep": 5,
	"fatal_blow": 10,
	"impact_wave": 5,
	"endure": 5,
	"provoke": 5,
	"fatal_smash": 1,
	"implosion": 1,
	"spell_mastery": 10,
	"elemental_mastery": 10,
	"aqua_blast": 5,
	"fire_bolt": 5,
	"sonic_boom": 5,
	"seismic_fissure": 1,
	"holy_veil": 1,
	"hex": 10,
	"soul_drain": 1,
	"hunters_mark": 10,
	"falcon_dive": 10,
	"arrow_rain": 5,
	"agility_mastery": 10,
	"haste": 5,
	"mirage_strike": 5,
	"fortunes_eye": 10,
	"shadow_walk": 5,
	"thief": 5,
	"phantom_strike": 5,
	"phantom_flurry": 1,
	"poison_weapon": 5
} # ID skill : level
var quick_skills = ["aqua_blast", "fire_bolt", "sonic_boom", "seismic_fissure", "", "", "", ""] # skill slot 1 to 8

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
