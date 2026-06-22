extends Area3D

var damage: int = 10
var aoe_radius: float = 2.0 # In meters (scaled down)
var duration: float = 3.0
var elements: Array = ["netral"]

var tick_timer: float = 0.0
var tick_rate: float = 0.5
var arrow_timer: float = 0.0

var visual_cylinder: CSGCylinder3D

func _ready():
	monitoring = true
	monitorable = false
	collision_layer = 0
	for i in range(1, 10): set_collision_mask_value(i, true)
	var shape = CylinderShape3D.new()
	shape.radius = aoe_radius
	shape.height = 4.0
	
	var collision = CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 2.0, 0)
	add_child(collision)
	
	# Visual Area
	visual_cylinder = CSGCylinder3D.new()
	visual_cylinder.radius = aoe_radius
	visual_cylinder.height = 0.1
	visual_cylinder.position = Vector3(0, 0.05, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual_cylinder.material = mat
	add_child(visual_cylinder)
	
	# Efek pudarkan dan hapus
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _physics_process(delta):
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0 and randf() < 0.2:
		players[0].apply_camera_shake(1.5, 0.1)
		
	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = tick_rate
		# Force physics update if needed, but monitoring=true should handle it
		_deal_damage()
		
	arrow_timer -= delta
	if arrow_timer <= 0:
		arrow_timer = 0.1
		_spawn_visual_arrow()

func _spawn_visual_arrow():
	var wrapper = Node3D.new()
	var arrow_scene = load("res://Scenes/Skills/arrow_projectile.tscn")
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		arrow.rotation.z = -PI/2.0 # Arrow mesh points along +X, rotate around Z to point down
		arrow.rotation.x = 0.0
		arrow.set_script(null) # Remove projectile script ALWAYS
		if arrow is Area3D or arrow is RigidBody3D or arrow is CharacterBody3D:
			if "monitoring" in arrow: arrow.monitoring = false
			if "monitorable" in arrow: arrow.monitorable = false
			# Make it purely visual, remove script if any to prevent normal projectile logic
			arrow.set_script(null)
		wrapper.add_child(arrow)
	
	var script = GDScript.new()
	script.source_code = """
extends Node3D
var target_y = 0.0
func _process(delta):
	position.y -= 15.0 * delta
	if position.y <= target_y:
		queue_free()
		set_process(false)
"""
	script.reload()
	wrapper.set_script(script)
	
	var angle = randf() * PI * 2
	var r = sqrt(randf()) * aoe_radius
	var offset = Vector3(cos(angle) * r, 0, sin(angle) * r)
	
	wrapper.set("target_y", 0.0)
	wrapper.position = offset + Vector3(0, 5.0, 0)
	add_child(wrapper)

func _deal_damage():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.get("is_dead"): continue
		
		var flat_dist = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if flat_dist <= aoe_radius and abs(global_position.y - enemy.global_position.y) < 5.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, Vector3.ZERO, elements)
				if enemy.get("status_manager") != null:
					enemy.status_manager.apply_effect("chill", 2.0)
					enemy.status_manager.apply_effect("slow", 2.0, {"amount": 0.1})
