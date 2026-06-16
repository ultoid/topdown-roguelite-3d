extends Area3D

@export var yield_item: String = "herb"
@export var respawn_time: float = 30.0
@export var yield_amount: int = 1

@onready var sprite = $MeshInstance3D
@onready var collision = $CollisionShape3D

var is_active = true

func _ready():
	add_to_group("Interactable")
	# 3D Note: Change meshes/materials dynamically here instead of atlas frames
	pass

func on_interact(player):
	if not is_active: return
	
	if not Global.inventory.has(yield_item):
		Global.inventory[yield_item] = 0
	Global.inventory[yield_item] += yield_amount
	player.spawn_floating_text("+" + str(yield_amount) + " " + yield_item.capitalize(), Color(0.2, 1, 0.2))
	
	is_active = false
	sprite.visible = false
	collision.set_deferred("disabled", true)
	
	await get_tree().create_timer(respawn_time).timeout
	
	is_active = true
	sprite.visible = true
	collision.set_deferred("disabled", false)
