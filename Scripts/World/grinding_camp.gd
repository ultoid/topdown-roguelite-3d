extends Node3D

@export var max_enemies: int = 3
@export var respawn_time: float = 10.0
@export var spawn_radius: float = 50.0 # Jarak sebaran posisi musuh dari pusat camp

var alive_enemies: int = 0
var respawn_timer: Timer

func _ready():
	# Menyembunyikan ikon penanda (jika Anda menambahkannya nanti di editor) saat game berjalan
	var sprite = get_node_or_null("MeshInstance3D")
	if sprite:
		sprite.visible = false
	
	# Buat dan konfigurasikan hitung mundur (Timer)
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = respawn_time
	respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(respawn_timer)
	
	# Memanggil gelombang (wave) pertama saat game dimulai
	call_deferred("spawn_wave")

func spawn_wave():
	var enemy_scene = load("res://Scenes/Entities/enemy.tscn")
	if not enemy_scene:
		print("Error: Gagal memuat musuh di GrindingCamp")
		return
		
	print("Grinding Camp melahirkan ", max_enemies, " musuh di titik: ", global_position)
	
	for i in range(max_enemies):
		var enemy = enemy_scene.instantiate()
		
		# Tentukan posisi acak di sekitar pusat camp agar tidak saling menumpuk
		var random_angle = randf_range(0, TAU)
		var random_dist = randf_range(10.0, spawn_radius)
		var offset = Vector3(cos(random_angle), 0, sin(random_angle)) * random_dist
		
		enemy.global_position = global_position + offset
		
		# Pantau musuh ini. Jika dihapus (karena mati), panggil fungsi _on_enemy_died
		enemy.tree_exited.connect(_on_enemy_died)
		
		# Tambahkan ke dunia
		get_tree().current_scene.add_child(enemy)
		alive_enemies += 1

func _on_enemy_died():
	alive_enemies -= 1
	
	# Jika musuh terakhir gugur, mulai proses hitung mundur respawn
	if alive_enemies <= 0:
		print("Grinding Camp bersih! Akan respawn dalam ", respawn_time, " detik...")
		if is_inside_tree():
			respawn_timer.start()

func _on_respawn_timeout():
	spawn_wave()
