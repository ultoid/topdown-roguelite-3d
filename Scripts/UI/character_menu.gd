extends CanvasLayer

var player: Node3D

var temp_points: int = 0
var temp_stats = {
	"STR": 0, "VIT": 0, "INT": 0, "LUK": 0, "AGI": 0, "DEX": 0
}

var lbl_points: Label
@onready var btn_confirm = $Panel/MainVBox/BtnConfirm
@onready var btn_close = $Panel/BtnClose

var ui_stats = {}
var ui_details = {}

var elem_atk_container: HBoxContainer
var elem_def_container: VBoxContainer

var equip_btns = {}
var equip_inv_grid: GridContainer
var equip_inv_title: Label
var current_selected_equip_slot: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Node bisa dicari secara dinamis karena strukturnya rumit
	var stats_grid = find_child("StatsGrid", true, false)
	if stats_grid:
		for stat in ["STR", "VIT", "INT", "LUK", "AGI", "DEX"]:
			var btn_up = stats_grid.get_node("BtnUp" + stat)
			var btn_dn = stats_grid.get_node("BtnDn" + stat)
			var lbl_val = stats_grid.get_node("Val" + stat)
			
			ui_stats[stat] = {
				"btn_up": btn_up,
				"btn_dn": btn_dn,
				"lbl_val": lbl_val
			}
			
			btn_up.pressed.connect(func(): _change_stat(stat, 1))
			btn_dn.pressed.connect(func(): _change_stat(stat, -1))
			
	var detail_grid = find_child("DetailGrid", true, false)
	if detail_grid:
		for d in ["MaxHP", "MaxMP", "Atk", "Matk", "Def", "Mdef", "Hit", "Flee", "Critical", "Aspd"]:
			ui_details[d] = detail_grid.get_node("Detail" + d)
			
		var elem_vbox = VBoxContainer.new()
		elem_vbox.name = "ElementVBox"
		elem_vbox.custom_minimum_size = Vector2(180, 0)
		
		var title = Label.new()
		title.text = "--- Elemen & Resist ---"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elem_vbox.add_child(title)
		
		var atk_title = Label.new()
		atk_title.text = "Serangan:"
		elem_vbox.add_child(atk_title)
		
		elem_atk_container = HBoxContainer.new()
		elem_vbox.add_child(elem_atk_container)
		
		var def_title = Label.new()
		def_title.text = "Pertahanan:"
		elem_vbox.add_child(def_title)
		
		elem_def_container = VBoxContainer.new()
		elem_vbox.add_child(elem_def_container)
		
		detail_grid.get_parent().add_child(elem_vbox)
			
	equip_inv_grid = find_child("EquipInvGrid", true, false)
	equip_inv_title = find_child("EquipInvTitle", true, false)
	
	var slot_ids = ["main_weapon", "helm", "armor", "boots", "secondary_weapon", "artifact", "accessory1", "accessory2"]
	for s_id in slot_ids:
		var btn = find_child("Btn" + s_id, true, false)
		if btn:
			btn.pressed.connect(_on_slot_clicked.bind(s_id))
			equip_btns[s_id] = btn
	# Perbaiki LblPoints yang lokasinya di StatHeader
	var stat_header = find_child("LblPoints", true, false)
	if stat_header:
		lbl_points = stat_header
		
	if btn_confirm: btn_confirm.pressed.connect(_confirm_stats)
	if btn_close: btn_close.pressed.connect(_close_menu)

func setup(player_node: Node3D):
	player = player_node
	
	temp_points = player.stat_points
	temp_stats["STR"] = player.stat_str
	temp_stats["VIT"] = player.stat_vit
	temp_stats["INT"] = player.stat_int
	temp_stats["LUK"] = player.stat_luk
	temp_stats["AGI"] = player.stat_agi
	temp_stats["DEX"] = player.stat_dex
	
	_update_ui()
	_update_equipment_ui()



func _update_equipment_ui():
	var item_db = get_node_or_null("/root/ItemDB")
	
	var main_is_2h = false
	var main_id = Global.equipment.get("main_weapon", "")
	if main_id != "" and item_db:
		var main_data = item_db.get_item(main_id)
		if main_data.get("weapon_type") in ["long_sword", "lance", "staff", "long_bow", "gloves"]:
			main_is_2h = true
			
	for slot in equip_btns.keys():
		var btn = equip_btns[slot]
		var item_id = Global.equipment.get(slot, "")
		
		var is_shadowing_2h = false
		if slot == "secondary_weapon" and main_is_2h:
			item_id = main_id
			is_shadowing_2h = true
		
		if slot == current_selected_equip_slot:
			btn.modulate = Color(1.5, 1.5, 0.5)
		else:
			btn.modulate = Color(1, 1, 1)
			
		if is_shadowing_2h:
			btn.modulate = Color(0.6, 0.6, 0.6) # Dim it a bit to show it's occupied by main
			
		if item_id == "":
			btn.text = "Kosong"
			btn.icon = null
			btn.tooltip_text = ""
		else:
			if item_db:
				var data = item_db.get_item(item_id)
				btn.text = data.get("name", item_id.capitalize())
				
				var rarity_desc = "Common"
				var rarity_color = Color(0.2, 0.2, 0.2, 0.8)
				if data.has("rarity"):
					rarity_desc = data["rarity"].capitalize()
					rarity_color = item_db.get_rarity_color(data["rarity"])
				
				var type_desc = data.get("type", "equipment").capitalize()
				if type_desc == "Equipment" and data.has("equipment_slot"):
					type_desc = "Equipment (" + data["equipment_slot"].capitalize().replace("_", " ") + ")"
				var item_desc = data.get("description", "")
				btn.tooltip_text = btn.text + "\n[" + type_desc + " - " + rarity_desc + "]\n" + item_desc
				
				var tex = item_db.get_item_icon(item_id)
				if tex:
					btn.icon = tex
					btn.expand_icon = true
					
				var style = StyleBoxFlat.new()
				style.bg_color = rarity_color
				style.set_corner_radius_all(4)
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
			else:
				btn.text = item_id

func _on_slot_clicked(slot: String):
	current_selected_equip_slot = slot
	_update_equipment_ui()
	_populate_equip_inventory(slot)

func _populate_equip_inventory(slot: String):
	if not equip_inv_grid: return
	
	for c in equip_inv_grid.get_children():
		c.queue_free()
		
	if equip_inv_title:
		equip_inv_title.text = "Pilih " + slot.capitalize().replace("_", " ")
		
	var has_item = Global.equipment.get(slot, "") != ""
	if slot == "secondary_weapon":
		var main_id = Global.equipment.get("main_weapon", "")
		if main_id != "":
			var item_db_tmp = get_node_or_null("/root/ItemDB")
			if item_db_tmp:
				var m_data = item_db_tmp.get_item(main_id)
				if m_data.get("weapon_type") in ["long_sword", "lance", "staff", "long_bow", "gloves"]:
					has_item = true
		
	if has_item:
		var btn_lepas = Button.new()
		btn_lepas.custom_minimum_size = Vector2(80, 80)
		btn_lepas.text = "Lepas"
		btn_lepas.pressed.connect(_unequip_item.bind(slot))
		equip_inv_grid.add_child(btn_lepas)
		
	var item_db = get_node_or_null("/root/ItemDB")
	
	for item_id in Global.inventory.keys():
		var count = Global.inventory[item_id]
		if count <= 0: continue
		
		if item_db:
			var data = item_db.get_item(item_id)
			var target_slot = slot
			if slot.begins_with("accessory"): target_slot = "accessory"
			
			var w_type = data.get("weapon_type", "None")
			var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
			var allowed_weapons = []
			match cls:
				"fighter": allowed_weapons = ["long_sword", "sword", "gloves", "lance"]
				"apprentice": allowed_weapons = ["staff", "rune"]
				"scout": allowed_weapons = ["long_bow", "crossbow", "dagger"]
				
			if w_type != "None" and not w_type in allowed_weapons:
				continue # Skip this weapon if it doesn't match the class
			
			var is_valid_slot = false
			if data.get("equipment_slot") == target_slot:
				is_valid_slot = true
			elif target_slot == "secondary_weapon" and w_type == "dagger":
				is_valid_slot = true
				
			if data.get("type") == "equipment" and is_valid_slot:
				var btn = Button.new()
				btn.custom_minimum_size = Vector2(80, 80)
				
				var tex = item_db.get_item_icon(item_id)
				if tex:
					btn.icon = tex
					btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
					btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
					btn.expand_icon = true
					
				var item_name = data.get("name", item_id.capitalize())
				
				var rarity_desc = "Common"
				var rarity_color = Color(0.2, 0.2, 0.2, 0.8)
				if data.has("rarity"):
					rarity_desc = data["rarity"].capitalize()
					rarity_color = item_db.get_rarity_color(data["rarity"])
					
				var type_desc = data.get("type", "equipment").capitalize()
				if type_desc == "Equipment" and data.has("equipment_slot"):
					type_desc = "Equipment (" + data["equipment_slot"].capitalize().replace("_", " ") + ")"
				var item_desc = data.get("description", "")
				
				var tooltip = item_name + " x" + str(count) + "\n[" + type_desc + " - " + rarity_desc + "]\n" + item_desc
				btn.tooltip_text = tooltip
				
				var style = StyleBoxFlat.new()
				style.bg_color = rarity_color
				style.set_corner_radius_all(4)
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
				
				btn.pressed.connect(_equip_item.bind(slot, item_id))
				equip_inv_grid.add_child(btn)

func _equip_item(slot: String, item_id: String):
	var item_db = get_node_or_null("/root/ItemDB")
	
	if item_db:
		var w_data = item_db.get_item(item_id)
		var w_type = w_data.get("weapon_type", "None")
		
		# If equipping a 2-handed weapon into main_weapon
		if slot == "main_weapon" and w_type in ["long_sword", "lance", "staff", "long_bow", "gloves"]:
			if Global.equipment.get("secondary_weapon", "") != "":
				_unequip_item("secondary_weapon")
				
		# If equipping a secondary weapon, and main weapon is 2-handed
		if slot == "secondary_weapon":
			var main_id = Global.equipment.get("main_weapon", "")
			if main_id != "":
				var main_data = item_db.get_item(main_id)
				var main_w_type = main_data.get("weapon_type", "None")
				if main_w_type in ["long_sword", "lance", "staff", "long_bow", "gloves"]:
					_unequip_item("main_weapon")

	var old_equip = Global.equipment.get(slot, "")
	if old_equip != "":
		if not Global.inventory.has(old_equip):
			Global.inventory[old_equip] = 0
		Global.inventory[old_equip] += 1
		
	Global.equipment[slot] = item_id
	Global.inventory[item_id] -= 1
	if Global.inventory[item_id] <= 0:
		Global.inventory.erase(item_id)
		
	if player.has_method("recalculate_stats"):
		player.recalculate_stats()
		var hud = get_node_or_null("/root/PlayerHUD")
		if hud:
			hud._update_hp_mp_ep()
	if player.has_method("update_equipped_weapon"):
		player.update_equipped_weapon()
			
	_update_equipment_ui()
	_update_ui()
	_populate_equip_inventory(slot)

func _unequip_item(slot: String):
	var item_id = Global.equipment.get(slot, "")
	
	if slot == "secondary_weapon" and item_id == "":
		var item_db = get_node_or_null("/root/ItemDB")
		var main_id = Global.equipment.get("main_weapon", "")
		if main_id != "" and item_db:
			var main_data = item_db.get_item(main_id)
			if main_data.get("weapon_type") in ["long_sword", "lance", "staff", "long_bow", "gloves"]:
				_unequip_item("main_weapon")
				return
				
	if item_id == "": return
	
	Global.equipment[slot] = ""
	if not Global.inventory.has(item_id):
		Global.inventory[item_id] = 0
	Global.inventory[item_id] += 1
	
	if player.has_method("recalculate_stats"):
		player.recalculate_stats()
		var hud = get_node_or_null("/root/PlayerHUD")
		if hud:
			hud._update_hp_mp_ep()
	if player.has_method("update_equipped_weapon"):
		player.update_equipped_weapon()
			
	_update_equipment_ui()
	_update_ui()
	if current_selected_equip_slot == slot:
		_populate_equip_inventory(slot)

func _update_ui():
	if lbl_points: lbl_points.text = "Sisa Stat Point: %02d" % temp_points
	
	var bonuses = {}
	if player.has_method("get_equipment_bonuses"):
		bonuses = player.get_equipment_bonuses()
		
	var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
	var base_stats = {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}
	if get_node_or_null("/root/Global") and Global.CLASS_BASE_STATS.has(cls):
		base_stats = Global.CLASS_BASE_STATS[cls]
		
	for stat in temp_stats.keys():
		var bns = bonuses.get(stat.to_lower(), 0)
		var base_val = base_stats[stat.to_lower()]
		var total_val = base_val + temp_stats[stat] + bns
		
		ui_stats[stat]["lbl_val"].text = str(total_val)
		ui_stats[stat]["lbl_val"].tooltip_text = "Base Stat: %d\nStat Level Up: %d\nEquipment: %d" % [base_val, temp_stats[stat], bns]
		ui_stats[stat]["lbl_val"].mouse_filter = Control.MOUSE_FILTER_STOP # Ensure tooltip works
		
		ui_stats[stat]["btn_up"].disabled = temp_points <= 0
		ui_stats[stat]["btn_dn"].disabled = temp_stats[stat] <= player.get("stat_" + stat.to_lower())
		
	var t_str = base_stats["str"] + temp_stats["STR"] + bonuses.get("str", 0)
	var t_vit = base_stats["vit"] + temp_stats["VIT"] + bonuses.get("vit", 0)
	var t_int = base_stats["int"] + temp_stats["INT"] + bonuses.get("int", 0)
	var t_luk = base_stats["luk"] + temp_stats["LUK"] + bonuses.get("luk", 0)
	var t_agi = base_stats["agi"] + temp_stats["AGI"] + bonuses.get("agi", 0)
	var t_dex = base_stats["dex"] + temp_stats["DEX"] + bonuses.get("dex", 0)
		
	var sim_hp = 50 + (t_vit * 10) + bonuses.get("max_hp", 0)
	var sim_mp = 20 + (t_int * 5) + bonuses.get("max_mp", 0)
	var sim_p_atk = 10 + (t_str * 2) + bonuses.get("p_atk", 0)
	var sim_m_atk = 10 + (t_int * 2) + bonuses.get("m_atk", 0)
	var sim_p_def = t_vit + bonuses.get("p_def", 0)
	var sim_m_def = int(t_vit / 2.0 + t_int / 2.0) + bonuses.get("m_def", 0)
	var sim_spd = 80.0 + (t_agi * 4.0)
	var sim_crit = t_luk * 1.0
	
	if ui_details.has("MaxHP"): ui_details["MaxHP"].text = str(sim_hp)
	if ui_details.has("MaxMP"): ui_details["MaxMP"].text = str(sim_mp)
	if ui_details.has("Atk"): ui_details["Atk"].text = str(sim_p_atk)
	if ui_details.has("Matk"): ui_details["Matk"].text = str(sim_m_atk)
	if ui_details.has("Def"): ui_details["Def"].text = str(sim_p_def)
	if ui_details.has("Mdef"): ui_details["Mdef"].text = str(sim_m_def)
	if ui_details.has("Hit"): ui_details["Hit"].text = str(t_dex * 2)
	if ui_details.has("Flee"): ui_details["Flee"].text = str(t_agi * 2)
	if ui_details.has("Critical"): ui_details["Critical"].text = "%.1f%%" % sim_crit
	if ui_details.has("Aspd"): ui_details["Aspd"].text = str(sim_spd)
	
	# Update Elemental Icons
	if elem_atk_container and player and "atk_elements" in player:
		for c in elem_atk_container.get_children():
			c.queue_free()
		var elem_db = get_node_or_null("/root/ElementDB")
		for el in player.atk_elements:
			var hbox = HBoxContainer.new()
			var icon = TextureRect.new()
			if elem_db:
				icon.texture = elem_db.get_element_icon(el)
				if icon.texture:
					icon.custom_minimum_size = Vector2(24, 24)
					icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var lbl = Label.new()
			lbl.text = el.capitalize()
			if icon.texture: hbox.add_child(icon)
			hbox.add_child(lbl)
			elem_atk_container.add_child(hbox)
			
	if elem_def_container and player and "def_resistances" in player:
		for c in elem_def_container.get_children():
			c.queue_free()
		var elem_db = get_node_or_null("/root/ElementDB")
		
		if "def_element" in player:
			var hbox_def = HBoxContainer.new()
			var icon_def = TextureRect.new()
			if elem_db:
				icon_def.texture = elem_db.get_element_icon(player.def_element)
				if icon_def.texture:
					icon_def.custom_minimum_size = Vector2(24, 24)
					icon_def.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var lbl_def = Label.new()
			lbl_def.text = "Dasar: " + player.def_element.capitalize()
			if icon_def.texture: hbox_def.add_child(icon_def)
			hbox_def.add_child(lbl_def)
			elem_def_container.add_child(hbox_def)
			
		if not player.def_resistances.is_empty():
			for el in player.def_resistances.keys():
				var hbox = HBoxContainer.new()
				var icon = TextureRect.new()
				if elem_db:
					icon.texture = elem_db.get_element_icon(el)
					if icon.texture:
						icon.custom_minimum_size = Vector2(24, 24)
						icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				var lbl = Label.new()
				lbl.text = el.capitalize() + " (" + str(player.def_resistances[el]) + "%)"
				if icon.texture: hbox.add_child(icon)
				hbox.add_child(lbl)
				elem_def_container.add_child(hbox)
				
	if btn_confirm: btn_confirm.disabled = temp_points == player.stat_points
	

func _change_stat(stat_name: String, amount: int):
	if amount > 0 and temp_points <= 0: return
	
	var current_base = player.get("stat_" + stat_name.to_lower())
	if amount < 0 and temp_stats[stat_name] <= current_base: return
	
	temp_stats[stat_name] += amount
	temp_points -= amount
	_update_ui()

func _confirm_stats():
	player.stat_str = temp_stats["STR"]
	player.stat_vit = temp_stats["VIT"]
	player.stat_int = temp_stats["INT"]
	player.stat_luk = temp_stats["LUK"]
	player.stat_agi = temp_stats["AGI"]
	player.stat_dex = temp_stats["DEX"]
	player.stat_points = temp_points
	
	player.recalculate_stats()
	_update_ui()

func _close_menu():
	get_tree().paused = false
	queue_free()

func _unhandled_key_input(event):
	if event.is_action_pressed("open_menu"):
		_close_menu()
		get_viewport().set_input_as_handled()
