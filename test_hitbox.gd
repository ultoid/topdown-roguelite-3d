extends SceneTree

func _init():
	var root = get_root()
	var player_scene = load("res://Scenes/Entities/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Simulate equipment
	Global.equipment["main_weapon"] = "sw_01" # Assuming sw_01 is a long sword, or we can just mock it
	# Actually let's just instantiate long_sword.tscn and attach it
	var weapon_scene = load("res://Scenes/Weapons/long_sword.tscn")
	var weapon = weapon_scene.instantiate()
	var right_hand = player.find_child("RightHandAttachment", true, false)
	right_hand.add_child(weapon)
	
	# Run a frame so transforms update
	await create_timer(0.1).timeout
	
	var rh = player.find_child("RightHandHitBox", true, false)
	print("--- RESULTS ---")
	print("Hitbox Global Scale: ", rh.global_transform.basis.get_scale())
	print("Hitbox Global Position: ", rh.global_position)
	print("---------------")
	quit()
