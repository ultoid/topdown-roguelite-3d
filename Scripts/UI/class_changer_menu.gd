extends CanvasLayer

@onready var btn_fighter = $Panel/VBoxContainer/BtnFighter
@onready var btn_apprentice = $Panel/VBoxContainer/BtnApprentice
@onready var btn_scout = $Panel/VBoxContainer/BtnScout
@onready var btn_close = $Panel/VBoxContainer/BtnClose

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if btn_fighter: btn_fighter.pressed.connect(_on_class_selected.bind("fighter"))
	if btn_apprentice: btn_apprentice.pressed.connect(_on_class_selected.bind("apprentice"))
	if btn_scout: btn_scout.pressed.connect(_on_class_selected.bind("scout"))
	if btn_close: btn_close.pressed.connect(_close_menu)

func _on_class_selected(cls: String):
	if get_node_or_null("/root/Global"):
		Global.current_class = cls
		for i in range(8):
			Global.quick_skills[i] = ""
			
		var item_db = get_node_or_null("/root/ItemDB")
		var allowed_weapons = []
		match cls:
			"fighter": allowed_weapons = ["long_sword", "sword", "gloves", "lance"]
			"apprentice": allowed_weapons = ["staff", "rod"]
			"scout": allowed_weapons = ["long_bow", "crossbow", "dagger"]

		for slot in ["main_weapon", "secondary_weapon"]:
			var eq_id = Global.equipment.get(slot, "")
			if eq_id != "" and item_db:
				var data = item_db.get_item(eq_id)
				var w_type = data.get("weapon_type", "None")
				if w_type != "None" and not w_type in allowed_weapons:
					if not Global.inventory.has(eq_id):
						Global.inventory[eq_id] = 0
					Global.inventory[eq_id] += 1
					Global.equipment[slot] = ""
		
		
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var p = players[0]
			if p.has_method("recalculate_stats"):
				p.recalculate_stats()
				
		var hud = get_node_or_null("/root/PlayerHUD")
		if hud:
			if hud.has_method("_update_quick_skills"): hud._update_quick_skills()
			if hud.has_method("update_class_ui"): hud.update_class_ui()
			
	_close_menu()

func _close_menu():
	get_tree().paused = false
	queue_free()

func _unhandled_key_input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		_close_menu()
		get_viewport().set_input_as_handled()
