extends StaticBody3D

@export var npc_name: String = "Penduduk"
@export_multiline var dialogue_lines: Array[String] = ["Halo, selamat datang di kota kami!"]
@export_enum("Talk", "Merchant", "Portal", "DebugStatus", "ClassChanger", "Healer") var npc_type: String = "Talk"
@export var merchant_items: Array[String] = ["potion", "ether"]


var player_in_range = false
var dialogue_box_scene = preload("res://Scenes/UI/dialogue_box.tscn")
var current_dialogue_box = null
var cooldown_timer: float = 0.0

func _ready():
	$Label.text = npc_name
	if has_node("InteractArea"):
		$InteractArea.body_entered.connect(_on_body_entered)
		$InteractArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
		
	if player_in_range and Input.is_action_just_pressed("interact"):
		if cooldown_timer <= 0 and (current_dialogue_box == null or not is_instance_valid(current_dialogue_box)):
			interact()

func interact():
	cooldown_timer = 1.0
	current_dialogue_box = dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(current_dialogue_box)
	
	if npc_type == "Talk":
		current_dialogue_box.start_dialogue(dialogue_lines)
	elif npc_type == "Merchant":
		current_dialogue_box.start_dialogue(dialogue_lines, self, "open_shop")
	elif npc_type == "Portal":
		current_dialogue_box.start_dialogue(dialogue_lines, self, "warp_to_dungeon")
	elif npc_type == "DebugStatus":
		current_dialogue_box.start_dialogue(dialogue_lines, self, "open_debug_status")
	elif npc_type == "ClassChanger":
		current_dialogue_box.start_dialogue(dialogue_lines, self, "open_class_changer")
	elif npc_type == "Healer":
		current_dialogue_box.start_dialogue(dialogue_lines, self, "heal_player")

func open_class_changer():
	var menu_scene = load("res://Scenes/UI/class_changer_menu.tscn")
	if not menu_scene:
		# Fallback to pure script if scene doesn't exist
		var menu = Node.new()
		menu.set_script(load("res://Scripts/UI/class_changer_menu.gd"))
		get_tree().current_scene.add_child(menu)
	else:
		var menu = menu_scene.instantiate()
		get_tree().current_scene.add_child(menu)
	get_tree().paused = true

func open_shop():
	var shop_scene = load("res://Scenes/UI/shop_menu.tscn")
	if shop_scene:
		var shop = shop_scene.instantiate()
		get_tree().current_scene.add_child(shop)
		if shop.has_method("setup"):
			shop.setup(merchant_items)
		get_tree().paused = true
			
func warp_to_dungeon():
	if get_node_or_null("/root/Global"):
		Global.reset_dungeon_run()
	get_tree().change_scene_to_file("res://Scenes/Maps/forest.tscn")

func open_debug_status():
	var debug_menu_scene = load("res://Scenes/UI/debug_status_menu.tscn")
	var menu = debug_menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	var player_nodes = get_tree().get_nodes_in_group("Player")
	if player_nodes.size() > 0:
		menu.setup(player_nodes[0])


func heal_player():
	var p = get_tree().get_nodes_in_group("Player")
	if p.size() > 0:
		var player = p[0]
		player.current_health = player.max_health
		player.current_mana = player.max_mana
		player.current_energy = player.max_energy
		player.emit_signal("health_changed", player.current_health, player.max_health)
		player.emit_signal("mana_changed", player.current_mana, player.max_mana)
		player.emit_signal("energy_changed", player.current_energy, player.max_energy)
		if player.has_method("spawn_floating_text"):
			player.spawn_floating_text("Bugar Kembali!", Color(0, 1, 0))
