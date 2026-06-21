import os

PROJECT_DIR = r"e:\Top Down Action Game\topdownaction-3d"
SCRIPTS_DIR = os.path.join(PROJECT_DIR, "Scripts")

# Folders to create
FOLDERS = ["Player", "PlayerClasses", "Enemy", "Skills", "System", "UI", "World"]

# File Mapping: "filename.gd": "Folder"
FILE_MAP = {
    "player.gd": "Player", "player_hud.gd": "Player", "target_indicator.gd": "Player",
    "sword_hitbox.gd": "Player", "blind_overlay.gd": "Player", "player_projectile.gd": "Player",
    "enemy.gd": "Enemy", "boss_enemy.gd": "Enemy", "ranged_enemy.gd": "Enemy",
    "red_enemy.gd": "Enemy", "dummy_enemy.gd": "Enemy", "enemy_projectile.gd": "Enemy",
    "aqua_blast_wave.gd": "Skills", "arrow_projectile.gd": "Skills", "arrow_rain.gd": "Skills",
    "fireball.gd": "Skills", "fire_bolt.gd": "Skills", "seismic_fissure_hazard.gd": "Skills",
    "skill_db.gd": "Skills", "skill_data.gd": "Skills",
    "global.gd": "System", "item_db.gd": "System", "item_data.gd": "System",
    "element_db.gd": "System", "status_effect_manager.gd": "System", "status_icon_manager.gd": "System",
    "character_menu.gd": "UI", "inventory_menu.gd": "UI", "shop_menu.gd": "UI",
    "buff_shop_menu.gd": "UI", "dialogue_box.gd": "UI", "game_over_hud.gd": "UI",
    "debug_status_menu.gd": "UI", "skill_menu.gd": "UI", "boss_hud.gd": "UI",
    "npc.gd": "World", "class_mentor.gd": "World", "collectible.gd": "World", "grinding_camp.gd": "World",
}

replacements = {}
for file_name, folder in FILE_MAP.items():
    old_res_path = f"res://Scripts/{file_name}"
    new_res_path = f"res://Scripts/{folder}/{file_name}"
    replacements[old_res_path.encode('utf-8')] = new_res_path.encode('utf-8')
    replacements[old_res_path.encode('utf-16le')] = new_res_path.encode('utf-16le')

for root, dirs, files in os.walk(PROJECT_DIR):
    if ".git" in root or ".godot" in root:
        continue
    for file in files:
        if file.endswith((".tscn", ".tres", ".gd")):
            filepath = os.path.join(root, file)
            with open(filepath, 'rb') as f:
                content = f.read()
            
            modified = False
            for old_res, new_res in replacements.items():
                if old_res in content:
                    content = content.replace(old_res, new_res)
                    modified = True
            
            if modified:
                with open(filepath, 'wb') as f:
                    f.write(content)
                print(f"Updated references in {file}")

print("Done!")
