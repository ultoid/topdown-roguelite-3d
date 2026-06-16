# 3D Action Roguelite RPG

Proyek ini adalah evolusi dari *Top Down Action Game* 2D menjadi petualangan 3D seutuhnya. Seluruh komponen logika, fisika pergerakan, hingga perhitungan jarak jangkauan proyektil dan *skill* yang asalnya dalam bentuk piksel (*Vector2*) kini telah ditranslasikan secara terukur ke dalam dimensi metrik 3D (*Vector3*).

Perubahan mendasar yang ada dalam sistem 3D ini meliputi penggantian `CharacterBody2D` menjadi `CharacterBody3D`, `CollisionShape` ke dimensi volumetrik (`BoxShape3D`, `CapsuleShape3D`, `CylinderShape3D`), serta penggunaan Node spasial untuk interaksi dunia, proyektil, dan musuh.

## To Do List
- [ ] Menyelesaikan Migrasi 2D ke 3D all component and system
- [ ] Melengkapi animasi model 3d
- [ ] Implementasi animasi ke game
