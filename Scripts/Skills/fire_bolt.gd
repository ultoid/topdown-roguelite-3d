extends Area3D

var damage: int = 10
var target: Node3D = null
var speed: float = 27.77 # 100 km/h
var elements: Array = ["api"]
var velocity: Vector3 = Vector3.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	var visual = CSGSphere3D.new()
	visual.radius = 0.3
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 2.0
	visual.material = mat
	add_child(visual)
	
	var coll = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.3
	coll.shape = sphere
	add_child(coll)
	
	if is_instance_valid(target):
		velocity = (target.global_position - global_position).normalized() * speed
	else:
		velocity = Vector3.RIGHT * speed

func _process(delta):
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		var dir = (target.global_position - global_position).normalized()
		# Aggressive homing
		velocity = velocity.move_toward(dir * speed, speed * 4.0 * delta).normalized() * speed
	global_position += velocity * delta

func _on_body_entered(body):
	_apply_damage(body)

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent: _apply_damage(parent)

func _apply_damage(body):
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position, elements)
		queue_free()
