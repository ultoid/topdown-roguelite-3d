extends Control

@onready var buffs_row = $VBoxContainer/BuffsRow
@onready var debuffs_row = $VBoxContainer/DebuffsRow

var target_manager = null
var skill_db = null

func _ready():
	skill_db = get_node_or_null("/root/SkillDB")

func setup(manager):
	target_manager = manager
	if not target_manager.status_changed.is_connected(update_icons):
		target_manager.status_changed.connect(update_icons)
	update_icons()

func update_icons():
	# Clear existing
	for child in buffs_row.get_children():
		child.queue_free()
	for child in debuffs_row.get_children():
		child.queue_free()
		
	if not is_instance_valid(target_manager): return
	
	var debuffs = target_manager.get_active_debuffs()
	for d in debuffs:
		_create_icon(d.id, d.duration, false)
		
	var buffs = target_manager.get_active_buffs()
	for b in buffs:
		_create_icon(b.id, b.duration, true)

func _create_icon(effect_id: String, duration: float, is_buff: bool):
	var rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(24, 24)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var sprite = get_node_or_null("Icons/" + effect_id)
	if sprite is Sprite2D and sprite.texture:
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		
		var h = sprite.hframes
		var v = sprite.vframes
		var frame = sprite.frame
		var tex_size = sprite.texture.get_size()
		
		if h > 1 or v > 1:
			var tile_w = tex_size.x / h
			var tile_h = tex_size.y / v
			var fx = frame % h
			var fy = int(frame / h)
			atlas.region = Rect2(fx * tile_w, fy * tile_h, tile_w, tile_h)
		else:
			atlas.region = Rect2(0, 0, tex_size.x, tex_size.y)
			
		rect.texture = atlas
	else:
		var bg = ColorRect.new()
		bg.set_anchors_preset(PRESET_FULL_RECT)
		if effect_id == "poison": bg.color = Color(0.2, 0.8, 0.2)
		elif effect_id == "burn": bg.color = Color(0.9, 0.4, 0.1)
		elif effect_id == "freeze": bg.color = Color(0.4, 0.8, 1.0)
		elif effect_id == "chill": bg.color = Color(0.6, 0.9, 1.0)
		elif effect_id == "bleed": bg.color = Color(0.8, 0.1, 0.1)
		elif effect_id == "paralyze": bg.color = Color(0.9, 0.9, 0.2)
		elif effect_id == "sleep": bg.color = Color(0.5, 0.5, 0.8)
		elif effect_id == "confuse": bg.color = Color(0.8, 0.2, 0.8)
		elif effect_id == "fear": bg.color = Color(0.3, 0.1, 0.4)
		elif effect_id == "curse": bg.color = Color(0.2, 0.0, 0.3)
		elif effect_id == "blind": bg.color = Color(0.1, 0.1, 0.1)
		elif effect_id == "silence": bg.color = Color(0.8, 0.4, 0.8)
		else: bg.color = Color(0.5, 0.5, 0.5)
		rect.add_child(bg)
	
	rect.tooltip_text = effect_id.capitalize()
	
	if is_buff:
		buffs_row.add_child(rect)
	else:
		debuffs_row.add_child(rect)

func _process(_delta):
	if not is_instance_valid(target_manager): return
	# Update timers or visuals if needed (e.g. cooldown sweep)
