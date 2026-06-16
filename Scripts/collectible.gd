extends Area3D

enum ItemType { COIN, EXP }
@export var type: ItemType = ItemType.COIN
@export var amount: int = 1

var player: Node3D = null
var magnet_speed: float = 0.0

func _ready():
	# Item terlempar secara acak sedikit saat spawn (efek meletup dari musuh)
	var random_offset = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position + random_offset, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Fitur Magnet Otomatis
	if player == null:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var p = players[0]
			var distance = global_position.distance_to(p.global_position)
			
			# Jika player mendekat dalam radius 50 pixel, item akan tersedot!
			if distance < 50.0:
				player = p
	else:
		# Item terbang mengejar player dengan kecepatan yang semakin meningkat
		magnet_speed += 800.0 * delta
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if type == ItemType.COIN:
			if body.has_method("add_coin"):
				body.add_coin(amount)
		elif type == ItemType.EXP:
			if body.has_method("add_exp"):
				body.add_exp(amount)
				
		queue_free()
