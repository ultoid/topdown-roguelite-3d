extends CanvasLayer

var player_ref: Node = null

@onready var health_bar = get_node_or_null("HealthBar")
@onready var energy_bar = get_node_or_null("EnergyBar")
@onready var mana_bar = get_node_or_null("ManaBar")
@onready var exp_bar = get_node_or_null("ExpBar")
@onready var level_label = get_node_or_null("LevelLabel")

@onready var class_exp_bar = get_node_or_null("ClassExpBar")
@onready var class_level_label = get_node_or_null("ClassLevelLabel")
@onready var class_label = get_node_or_null("ClassLabel")

@onready var dash_cooldown_rect = get_node_or_null("DashIcon/DashCooldown")
@onready var heavy_cooldown_rect = get_node_or_null("HeavyIcon/HeavyCooldown")

@onready var quick_skill_labels = [
	$SkillSlot0/NameLabel,
	$SkillSlot1/NameLabel,
	$SkillSlot2/NameLabel,
	$SkillSlot3/NameLabel,
	$SkillSlot4/NameLabel,
	$SkillSlot5/NameLabel,
	$SkillSlot6/NameLabel,
	$SkillSlot7/NameLabel
]
@onready var quick_item_labels = [
	$ItemSlot0/NameLabel,
	$ItemSlot1/NameLabel,
	$ItemSlot2/NameLabel,
	$ItemSlot3/NameLabel
]

func _ready():
	
	update_class_ui()
	_set_skill_icon("DashIcon", "dash")
	_set_skill_icon("HeavyIcon", "heavy")



func _connect_to_player():
	if not is_instance_valid(player_ref): return
	
	if not player_ref.health_changed.is_connected(_on_health_changed):
		player_ref.health_changed.connect(_on_health_changed)
		player_ref.energy_changed.connect(_on_energy_changed)
		player_ref.mana_changed.connect(_on_mana_changed)
		player_ref.exp_changed.connect(_on_exp_changed)
		
	_on_health_changed(player_ref.current_health, player_ref.max_health)
	_on_energy_changed(player_ref.current_energy, player_ref.max_energy)
	_on_mana_changed(player_ref.current_mana, player_ref.max_mana)
	_on_exp_changed(player_ref.current_exp, player_ref.max_exp, player_ref.level)
	
	if has_node("StatusIconManager") and player_ref.get("status_manager"):
		$StatusIconManager.setup(player_ref.status_manager)
		
	update_class_ui()

func _set_skill_icon(node_path: String, skill_id: String):
	var node = get_node_or_null(node_path)
	if not node: return
	
	# Hapus label text karena sudah pakai icon
	var lbl = node.get_node_or_null(node_path.replace("Icon", "Label"))
	if lbl: lbl.queue_free()
	
	# Samakan warna background dengan skill slot
	if node is ColorRect:
		node.color = Color(0.1, 0.1, 0.1, 0.8)
	
	var skill_db = get_node_or_null("/root/SkillDB")
	if not skill_db: return
	
	var tex = skill_db.get_skill_icon(skill_id)
	if not tex: return
	
	if node is TextureRect:
		node.texture = tex
	else:
		var tex_rect = node.get_node_or_null("IconRect")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "IconRect"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			tex_rect.offset_left = 2
			tex_rect.offset_top = 2
			tex_rect.offset_right = -2
			tex_rect.offset_bottom = -2
			node.add_child(tex_rect)
			node.move_child(tex_rect, 0)
		tex_rect.texture = tex




func _process(delta):
	if not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player_ref = players[0]
			_connect_to_player()
			
	if player_ref:
		if dash_cooldown_rect:
			var dash_lbl = dash_cooldown_rect.get_parent().get_node_or_null("CdText")
			if not dash_lbl:
				dash_lbl = Label.new()
				dash_lbl.name = "CdText"
				dash_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
				dash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				dash_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				dash_lbl.add_theme_font_size_override("font_size", 16)
				dash_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
				dash_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
				dash_lbl.add_theme_constant_override("outline_size", 4)
				dash_cooldown_rect.get_parent().add_child(dash_lbl)
			
			if player_ref.current_dash_cooldown > 0:
				var p = player_ref.current_dash_cooldown / player_ref.dash_cooldown
				dash_cooldown_rect.size.y = p * 50.0
				dash_lbl.text = "%.1f" % player_ref.current_dash_cooldown
				dash_lbl.visible = true
			else:
				dash_cooldown_rect.size.y = 0
				dash_lbl.visible = false
				
		if heavy_cooldown_rect:
			var heavy_lbl = heavy_cooldown_rect.get_parent().get_node_or_null("CdText")
			if not heavy_lbl:
				heavy_lbl = Label.new()
				heavy_lbl.name = "CdText"
				heavy_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
				heavy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				heavy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				heavy_lbl.add_theme_font_size_override("font_size", 16)
				heavy_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
				heavy_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
				heavy_lbl.add_theme_constant_override("outline_size", 4)
				heavy_cooldown_rect.get_parent().add_child(heavy_lbl)
				
			if player_ref.charge_attack_cooldown > 0:
				var p = player_ref.charge_attack_cooldown / 2.0
				heavy_cooldown_rect.size.y = p * 50.0
				heavy_lbl.text = "%.1f" % player_ref.charge_attack_cooldown
				heavy_lbl.visible = true
			else:
				heavy_cooldown_rect.size.y = 0
				heavy_lbl.visible = false
				
		for i in range(8):
			var skill_id = Global.quick_skills[i]
			var slot_node = get_node_or_null("SkillSlot" + str(i))
			if slot_node:
				var cooldown_rect = slot_node.get_node_or_null("CooldownRect")
				var cd_lbl = slot_node.get_node_or_null("CdText")
				
				if skill_id != "":
					if not cooldown_rect:
						cooldown_rect = ColorRect.new()
						cooldown_rect.name = "CooldownRect"
						cooldown_rect.color = Color(0, 0, 0, 0.6)
						cooldown_rect.anchor_right = 1.0
						cooldown_rect.anchor_bottom = 1.0
						cooldown_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
						slot_node.add_child(cooldown_rect)
						
					if not cd_lbl:
						cd_lbl = Label.new()
						cd_lbl.name = "CdText"
						cd_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
						cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						cd_lbl.add_theme_font_size_override("font_size", 16)
						cd_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
						cd_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
						cd_lbl.add_theme_constant_override("outline_size", 4)
						slot_node.add_child(cd_lbl)
					
					var cd = player_ref.active_skill_cooldowns.get(skill_id, 0.0)
					if cd > 0:
						cooldown_rect.visible = true
						cd_lbl.text = "%.1f" % cd
						cd_lbl.visible = true
					else:
						cooldown_rect.visible = false
						cd_lbl.visible = false
				else:
					if cooldown_rect: cooldown_rect.visible = false
					if cd_lbl: cd_lbl.visible = false
	
	_update_quick_items()
	_update_quick_skills()

func _update_quick_items():
	if not get_node_or_null("/root/Global"): return
	var item_db = get_node_or_null("/root/ItemDB")
	
	for i in range(4):
		var item_id = Global.quick_items[i]
		var slot_node = get_node("ItemSlot" + str(i))
		
		var tex_rect = slot_node.get_node_or_null("IconRect")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "IconRect"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			slot_node.add_child(tex_rect)
			slot_node.move_child(tex_rect, 0)
			
		if tex_rect:
			tex_rect.offset_left = 2
			tex_rect.offset_top = 2
			tex_rect.offset_right = -2
			tex_rect.offset_bottom = -2
			
		var hotkey_lbl = slot_node.get_node_or_null("HotkeyLabel")
		if hotkey_lbl:
			hotkey_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
			hotkey_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			
		var count_lbl = quick_item_labels[i]
		if count_lbl:
			count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			
		if item_id == "" or Global.inventory.get(item_id, 0) <= 0:
			quick_item_labels[i].text = ""
			if tex_rect: tex_rect.texture = null
		else:
			var count = Global.inventory.get(item_id, 0)
			if item_db:
				tex_rect.texture = item_db.get_item_icon(item_id)
			quick_item_labels[i].text = str(count)

func _update_quick_skills():
	if not get_node_or_null("/root/Global"): return
	var skill_db = get_node_or_null("/root/SkillDB")
	
	for i in range(8):
		var skill_id = Global.quick_skills[i]
		var slot_node = get_node_or_null("SkillSlot" + str(i))
		if not slot_node: continue
		
		var tex_rect = slot_node.get_node_or_null("IconRect")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "IconRect"
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			tex_rect.offset_left = 2
			tex_rect.offset_top = 2
			tex_rect.offset_right = -2
			tex_rect.offset_bottom = -2
			slot_node.add_child(tex_rect)
			slot_node.move_child(tex_rect, 0)
			
		var hotkey_lbl = slot_node.get_node_or_null("HotkeyLabel")
		if hotkey_lbl:
			hotkey_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			hotkey_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hotkey_lbl.offset_right = -2
			
		if skill_id == "":
			quick_skill_labels[i].text = ""
			if tex_rect: tex_rect.texture = null
		else:
			var skill_name = ""
			if skill_db:
				var tex = skill_db.get_skill_icon(skill_id)
				if tex_rect: tex_rect.texture = tex
				
				# Hanya tampilkan nama jika tidak ada icon
				if not tex:
					var data = skill_db.get_skill(skill_id)
					if data and data.has("name"):
						skill_name = data["name"].substr(0, 3)
					else:
						skill_name = skill_id.substr(0, 3).capitalize()
				
			# Cek persyaratan senjata -> gelap jika tidak terpenuhi
			const BOW_SKILLS_HUD = ["falcon_dive", "arrow_rain"]
			var weapon_locked = false
			if skill_id in BOW_SKILLS_HUD and get_node_or_null("/root/Global") and get_node_or_null("/root/ItemDB"):
				var main_w = Global.equipment.get("main_weapon", "")
				var has_bow = false
				if main_w != "":
					var w_data = ItemDB.get_item(main_w)
					if typeof(w_data) == TYPE_DICTIONARY and w_data.get("weapon_type", "None") in ["long_bow", "crossbow"]:
						has_bow = true
				weapon_locked = not has_bow
			
			if tex_rect:
				tex_rect.modulate = Color(0.3, 0.3, 0.3, 1.0) if weapon_locked else Color(1, 1, 1, 1)
			if slot_node:
				var lock_label = slot_node.get_node_or_null("LockLabel")
				if weapon_locked:
					if not lock_label:
						lock_label = Label.new()
						lock_label.name = "LockLabel"
						lock_label.text = "🔒"
						lock_label.set_anchors_preset(Control.PRESET_CENTER)
						lock_label.add_theme_font_size_override("font_size", 14)
						lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
						slot_node.add_child(lock_label)
				else:
					if lock_label: lock_label.queue_free()
				
			quick_skill_labels[i].text = skill_name

func _on_health_changed(current: int, maximum: int):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func _on_mana_changed(current: int, maximum: int):
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current

func _on_energy_changed(current: float, maximum: float):
	if energy_bar:
		energy_bar.max_value = maximum
		energy_bar.value = current


func _on_exp_changed(current: int, maximum: int, level: int):
	if exp_bar:
		exp_bar.max_value = maximum
		exp_bar.value = current
	if level_label:
		level_label.text = "Lv." + str(level)
		
	update_class_ui()

func _update_hp_mp_ep():
	if not is_instance_valid(player_ref): return
	_on_health_changed(player_ref.current_health, player_ref.max_health)
	_on_energy_changed(player_ref.current_energy, player_ref.max_energy)
	_on_mana_changed(player_ref.current_mana, player_ref.max_mana)

func update_class_ui():
	if get_node_or_null("/root/Global"):
		var cls = Global.current_class
		if cls == "":
			if class_label: class_label.text = "Class: None"
			if class_exp_bar:
				class_exp_bar.max_value = 1
				class_exp_bar.value = 0
			if class_level_label:
				class_level_label.text = "No Class"
			return
			
		if class_label: class_label.text = "Class: " + cls.capitalize()
		if class_exp_bar:
			class_exp_bar.max_value = Global.class_max_exp[cls]
			class_exp_bar.value = Global.class_exp[cls]
		if class_level_label:
			class_level_label.text = cls.capitalize() + " Lv." + str(Global.class_levels[cls])
