extends CharacterBody3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

signal health_changed(current, maximum)
signal boss_died

@export var speed: float = 0.6
@export var max_health: int = 200
@export var damage: int = 15
@export_enum("netral", "api", "air", "tanah", "udara", "listrik", "es", "besi", "suara", "cahaya", "kegelapan") var element: String = "netral"
@export var chase_radius: float = 8.0
@export var boss_name: String = "The Skeleton King"

var current_health: int
var hp_bar: ProgressBar = null
var knockback_velocity: Vector3 = Vector3.ZERO

var is_chasing: bool = false
var shoot_timer: float = 0.0
var state: String = "CHASE" # CHASE atau SHOOT

var player: Node3D

@onready var sprite = $MeshInstance3D
@onready var projectile_scene = preload("res://Scenes/Skills/enemy_projectile.tscn")

var status_manager: StatusEffectManager = null

func _ready():
	status_manager = StatusEffectManager.new()
	add_child(status_manager)
	status_manager.setup(self)
	
	current_health = max_health
	
	var sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(120, 18) # Sedikit lebih besar
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(120, 18)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.8, 0.1, 0.1, 1.0) # Merah darah
	hp_bar.add_theme_stylebox_override("background", sb_bg)
	hp_bar.add_theme_stylebox_override("fill", sb_fg)
	
	sub_viewport.add_child(hp_bar)
	add_child(sub_viewport)
	
	var hp_sprite = Sprite3D.new()
	hp_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_sprite.position = Vector3(0, 3.5, 0) # Posisi lebih tinggi untuk bos
	hp_sprite.texture = sub_viewport.get_texture()
	hp_sprite.no_depth_test = true
	hp_sprite.pixel_size = 0.015 # Skala lebih besar
	add_child(hp_sprite)
	
	add_to_group("Enemy")
	add_to_group("Boss")
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		
	_update_hud()

func _update_hud():
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	if knockback_velocity != Vector3.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 0.1)
		if knockback_velocity.length() < 0.1:
			knockback_velocity = Vector3.ZERO
		move_and_slide()
		return
		
	if player and not player.is_dead:
		var dist = global_position.distance_to(player.global_position)
		
		if dist <= chase_radius:
			is_chasing = true
		elif dist > chase_radius + 2.0:
			is_chasing = false
			
		if is_chasing:
			shoot_timer -= delta
			
			if state == "CHASE":
				var dir = (player.global_position - global_position).normalized()
				if status_manager: dir = status_manager.get_override_movement(dir)
				
				var move_speed = speed
				if status_manager: move_speed *= status_manager.get_speed_multiplier()
				
				velocity = dir * move_speed
				if velocity != Vector3.ZERO:
					var target_angle = atan2(-velocity.z, velocity.x)
					sprite.rotation.y = lerp_angle(sprite.rotation.y, target_angle - PI/2.0, 10.0 * delta)
					
				# Berhenti dan tembak setiap 4 detik
				if shoot_timer <= 0:
					if not status_manager or status_manager.can_attack():
						state = "SHOOT"
						velocity = Vector3.ZERO
						var atk_mult = 1.0
						if status_manager: atk_mult = status_manager.get_attack_speed_multiplier()
						shoot_timer = 1.0 / atk_mult # Waktu diam saat menembak
						call_deferred("shoot_bullet_hell")
			
			elif state == "SHOOT":
				# Diam di tempat selama 1 detik (animasi menembak)
				velocity = Vector3.ZERO
				if shoot_timer <= 0:
					state = "CHASE"
					var atk_mult = 1.0
					if status_manager: atk_mult = status_manager.get_attack_speed_multiplier()
					shoot_timer = 4.0 / atk_mult # Kembali mengejar selama 4 detik
		else:
			velocity = Vector3.ZERO
			
		if status_manager and not status_manager.can_move():
			velocity = Vector3.ZERO
				
	move_and_slide()

func shoot_bullet_hell():
	if not projectile_scene: return
	print("Boss mengeluarkan Bullet Hell 8 Arah!")
	
	var num_bullets = 8
	for i in range(num_bullets):
		var angle = (PI * 2 / num_bullets) * i
		var dir = Vector3(cos(angle), 0, sin(angle))
		
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = dir
		proj.z_index = 5
		get_tree().current_scene.call_deferred("add_child", proj)

func _on_hurtbox_body_entered(body):
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position, element)
		knockback_velocity = (global_position - body.global_position).normalized() * 3.0

func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, atk_elements: Array = ["netral"]):
	var multiplier = 1.0
	if get_node_or_null("/root/Global"):
		multiplier = Global.get_element_multiplier(atk_elements, element)
		
	var final_damage = int(amount * multiplier)
	
	if final_damage <= 0 and multiplier == 0.0:
		spawn_damage_text("Immune!", Color(0.8, 0.8, 0.8))
		return
		
	if status_manager:
		final_damage = int(final_damage * status_manager.get_damage_taken_multiplier())
		if status_manager.has_effect("hex"):
			var hex_data = status_manager.get_effect_data("hex")
			var mdef_red = hex_data.get("mdef_reduction", 0)
			final_damage += int(final_damage * (mdef_red / 100.0))
		status_manager.handle_damage_taken()
		
	current_health -= final_damage
	if is_instance_valid(hp_bar):
		hp_bar.value = current_health
	_update_hud()
	
	var dmg_color = Color(1, 0.84, 0) # Emas untuk boss default
	if multiplier > 1.0: dmg_color = Color(1, 0.2, 0.2) # Merah (Super Effective)
	elif multiplier < 1.0: dmg_color = Color(0.6, 0.6, 0.6) # Abu-abu (Resisted)
	
	spawn_damage_text(final_damage, dmg_color)
	
	if knockback_source != Vector3.ZERO:
		var knockback_direction = (global_position - knockback_source).normalized()
		knockback_velocity = knockback_direction * 0.5 # Boss susah dipantulkan
	
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 0.5, 0.5) # Kembali ke warna aslinya
	
	if current_health <= 0:
		var hud = get_tree().current_scene.get_node_or_null("BossHUD")
		if hud:
			hud.queue_free()
			
		if player and not player.is_dead:
			player.enemies_killed += 1
			
		# Panggil UI Hadiah Boss (Buff Shop)
		var buff_shop_scene = load("res://Scenes/UI/buff_shop_menu.tscn")
		if buff_shop_scene:
			var shop = buff_shop_scene.instantiate()
			# Tambahkan ke parent tertinggi agar tidak ikut hancur saat boss queue_free
			get_tree().current_scene.add_child(shop)
			shop.setup(player)
			
		emit_signal("boss_died")
		drop_loot()
		queue_free()

func drop_loot():
	if not is_inside_tree(): return
	# Boss menjatuhkan banyak hadiah
	for i in range(5):
		var coin_scene = load("res://Scenes/Items/coin.tscn")
		if coin_scene:
			var coin = coin_scene.instantiate()
			coin.global_position = global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
			get_tree().current_scene.call_deferred("add_child", coin)
			
	for i in range(3):
		var exp_scene = load("res://Scenes/Items/exp_gem.tscn")
		if exp_scene:
			var exp_gem = exp_scene.instantiate()
			exp_gem.global_position = global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
			get_tree().current_scene.call_deferred("add_child", exp_gem)

func spawn_damage_text(text_val: Variant, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.05
	label.text = str(text_val)
	label.modulate = color
	label.global_position = global_position + Vector3(randf_range(-20, 20), 0, -40)
	
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0, -40), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)
