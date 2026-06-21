extends Node
class_name StatusEffectManager
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

signal status_changed()

var target: Node3D = null
var is_player: bool = false

# Format: { "effect_id": { "duration": float, "amount": float, "tick_timer": float, "source_pos": Vector3 } }
var active_effects: Dictionary = {}

var confused_dir: Vector3 = Vector3.ZERO
var confused_timer: float = 0.0

var blind_overlay_node: Node = null
var curse_icon_node: Node3D = null
var holy_veil_node: CSGCylinder3D = null

func setup(t: Node3D):
	target = t
	is_player = target.is_in_group("Player")
	
func apply_effect(effect_id: String, duration: float, extra_data: Dictionary = {}):
	var amount = extra_data.get("amount", 0.0)
	var source_pos = extra_data.get("source_pos", Vector3.ZERO)
	
	if active_effects.has(effect_id):
		if duration >= active_effects[effect_id]["duration"]:
			active_effects[effect_id]["duration"] = duration
		if amount > active_effects[effect_id]["amount"]:
			active_effects[effect_id]["amount"] = amount
		active_effects[effect_id]["source_pos"] = source_pos
		for k in extra_data.keys():
			if k not in ["amount", "source_pos", "duration"]:
				active_effects[effect_id][k] = extra_data[k]
	else:
		active_effects[effect_id] = {
			"duration": duration,
			"amount": amount,
			"tick_timer": 1.0,
			"source_pos": source_pos
		}
		for k in extra_data.keys():
			if k not in ["amount", "source_pos", "duration"]:
				active_effects[effect_id][k] = extra_data[k]
		
	if effect_id == "confuse":
		_randomize_confuse_dir()
		
	emit_signal("status_changed")
	update_visuals()

func remove_effect(effect_id: String):
	if active_effects.has(effect_id):
		active_effects.erase(effect_id)
		emit_signal("status_changed")
		update_visuals()

func get_effect_data(effect_id: String) -> Dictionary:
	if active_effects.has(effect_id):
		return active_effects[effect_id]
	return {}
	
func has_effect(effect_id: String) -> bool:
	return active_effects.has(effect_id)

func _physics_process(delta):
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
		
	var effects_to_remove = []
	var current_keys = active_effects.keys()
	for effect_id in current_keys:
		if not active_effects.has(effect_id):
			continue
			
		var effect = active_effects[effect_id]
		effect["duration"] -= delta
		
		# DoT ticks
		if effect_id in ["poison", "burn", "bleed", "curse", "soul_drain"]:
			effect["tick_timer"] -= delta
			if effect["tick_timer"] <= 0:
				effect["tick_timer"] = 1.0
				var dmg = effect["amount"]
				if effect_id == "bleed" and target.get("velocity") != null and target.velocity != Vector3.ZERO:
					dmg *= 2.0
				
				if effect_id == "soul_drain":
					dmg = effect.get("damage", 10)
					var elements = effect.get("elements", ["kegelapan"])
					if dmg > 0:
						target.take_damage(dmg, Vector3.ZERO, elements)
						var p = effect.get("player", null)
						if is_instance_valid(p) and p.has_method("restore_hp"):
							p.restore_hp(int(dmg * 0.5))
				elif dmg > 0:
					target.take_damage(dmg, Vector3.ZERO)
		
		if effect_id == "confuse":
			confused_timer -= delta
			if confused_timer <= 0:
				_randomize_confuse_dir()
				
		if effect["duration"] <= 0:
			effects_to_remove.append(effect_id)
			
	for effect_id in effects_to_remove:
		active_effects.erase(effect_id)
		
	var taunt_mark = target.get_node_or_null("TauntMark")
	if active_effects.has("taunt"):
		if not taunt_mark:
			taunt_mark = Label3D.new()
			taunt_mark.name = "TauntMark"
			taunt_mark.text = "💢"
			taunt_mark.modulate = Color(1, 0.2, 0.2)
			taunt_mark.position = Vector3(0, 2.5, 0)
			taunt_mark.pixel_size = 0.05
			taunt_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			taunt_mark.no_depth_test = true
			target.add_child(taunt_mark)
	else:
		if taunt_mark:
			taunt_mark.queue_free()

	var stun_mark = target.get_node_or_null("StunMark")
	if active_effects.has("stun"):
		if not stun_mark:
			stun_mark = Label3D.new()
			stun_mark.name = "StunMark"
			stun_mark.text = "💫"
			stun_mark.modulate = Color(1, 1, 0.5)
			stun_mark.position = Vector3(0, 3.0, 0)
			stun_mark.pixel_size = 0.05
			stun_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			stun_mark.no_depth_test = true
			target.add_child(stun_mark)
	else:
		if stun_mark:
			stun_mark.queue_free()

	var hunters_mark = target.get_node_or_null("HuntersMark")
	if active_effects.has("hunters_mark"):
		if not hunters_mark:
			hunters_mark = Label3D.new()
			hunters_mark.name = "HuntersMark"
			hunters_mark.text = "🎯"
			hunters_mark.modulate = Color(1, 0.3, 0.3)
			hunters_mark.position = Vector3(0, 3.5, 0)
			hunters_mark.pixel_size = 0.05
			hunters_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			hunters_mark.no_depth_test = true
			target.add_child(hunters_mark)
	else:
		if hunters_mark:
			hunters_mark.queue_free()

	if effects_to_remove.size() > 0:
		emit_signal("status_changed")
		update_visuals()
		
func _randomize_confuse_dir():
	confused_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	confused_timer = randf_range(0.5, 1.5)

# --- GETTERS ---
func get_speed_multiplier() -> float:
	var mult = 1.0
	if has_effect("chill"): mult *= 0.6
	if has_effect("burn"): mult *= 0.8
	if has_effect("slow"):
		var amt = active_effects["slow"].get("amount", 0.0)
		if amt <= 0.0: amt = 0.5 # Default 50% slow
		mult *= amt
	return mult

func get_attack_speed_multiplier() -> float:
	var mult = 1.0
	if has_effect("chill"): mult *= 0.6
	if has_effect("paralyze"): mult *= 0.5
	if has_effect("haste"): mult *= 2.0
	return mult
	
func get_damage_taken_multiplier() -> float:
	var mult = 1.0
	if has_effect("vulnerable") or has_effect("sleep"):
		mult *= 1.5
	if has_effect("hunters_mark"):
		mult *= 2.0
	return mult

func can_move() -> bool:
	if has_effect("holy_veil"): return true
	if has_effect("freeze") or has_effect("sleep") or has_effect("root") or has_effect("stun"):
		return false
	return true
	
func get_movement_restriction_name() -> String:
	if has_effect("freeze"): return "Freeze"
	if has_effect("sleep"): return "Sleep"
	if has_effect("root"): return "Root"
	return "Status"
	
func can_attack() -> bool:
	if has_effect("holy_veil"): return true
	if has_effect("freeze") or has_effect("sleep"):
		return false
	return true

func can_cast() -> bool:
	if has_effect("silence"): return false
	if has_effect("holy_veil"): return true
	if has_effect("freeze") or has_effect("sleep") or has_effect("stun") or has_effect("paralyze"):
		return false
	return true

func get_override_element() -> String:
	# Jika punya buff elemen, return elemennya. (Contoh: "mantel_api" -> "api")
	for eff in active_effects.keys():
		if eff.begins_with("mantel_"):
			return eff.replace("mantel_", "")
	return ""
	
func can_heal() -> bool:
	if has_effect("curse"):
		return false
	return true

func handle_damage_taken():
	if has_effect("sleep"): remove_effect("sleep")
	if has_effect("freeze"):
		remove_effect("freeze")
		apply_effect("chill", 3.0)
		
func get_override_movement(original_dir: Vector3) -> Vector3:
	if has_effect("fear"):
		var sp = active_effects["fear"].get("source_pos", target.global_position)
		if sp != target.global_position:
			return (target.global_position - sp).normalized()
		else:
			return confused_dir
	if has_effect("confuse"):
		return confused_dir
	return original_dir
	
func get_active_buffs() -> Array:
	return []
	
func get_active_debuffs() -> Array:
	var list = []
	for e in active_effects.keys():
		list.append({"id": e, "duration": active_effects[e]["duration"]})
	return list

func update_visuals():
	if not is_instance_valid(target): return
	
	if has_effect("freeze"): target.modulate = Color(0.4, 0.8, 1.0)
	elif has_effect("chill"): target.modulate = Color(0.7, 0.9, 1.0)
	elif has_effect("poison"): target.modulate = Color(0.4, 1.0, 0.4)
	elif has_effect("burn"): target.modulate = Color(1.0, 0.5, 0.2)
	elif has_effect("bleed"): target.modulate = Color(1.0, 0.3, 0.3)
	elif has_effect("paralyze"): target.modulate = Color(1.0, 1.0, 0.2)
	elif has_effect("sleep"): target.modulate = Color(0.5, 0.5, 0.8)
	elif has_effect("confuse"): target.modulate = Color(0.8, 0.4, 0.8)
	elif has_effect("curse"): target.modulate = Color(0.3, 0.0, 0.4)
	elif has_effect("stun"): target.modulate = Color(0.7, 0.7, 0.7)
	else: target.modulate = Color(1, 1, 1)
	
	if has_effect("shadow_walk"):
		target.modulate.a = 0.5
	
	if has_effect("curse"):
		if not is_instance_valid(curse_icon_node):
			curse_icon_node = Label3D.new()
			curse_icon_node.text = "💀"
			curse_icon_node.modulate = Color(0.4, 0.0, 0.6, 0.9)
			curse_icon_node.position = Vector3(0, 3.5, 0)
			curse_icon_node.pixel_size = 0.05
			curse_icon_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			curse_icon_node.no_depth_test = true
			target.add_child(curse_icon_node)

	else:
		if is_instance_valid(curse_icon_node):
			curse_icon_node.queue_free()
			curse_icon_node = null

	if has_effect("holy_veil"):
		if not is_instance_valid(holy_veil_node):
			holy_veil_node = CSGCylinder3D.new()
			holy_veil_node.radius = 0.8
			holy_veil_node.height = 2.0
			holy_veil_node.position = Vector3(0, 1.0, 0)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 1.0, 0.2, 0.4) # Yellow transparent
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			holy_veil_node.material = mat
			target.add_child(holy_veil_node)
	else:
		if is_instance_valid(holy_veil_node):
			holy_veil_node.queue_free()
			holy_veil_node = null

	if is_player:
		if has_effect("blind"):
			if not is_instance_valid(blind_overlay_node):
				var BlindScript = load("res://Scripts/blind_overlay.gd")
				if BlindScript:
					blind_overlay_node = BlindScript.new()
					target.get_tree().current_scene.add_child(blind_overlay_node)
					blind_overlay_node.setup(target)
		else:
			if is_instance_valid(blind_overlay_node):
				blind_overlay_node.queue_free()
				blind_overlay_node = null
