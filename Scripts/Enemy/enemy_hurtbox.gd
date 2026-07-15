extends Area3D
class_name EnemyHurtbox

var is_active: bool = true
var damage_multiplier: float = 1.0

var enemy: Node = null

func _ready():
	collision_layer = 4
	collision_mask = 0
	
	# Cari node yang memiliki method take_damage (parent)
	var curr = get_parent()
	while curr != null:
		if curr.has_method("take_damage"):
			enemy = curr
			break
		curr = curr.get_parent()

## Panggil ini sebagai pengganti langsung take_damage()
func receive_hit(damage: int, source_pos: Vector3,
				 elements: Array = ["netral"], kb_force: float = 3.0):
	if not is_active: return
	if not is_instance_valid(enemy): return
	if enemy.get("is_dead"): return
	var final_dmg = int(damage * damage_multiplier)
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_dmg, source_pos, elements, kb_force)

## Buat enemy invincible selama durasi (i-frame setelah kena hit)
func set_invincible(duration: float):
	is_active = false
	get_tree().create_timer(duration).timeout.connect(func(): is_active = true)

## Terapkan damage reduction dari shield
func apply_shield(reduction_multiplier: float, duration: float):
	damage_multiplier = reduction_multiplier
	get_tree().create_timer(duration).timeout.connect(func(): damage_multiplier = 1.0)
