@tool
extends Node3D

enum PoseType {
	IDLE_DEFAULT,
	IDLE_LONG_SWORD,
	IDLE_RUNE,
	IDLE_SWORD
}

@export var pose: PoseType = PoseType.IDLE_DEFAULT:
	set(value):
		pose = value
		_update_pose()

func _ready():
	if not Engine.is_editor_hint():
		queue_free()
		return
	
	# Bersihkan mannequin lama jika ada
	var old_mannequin = get_node_or_null("Mannequin")
	if old_mannequin:
		old_mannequin.free()
		
	var player_scene = load("res://Scenes/Entities/player.tscn")
	if player_scene:
		var mannequin = player_scene.instantiate()
		mannequin.name = "Mannequin"
		_strip_physics(mannequin)
		add_child(mannequin)
		_update_pose()

func _strip_physics(node: Node):
	for child in node.get_children():
		_strip_physics(child)
	if node is CollisionShape3D or node is Area3D or node is RigidBody3D or node is CharacterBody3D or node is BoneAttachment3D:
		# Jangan hapus BoneAttachment3D utama (RightHand) karena dipakai untuk referensi posisi
		if node.name != "BoneAttachment3D":
			node.queue_free()

func _update_pose():
	if not Engine.is_editor_hint(): return
	var mannequin = get_node_or_null("Mannequin")
	if not mannequin: return
	
	var anim_player = mannequin.get_node_or_null("Visuals/HeroModel/AnimationPlayer")
	if not anim_player: return
	
	var anim_name = "RESET"
	match pose:
		PoseType.IDLE_DEFAULT: anim_name = "RESET"
		PoseType.IDLE_LONG_SWORD: anim_name = "longsword/longsword_idle"
		PoseType.IDLE_RUNE: anim_name = "rune/rune_idle"
		PoseType.IDLE_SWORD: anim_name = "sword/sword_idle"
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		anim_player.advance(0.1)
		_update_transform()

func _update_transform():
	if not Engine.is_editor_hint(): return
	var mannequin = get_node_or_null("Mannequin")
	if not mannequin: return
	
	var visuals = mannequin.get_node_or_null("Visuals")
	var hero = mannequin.get_node_or_null("Visuals/HeroModel")
	var skeleton = mannequin.get_node_or_null("Visuals/HeroModel/GeneralSkeleton")
	var bone_attach = mannequin.get_node_or_null("Visuals/HeroModel/GeneralSkeleton/BoneAttachment3D")
	
	if visuals and hero and skeleton and bone_attach:
		# Calculate hand transform relative to mannequin root
		var t_hand = visuals.transform * hero.transform * bone_attach.transform
		var t_hand_ortho = Transform3D(t_hand.basis.orthonormalized(), t_hand.origin)
		transform = t_hand_ortho.affine_inverse()
