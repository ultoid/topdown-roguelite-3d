extends Node
class_name PlayerLifeSkill

var player: CharacterBody3D

var is_doing_life_skill: bool = false
var life_skill_target: Node = null
var life_skill_type: String = ""
var life_skill_progress: int = 0
var life_skill_max_progress: int = 0
var life_skill_bar: ProgressBar = null

var is_farming_targeting: bool = false
var farming_zone_ref: Node = null
var farming_indicator: MeshInstance3D = null

var is_auto_walking: bool = false
var auto_walk_target: Vector3 = Vector3.ZERO
var auto_walk_callback: Callable = Callable()

func setup(p_player: CharacterBody3D):
	player = p_player

func _cancel_life_skill():
	is_doing_life_skill = false
	if is_instance_valid(life_skill_bar):
		life_skill_bar.queue_free()
	if life_skill_target and is_instance_valid(life_skill_target) and life_skill_target.has_method("on_cancel"):
		life_skill_target.on_cancel()
	life_skill_target = null

func start_life_skill(target_node: Node, required_cycles: int, skill_type: String = ""):
	if is_doing_life_skill or player.is_attacking or player.is_dashing or player.is_casting: return
	is_doing_life_skill = true
	life_skill_target = target_node
	life_skill_type = skill_type
	life_skill_max_progress = required_cycles
	life_skill_progress = 0
	
	life_skill_bar = ProgressBar.new()
	life_skill_bar.min_value = 0
	life_skill_bar.max_value = required_cycles
	life_skill_bar.value = 0
	life_skill_bar.show_percentage = false
	life_skill_bar.custom_minimum_size = Vector2(40, 6)
	life_skill_bar.position = Vector2(-20, -30)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	life_skill_bar.add_theme_stylebox_override("background", sb_bg)
	life_skill_bar.add_theme_stylebox_override("fill", sb_fg)
	player._get_hud_canvas().add_child(life_skill_bar)
	
	_life_skill_loop()

func _life_skill_loop():
	while is_doing_life_skill and is_instance_valid(life_skill_target):
		var target_dir = (life_skill_target.global_position - player.global_position).normalized()
		
		# Snap to 4-way direction to prevent animation blend issues (sprite disappearing)
		var anim_dir = target_dir
		if abs(anim_dir.x) > abs(anim_dir.z):
			anim_dir.z = 0
		else:
			anim_dir.x = 0
		anim_dir = anim_dir.normalized()
		
		player.last_direction = anim_dir
		
		player.is_attacking = true
		player.current_attack_speed = 1.0
		
		var actual_len = player._get_state_length("Attack", player.base_attack_duration)
		player.current_anim_speed_ratio = actual_len / player.base_attack_duration
		
		if player.animation_tree:
			player.animation_tree.set("parameters/AttackTimeScale/scale", 1.0 * player.current_anim_speed_ratio)
			
		if player.state_machine:
			player.state_machine.travel("Attack")
			
		var duration = player.base_attack_duration
		await get_tree().create_timer(duration).timeout
		
		player.is_attacking = false
		if player.state_machine: player.state_machine.travel("Idle")
		
		if not is_doing_life_skill or not is_instance_valid(life_skill_target):
			break
			
		life_skill_progress += 1
		if is_instance_valid(life_skill_bar):
			life_skill_bar.value = life_skill_progress
			
		if life_skill_progress >= life_skill_max_progress:
			var target = life_skill_target
			_cancel_life_skill() # Bersihkan UI
			if target and is_instance_valid(target) and target.has_method("on_complete"):
				target.on_complete(player)
			player.spawn_floating_text("Selesai!", Color(0.2, 1, 0.2))
			break


func start_farming_targeting(zone):
	if is_farming_targeting or is_doing_life_skill or player.is_targeting: return
	is_farming_targeting = true
	farming_zone_ref = zone
	
	farming_indicator = MeshInstance3D.new()
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(20, 20)
	farming_indicator.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	farming_indicator.material_override = mat
	
	player.get_parent().add_child(farming_indicator)

func _cancel_farming_targeting():
	set_deferred("is_farming_targeting", false)
	if is_instance_valid(farming_indicator):
		farming_indicator.queue_free()
	farming_zone_ref = null

func _confirm_farming():
	var pos = farming_indicator.global_position
	var zone = farming_zone_ref
	
	if zone and zone.has_method("is_valid_plot_pos"):
		if not zone.is_valid_plot_pos(pos):
			player.spawn_floating_text("Posisi tidak valid!", Color(1, 0.2, 0.2))
			return
			
	_cancel_farming_targeting()
	
	if zone and is_instance_valid(zone):
		start_auto_walk(pos, func():
			zone.target_pos = pos
			start_life_skill(zone, 1, "farming")
		)

func start_auto_walk(target_pos: Vector3, callback: Callable):
	is_auto_walking = true
	auto_walk_target = target_pos
	auto_walk_callback = callback
	if player.nav_agent:
		player.nav_agent.target_position = target_pos

func _cancel_auto_walk():
	is_auto_walking = false
	auto_walk_callback = Callable()

func _complete_auto_walk():
	is_auto_walking = false
	if auto_walk_callback.is_valid():
		auto_walk_callback.call()
	auto_walk_callback = Callable()
