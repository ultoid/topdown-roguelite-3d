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
		_deal_damage()
		
	arrow_timer -= delta
	if arrow_timer <= 0:
		arrow_timer = 0.1
		_spawn_visual_arrow()

func _spawn_visual_arrow():
	var arrow = CSGBox3D.new()
	arrow.size = Vector3(0.05, 0.5, 0.05)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 1.0, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow.material = mat
	
	var script = GDScript.new()
	script.source_code = """
extends CSGBox3D
var target_y = 0.0
func _process(delta):
	position.y -= 15.0 * delta
	if position.y <= target_y:
		position.y = target_y
		var mat = material as StandardMaterial3D
		if mat:
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.1)
			tween.tween_callback(queue_free)
		else:
			queue_free()
		set_process(false)
"""
	script.reload()
	arrow.set_script(script)
	
	var angle = randf() * PI * 2
	var r = sqrt(randf()) * aoe_radius
	var offset = Vector3(cos(angle) * r, 0, sin(angle) * r)
	
	arrow.set("target_y", 0.0)
	arrow.position = offset + Vector3(0, 5.0, 0)
	add_child(arrow)

func _deal_damage():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(damage, Vector3.ZERO, elements)
			if body.get("status_manager") != null:
				body.status_manager.apply_effect("chill", 2.0) # Apply slow
