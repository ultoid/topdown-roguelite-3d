# 3D Action Roguelite RPG

Proyek ini adalah evolusi dari *Top Down Action Game* 2D menjadi petualangan 3D seutuhnya. Seluruh komponen logika, fisika pergerakan, hingga perhitungan jarak jangkauan proyektil dan *skill* yang asalnya dalam bentuk piksel (*Vector2*) kini telah ditranslasikan secara terukur ke dalam dimensi metrik 3D (*Vector3*).

Perubahan mendasar yang ada dalam sistem 3D ini meliputi penggantian `CharacterBody2D` menjadi `CharacterBody3D`, `CollisionShape` ke dimensi volumetrik (`BoxShape3D`, `CapsuleShape3D`, `CylinderShape3D`), serta penggunaan Node spasial untuk interaksi dunia, proyektil, dan musuh.

## To Do List
- [ ] Menyelesaikan Migrasi 2D ke 3D all component and system
  - [x] Fix Skill Apprentice
  - [x] Fix Skill Scout
- [ ] Melengkapi animasi model 3d
  - [x] Long Sword Animation
  - [ ] Sword Animation
  - [ ] Bow Animation
  - [ ] Crossbow Animation
  - [ ] Dagger Animation
  - [ ] Staff Animation
  - [x] Rune Animation
  - [ ] Lance Animation
- [x] Implementasi animasi ke game (Synty Modular)
- [ ] Sistem Visual Equipment (Armor, Helm, Boots)
  - [x] Struktur slot node di player.tscn
  - [x] Fungsi `update_visual_equipment()` di player.gd
  - [ ] Membuat scene armor/helm/boots pertama
  - [ ] Integrasi dengan ItemDB
- [ ] Sistem Character Customization
  - [x] Base system dengan `Global.gd` customization state
  - [x] Dynamic bone merging untuk tulang hair_dyn & fchr_dyn
  - [x] UI Kustomisasi dengan Realtime 3D Preview (SubViewport)
  - [x] Offset system & PartAlignmentTool (DevTool)
  - [x] Perbaikan orientasi & skala offset part kustomisasi
  - [x] `PlayerVisual.gd` — Auto bone merge editor tool untuk workflow Hair/Beard DB
  - [ ] Selesaikan `Hair_db.tscn` & `Beard_db.tscn`
  - [ ] Tambahkan variasi Wajah & Warna Kulit

## Architecture & Dev Notes

### Dynamic Animation System
Sistem animasi *combat* dan *movement* karakter bersifat **sepenuhnya dinamis** dan menyesuaikan dengan senjata yang dipakai secara otomatis, tanpa *hardcode*.
1. Skrip `player.gd` memiliki fungsi `get_anim_state(base_state)` yang otomatis mendeteksi tipe senjata dari `ItemDB` (misal: `long_sword`).
2. Kode akan memanggil state `[weapon_type]_[base_state]` ke `AnimationTree`. Contoh: jika memanggil `Attack` dengan pedang, ia akan otomatis mencari node `long_sword_Attack`.
3. Jika node tersebut tidak ditemukan di *AnimationTree*, sistem akan melakukan *fallback* dengan selamat ke state `Attack` biasa.
4. **Skill Animasi**: Durasi skill didapatkan dengan membaca durasi state animasi yang namanya persis seperti nama skill (contoh: skill `seismic_fissure` akan mencari state bernama `SeismicFissure`).

### Workflow Aset 3D & Animasi
1. Model karakter dan model senjata **harus diekspor secara terpisah** dari Blender menggunakan format **`.fbx`** (bukan `.glb`). Pedang/senjata diletakkan di Blender hanya sebagai referensi animasi.
2. Di Godot, file animasi `.fbx` diekstrak menjadi file mandiri (`.res` atau `.tres`). Masalah terkait path tulang bawaan saat ini ditangani via teks editor atau UI secara manual, lalu didaftarkan ke `AnimationPlayer`.
3. Gunakan node `BoneAttachment3D` pada `Skeleton3D` untuk menempelkan model 3D senjata (misal: ke tulang tangan karakter) agar senjatanya bisa diganti secara dinamis saat permainan berjalan.
4. **Modular Weapon Scenes**: Senjata kini diimplementasikan menggunakan pendekatan *Modular Scene*. Fisik 3D senjata beserta *hitbox* area serangannya disimpan di dalam file `.tscn` terpisah dan di-*load* berdasarkan `weapon_scene_path` dari *Item Database*.

### Workflow Hair & Beard DB
1. Buka scene `PlayerVisual.tscn` di editor.
2. Drag FBX rambut/jenggot dari FileSystem ke bawah node `Base_Hair` atau `Cust_Beard`.
3. Script `PlayerVisual.gd` (`@tool`) secara otomatis meng-*merge* physics bones dari FBX ke `GeneralSkeleton` sehingga rambut tampil benar di editor.
4. Posisikan FBX hingga rambut menempel sempurna di kepala T-pose karakter.
5. Setelah semua variasi rambut/jenggot diposisikan, minta Antigravity untuk mengekstrak dan membuat `Hair_db.tscn` & `Beard_db.tscn`.

### Physics Bones pada Hair FBX (Synty)
Model rambut Synty memiliki 3 tulang physics tambahan (`hair_dyr_01`, `hair_dyr_01_l`, dll) yang tidak ada di `GeneralSkeleton` standar (88 bone). Jika tidak di-merge, vertex yang terpengaruh tulang ini akan "nyangkut" di posisi kaki karakter. Script `PlayerVisual.gd` menangani ini secara otomatis menggunakan inverse bind matrix dari `Skin` resource.

## Change Log

### 30 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-30.md)

### 29 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-29.md)

### 20 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-20.md)

### 21 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-21.md)

### 22 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-22.md)

### 23 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-23.md)

### 24 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-24.md)

### 25 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-25.md)

### 27 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-27.md)

### 28 Juni 2026
[Lihat detail perubahan](Change%20Log/2026-06-28.md)
