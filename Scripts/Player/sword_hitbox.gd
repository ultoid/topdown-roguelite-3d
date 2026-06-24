extends Area3D

var hit_enemies = []
var is_active: bool = false

func _ready():
	# Memastikan Area3D ini bisa mendeteksi tabrakan
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func clear_hit_list():
	hit_enemies.clear()
	is_active = true
	# Secara proaktif cek musuh yang sudah ada di dalam jangkauan
	# (karena jika mereka sudah di dalam, signal body_entered tidak akan terpicu lagi)
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func deactivate():
	is_active = false

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
		
	var player = owner if owner and owner.is_in_group("Player") else get_parent()
	# Terus cari ke atas jika belum ketemu (mengantisipasi hitbox ada di dalam BoneAttachment)
	var current_node = self
	while current_node and not current_node.is_in_group("Player"):
		current_node = current_node.get_parent()
		if current_node and current_node.is_in_group("Player"):
			player = current_node
			break

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
					
		var kb_force = 3.464
		if player:
			var item_db = player.get_node_or_null("/root/ItemDB")
			if item_db and Global.equipment.get("main_weapon", "") != "":
				var w_data = item_db.get_item(Global.equipment["main_weapon"])
				if w_data and w_data.get("weapon_type", "") == "long_sword":
					kb_force = 6.0
					
		enemy_node.take_damage(current_damage, global_position, atk_elements, kb_force)
		if player and player.has_method("apply_camera_shake"):
			if player.get("is_charge_attacking"):
				player.apply_camera_shake(8.0, 0.2)
			else:
				player.apply_camera_shake(3.0, 0.1)
