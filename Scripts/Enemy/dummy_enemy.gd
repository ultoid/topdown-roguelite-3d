extends "res://Scripts/Enemy/enemy.gd"

func _ready():
	super._ready()
	speed = 0.0
	chase_radius = 0.0
	max_health = 9999999
	current_health = max_health
	damage = 0
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health

func _physics_process(delta):
	if knockback_velocity != Vector3.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 6.0 * delta)
	else:
		velocity = Vector3.ZERO
		
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	move_and_slide()

func take_damage(amount: int, knockback_source: Vector3 = Vector3.ZERO, atk_elements: Array = ["netral"]):
	super.take_damage(amount, knockback_source, atk_elements)
	if current_health <= 100000:
		current_health = max_health
		if hp_bar: hp_bar.value = current_health
