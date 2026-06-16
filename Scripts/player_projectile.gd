extends Area3D
class_name PlayerProjectile

@export var speed: float = 4.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector3 = Vector3.ZERO
var atk_elements: Array = ["netral"]

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
		queue_free()

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.is_in_group("Enemy"):
		_deal_damage(parent)

func _deal_damage(enemy_node):
	if enemy_node.has_method("take_damage"):
		enemy_node.take_damage(damage, global_position, atk_elements)
		
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var player = players[0]
			if player.has_method("apply_camera_shake"):
				if scale.x > 1.1:
					player.apply_camera_shake(6.0, 0.2)
				else:
					player.apply_camera_shake(2.0, 0.1)
					
		queue_free()
