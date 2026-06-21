extends Area3D

enum ItemType { COIN, EXP }
@export var type: ItemType = ItemType.COIN
@export var amount: int = 1

var player: Node3D = null
var magnet_speed: float = 0.0
var picked_up: bool = false

# Jarak agar item mulai tersedot ke player
const MAGNET_DISTANCE: float = 5.0
# Jarak agar item langsung terpickup (tanpa bergantung pada collision layer)
const PICKUP_DISTANCE: float = 0.6

func _ready():
	# Item terlempar sedikit secara acak saat spawn
	var random_offset = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position + random_offset, 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Cari player langsung — tidak bergantung pada signal collision
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if picked_up or not is_instance_valid(player):
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Jika sudah sangat dekat → langsung pickup tanpa perlu collision
	if distance <= PICKUP_DISTANCE:
		_collect(player)
		return
	
	# Jika dalam radius magnet → terbang mengejar player
	if distance <= MAGNET_DISTANCE:
		magnet_speed = min(magnet_speed + 15.0 * delta, 20.0)
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta
	else:
		magnet_speed = 0.0 # Reset speed jika player menjauh

func _collect(body: Node3D):
	if picked_up:
		return
	picked_up = true
	if type == ItemType.COIN:
		if body.has_method("add_coin"):
			body.add_coin(amount)
	elif type == ItemType.EXP:
		if body.has_method("add_exp"):
			body.add_exp(amount)
	queue_free()
