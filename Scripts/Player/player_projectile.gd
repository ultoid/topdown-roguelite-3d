extends Area3D
class_name PlayerProjectile

@export var speed: float = 4.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.ZERO
var atk_elements: Array = ["netral"]

var is_piercing: bool = false
var hit_enemies: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		_deal_damage(body)
	elif body is GridMap or body is StaticBody3D or body is CSGShape3D:
		if not is_piercing: queue_free()

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.is_in_group("Enemy"):
		_deal_damage(parent)

func _deal_damage(enemy_node):
	if is_piercing and enemy_node in hit_enemies: return
	
	if enemy_node.has_method("take_damage"):
		var final_damage = damage
		if is_piercing:
			hit_enemies.append(enemy_node)
			# Calculate perpendicular distance to trajectory for "directness" of hit
			var perp_dist = (enemy_node.global_position - global_position).cross(direction).length()
			var max_dist = (0.4 * scale.x) + 0.5 # Proj radius + approx enemy radius
			# Factor from 0.3 (grazing) to 1.0 (dead center)
			var hit_factor = clamp(1.0 - (perp_dist / max_dist), 0.3, 1.0)
			final_damage = int(damage * hit_factor)
			
		enemy_node.take_damage(final_damage, Vector3.ZERO, atk_elements)
		
		# Terapkan custom knockback 0.5 meter (velocity 2.449 dengan friksi 6.0)
		if "knockback_velocity" in enemy_node:
			var push_dir = (enemy_node.global_position - global_position)
			push_dir.y = 0
			if push_dir == Vector3.ZERO: push_dir = Vector3(0, 0, 1)
			enemy_node.knockback_velocity = push_dir.normalized() * 2.449
			
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var player = players[0]
			if player.has_method("apply_camera_shake"):
				if scale.x > 1.1:
					player.apply_camera_shake(6.0, 0.2)
				else:
					player.apply_camera_shake(2.0, 0.1)
					
		if not is_piercing:
			queue_free()
