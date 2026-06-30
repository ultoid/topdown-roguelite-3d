extends Control

@onready var hair_label = $Panel/HBoxContainer/VBoxContainer/HairRow/LabelValue
@onready var beard_label = $Panel/HBoxContainer/VBoxContainer/BeardRow/LabelValue
@onready var sub_viewport = $Panel/HBoxContainer/SubViewportContainer/SubViewport

var max_hair_id = 1
var max_beard_id = 1

var _preview_camera: Camera3D

func _ready():
	if get_node_or_null("/root/CustomizationDB"):
		max_hair_id = CustomizationDB.get_hair_list().size()
		max_beard_id = CustomizationDB.get_beard_list().size()
	
	_setup_preview()
	_update_labels()

func _setup_preview():
	# SubViewport berbagi dunia 3D yang sama dengan game (own_world_3d = false)
	# sehingga karakter player langsung tampil sebagai preview
	sub_viewport.own_world_3d = false
	
	# Buat kamera khusus untuk preview
	_preview_camera = Camera3D.new()
	_preview_camera.name = "PreviewCamera"
	sub_viewport.add_child(_preview_camera)
	
	# Tambahkan cahaya agar preview lebih terang
	var spotlight = DirectionalLight3D.new()
	spotlight.name = "PreviewLight"
	spotlight.light_energy = 1.5
	spotlight.rotation_degrees = Vector3(-45, 30, 0)
	sub_viewport.add_child(spotlight)
	
	# Posisikan kamera menghadap pemain
	_position_preview_camera()

func _position_preview_camera():
	var player = get_tree().get_first_node_in_group("Player")
	if not is_instance_valid(player) or not is_instance_valid(_preview_camera): return
	
	var player_pos = player.global_position
	
	# Gunakan arah hadap player (bukan world-space offset tetap)
	# Model dirotasi 180° sehingga basis.z adalah arah "depan visual"
	var visual_front = player.global_transform.basis.z.normalized()
	
	# Posisikan kamera di depan wajah player, setinggi kepala
	var cam_pos = player_pos + Vector3(0, 2.5, 0) + visual_front * 1.5
	_preview_camera.global_position = cam_pos
	_preview_camera.look_at(player_pos + Vector3(0, 1.6, 0), Vector3.UP)

func _process(_delta):
	# Update posisi kamera setiap frame mengikuti player
	_position_preview_camera()

func _update_labels():
	if not get_node_or_null("/root/Global"): return
	if is_instance_valid(hair_label):
		hair_label.text = str(Global.customization["hair"])
	if is_instance_valid(beard_label):
		if Global.customization["facialhair"] == 0:
			beard_label.text = "None"
		else:
			beard_label.text = str(Global.customization["facialhair"])

func _apply_to_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("update_character_customization"):
		player.update_character_customization()

# --- Tombol Rambut ---
func _on_hair_prev_pressed():
	if not get_node_or_null("/root/Global"): return
	Global.customization["hair"] -= 1
	if Global.customization["hair"] < 1:
		Global.customization["hair"] = max_hair_id
	_update_labels()
	_apply_to_player()

func _on_hair_next_pressed():
	if not get_node_or_null("/root/Global"): return
	Global.customization["hair"] += 1
	if Global.customization["hair"] > max_hair_id:
		Global.customization["hair"] = 1
	_update_labels()
	_apply_to_player()

# --- Tombol Jenggot ---
func _on_beard_prev_pressed():
	if not get_node_or_null("/root/Global"): return
	Global.customization["facialhair"] -= 1
	if Global.customization["facialhair"] < 0:
		Global.customization["facialhair"] = max_beard_id
	_update_labels()
	_apply_to_player()

func _on_beard_next_pressed():
	if not get_node_or_null("/root/Global"): return
	Global.customization["facialhair"] += 1
	if Global.customization["facialhair"] > max_beard_id:
		Global.customization["facialhair"] = 0
	_update_labels()
	_apply_to_player()

# --- Tombol Close ---
func _on_close_button_pressed():
	if is_instance_valid(_preview_camera):
		_preview_camera.queue_free()
	queue_free()
