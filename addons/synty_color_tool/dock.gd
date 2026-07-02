@tool
extends Control

@onready var load_btn = $VBoxContainer/LoadButton
@onready var status_lbl = $VBoxContainer/StatusLabel
@onready var parts_list = $VBoxContainer/ScrollContainer/PartsList

var _current_meshes: Array[MeshInstance3D] = []

func _ready():
	if not Engine.is_editor_hint():
		return
		
	load_btn.pressed.connect(_on_load_pressed)

func _on_load_pressed():
	# Munculkan popup OS untuk memastikan tombol benar-benar bereaksi
	OS.alert("Tombol Load ditekan! Memulai proses...", "Synty Tool Debug")
	
	status_lbl.text = "Memuat..."
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		OS.alert("Error: Tidak ada node yang dipilih!", "Synty Tool Debug")
		status_lbl.text = "Error: Select a character node first!"
		return
		
	var target = selection[0]
	
	# Bersihkan list lama
	for child in parts_list.get_children():
		child.queue_free()
	_current_meshes.clear()
	
	# Sisir semua mesh
	_collect_meshes(target)
	
	if _current_meshes.is_empty():
		status_lbl.text = "Warning: No MeshInstance3D found in " + target.name
		return
		
	status_lbl.text = "Loaded " + str(_current_meshes.size()) + " parts from " + target.name
	
	# Buat UI untuk tiap mesh
	for mesh_inst in _current_meshes:
		_create_part_ui(mesh_inst)

func _collect_meshes(node: Node):
	if node is MeshInstance3D:
		_current_meshes.append(node)
	for child in node.get_children(true): # True agar bisa membaca isi dalam instanced scene
		_collect_meshes(child)

func _create_part_ui(mesh_inst: MeshInstance3D):
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Percantik nama dengan menghapus prefix aneh jika ada
	var clean_name = mesh_inst.name.replace("SK_SPEC_HUMN_BASE_01_", "").replace("SK_FANT_KNGT_17_", "")
	lbl.text = clean_name
	
	var picker = ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Coba tebak warna saat ini
	var current_color = Color.WHITE
	var mat = mesh_inst.get_surface_override_material(0)
	if mat == null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() > 0:
		mat = mesh_inst.mesh.surface_get_material(0)
		
	if mat is StandardMaterial3D:
		current_color = mat.albedo_color
		
	picker.color = current_color
	
	# Binding node ke sinyal
	picker.color_changed.connect(func(c): _on_part_color_changed(c, mesh_inst))
	
	hbox.add_child(lbl)
	hbox.add_child(picker)
	parts_list.add_child(hbox)

func _on_part_color_changed(new_color: Color, mesh_inst: MeshInstance3D):
	# Dapatkan atau buat material override baru
	var mat = mesh_inst.get_surface_override_material(0)
	
	if not (mat is StandardMaterial3D):
		mat = StandardMaterial3D.new()
		# Jika material lama punya tekstur, usahakan dipertahankan
		var old_mat = mesh_inst.mesh.surface_get_material(0) if mesh_inst.mesh and mesh_inst.mesh.get_surface_count() > 0 else null
		if old_mat is StandardMaterial3D:
			mat.albedo_texture = old_mat.albedo_texture
			
	mat.albedo_color = new_color
	# Matikan vertex color as albedo agar warna solid kita masuk
	mat.vertex_color_use_as_albedo = false
	
	mesh_inst.set_surface_override_material(0, mat)
