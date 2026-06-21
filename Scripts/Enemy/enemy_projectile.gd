extends Area3D

@export var speed: float = 2.5
@export var damage: int = 5
@export var lifetime: float = 3.0 # Akan hancur otomatis dalam 3 detik agar tidak membebani memori

var direction: Vector3 = Vector3.ZERO
var element: String = "netral"

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Timer penghancur otomatis
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# Jika menabrak Player, berikan damage dan hancurkan peluru
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position, element, 100.0)
		queue_free()
	# Jika menabrak dinding (GridMap / StaticBody3D), peluru hancur
	elif body is GridMap or body is StaticBody3D or body is CSGShape3D:
		queue_free()
