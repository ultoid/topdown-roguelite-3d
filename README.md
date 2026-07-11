# 3D Action Roguelite RPG

Proyek ini adalah evolusi dari *Top Down Action Game* 2D menjadi petualangan 3D seutuhnya. Seluruh komponen logika, fisika pergerakan, hingga perhitungan jarak jangkauan proyektil dan *skill* yang asalnya dalam bentuk piksel kini telah ditranslasikan secara terukur ke dalam dimensi metrik 3D.

Gim ini mengusung genre Action Roguelite dengan sudut pandang *Top Down* (ala Diablo). Pemain dapat menjelajahi dunia, bertarung menggunakan berbagai jenis senjata dan sihir, mengumpulkan perlengkapan (Loot), serta meningkatkan level kelas karakter.

## Fitur Utama
- **Combat Dinamis**: Pertarungan *hack and slash* cepat dengan dukungan rotasi arah otomatis (Aiming) dan sistem Hitbox/Hurtbox multi-layer.
- **Weapon System**: Berbagai macam tipe senjata (Pedang, Tongkat Sihir, Busur, Belati, dsb) yang masing-masing mengubah animasi dan *playstyle* karakter.
- **Character Customization**: Sesuaikan penampilan karakter dari bentuk rambut, jenggot, hingga *equipment* zirah yang dipakai (visual equipment dinamis).
- **Skill & Class System**: Pemain dapat memilih dan mengembangkan kelas (Fighter, Apprentice, Scout) beserta sistem *skill tree* masing-masing.

## Pengembangan (Development)
Untuk log perubahan harian, catatan arsitektur teknis, sistem dinamis, serta masalah yang belum terselesaikan (Known Issues), silakan merujuk ke file:
- **[Developer Notes & Architecture](DEV_NOTES.md)**
- **[Change Log Harian](Change%20Log/)**

---

### To Do List
- [ ] Menyelesaikan Migrasi 2D ke 3D all component and system
  - [x] Fix Skill Apprentice
  - [x] Fix Skill Scout
- [x] Melengkapi animasi model 3d
  - [x] Long Sword Animation
  - [x] Sword Animation
  - [x] Bow Animation
  - [x] Crossbow Animation
  - [x] Dagger Animation
  - [x] Staff Animation
  - [x] Rune Animation
  - [x] Lance Animation
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
  - [x] `SyntyColorTool` — Editor Plugin untuk Dynamic Real-time Component Coloring
  - [ ] Selesaikan `Hair_db.tscn` & `Beard_db.tscn`
  - [ ] Tambahkan variasi Wajah & Warna Kulit
- [x] **[REFACTOR]** Merombak total struktur skeleton, model, dan animasi
- [x] Menyelesaikan semua animasi base (idle, walk, run, attack, death, damage)
- [ ] Melanjutkan development ke arah mapping dan scenario story
