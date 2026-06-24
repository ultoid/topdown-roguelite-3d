extends CharacterBody3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

@export var speed: float = 0.8
@export var max_health: int = 50
@export var damage: int = 10
@export_enum("netral", "api", "air", "tanah", "udara", "listrik", "es", "besi", "suara", "cahaya", "kegelapan") var element: String = "netral"
@export var exp_reward: int = 10

@export var chase_radius: float = 1.5
@export var lose_interest_radius: float = 2.5
var is_chasing: bool = false

var current_health: int
var player: Node3D = null
var knockback_velocity: Vector3 = Vector3.ZERO
var attack_cooldown: float = 1.5
var spawn_position: Vector3 = Vector3.ZERO
var attack_state: String = "idle"
var lunge_timer: float = 0.0
var lunge_direction: Vector3 = Vector3.ZERO
var status_manager: StatusEffectManager = null
var hp_bar: ProgressBar = null

@onready var hurtbox = get_node_or_null("Hurtbox")

func _ready():
	status_manager = StatusEffectManager.new()
	add_child(status_manager)
	status_manager.setup(self)
	current_health = max_health
	
	var sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(100, 15)
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = max_health
	hp_bar.value = current_health
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(100, 15)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.8, 0.1, 0.1, 1.0)
	hp_bar.add_theme_stylebox_override("background", sb_bg)
	hp_bar.add_theme_stylebox_override("fill", sb_fg)
	
	sub_viewport.add_child(hp_bar)
	add_child(sub_viewport)
	
	var hp_sprite = Sprite3D.new()
	hp_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_sprite.position = Vector3(0, 1.5, 0) # Di atas kepala
	hp_sprite.texture = sub_viewport.get_texture()
	hp_sprite.no_depth_test = true
	hp_sprite.pixel_size = 0.01
	add_child(hp_sprite)
	spawn_position = global_position # Ingat posisi lahir/awal
	# Masukkan musuh ke grup Enemy agar bisa diserang pedang
	add_to_group("Enemy")
	
	# Cari player di dalam scene
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
		
	# Prioritaskan gerakan pantulan (knockback) jika sedang terpental
	if knockback_velocity != Vector3.ZERO:
		velocity = knockback_velocity
		# Kurangi kecepatan pantulan seiring waktu (efek gesekan)
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 6.0 * delta)
	else:
		if status_manager and not status_manager.can_move():
			velocity = Vector3.ZERO
		else:
			if player:
				var distance = global_position.distance_to(player.global_position)
				var actual_chase_radius = chase_radius
				if status_manager and status_manager.has_effect("blind"):
					actual_chase_radius = chase_radius * 0.2
				if player.get("status_manager") and player.status_manager.has_effect("shadow_walk"):
					actual_chase_radius = -1.0
					is_chasing = false
					
				# Logika Aggro (Sensor Jarak)
				if not is_chasing and distance <= actual_chase_radius:
					is_chasing = true
				elif is_chasing and distance >= lose_interest_radius:
					is_chasing = false
					
				if attack_state == "idle":
					var direction = Vector3.ZERO
					var is_moving = false
					
					if is_chasing:
						if distance > 2.0:
							direction = (player.global_position - global_position).normalized()
							is_moving = true
						elif distance <= 2.0:
							is_moving = false
							# In range to attack!
							if attack_cooldown <= 0.0 and (not status_manager or status_manager.can_attack()):
								attack_state = "lunging"
								lunge_timer = 0.25
								# Arah lunge persis menuju player (abaikan Y)
								lunge_direction = (player.global_position - global_position)
								lunge_direction.y = 0
								lunge_direction = lunge_direction.normalized()
					else:
						var dist_to_spawn = global_position.distance_to(spawn_position)
						if dist_to_spawn > 5.0:
							direction = (spawn_position - global_position).normalized()
							is_moving = true
					
					if is_moving:
						if status_manager: direction = status_manager.get_override_movement(direction)
						var move_speed = speed
						if status_manager: move_speed *= status_manager.get_speed_multiplier()
						if not is_chasing: move_speed *= 0.8
						velocity = direction * move_speed
						# Hadapkan musuh ke arah gerakan
						var look_target = global_position + Vector3(direction.x, 0, direction.z)
						if look_target.distance_to(global_position) > 0.01:
							var visuals = get_node_or_null("Visuals")
							if visuals:
								visuals.look_at(look_target, Vector3.UP)
								visuals.rotation.x = 0
								visuals.rotation.z = 0
					else:
						velocity = Vector3.ZERO
						# Tetap menatap player jika diam dan mengejar
						if is_chasing:
							var look_target = global_position + Vector3(player.global_position.x - global_position.x, 0, player.global_position.z - global_position.z)
							if look_target.distance_to(global_position) > 0.01:
								var visuals = get_node_or_null("Visuals")
								if visuals:
									visuals.look_at(look_target, Vector3.UP)
									visuals.rotation.x = 0
									visuals.rotation.z = 0
									
				elif attack_state == "lunging":
					var move_speed = speed * 5.0
					if status_manager: move_speed *= status_manager.get_speed_multiplier()
					velocity = lunge_direction * move_speed
					
					lunge_timer -= delta
					
					var current_dist = global_position.distance_to(player.global_position)
					if current_dist <= 1.2 and not player.is_dead:
						player.take_damage(damage, global_position, element)
						attack_state = "returning"
						lunge_timer = 1.0
						velocity = Vector3.ZERO
					elif lunge_timer <= 0:
						attack_state = "returning"
						lunge_timer = 1.0 # Timeout saat kembali mundur
				
				elif attack_state == "returning":
					var dir_away = (global_position - player.global_position)
					dir_away.y = 0
					dir_away = dir_away.normalized()
					
					var move_speed = speed * 2.5
					if status_manager: move_speed *= status_manager.get_speed_multiplier()
					velocity = dir_away * move_speed
					
					lunge_timer -= delta
					if distance >= 2.0 or lunge_timer <= 0:
						attack_state = "idle"
						var atk_speed_mult = 1.0
						if status_manager: atk_speed_mult = status_manager.get_attack_speed_multiplier()
						attack_cooldown = 1.0 / atk_speed_mult
						velocity = Vector3.ZERO
						
	move_and_slide()

func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, atk_elements: Array = ["netral"], kb_force: float = 3.464):
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
	
	var dmg_color = Color(1, 1, 1) # Putih
	if multiplier > 1.0: dmg_color = Color(1, 0.2, 0.2) # Merah (Super Effective)
	elif multiplier < 1.0: dmg_color = Color(0.6, 0.6, 0.6) # Abu-abu (Resisted)
	
	spawn_damage_text(final_damage, dmg_color)
	
	# Hambat musuh menyerang (Interrupt / Stun ringan)
	attack_cooldown = 5.0
	if attack_state == "lunging":
		attack_state = "returning"
		lunge_timer = 1.0
		velocity = Vector3.ZERO
	
	# Kalkulasi efek pantulan (Knockback)
	if knockback_source != Vector3.ZERO:
		# Cari arah menjauh dari sumber serangan
		var knockback_direction = (global_position - knockback_source)
		knockback_direction.y = 0 # Jangan pantulkan ke atas/bawah
		knockback_direction = knockback_direction.normalized()
		# Terapkan daya pantul
		knockback_velocity = knockback_direction * kb_force
	
	if get_node_or_null("/root/Global"):
		Global.flash_red_3d(self)
		var current_scene = get_tree().current_scene
		if current_scene:
			Global.spawn_hit_spark(global_position + Vector3(0, 1.0, 0), current_scene)
	
	if current_health <= 0:
		if player and not player.is_dead:
			player.enemies_killed += 1
		drop_loot()
		queue_free()

func drop_loot():
	if not is_inside_tree(): return
	# Drop Koin (50% kesempatan)
	if randf() > 0.5:
		var coin_scene = load("res://Scenes/Items/coin.tscn")
		if coin_scene:
			var coin = coin_scene.instantiate()
			coin.position = global_position
			get_tree().current_scene.call_deferred("add_child", coin)
			
	# Drop EXP (Pasti drop 1 EXP)
	var exp_scene = load("res://Scenes/Items/exp_gem.tscn")
	if exp_scene:
		var exp_gem = exp_scene.instantiate()
		exp_gem.position = global_position
		get_tree().current_scene.call_deferred("add_child", exp_gem)

func spawn_damage_text(text_val: Variant, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.05
	label.text = str(text_val)
	label.modulate = color
	label.position = global_position + Vector3(0, 2.0, 0)
	 
	
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 3.0, 0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

# Signal ini disambungkan dari Area3D (Hurtbox musuh) ketika mengenai sesuatu
func _on_hurtbox_body_entered(body):
	# Dikosongkan karena sistem serangan diganti ke _physics_process
	pass
