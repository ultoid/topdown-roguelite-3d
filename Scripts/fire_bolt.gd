extends Area3D

var damage: int = 10
var target: Node3D = null
var speed: float = 400.0
var elements: Array = ["api"]
var velocity: Vector3 = Vector3.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	var sprite = ColorRect.new()
	sprite.color = Color(1.0, 0.4, 0.0)
	sprite.size = Vector3(16, 0, 16)
	sprite.position = Vector3(-8, 0, -8)
	add_child(sprite)
	
	var coll = CollisionShape3D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	coll.shape = circle
	add_child(coll)
	
	if is_instance_valid(target):
		velocity = (target.global_position - global_position).normalized() * speed
	else:
		velocity = Vector3.RIGHT * speed

func _process(delta):
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		var dir = (target.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * speed, speed * 2.0 * delta)
	global_position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position, elements)
		queue_free()
