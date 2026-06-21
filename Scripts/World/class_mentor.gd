extends "res://Scripts/World/npc.gd"

func _ready():
	# Timpa perilaku NPC dasar
	if has_node("Label3D"):
		$Label3D.text = npc_name
	
	if has_node("InteractArea"):
		$InteractArea.body_entered.connect(_on_body_entered)
		$InteractArea.body_exited.connect(_on_body_exited)
	
	# Ambil model hero dan ubah warnanya jadi hijau
	if has_node("HeroModel"):
		var hero_model = $HeroModel
		_make_green(hero_model)
		# Matikan AnimationPlayer bawaan agar tidak bentrok atau mainkan idle
		if hero_model.has_node("AnimationPlayer"):
			var anim = hero_model.get_node("AnimationPlayer")
			if anim.has_animation("Idle"):
				anim.play("Idle")

func _make_green(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			# Beri material override hijau muda
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 1.0, 0.2, 1.0) # Hijau
			child.material_override = mat
		_make_green(child)
