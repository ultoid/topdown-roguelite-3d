extends Area3D

func on_interact(player):
    get_parent().on_interact(player)
