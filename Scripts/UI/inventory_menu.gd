extends CanvasLayer

var player_ref: Node3D = null

@onready var grid = get_node_or_null("Panel/Grid")
@onready var btn_close = get_node_or_null("Panel/BtnClose")
@onready var popup = get_node_or_null("ItemPopup")

@onready var lbl_gold = get_node_or_null("Panel/CoinContainer/GoldBox/Label")
@onready var lbl_silver = get_node_or_null("Panel/CoinContainer/SilverBox/Label")
@onready var lbl_bronze = get_node_or_null("Panel/CoinContainer/BronzeBox/Label")

var current_selected_item: String = ""
var current_selected_is_equipped: bool = false
var current_selected_quickslot: int = -1
var unequip_popup: PopupMenu = null
var current_selected_slot: int = -1

var drop_popup: Panel
var drop_spinbox: SpinBox
var drop_lbl_name: Label
var drop_hbox_qty: HBoxContainer

var current_filter_tab: String = "Semua"
var hbox_tabs: HBoxContainer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if btn_close:
		btn_close.pressed.connect(_close_menu)
		
	if popup:
		popup.id_pressed.connect(_on_popup_pressed)
		
	hbox_tabs = find_child("HBoxTabs", true, false)
	if hbox_tabs:
		var tabs = ["Semua", "Consumable", "Equipment", "Material", "Upgrade", "Key Item"]
		for t in tabs:
			var btn = hbox_tabs.find_child("BtnTab" + t.replace(" ", ""), true, false)
			if btn:
				btn.pressed.connect(_on_tab_pressed.bind(t))
	_create_drop_popup()
	unequip_popup = PopupMenu.new()
	unequip_popup.name = "UnequipPopup"
	unequip_popup.add_item("Lepas", 0)
	unequip_popup.add_item("Batal", 1)
	unequip_popup.id_pressed.connect(_on_unequip_popup_pressed)
	add_child(unequip_popup)
	
	if popup:
		var sub_menu = popup.get_node_or_null("SlotSubMenu")
		if not sub_menu:
			sub_menu = PopupMenu.new()
			sub_menu.name = "SlotSubMenu"
			popup.add_child(sub_menu)
		sub_menu.clear()
		sub_menu.add_item("Pasang ke Slot 9", 0)
		sub_menu.add_item("Pasang ke Slot 0", 1)
		sub_menu.add_item("Pasang ke Slot -", 2)
		sub_menu.add_item("Pasang ke Slot =", 3)
		if not sub_menu.id_pressed.is_connected(_on_slot_selected):
			sub_menu.id_pressed.connect(_on_slot_selected)
			
	for i in range(4):
		var slot = get_node_or_null("Panel/QuickSlots/Slot" + str(i))
		if slot:
			slot.set_drag_forwarding(Callable(), Callable(self, "_can_drop_fw").bind(i), Callable(self, "_drop_fw").bind(i))
			if not slot.gui_input.is_connected(_on_quick_slot_gui_input):
				slot.gui_input.connect(_on_quick_slot_gui_input.bind(i))
				
	_update_quick_slots_ui()

	_update_coins()

func _update_coins():
	var coins = Global.coins
	var gold = coins / 10000
	var silver = (coins / 100) % 100
	var bronze = coins % 100
	
	if lbl_gold: lbl_gold.text = str(gold)
	if lbl_silver: lbl_silver.text = str(silver)
	if lbl_bronze: lbl_bronze.text = str(bronze)

func _on_tab_pressed(tab_name: String):
	current_filter_tab = tab_name
	_refresh_inventory()

func setup(p: Node3D):
	player_ref = p
	_refresh_inventory()

func _refresh_inventory():
	_update_coins()
	if not grid: return
	
	for child in grid.get_children():
		child.queue_free()
		
	if not get_node_or_null("/root/Global"): return
	
	var items = []
	
	for slot in Global.equipment.keys():
		var eq_id = Global.equipment[slot]
		if eq_id != "":
			items.append({"id": eq_id, "count": 1, "is_equipped": true, "quickslot": -1})
			
	for item_id in Global.inventory.keys():
		var count = Global.inventory[item_id]
		if count > 0:
			var q_slot = -1
			for j in range(4):
				if Global.quick_items[j] == item_id:
					q_slot = j
					break
			items.append({"id": item_id, "count": count, "is_equipped": false, "quickslot": q_slot})
			
	var item_db = get_node_or_null("/root/ItemDB")
	
	var filtered_items = []
	for item in items:
		if current_filter_tab == "Semua":
			filtered_items.append(item)
		elif item_db:
			var data = item_db.get_item(item.id)
			var type = data.get("type", "consumable")
			if current_filter_tab == "Consumable" and type == "consumable":
				filtered_items.append(item)
			elif current_filter_tab == "Equipment" and type == "equipment":
				filtered_items.append(item)
			elif current_filter_tab == "Material" and type == "material":
				filtered_items.append(item)
			elif current_filter_tab == "Upgrade" and type == "upgrade_item":
				filtered_items.append(item)
			elif current_filter_tab == "Key Item" and type == "key_item":
				filtered_items.append(item)
				
	for i in range(24): # 3 rows of 8
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		
		if i < filtered_items.size():
			var item = filtered_items[i]
			var full_name = item.id.capitalize()
			var type_desc = "Consumable"
			var item_desc = ""
			
			var rarity_desc = "Common"
			var rarity_color = Color(0.2, 0.2, 0.2, 0.8)
			
			var is_wrong_class = false
			if item_db:
				var data = item_db.get_item(item.id)
				if data:
					if data.has("name"): full_name = data["name"]
					if data.has("description"): item_desc = data["description"]
					if data.has("rarity"):
						rarity_desc = data["rarity"].capitalize()
						rarity_color = item_db.get_rarity_color(data["rarity"])
					
					if data.has("type"):
						type_desc = data["type"].capitalize()
						if type_desc == "Equipment" and data.has("equipment_slot"):
							type_desc = "Equipment (" + data["equipment_slot"].capitalize().replace("_", " ") + ")"
							
					if data.get("type", "") == "equipment":
						var w_type = data.get("weapon_type", "None")
						if w_type != "None":
							var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
							var allowed_weapons = []
							match cls:
								"fighter": allowed_weapons = ["long_sword", "sword", "gloves", "lance"]
								"apprentice": allowed_weapons = ["staff", "rod"]
								"scout": allowed_weapons = ["long_bow", "crossbow", "dagger"]
							
							if not w_type in allowed_weapons:
								is_wrong_class = true
								var req_cls = "Fighter"
								if w_type in ["staff", "rod"]: req_cls = "Apprentice"
								if w_type in ["long_bow", "crossbow", "dagger"]: req_cls = "Scout"
								item_desc += "\n\n(Senjata khusus " + req_cls + ")"
					
				var tex = item_db.get_item_icon(item.id)
				if tex:
					btn.icon = tex
					btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
					btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
					btn.expand_icon = true
					
			btn.text = ""
			btn.tooltip_text = full_name + " x" + str(item.count) + "\n[" + type_desc + " - " + rarity_desc + "]\n" + item_desc
			
			if is_wrong_class:
				var cross_lbl = Label.new()
				cross_lbl.text = "X"
				cross_lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 0.8))
				cross_lbl.add_theme_font_size_override("font_size", 32)
				cross_lbl.set_anchors_preset(Control.PRESET_CENTER)
				cross_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cross_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				cross_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
				cross_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
				btn.add_child(cross_lbl)
				btn.modulate = Color(0.6, 0.6, 0.6)
				
			var style = StyleBoxFlat.new()
			style.bg_color = rarity_color
			style.set_corner_radius_all(4)
			
			# Tambahkan border tipis kuning/biru jika di-equip/hotkey agar tetap jelas
			if item.is_equipped:
				style.set_border_width_all(2)
				style.border_color = Color(1, 0.8, 0.2)
			elif item.get("quickslot", -1) != -1:
				style.set_border_width_all(2)
				style.border_color = Color(0.5, 0.8, 1.0)
				
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			
			var lbl = Label.new()
			if not item.is_equipped and item.get("quickslot", -1) == -1:
				lbl.text = str(item.count)
			else:
				if item.is_equipped:
					lbl.text = ""
					var eq_lbl = Label.new()
					eq_lbl.text = "E"
					eq_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
					eq_lbl.add_theme_font_size_override("font_size", 14)
					eq_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
					eq_lbl.offset_left = 4
					eq_lbl.offset_top = 2
					btn.add_child(eq_lbl)
				else:
					lbl.text = str(item.count)
					var qs_lbl = Label.new()
					qs_lbl.text = str(item.quickslot)
					qs_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
					qs_lbl.add_theme_font_size_override("font_size", 14)
					qs_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
					qs_lbl.offset_left = 4
					qs_lbl.offset_top = 2
					btn.add_child(qs_lbl)
				
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
			lbl.offset_right = -4
			lbl.offset_bottom = -2
			btn.add_child(lbl)
			
			btn.pressed.connect(_on_item_click.bind(item.id, item.is_equipped, item.get("quickslot", -1), is_wrong_class))
			btn.set_drag_forwarding(Callable(self, "_get_drag_data_fw").bind(btn, item.id), Callable(), Callable())
		else:
			btn.disabled = true
			
		grid.add_child(btn)

func _on_item_click(item_id: String, is_equipped: bool = false, quickslot: int = -1, is_wrong_class: bool = false):
	current_selected_item = item_id
	current_selected_is_equipped = is_equipped
	current_selected_quickslot = quickslot
	if popup:
		popup.clear()
		
		var is_equip = false
		var is_key_or_mat = false
		var item_db = get_node_or_null("/root/ItemDB")
		if item_db:
			var data = item_db.get_item(item_id)
			var type = data.get("type", "consumable")
			if type == "equipment" and data.get("equipment_slot", "") != "":
				is_equip = true
			if type == "key_item" or type == "material":
				is_key_or_mat = true
				
		if is_equip:
			if current_selected_is_equipped:
				popup.add_item("Lepas", 4)
				popup.add_item("Batal", 5)
			else:
				if not is_wrong_class:
					popup.add_item("Pakai", 0)
				popup.add_item("Buang", 3)
				popup.add_item("Batal", 5)
		elif is_key_or_mat:
			popup.add_item("Buang", 3)
			popup.add_item("Batal", 5)
		else:
			popup.add_item("Gunakan", 0)
			popup.add_submenu_item("Pasang di Quick Slot", "SlotSubMenu")
			popup.add_item("Buang", 3)
			popup.add_item("Batal", 5)
			
		popup.position = Vector2(get_viewport().get_mouse_position().x, get_viewport().get_mouse_position().y)
		popup.popup()

func _on_popup_pressed(id: int):
	if current_selected_item == "" or not get_node_or_null("/root/Global"): return
	
	var item_db = get_node_or_null("/root/ItemDB")
	var data = {}
	if item_db: data = item_db.get_item(current_selected_item)
	var type = data.get("type", "consumable")
	
	if id == 0: # Gunakan / Pakai
		if type == "equipment":
			var eq_slot = data.get("equipment_slot", "")
			var wp_type = data.get("weapon_type", "None")
			if eq_slot == "": return
			
			if wp_type != "None":
				var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
				var allowed_weapons = []
				match cls:
					"fighter": allowed_weapons = ["long_sword", "sword", "gloves", "lance"]
					"apprentice": allowed_weapons = ["staff", "rod"]
					"scout": allowed_weapons = ["long_bow", "crossbow", "dagger"]
					
				if not wp_type in allowed_weapons:
					if player_ref and player_ref.has_method("spawn_floating_text"):
						player_ref.spawn_floating_text("Bukan senjata " + cls.capitalize() + "!", Color(1, 0.2, 0.2))
					return
			
			if eq_slot == "accessory":
				if Global.equipment.get("accessory1", "") == "":
					eq_slot = "accessory1"
				elif Global.equipment.get("accessory2", "") == "":
					eq_slot = "accessory2"
				else:
					eq_slot = "accessory1"
					
			if wp_type == "dagger" and eq_slot == "main_weapon":
				if Global.equipment.get("main_weapon", "") != "":
					if Global.equipment.get("secondary_weapon", "") == "":
						eq_slot = "secondary_weapon"
						
			var is_2h = wp_type in ["long_sword", "gloves", "lance", "staff", "long_bow"]
			
			if is_2h:
				eq_slot = "main_weapon"
				var old_sec = Global.equipment.get("secondary_weapon", "")
				if old_sec != "":
					if not Global.inventory.has(old_sec): Global.inventory[old_sec] = 0
					Global.inventory[old_sec] += 1
					Global.equipment["secondary_weapon"] = ""
			elif eq_slot == "secondary_weapon":
				var main_w = Global.equipment.get("main_weapon", "")
				if main_w != "":
					var main_data = item_db.get_item(main_w)
					var main_type = main_data.get("weapon_type", "None")
					if main_type in ["long_sword", "gloves", "lance", "staff", "long_bow"]:
						if not Global.inventory.has(main_w): Global.inventory[main_w] = 0
						Global.inventory[main_w] += 1
						Global.equipment["main_weapon"] = ""
			
			var old_equip = Global.equipment.get(eq_slot, "")
			if old_equip != "":
				if not Global.inventory.has(old_equip):
					Global.inventory[old_equip] = 0
				Global.inventory[old_equip] += 1
				
			Global.equipment[eq_slot] = current_selected_item
			Global.inventory[current_selected_item] -= 1
			
			if player_ref and player_ref.has_method("recalculate_stats"):
				player_ref.recalculate_stats()
				if player_ref.has_method("update_equipped_weapon"):
					player_ref.update_equipped_weapon()
				var hud = get_node_or_null("/root/PlayerHUD")
				if hud:
					hud._update_hp_mp_ep()
		else:
			if player_ref and player_ref.has_method("_use_quick_item"):
				var old = Global.quick_items[0]
				Global.quick_items[0] = current_selected_item
				player_ref._use_quick_item(0)
				Global.quick_items[0] = old
			
	elif id == 3: # Buang
		_show_drop_popup()
		return # Jangan refresh inventory karena masih konfirmasi
	elif id == 4: # Lepas
		if type == "equipment":
			for slot in Global.equipment.keys():
				if Global.equipment[slot] == current_selected_item:
					Global.equipment[slot] = ""
					if not Global.inventory.has(current_selected_item):
						Global.inventory[current_selected_item] = 0
					Global.inventory[current_selected_item] += 1
					break
				
				if player_ref and player_ref.has_method("recalculate_stats"):
					player_ref.recalculate_stats()
					if player_ref.has_method("update_equipped_weapon"):
						player_ref.update_equipped_weapon()
					var hud = get_node_or_null("/root/PlayerHUD")
					if hud:
						hud._update_hp_mp_ep()

		
	_refresh_inventory()

func _update_hud():
	var hud = get_node_or_null("/root/PlayerHUD")
	if hud and hud.has_method("_update_quick_items"):
		hud._update_quick_items()

func _close_menu():
	get_tree().paused = false
	queue_free()

func _unhandled_key_input(event):
	if event.is_action_pressed("open_inventory"):
		_close_menu()
		get_viewport().set_input_as_handled()

func _create_drop_popup():
	drop_popup = Panel.new()
	drop_popup.custom_minimum_size = Vector2(300, 150)
	drop_popup.set_anchors_preset(Control.PRESET_CENTER)
	drop_popup.hide()
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	drop_popup.add_child(vbox)
	
	drop_lbl_name = Label.new()
	drop_lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(drop_lbl_name)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	drop_hbox_qty = HBoxContainer.new()
	drop_hbox_qty.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(drop_hbox_qty)
	
	var lbl_qty = Label.new()
	lbl_qty.text = "Jumlah: "
	drop_hbox_qty.add_child(lbl_qty)
	
	drop_spinbox = SpinBox.new()
	drop_spinbox.min_value = 1
	drop_spinbox.step = 1
	drop_hbox_qty.add_child(drop_spinbox)
	
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)
	
	var hbox_btn = HBoxContainer.new()
	hbox_btn.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btn.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_btn)
	
	var btn_yakin = Button.new()
	btn_yakin.text = "Yakin"
	btn_yakin.custom_minimum_size = Vector2(80, 0)
	btn_yakin.pressed.connect(_on_drop_confirm)
	hbox_btn.add_child(btn_yakin)
	
	var btn_tidak = Button.new()
	btn_tidak.text = "Tidak"
	btn_tidak.custom_minimum_size = Vector2(80, 0)
	btn_tidak.pressed.connect(func(): drop_popup.hide())
	hbox_btn.add_child(btn_tidak)
	
	add_child(drop_popup)

func _show_drop_popup():
	var count = Global.inventory.get(current_selected_item, 0)
	if count <= 0: return
	
	var item_name = current_selected_item.capitalize()
	var item_db = get_node_or_null("/root/ItemDB")
	if item_db:
		var data = item_db.get_item(current_selected_item)
		if data and data.has("name"):
			item_name = data["name"]
			
	drop_lbl_name.text = "Yakin ingin membuang\n" + item_name + "?"
	
	if count > 1:
		drop_hbox_qty.show()
		drop_spinbox.max_value = count
		drop_spinbox.value = 1
	else:
		drop_hbox_qty.hide()
		drop_spinbox.value = 1
		
	drop_popup.show()

func _on_drop_confirm():
	var drop_amount = int(drop_spinbox.value)
	if Global.inventory.has(current_selected_item):
		Global.inventory[current_selected_item] -= drop_amount
		if Global.inventory[current_selected_item] <= 0:
			Global.inventory.erase(current_selected_item)
			
		if not Global.inventory.has(current_selected_item) or Global.inventory[current_selected_item] <= 0:
			if Global.quick_items[0] == current_selected_item:
				Global.quick_items[0] = ""
				_update_hud()
			if Global.quick_items[1] == current_selected_item:
				Global.quick_items[1] = ""
				_update_hud()
				
	drop_popup.hide()
	_refresh_inventory()

func _get_drag_data_fw(at_position: Vector2, btn: Control, item_id: String) -> Variant:
	var count = Global.inventory.get(item_id, 0)
	if count <= 0: return null
	
	var item_db = get_node_or_null("/root/ItemDB")
	var data = item_db.get_item(item_id) if item_db else {}
	if data.get("type", "consumable") != "consumable": return null
	
	var tex = item_db.get_item_icon(item_id) if item_db else null
	var prev = TextureRect.new()
	prev.texture = tex
	prev.modulate.a = 0.5
	var c = Control.new()
	c.add_child(prev)
	prev.position = -prev.size / 2
	btn.set_drag_preview(c)
	return item_id

func _can_drop_fw(at_position: Vector2, data: Variant, slot_idx: int) -> bool:
	return typeof(data) == TYPE_STRING

func _drop_fw(at_position: Vector2, data: Variant, slot_idx: int):
	current_selected_item = str(data)
	_on_slot_selected(slot_idx)

func _on_slot_selected(slot_idx: int):
	if current_selected_item == "": return
	Global.quick_items[slot_idx] = current_selected_item
	for i in range(4):
		if i != slot_idx and Global.quick_items[i] == current_selected_item:
			Global.quick_items[i] = ""
	_update_quick_slots_ui()
	_update_hud()
	_refresh_inventory()

func _update_quick_slots_ui():
	var item_db = get_node_or_null("/root/ItemDB")
	for i in range(4):
		var slot = get_node_or_null("Panel/QuickSlots/Slot" + str(i))
		if slot:
			var tex_rect = slot.get_node_or_null("IconRect")
			if not tex_rect:
				tex_rect = TextureRect.new()
				tex_rect.name = "IconRect"
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				tex_rect.offset_left = 2
				tex_rect.offset_top = 2
				tex_rect.offset_right = -2
				tex_rect.offset_bottom = -2
				tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(tex_rect)
			
			var lbl_count = slot.get_node_or_null("CountLabel")
			if not lbl_count:
				lbl_count = Label.new()
				lbl_count.name = "CountLabel"
				lbl_count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
				lbl_count.add_theme_font_size_override("font_size", 12)
				lbl_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				lbl_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				lbl_count.offset_right = -2
				lbl_count.offset_bottom = 2
				lbl_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
				slot.add_child(lbl_count)
			
			var iid = Global.quick_items[i]
			if iid == "" or Global.inventory.get(iid, 0) <= 0:
				tex_rect.texture = null
				lbl_count.text = ""
			else:
				if item_db:
					tex_rect.texture = item_db.get_item_icon(iid)
				lbl_count.text = str(Global.inventory.get(iid, 0))

func _on_quick_slot_gui_input(event: InputEvent, slot_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.quick_items[slot_idx] != "":
			current_selected_slot = slot_idx
			unequip_popup.position = Vector2(get_viewport().get_mouse_position().x, get_viewport().get_mouse_position().y)
			unequip_popup.popup()

func _on_unequip_popup_pressed(id: int):
	if id == 0:
		if current_selected_slot != -1:
			Global.quick_items[current_selected_slot] = ""
			_update_quick_slots_ui()
			_update_hud()
			_refresh_inventory()
			current_selected_slot = -1
	elif id == 1:
		current_selected_slot = -1
