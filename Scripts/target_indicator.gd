extends Node3D

var modulate: Color = Color(1, 1, 1) # Dummy for 3D

var max_range: float = 250.0
var aoe_radius: float = 60.0

var frozen: bool = false
var global_target_pos: Vector3 = Vector3.ZERO

var indicator_type: String = "circle" # circle, cone, single
var single_target_node: Node3D = null
var player_node: Node3D = null

var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh
var material: StandardMaterial3D

func _ready():
	mesh_instance = MeshInstance3D.new()
	immediate_mesh = ImmediateMesh.new()
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = true # Pastikan indikator digambar di atas segalanya
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	
	# Angkat sedikit agar tidak z-fighting dengan tanah jika no_depth_test tidak didukung
	mesh_instance.position.y = 0.5 
	
	add_child(mesh_instance)

func _process(_delta):
	if indicator_type == "single" and not frozen:
		var mouse_pos = Vector3.ZERO
		if is_instance_valid(player_node) and player_node.has_method("get_mouse_3d_pos"):
			mouse_pos = player_node.get_mouse_3d_pos()
			
		var closest_enemy = null
		var closest_dist = 99999.0
		var enemies = get_tree().get_nodes_in_group("Enemy")
		for e in enemies:
			if not e.get("is_dead"):
				# check if within max_range of player
				var p_pos = player_node.global_position if is_instance_valid(player_node) else global_position
				if e.global_position.distance_to(p_pos) <= max_range:
					var dist = e.global_position.distance_to(mouse_pos)
					if dist < closest_dist and dist < 100.0: # 100px snap radius
						closest_dist = dist
						closest_enemy = e
		single_target_node = closest_enemy
		
	_update_mesh()

func start_casting(target_global: Vector3):
	frozen = true
	global_target_pos = target_global
	
	# Efek kedip
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _update_mesh():
	immediate_mesh.clear_surfaces()
	
	var center = Vector3.ZERO
	# 1. Menggambar batas maksimal cast (Lingkaran besar berpusat di player)
	_draw_arc(center, max_range, 64, Color(0.2, 0.8, 1.0, 0.6 * modulate.a))
	_draw_circle_filled(center, max_range, 32, Color(0.2, 0.8, 1.0, 0.15 * modulate.a))
	
	if indicator_type == "circle":
		var mouse_pos = Vector3.ZERO
		if frozen:
			mouse_pos = to_local(global_target_pos)
		else:
			if is_instance_valid(player_node) and player_node.has_method("get_mouse_3d_pos"):
				mouse_pos = to_local(player_node.get_mouse_3d_pos())
				
		if not frozen and mouse_pos.length() > max_range:
			mouse_pos = mouse_pos.normalized() * max_range
		
		_draw_circle_filled(mouse_pos, aoe_radius, 32, Color(1.0, 0.2, 0.2, 0.5 * modulate.a))
		_draw_arc(mouse_pos, aoe_radius, 32, Color(1.0, 0.2, 0.2, 0.9 * modulate.a))
		
	elif indicator_type == "single":
		if frozen:
			var loc = to_local(global_target_pos)
			_draw_circle_filled(loc, 30.0, 16, Color(1.0, 0.8, 0.0, 0.6 * modulate.a))
			_draw_arc(loc, 30.0, 32, Color(1.0, 0.8, 0.0, 1.0 * modulate.a))
		elif is_instance_valid(single_target_node):
			var loc = to_local(single_target_node.global_position)
			_draw_circle_filled(loc, 30.0, 16, Color(1.0, 0.2, 0.2, 0.5 * modulate.a))
			_draw_arc(loc, 30.0, 32, Color(1.0, 0.2, 0.2, 0.9 * modulate.a))
		else:
			var mouse_pos = Vector3.ZERO
			if is_instance_valid(player_node) and player_node.has_method("get_mouse_3d_pos"):
				mouse_pos = to_local(player_node.get_mouse_3d_pos())
			if mouse_pos.length() > max_range:
				mouse_pos = mouse_pos.normalized() * max_range
			_draw_arc(mouse_pos, 20.0, 16, Color(0.5, 0.5, 0.5, 0.5 * modulate.a))
			
	elif indicator_type == "cone":
		var mouse_pos = Vector3.ZERO
		if frozen:
			mouse_pos = to_local(global_target_pos)
		else:
			if is_instance_valid(player_node) and player_node.has_method("get_mouse_3d_pos"):
				mouse_pos = to_local(player_node.get_mouse_3d_pos())
				
		var dir = mouse_pos.normalized()
		var angle = atan2(-dir.z, dir.x)
		var fov = deg_to_rad(45.0) # 45 degree cone
		
		# Cone filled
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
		var segments = 16
		var poly_color = Color(1.0, 0.2, 0.2, 0.5 * modulate.a)
		for i in range(segments):
			var a1 = angle - fov/2.0 + (fov * float(i) / segments)
			var a2 = angle - fov/2.0 + (fov * float(i + 1) / segments)
			var p1 = Vector3(cos(a1), 0, sin(a1)) * max_range
			var p2 = Vector3(cos(a2), 0, sin(a2)) * max_range
			immediate_mesh.surface_set_color(poly_color)
			immediate_mesh.surface_add_vertex(Vector3.ZERO)
			immediate_mesh.surface_set_color(poly_color)
			immediate_mesh.surface_add_vertex(p2) # swap winding
			immediate_mesh.surface_set_color(poly_color)
			immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_end()
		
		# Cone outline
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		var line_color = Color(1.0, 0.2, 0.2, 0.9 * modulate.a)
		var p_start = Vector3(cos(angle - fov/2.0), 0, sin(angle - fov/2.0)) * max_range
		var p_end = Vector3(cos(angle + fov/2.0), 0, sin(angle + fov/2.0)) * max_range
		
		immediate_mesh.surface_set_color(line_color)
		immediate_mesh.surface_add_vertex(Vector3.ZERO)
		immediate_mesh.surface_set_color(line_color)
		immediate_mesh.surface_add_vertex(p_start)
		
		for i in range(segments):
			var a1 = angle - fov/2.0 + (fov * float(i) / segments)
			var a2 = angle - fov/2.0 + (fov * float(i + 1) / segments)
			var p1 = Vector3(cos(a1), 0, sin(a1)) * max_range
			var p2 = Vector3(cos(a2), 0, sin(a2)) * max_range
			immediate_mesh.surface_set_color(line_color)
			immediate_mesh.surface_add_vertex(p1)
			immediate_mesh.surface_set_color(line_color)
			immediate_mesh.surface_add_vertex(p2)
			
		immediate_mesh.surface_set_color(line_color)
		immediate_mesh.surface_add_vertex(p_end)
		immediate_mesh.surface_set_color(line_color)
		immediate_mesh.surface_add_vertex(Vector3.ZERO)
		immediate_mesh.surface_end()

func _draw_arc(center: Vector3, radius: float, segments: int, color: Color):
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for i in range(segments):
		var a1 = float(i) / segments * TAU
		var a2 = float(i + 1) / segments * TAU
		var p1 = center + Vector3(cos(a1), 0, sin(a1)) * radius
		var p2 = center + Vector3(cos(a2), 0, sin(a2)) * radius
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p2)
	immediate_mesh.surface_end()

func _draw_circle_filled(center: Vector3, radius: float, segments: int, color: Color):
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in range(segments):
		var a1 = float(i) / segments * TAU
		var a2 = float(i + 1) / segments * TAU
		var p1 = center + Vector3(cos(a1), 0, sin(a1)) * radius
		var p2 = center + Vector3(cos(a2), 0, sin(a2)) * radius
		
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(center)
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p2) # swap for winding
		immediate_mesh.surface_set_color(color)
		immediate_mesh.surface_add_vertex(p1)
	immediate_mesh.surface_end()
