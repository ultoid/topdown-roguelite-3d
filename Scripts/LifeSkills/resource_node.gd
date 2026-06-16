extends Area3D

@export var yield_item: String = "stone"
@export var required_tool: String = "pickaxe"
@export var required_cycles: int = 2
@export var respawn_time: float = 10.0
@export var yield_amount: int = 1

@onready var sprite = $MeshInstance3D
@onready var collision = $CollisionShape3D

var is_active = true

func _ready():
	add_to_group("Interactable")
	# 3D Note: For MeshInstance3D, instead of changing frame, you would load different meshes/materials here.
	# e.g., if yield_item == "stone": sprite.mesh = load("res://models/stone.obj")
	pass

func on_interact(player):
	if not is_active: return
	
	# Check if player has the tool
	if not Global.inventory.has(required_tool) or Global.inventory[required_tool] <= 0:
		player.spawn_floating_text("Butuh " + required_tool.capitalize() + "!", Color(1, 0.2, 0.2))
		return
		
	player.start_life_skill(self, required_cycles, "mining" if required_tool == "pickaxe" else "logging")

func on_cancel():
	pass

func on_complete(player):
	# Give item
	if not Global.inventory.has(yield_item):
		Global.inventory[yield_item] = 0
	Global.inventory[yield_item] += yield_amount
	player.spawn_floating_text("+" + str(yield_amount) + " " + yield_item.capitalize(), Color(1, 1, 0))
	
	# Hide and start respawn
	is_active = false
	sprite.visible = false
	collision.set_deferred("disabled", true)
	
	await get_tree().create_timer(respawn_time).timeout
	
	# Respawn
	is_active = true
	sprite.visible = true
	collision.set_deferred("disabled", false)
