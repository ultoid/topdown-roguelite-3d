# Developer Notes & Architecture

Dokumen ini berisi catatan teknis pengembangan, arsitektur sistem, serta isu-isu yang sedang ditangani.

## Known Issues

### ⚠️ Skin Bind Tulang Jari Tangan Tidak Menempel
Saat runtime, Godot menampilkan notifikasi berulang:
`_notification: Skin bind #XX contains named bind 'index_01_l' but Skeleton3D has no bone by that name.`

Penyebabnya adalah **perbedaan konvensi penamaan tulang** antara Skin mesh dan `Skeleton3D`:
- Skin mencari: `index_01_l`, `middle_01_r`, dst. *(snake_case / Mixamo-style)*
- Skeleton3D memiliki: `RightIndexProximal`, `RightMiddleProximal`, dst. *(PascalCase / Humanoid-style)*

Game masih bisa berjalan (bukan error fatal), namun **animasi jari tangan tidak berfungsi**. Belum terselesaikan.

### ⏳ Retargeting Animasi Explosive LLC → Mixamo (Dalam Proses)
Integrasi animasi **Explosive LLC** (skeleton Unreal/`B_Pelvis`) ke karakter **Synty** (Mixamo rig) menghadapi beberapa rintangan:

- FBX *Animation Only* dari Explosive LLC **tidak membentuk `Armature`** saat diimpor ke Blender — melainkan hierarki objek **`Empty`/Null node**.
- Akibatnya, **Rokoko Studio Live** menolak sumber animasi tersebut (*"No results found"*) karena hanya menerima `Armature`.
- **BoneMap Retargeting bawaan Godot 4** juga gagal karena FBX tanpa mesh tidak menghasilkan node `Skeleton3D` yang valid.

**Solusi yang sedang diuji:** Script Python Blender otomatis (`DevTools/blender_retarget_explosive_to_mixamo.py`) yang mengkonversi hierarki `Empty` → `Armature`, lalu melakukan retarget via constraint + visual bake.

## Architecture & Dev Notes

### Dynamic Animation System
Sistem animasi *combat* dan *movement* karakter bersifat **sepenuhnya dinamis** dan menyesuaikan dengan senjata yang dipakai secara otomatis, tanpa *hardcode*.
1. Skrip `player.gd` memiliki fungsi `get_anim_state(base_state)` yang otomatis mendeteksi tipe senjata dari `ItemDB` (misal: `long_sword`).
2. Kode akan memanggil state `[weapon_type]_[base_state]` ke `AnimationTree`. Contoh: jika memanggil `Attack` dengan pedang, ia akan otomatis mencari node `long_sword_Attack`.
3. Jika node tersebut tidak ditemukan di *AnimationTree*, sistem akan melakukan *fallback* dengan selamat ke state `Attack` biasa.
4. **Skill Animasi**: Durasi skill didapatkan dengan membaca durasi state animasi yang namanya persis seperti nama skill (contoh: skill `seismic_fissure` akan mencari state bernama `SeismicFissure`).
5. **Inverse Kinematics (IK) Senjata 2 Tangan**: Terdapat sistem `SkeletonIK3D` otomatis untuk tangan kiri (*off-hand*). Sistem mendeteksi senjata bertipe 2-tangan, lalu mengikat tangan kiri ke node `LeftHand_Target` (Marker3D) pada senjata tersebut secara dinamis.

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
