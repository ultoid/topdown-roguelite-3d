extends CharacterBody3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

@export var speed: float = 0.7
@export var max_health: int = 30
@export var damage: int = 5
@export_enum("netral", "api", "air", "tanah", "udara", "listrik", "es", "besi", "suara", "cahaya", "kegelapan") var element: String = "netral"

@export var chase_radius: float = 3.0
@export var ideal_min_dist: float = 1.2
@export var ideal_max_dist: float = 2.0

var current_health: int
var hp_bar: ProgressBar = null
var knockback_velocity: Vector3 = Vector3.ZERO

var is_chasing: bool = false
var spawn_position: Vector3
var shoot_timer: float = 0.0

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
	
	spawn_position = global_position
	add_to_group("Enemy")
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

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
		
		var actual_chase_radius = chase_radius
		if status_manager and status_manager.has_effect("blind"):
			actual_chase_radius = chase_radius * 0.2
		if player.get("status_manager") and player.status_manager.has_effect("shadow_walk"):
			actual_chase_radius = -1.0
			is_chasing = false
			
		if dist <= actual_chase_radius:
			is_chasing = true
		elif dist > chase_radius + 100:
			is_chasing = false
			
		if is_chasing:
			var dir = (player.global_position - global_position).normalized()
			
			# Kiting Logic
			if dist > ideal_max_dist:
				velocity = dir * speed # Kejar jika terlalu jauh
			elif dist < ideal_min_dist:
				velocity = -dir * speed # Mundur jika terlalu dekat
			else:
				velocity = Vector3.ZERO # Berhenti jika jarak ideal
				
			if status_manager and velocity != Vector3.ZERO:
				velocity = status_manager.get_override_movement(velocity.normalized()) * speed
				
			if velocity != Vector3.ZERO:
				var target_angle = atan2(-velocity.z, velocity.x)
				sprite.rotation.y = lerp_angle(sprite.rotation.y, target_angle - PI/2.0, 10.0 * delta)
				
			# Shooting Logic
			shoot_timer -= delta
			if shoot_timer <= 0:
				if not status_manager or status_manager.can_attack():
					shoot_projectile(dir)
					var atk_mult = 1.0
					if status_manager: atk_mult = status_manager.get_attack_speed_multiplier()
					shoot_timer = 2.0 / atk_mult
		else:
			# Kembali ke posisi awal jika player kabur
			if global_position.distance_to(spawn_position) > 0.5:
				var dir = (spawn_position - global_position).normalized()
				velocity = dir * speed
				if status_manager:
					velocity = status_manager.get_override_movement(velocity.normalized()) * speed
				if velocity != Vector3.ZERO:
					var target_angle = atan2(-velocity.z, velocity.x)
					sprite.rotation.y = lerp_angle(sprite.rotation.y, target_angle - PI/2.0, 10.0 * delta)
			else:
				velocity = Vector3.ZERO
				
		if status_manager:
			velocity *= status_manager.get_speed_multiplier()
			
		if status_manager and not status_manager.can_move():
			velocity = Vector3.ZERO
			
	move_and_slide()

func shoot_projectile(dir: Vector3):
	if not projectile_scene: return
	
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position
	proj.direction = dir
	proj.z_index = 5
	get_tree().current_scene.call_deferred("add_child", proj)
	print("Ranged Enemy menembak!")

# Melee contact (in case player touches them)
func _on_hurtbox_body_entered(body):
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position, element)
		knockback_velocity = (global_position - body.global_position).normalized() * 1.5

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
		status_manager.handle_damage_taken()
		
	current_health -= final_damage
	if is_instance_valid(hp_bar):
		hp_bar.value = current_health
	
	var dmg_color = Color(1, 1, 1) # Putih
	if multiplier > 1.0: dmg_color = Color(1, 0.2, 0.2) # Merah (Super Effective)
	elif multiplier < 1.0: dmg_color = Color(0.6, 0.6, 0.6) # Abu-abu (Resisted)
	
	spawn_damage_text(final_damage, dmg_color)
	
	if knockback_source != Vector3.ZERO:
		var knockback_direction = (global_position - knockback_source).normalized()
		knockback_velocity = knockback_direction * 2.0
	
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		if player and not player.is_dead:
			player.enemies_killed += 1
		drop_loot()
		queue_free()

func drop_loot():
	if not is_inside_tree(): return
	if randf() > 0.5:
		var coin_scene = load("res://Scenes/Items/coin.tscn")
		if coin_scene:
			var coin = coin_scene.instantiate()
			coin.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", coin)
			
	var exp_scene = load("res://Scenes/Items/exp_gem.tscn")
	if exp_scene:
		var exp_gem = exp_scene.instantiate()
		exp_gem.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", exp_gem)

func spawn_damage_text(text_val: Variant, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.05
	label.text = str(text_val)
	label.modulate = color
	label.global_position = global_position + Vector3(0, 2.0, 0)
	 
	
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 3.0, 0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)
