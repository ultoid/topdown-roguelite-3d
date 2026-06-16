extends Area3D

var target_pos: Vector3 = Vector3.ZERO

func _ready():
	add_to_group("Interactable")
	# Load existing plots
	if get_node_or_null("/root/Global"):
		var plot_scene = load("res://Scenes/LifeSkills/crop_plot.tscn")
		for plot_id in Global.farm_plots.keys():
			var data = Global.farm_plots[plot_id]
			var plot = plot_scene.instantiate()
			plot.global_position = data["position"]
			plot.plot_id = plot_id
			get_parent().call_deferred("add_child", plot)

func on_interact(player):
	if not Global.inventory.has("hoe") or Global.inventory["hoe"] <= 0:
		player.spawn_floating_text("Butuh Hoe!", Color(1, 0.2, 0.2))
		return
		
	player.start_farming_targeting(self)

func on_cancel():
	pass

func on_complete(player):
	# Spawn crop plot
	var plot_id = "plot_" + str(target_pos.x) + "_" + str(target_pos.y)
	
	if get_node_or_null("/root/Global"):
		Global.farm_plots[plot_id] = {
			"position": target_pos,
			"state": 0, # State.EMPTY
			"growth_time": 0.0,
			"watered_time_left": 0.0,
			"max_growth_time": 120.0
		}
	
	var plot_scene = load("res://Scenes/LifeSkills/crop_plot.tscn")
	var plot = plot_scene.instantiate()
	plot.global_position = target_pos
	plot.plot_id = plot_id
	get_parent().add_child(plot)

func is_valid_plot_pos(pos: Vector3) -> bool:
	var shape = $CollisionShape3D.shape as RectangleShape2D
	if not shape: return true
	
	var local_pos = to_local(pos)
	var extents = shape.size / 2.0
	
	# Plot is 32x32, shrink bounds by 16 to keep it fully inside
	var valid_extents_x = extents.x - 16.0
	var valid_extents_y = extents.y - 16.0
	
	if abs(local_pos.x) > valid_extents_x or abs(local_pos.y) > valid_extents_y:
		return false
		
	# Check distance to existing plots
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("plant_seed"):
				if child.global_position.distance_to(pos) < 32.0:
					return false
	
	return true
