extends Area3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

var damage: int = 10
var aoe_radius: float = 60.0

func _ready():
	# Atur ukuran collision sesuai aoe_radius
	var shape = CircleShape2D.new()
	shape.radius = aoe_radius
	
	var collision = CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	
	# Visual Ledakan Sementara (Bisa diganti sprite nanti)
	var tween = get_tree().create_tween()
	
	# Lingkaran api
	var rect = ColorRect.new()
	rect.color = Color(1.0, 0.4, 0.0, 0.8)
	rect.size = Vector3(aoe_radius * 2, 0, aoe_radius * 2)
	rect.position = -rect.size / 2
	# Buat agar terlihat seperti lingkaran dengan mengatur sudut
	# Tapi karena ColorRect kotak, kita pakai trik modulate saja.
	# Untuk lebih bagusnya, harusnya pakai Sprite lingkaran.
	add_child(rect)
	
	# Efek ledakan mengecil dan memudar
	tween.tween_property(rect, "scale", Vector3(1.2, 0, 1.2), 0.1)
	tween.tween_property(rect, "modulate:a", 0.0, 0.3)
	
	# Deteksi musuh dalam 0.1 detik pertama
	await get_tree().create_timer(0.05).timeout
	_deal_damage()
	
	# Buat bekas hitam (scorch mark) di tanah (Muncul bersamaan dengan ledakan)
	var scorch = CSGPolygon3D.new()
	var points = PackedVector3Array()
	var sides = 16
	for i in range(sides):
		var angle = i * TAU / sides
		points.append(Vector3(cos(angle), 0, sin(angle)) * aoe_radius)
	scorch.polygon = points
	scorch.color = Color(0.1, 0.1, 0.1, 0.6) # Hitam transparan
	scorch.global_position = global_position
	scorch.z_index = 0 # Ubah ke 0 agar tidak tertutup tilemap
	get_parent().add_child(scorch)
	
	# Pudarkan bekas secara perlahan (misal 12 detik)
	var scorch_tween = scorch.create_tween()
	scorch_tween.tween_property(scorch, "modulate:a", 0.0, 12.0)
	scorch_tween.tween_callback(scorch.queue_free)
	
	# Tunggu visual ledakan selesai
	await tween.finished
	
	queue_free()

func _deal_damage():
	var bodies = get_overlapping_bodies()
	var areas = get_overlapping_areas()
	
	var hit_enemies = []
	var has_hit = false
	
	# Cek Body (Musuh biasa)
	for body in bodies:
		if body.is_in_group("Enemy") and body.has_method("take_damage") and not hit_enemies.has(body):
			body.take_damage(damage, global_position, ["api"])
			hit_enemies.append(body)
			has_hit = true
			
	# Cek Area (Misal musuh tipe bos/part tertentu)
	for area in areas:
		var parent = area.get_parent()
		if parent and parent.is_in_group("Enemy") and parent.has_method("take_damage") and not hit_enemies.has(parent):
			parent.take_damage(damage, global_position, ["api"])
			hit_enemies.append(parent)
			has_hit = true
			
	if has_hit:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var player = players[0]
			if player.has_method("apply_camera_shake"):
				player.apply_camera_shake(4.0, 0.15)
