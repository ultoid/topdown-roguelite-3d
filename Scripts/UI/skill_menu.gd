extends CanvasLayer

var player_ref: Node3D = null

@onready var panel = get_node_or_null("Panel")
@onready var btn_close = get_node_or_null("Panel/BtnClose")
@onready var popup = get_node_or_null("SkillPopup")

var tree_container: Control = null
var current_selected_skill: String = ""
var current_selected_slot: int = -1
var unequip_popup: PopupMenu = null
var skill_buttons = {}

# Edit Phase States
var is_edit_phase: bool = false
var temp_sp: int = 0
var temp_unlocked_skills: Dictionary = {}

var tooltip_panel: PanelContainer = null
var tooltip_label: RichTextLabel = null
var btn_confirm: Button = null
var btn_cancel: Button = null

const POSITIONS = {
	"dash": Vector2(50, 50),
	"heavy": Vector2(50, 150),
	
	"weapon_mastery": Vector2(250, 250),
	"vitality_mastery": Vector2(250, 350),
	
	"cyclone_sweep": Vector2(450, 50),
	"fatal_blow": Vector2(450, 150),
	"impact_wave": Vector2(450, 250),
	"endure": Vector2(450, 350),
	"provoke": Vector2(450, 450),
	
	"fatal_smash": Vector2(650, 150),
	"implosion": Vector2(650, 450),
	
	"elemental_mastery": Vector2(250, 150),
	"spell_mastery": Vector2(250, 350),
	
	"aqua_blast": Vector2(450, 50),
	"fire_bolt": Vector2(450, 150),
	"sonic_boom": Vector2(450, 250),
	"heal": Vector2(450, 350),
	"hex": Vector2(450, 450),
	
	"seismic_fissure": Vector2(650, 150),
	"holy_veil": Vector2(650, 350),
	"soul_drain": Vector2(650, 450),
	
	"hunters_mark": Vector2(450, 50),
	"falcon_dive": Vector2(650, 50),
	"arrow_rain": Vector2(850, 50),
	
	"agility_mastery": Vector2(250, 150),
	"haste": Vector2(450, 150),
	"mirage_strike": Vector2(650, 150),
	
	"fortunes_eye": Vector2(250, 250),
	
	"shadow_walk": Vector2(450, 300),
	"thief": Vector2(650, 250),
	"phantom_strike": Vector2(650, 350),
	"phantom_flurry": Vector2(850, 350),
	
	"poison_weapon": Vector2(650, 450)
}

const CONNECTIONS = [
	["fatal_blow", "fatal_smash"],
	["vitality_mastery", "endure"],
	["provoke", "implosion"],
	
	["elemental_mastery", "aqua_blast"],
	["elemental_mastery", "fire_bolt"],
	["elemental_mastery", "sonic_boom"],
	["heal", "holy_veil"],
	["hex", "soul_drain"],
	
	["hunters_mark", "falcon_dive"],
	["falcon_dive", "arrow_rain"],
	
	["agility_mastery", "haste"],
	["haste", "mirage_strike"],
	
	["shadow_walk", "thief"],
	["shadow_walk", "phantom_strike"],
	["phantom_strike", "phantom_flurry"]
]

class TreeDrawer extends Control:
	var connections = []
	var buttons = {}
	func _draw():
		for conn in connections:
			var parent_id = conn[0]
			var child_id = conn[1]
			if buttons.has(parent_id) and buttons.has(child_id):
				var p1 = buttons[parent_id].position + buttons[parent_id].size / 2
				var p2 = buttons[child_id].position + buttons[child_id].size / 2
				p1.x += buttons[parent_id].size.x / 2
				p2.x -= buttons[child_id].size.x / 2
				draw_line(p1, p2, Color(0.8, 0.6, 0.2, 0.6), 3.0, true)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if btn_close:
		btn_close.text = "X"
		btn_close.position = Vector2(750, 10)
		btn_close.size = Vector2(40, 40)
		btn_close.pressed.connect(_close_menu)
		
	if popup:
		popup.clear()
		
		var sub_menu = popup.get_node_or_null("SlotSubMenu")
		if not sub_menu:
			sub_menu = PopupMenu.new()
			sub_menu.name = "SlotSubMenu"
			popup.add_child(sub_menu)
		
		sub_menu.clear()
		for i in range(1, 9):
			sub_menu.add_item("Pasang ke Slot " + str(i), i)
		if not sub_menu.id_pressed.is_connected(_on_slot_selected):
			sub_menu.id_pressed.connect(_on_slot_selected)
			
		popup.add_submenu_item("Pasang di Quick Slot", "SlotSubMenu")
		popup.add_item("Lepas dari Slot", 9)
		popup.add_item("Batal", 10)
		if not popup.id_pressed.is_connected(_on_popup_pressed):
			popup.id_pressed.connect(_on_popup_pressed)
			
	unequip_popup = PopupMenu.new()
	unequip_popup.name = "UnequipPopup"
	unequip_popup.add_item("Lepas", 0)
	unequip_popup.add_item("Batal", 1)
	unequip_popup.id_pressed.connect(_on_unequip_popup_pressed)
	add_child(unequip_popup)
	
	for i in range(8):
		var slot = get_node_or_null("Panel/QuickSlots/Slot" + str(i))
		if slot:
			slot.set_drag_forwarding(Callable(), Callable(self, "_can_drop_fw").bind(i), Callable(self, "_drop_fw").bind(i))
			if not slot.gui_input.is_connected(_on_quick_slot_gui_input):
				slot.gui_input.connect(_on_quick_slot_gui_input.bind(i))
	
	_update_quick_slots_ui()
		
	if panel:
		var old_grid = panel.get_node_or_null("Grid")
		if old_grid: old_grid.hide()
		var old_title = panel.get_node_or_null("Title")
		if old_title: old_title.hide()
		
		var scroll = ScrollContainer.new()
		scroll.name = "SkillScroll"
		scroll.position = Vector2(20, 60)
		scroll.size = Vector2(760, 410)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		
		tree_container = TreeDrawer.new()
		tree_container.custom_minimum_size = Vector2(1500, 800)
		tree_container.connections = CONNECTIONS
		tree_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		scroll.add_child(tree_container)
		panel.add_child(scroll)
		
		var sp_lbl = Label.new()
		sp_lbl.name = "SPLabel"
		sp_lbl.add_theme_font_size_override("font_size", 24)
		sp_lbl.position = Vector2(20, 20)
		sp_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.add_child(sp_lbl)
		
		# Buttons for Edit Phase
		btn_confirm = Button.new()
		btn_confirm.text = "Konfirmasi"
		btn_confirm.position = Vector2(650, 550)
		btn_confirm.size = Vector2(120, 40)
		btn_confirm.pressed.connect(_on_confirm)
		btn_confirm.hide()
		panel.add_child(btn_confirm)
		
		btn_cancel = Button.new()
		btn_cancel.text = "Batal"
		btn_cancel.position = Vector2(520, 550)
		btn_cancel.size = Vector2(120, 40)
		btn_cancel.pressed.connect(_on_cancel)
		btn_cancel.hide()
		panel.add_child(btn_cancel)
		
		# Tooltip
		tooltip_panel = PanelContainer.new()
		tooltip_panel.hide()
		tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip_panel.modulate = Color(1, 1, 1, 0.9)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.6, 0.4, 0.1)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		tooltip_panel.add_theme_stylebox_override("panel", style)
		
		tooltip_label = RichTextLabel.new()
		tooltip_label.custom_minimum_size = Vector2(230, 0)
		tooltip_label.bbcode_enabled = true
		tooltip_label.fit_content = true
		tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip_panel.add_child(tooltip_label)
		
		# Panel as topmost CanvasLayer child to avoid clipping
		add_child(tooltip_panel)

func _process(delta):
	if tooltip_panel and tooltip_panel.visible:
		var mp = get_viewport().get_mouse_position()
		tooltip_panel.position = mp + Vector2(15, 15)

func setup(p: Node3D):
	player_ref = p
	is_edit_phase = false
	_refresh_skills()

func _refresh_skills():
	if not tree_container: return
	
	var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
	
	if not is_edit_phase:
		temp_sp = Global.class_skill_points.get(cls, 0)
		temp_unlocked_skills = Global.unlocked_skills.duplicate()
		btn_confirm.hide()
		btn_cancel.hide()
	else:
		btn_confirm.show()
		btn_cancel.show()
		
	var splbl = panel.get_node_or_null("SPLabel")
	if splbl:
		if is_edit_phase:
			splbl.text = "Class: %s | Skill Points: %d (Edit Mode)" % [cls.capitalize(), temp_sp]
		else:
			splbl.text = "Class: %s | Skill Points: %d" % [cls.capitalize(), temp_sp]
		
	for c in tree_container.get_children():
		c.queue_free()
	skill_buttons.clear()
		
	var all_skills = POSITIONS.keys()
	
	for skill_id in all_skills:
		var data = SkillDB.get_skill(skill_id)
		if data.is_empty(): continue
		if data.get("class_owner", "fighter").to_lower() != cls.to_lower() and skill_id not in ["dash", "heavy"]: continue
		
		var max_lvl = data.get("max_level", 1)
		var base_lvl = Global.unlocked_skills.get(skill_id, 0)
		if skill_id in ["dash", "heavy"] and base_lvl == 0:
			Global.unlocked_skills[skill_id] = 1
			temp_unlocked_skills[skill_id] = 1
			base_lvl = 1
			
		var cur_lvl = temp_unlocked_skills.get(skill_id, 0)
		
		var req_skill = data.get("prerequisite_skill", "")
		var req_lvl = data.get("prerequisite_level", 1)
		var can_unlock = true
		if req_skill != "":
			var req_cur_lvl = temp_unlocked_skills.get(req_skill, 0)
			if req_cur_lvl < req_lvl:
				can_unlock = false
				
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 60)
		btn.position = POSITIONS[skill_id]
		
		if cur_lvl > 0:
			if cur_lvl > base_lvl:
				btn.text = data["name"] + "\n[Lv. %d+/%d]" % [cur_lvl, max_lvl]
				btn.modulate = Color(0.6, 1.0, 0.6)
			else:
				btn.text = data["name"] + "\n[Lv. %d/%d]" % [cur_lvl, max_lvl]
				btn.modulate = Color(1, 1, 1)
		else:
			if can_unlock:
				btn.text = data["name"] + "\n[Locked]"
				btn.modulate = Color(0.8, 0.8, 0.8)
			else:
				btn.text = data["name"] + "\n[Req: %s Lv.%d]" % [req_skill.capitalize(), req_lvl]
				btn.modulate = Color(0.4, 0.4, 0.4)
				
		if SkillDB.has_method("get_skill_icon"):
			var tex = SkillDB.get_skill_icon(skill_id)
			if tex:
				btn.icon = tex
				btn.expand_icon = true
				
		btn.pressed.connect(_on_skill_click.bind(skill_id, cur_lvl, max_lvl))
		btn.set_drag_forwarding(Callable(self, "_get_drag_data_fw").bind(btn, skill_id), Callable(), Callable())
		btn.mouse_entered.connect(_on_skill_hover.bind(skill_id))
		btn.mouse_exited.connect(_on_skill_exit)
		skill_buttons[skill_id] = btn
		tree_container.add_child(btn)
		
		# Add + and - buttons
		var plus_btn = Button.new()
		plus_btn.text = "+"
		plus_btn.position = btn.position + Vector2(155, 0)
		plus_btn.size = Vector2(25, 25)
		plus_btn.disabled = (temp_sp <= 0 or not can_unlock or cur_lvl >= max_lvl)
		plus_btn.pressed.connect(_on_plus_pressed.bind(skill_id))
		tree_container.add_child(plus_btn)
		
		var min_btn = Button.new()
		min_btn.text = "-"
		min_btn.position = btn.position + Vector2(155, 30)
		min_btn.size = Vector2(25, 25)
		min_btn.disabled = (cur_lvl <= base_lvl)
		min_btn.pressed.connect(_on_minus_pressed.bind(skill_id))
		tree_container.add_child(min_btn)
		
	tree_container.buttons = skill_buttons
	tree_container.queue_redraw()

func _on_plus_pressed(skill_id: String):
	is_edit_phase = true
	temp_sp -= 1
	temp_unlocked_skills[skill_id] = temp_unlocked_skills.get(skill_id, 0) + 1
	_refresh_skills()

func _on_minus_pressed(skill_id: String):
	temp_sp += 1
	temp_unlocked_skills[skill_id] = temp_unlocked_skills.get(skill_id, 0) - 1
	_refresh_skills()

func _on_confirm():
	var cls = Global.current_class
	Global.class_skill_points[cls] = temp_sp
	Global.unlocked_skills = temp_unlocked_skills.duplicate()
	is_edit_phase = false
	
	if player_ref and player_ref.has_method("recalculate_stats"):
		player_ref.recalculate_stats()
	var hud = get_node_or_null("/root/PlayerHUD")
	if hud and hud.has_method("update_class_ui"):
		hud.update_class_ui()
		
	_refresh_skills()

func _on_cancel():
	is_edit_phase = false
	_refresh_skills()

func _on_skill_hover(skill_id: String):
	var data = SkillDB.get_skill(skill_id)
	if data.is_empty(): return
	var cur_lvl = temp_unlocked_skills.get(skill_id, 0)
	var max_lvl = data.get("max_level", 1)
	
	var text = "[b][color=yellow]" + data["name"] + "[/color][/b]\n"
	text += "[color=gray]Tipe: " + data.get("type", "instant").capitalize() + "[/color]\n"
	text += data["description"] + "\n\n"
	
	var display_lvl = max(1, cur_lvl)
	var idx = display_lvl - 1
	
	var dmg = data.get("damages", [])
	var cd = data.get("cooldowns", [])
	var ep = data.get("ep_costs", [])
	var ct = data.get("cast_times", [])
	var mp = data.get("mp_costs", [])
	
	text += "[color=lightblue]Stat Level %d:[/color]\n" % display_lvl
	if dmg.size() > idx and dmg[idx] > 0:
		text += "Damage: " + str(dmg[idx]) + "\n"
	if cd.size() > idx and cd[idx] > 0:
		text += "Cooldown: " + str(cd[idx]) + "s\n"
	if ct.size() > idx and ct[idx] > 0.0:
		text += "Cast Time: " + str(ct[idx]) + "s\n"
	if ep.size() > idx and ep[idx] > 0:
		text += "EP Cost: " + str(ep[idx]) + "\n"
	if mp.size() > idx and mp[idx] > 0:
		text += "MP Cost: " + str(mp[idx]) + "\n"
		
	if cur_lvl < max_lvl:
		var n_idx = display_lvl if cur_lvl > 0 else 0
		text += "\n[color=lightgreen]Next Level:[/color]\n"
		if dmg.size() > n_idx and dmg[n_idx] > 0:
			text += "Damage: " + str(dmg[n_idx]) + "\n"
		if cd.size() > n_idx and cd[n_idx] > 0:
			text += "Cooldown: " + str(cd[n_idx]) + "s\n"
		if ct.size() > n_idx and ct[n_idx] > 0.0:
			text += "Cast Time: " + str(ct[n_idx]) + "s\n"
		if mp.size() > n_idx and mp[n_idx] > 0:
			text += "MP Cost: " + str(mp[n_idx]) + "\n"
		
	tooltip_label.text = text
	tooltip_panel.show()

func _on_skill_exit():
	if tooltip_panel:
		tooltip_panel.hide()

func _on_skill_click(skill_id: String, cur_lvl: int, max_lvl: int):
	if is_edit_phase: return
	
	current_selected_skill = skill_id
	if popup:
		var data = SkillDB.get_skill(skill_id)
		var is_active = data.get("type", "") != "passive"
		
		var is_disabled = (cur_lvl == 0 or not is_active)
		popup.set_item_disabled(0, is_disabled) # Pasang di Quick Slot
		var lepas_idx = popup.get_item_index(9)
		if lepas_idx != -1:
			popup.set_item_disabled(lepas_idx, not is_active)
			
		popup.position = Vector2(get_viewport().get_mouse_position().x, get_viewport().get_mouse_position().y)
		popup.popup()

func _on_popup_pressed(id: int):
	if current_selected_skill == "": return
	
	if id == 9: # Lepas dari Slot
		for i in range(8):
			if Global.quick_skills[i] == current_selected_skill:
				Global.quick_skills[i] = ""
	
	_update_quick_slots_ui()
	var hud = get_tree().current_scene.get_node_or_null("PlayerHUD")
	if hud and hud.has_method("_update_quick_skills"):
		hud._update_quick_skills()

func _update_hud():
	var hud = get_node_or_null("/root/PlayerHUD")
	if hud and hud.has_method("_update_quick_skills"):
		hud._update_quick_skills()

func _close_menu():
	get_tree().paused = false
	queue_free()

func _unhandled_key_input(event):
	if event.is_action_pressed("open_skill_menu"):
		_close_menu()
		get_viewport().set_input_as_handled()

func _get_drag_data_fw(at_position: Vector2, btn: Control, skill_id: String) -> Variant:
	var cur_lvl = temp_unlocked_skills.get(skill_id, 0)
	if cur_lvl <= 0: return null # Hanya skill terbuka yang bisa di-drag
	
	var skill_db = get_node_or_null("/root/SkillDB")
	var data = skill_db.get_skill(skill_id) if skill_db else {}
	var type = data.get("type", "")
	if type == "passive": return null # Skill pasif tidak bisa dipasang
	
	var tex = skill_db.get_skill_icon(skill_id) if skill_db else null
	var prev = TextureRect.new()
	prev.texture = tex
	prev.modulate.a = 0.5
	var c = Control.new()
	c.add_child(prev)
	prev.position = -prev.size / 2
	btn.set_drag_preview(c)
	return skill_id

func _can_drop_fw(at_position: Vector2, data: Variant, slot_idx: int) -> bool:
	return typeof(data) == TYPE_STRING

func _drop_fw(at_position: Vector2, data: Variant, slot_idx: int):
	current_selected_skill = str(data)
	_equip_to_slot(slot_idx)

func _on_slot_selected(id: int):
	_equip_to_slot(id - 1)

func _equip_to_slot(slot_idx: int):
	if current_selected_skill == "": return
	Global.quick_skills[slot_idx] = current_selected_skill
	for i in range(8):
		if i != slot_idx and Global.quick_skills[i] == current_selected_skill:
			Global.quick_skills[i] = ""
	_update_quick_slots_ui()
	
	var hud = get_tree().current_scene.get_node_or_null("PlayerHUD")
	if hud and hud.has_method("_update_quick_skills"):
		hud._update_quick_skills()

func _update_quick_slots_ui():
	for i in range(8):
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
				slot.add_child(tex_rect)
			
			var sid = Global.quick_skills[i]
			if sid == "":
				tex_rect.texture = null
			else:
				var skill_db = get_node_or_null("/root/SkillDB")
				if skill_db:
					tex_rect.texture = skill_db.get_skill_icon(sid)

func _on_quick_slot_gui_input(event: InputEvent, slot_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.quick_skills[slot_idx] != "":
			current_selected_slot = slot_idx
			unequip_popup.position = Vector2(get_viewport().get_mouse_position().x, get_viewport().get_mouse_position().y)
			unequip_popup.popup()

func _on_unequip_popup_pressed(id: int):
	if id == 0:
		if current_selected_slot != -1:
			Global.quick_skills[current_selected_slot] = ""
			_update_quick_slots_ui()
			_update_hud()
			current_selected_slot = -1
	elif id == 1:
		current_selected_slot = -1
