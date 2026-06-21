extends Area3D

var hit_enemies = []
var is_active: bool = true

func _ready():
	# Memastikan Area3D ini bisa mendeteksi tabrakan
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func clear_hit_list():
	hit_enemies.clear()

func _on_body_entered(body):
	if not is_active: return
	if body.is_in_group("Enemy"):
		_deal_damage(body)

func _on_area_entered(area):
	if not is_active: return
	var parent = area.get_parent()
	if parent and parent.is_in_group("Enemy"):
		_deal_damage(parent)

func _deal_damage(enemy_node):
	if enemy_node in hit_enemies:
		return # Mencegah damage ganda
		
	var player = get_parent()

	hit_enemies.append(enemy_node)
	
	if enemy_node.has_method("take_damage"):
		var current_damage = 10
		var atk_elements = ["netral"]
		
		if player:
			if "current_attack_damage" in player:
				current_damage = player.current_attack_damage
			if "atk_elements" in player:
				atk_elements = player.atk_elements.duplicate()
			if "status_manager" in player and player.status_manager:
				var override = player.status_manager.get_override_element()
				if override != "":
					atk_elements = [override]
					
		enemy_node.take_damage(current_damage, global_position, atk_elements)
		if player and player.has_method("apply_camera_shake"):
			if player.get("is_charge_attacking"):
				player.apply_camera_shake(8.0, 0.2)
			else:
				player.apply_camera_shake(3.0, 0.1)
