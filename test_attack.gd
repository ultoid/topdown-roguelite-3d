extends SceneTree

func _init():
    var scene = preload("res://Scenes/Maps/forest.tscn").instantiate()
    root.add_child(scene)
    
    var player = scene.get_node("Player")
    print("[TEST] Player found: ", player.name)
    
    var enemy = scene.get_node("enemy_group/red_player_enemy")
    print("[TEST] Enemy HP before: ", enemy.current_health)
    
    # Simulate attack
    player.player_combat.attack(false)
    
    # Process for 1 second (60 frames)
    for i in range(60):
        process(0.016)
        
    print("[TEST] Enemy HP after: ", enemy.current_health)
    
    quit()
