extends Area3D

var damage: int = 10
var elements: Array = ["tanah"]
var slow_duration: float = 5.0

var hit_enemies = []
var dot_timer: float = 0.0
var lifetime_timer: float = 0.0

var is_circle: bool = false
var radius: float = 0.6

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if is_circle:
		var visual = CSGCylinder3D.new()
		visual.radius = radius
		visual.height = 0.05
		visual.sides = 32
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.2, 0.0, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		visual.material = mat
		add_child(visual)
		
		var coll = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = 2.0
		coll.shape = cyl
		add_child(coll)
		
		lifetime_timer = slow_duration if slow_duration > 0 else 5.0
	else:
		var visual = CSGBox3D.new()
		visual.size = Vector3(1.0, 0.05, 1.0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.2, 0.0, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		visual.material = mat
		add_child(visual)
		
		var coll = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(1.0, 2.0, 1.0)
		coll.shape = box
		add_child(coll)
		
		lifetime_timer = 1.0 # Kotak cepat hilang
		_shake_camera(2.0, 0.1)

func _physics_process(delta):
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()
		return
		
	if is_circle:
		_shake_camera(4.0, 0.1)
		
		dot_timer -= delta
		if dot_timer <= 0:
			dot_timer = 0.5 # Tick rate DoT
			var all_targets = []
			all_targets.append_array(get_overlapping_bodies())
			for area in get_overlapping_areas():
				if area.get_parent() != null and not area.get_parent() in all_targets:
					all_targets.append(area.get_parent())
					
			for body in all_targets:
				if body.is_in_group("Enemy"):
					if body.has_method("take_damage"):
						body.take_damage(int(damage * 0.5), Vector3.ZERO, elements)
					if body.get("status_manager") != null:
						body.status_manager.apply_effect("slow", 1.0, {"amount": 0.1}) # Refresh slow (90% slow)

func _on_body_entered(body):
	_apply_damage(body)

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent: _apply_damage(parent)

func _apply_damage(body):
	if body.is_in_group("Enemy"):
		if not is_circle:
			if not body in hit_enemies:
				hit_enemies.append(body)
				if body.has_method("take_damage"):
					body.take_damage(damage, Vector3.ZERO, elements)
				if body.get("status_manager") != null:
					body.status_manager.apply_effect("slow", slow_duration, {"amount": 0.1})
		else:
			if body.get("status_manager") != null:
				body.status_manager.apply_effect("slow", 1.0, {"amount": 0.1})

func _shake_camera(intensity: float, duration: float):
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("apply_camera_shake"):
			player.apply_camera_shake(intensity, duration)
