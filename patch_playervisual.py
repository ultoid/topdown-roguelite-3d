import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

file_path = "Scenes/PlayerVisual.tscn"
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Tambah ext_resource untuk script setelah header
header = '[gd_scene format=4 uid="uid://c6teg26na3vpc"]'
script_ext = '[gd_scene format=4 uid="uid://c6teg26na3vpc"]\n\n[ext_resource type="Script" path="res://Scripts/Player/player_visual.gd" id="99_pvis"]'

if '99_pvis' not in content:
    content = content.replace(header, script_ext, 1)
    print("OK: Ext resource script ditambahkan")
else:
    print("SKIP: Ext resource sudah ada")

# 2. Tambah script = ExtResource ke node root PlayerVisual
old_node = '[node name="PlayerVisual" type="Node3D" unique_id=1410697190]'
new_node = '[node name="PlayerVisual" type="Node3D" unique_id=1410697190]\nscript = ExtResource("99_pvis")'

if 'script = ExtResource("99_pvis")' not in content:
    content = content.replace(old_node, new_node, 1)
    print("OK: Script dipasang ke node PlayerVisual")
else:
    print("SKIP: Script sudah terpasang")

with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print("DONE: PlayerVisual.tscn telah diperbarui.")
