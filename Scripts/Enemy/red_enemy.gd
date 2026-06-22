extends "res://Scripts/Enemy/enemy.gd"

func _ready():
	super._ready()
	# Memutar model 180 derajat (PI radian) karena model aslinya menghadap +Z (terbalik)
	var enemy_model = get_node_or_null("Visuals/enemy")
	if enemy_model:
		enemy_model.rotation.y = PI
