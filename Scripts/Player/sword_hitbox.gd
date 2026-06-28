extends Area3D

@export var manual_hit_radius: float = 0.0

var hit_enemies = []
var is_active: bool = false

func _ready():
	# Memastikan Area3D ini bisa mendeteksi tabrakan
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Sembunyikan bola debug secara default (jika ada)
	var debug_sphere = get_node_or_null("DebugSphere")
	if is_instance_valid(debug_sphere):
		debug_sphere.visible = false

func _physics_process(delta):
	if is_active:
		# Polling berlanjut di setiap frame selama animasi berlangsung
		# Ini menjamin tabrakan terdeteksi meskipun pedang berteleportasi
		for body in get_overlapping_bodies():
			_on_body_entered(body)
		for area in get_overlapping_areas():
			_on_area_entered(area)
			
		# [BULLETPROOF FALLBACK] Bypass physics engine dengan pengecekan jarak manual
		if manual_hit_radius > 0.0:
			# Gunakan posisi PLAYER (bukan tulang/bone) sebagai pusat jangkauan serangan
			var player_node = get_tree().get_first_node_in_group("Player")
			if not is_instance_valid(player_node):
				return
			var enemies = get_tree().get_nodes_in_group("Enemy")
			for e in enemies:
				if is_instance_valid(e):
					var p1 = player_node.global_position
					var p2 = e.global_position
					p1.y = 0
					p2.y = 0
					if p1.distance_to(p2) <= manual_hit_radius: 
						_deal_damage(e)

func clear_hit_list():
	hit_enemies.clear()
	is_active = true
	
	# Tampilkan bola merah debug saat hitbox aktif
	var debug_sphere = get_node_or_null("DebugSphere")
	if is_instance_valid(debug_sphere):
		debug_sphere.visible = true
		
	# Secara proaktif cek musuh yang sudah ada di dalam jangkauan
	# (karena jika mereka sudah di dalam, signal body_entered tidak akan terpicu lagi)
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func deactivate():
	is_active = false
	
	# Sembunyikan bola merah debug saat hitbox tidak aktif
	var debug_sphere = get_node_or_null("DebugSphere")
	if is_instance_valid(debug_sphere):
		debug_sphere.visible = false

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
	print("[DEBUG] _deal_damage ENTER for: ", enemy_node.name)
	if enemy_node in hit_enemies:
		print("[DEBUG] Enemy already hit: ", enemy_node.name)
		return
		
	hit_enemies.append(enemy_node)
	
	# Safe player resolution
	var player = get_tree().get_first_node_in_group("Player")
	
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
					
		print("[DEBUG] SUCCESS: Calling take_damage(", current_damage, ") on ", enemy_node.name)
		enemy_node.take_damage(current_damage, global_position, atk_elements, kb_force)
		
		if player and player.has_method("apply_camera_shake"):
			if player.get("is_charge_attacking"):
				player.apply_camera_shake(8.0, 0.2)
			else:
				player.apply_camera_shake(3.0, 0.1)
	else:
		print("[DEBUG] FAILED: enemy_node has no take_damage method!")
