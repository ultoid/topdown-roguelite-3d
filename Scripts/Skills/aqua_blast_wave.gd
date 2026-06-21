extends Area3D

var damage: int = 10
var elements: Array = ["air"]
var max_radius: float = 5.0
var duration: float = 0.5
var origin_pos: Vector3 = Vector3.ZERO

var hit_enemies = []
var visual: CSGCylinder3D
var coll: CollisionShape3D
var cyl: CylinderShape3D

func _ready():
	origin_pos = global_position
	
	visual = CSGCylinder3D.new()
	visual.radius = 0.1
	visual.height = 0.5
	visual.sides = 32
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.8, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual.material = mat
	add_child(visual)
	
	coll = CollisionShape3D.new()
	cyl = CylinderShape3D.new()
	cyl.radius = 0.1
	cyl.height = 2.0
	coll.shape = cyl
	add_child(coll)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "radius", max_radius, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(cyl, "radius", max_radius, duration).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	var all_targets = []
	all_targets.append_array(get_overlapping_bodies())
	for area in get_overlapping_areas():
		if area.get_parent() != null and not area.get_parent() in all_targets:
			all_targets.append(area.get_parent())
			
	var current_radius = visual.radius
	for body in all_targets:
		if body.is_in_group("Enemy"):
			var dir = (body.global_position - origin_pos)
			dir.y = 0
			if dir == Vector3.ZERO: dir = Vector3.RIGHT
			dir = dir.normalized()
			
			var dist = body.global_position.distance_to(origin_pos)
			# Only push them if they are inside the wave
			if dist < current_radius:
				var diff = current_radius - dist
				body.move_and_collide(dir * diff)
				if "knockback_velocity" in body:
					body.knockback_velocity = Vector3.ZERO
			
			if body.get("status_manager") != null:
				body.status_manager.apply_effect("slow", 0.5)

func _on_body_entered(body):
	_apply_damage(body)

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent: _apply_damage(parent)

func _apply_damage(body):
	if body.is_in_group("Enemy") and not body in hit_enemies:
		hit_enemies.append(body)
		if body.has_method("take_damage"):
			body.take_damage(damage, Vector3.ZERO, elements)
