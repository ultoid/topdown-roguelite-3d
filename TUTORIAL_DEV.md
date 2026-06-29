# Tutorial Pengembangan Nusvanir: Tales of The Dark Time

Dokumen ini berisi panduan teknis yang mudah dipahami bagi Anda yang ingin menambah konten game sendiri tanpa harus mengkoding dari nol.

---

## 1. Panduan Membuat NPC Baru
NPC di game ini sangat fleksibel (`Scenes/Entities/npc.tscn`). Anda bisa membuatnya sekadar untuk cerita (*lore*), membuka toko (Merchant), atau penjaga gerbang (Portal).

### Langkah-langkah:
1. Buka *scene* di mana Anda ingin meletakkan NPC (contoh: `Scenes/Maps/maincity.tscn`).
2. Tarik (*drag and drop*) file `Scenes/Entities/npc.tscn` dari panel FileSystem ke dalam layar kerja 3D Anda.
3. **Mengganti Visual/Model NPC**:
   - Klik NPC yang baru Anda masukkan.
   - Centang opsi **Editable Children** (klik kanan pada node NPC -> centang *Editable Children*).
   - Klik node `Sprite3D` atau `MeshInstance3D` yang muncul di dalam NPC tersebut.
   - Di bagian Inspector sebelah kanan, sesuaikan model 3D atau gambar *Sprite3D* karakter baru Anda.
4. **Mengubah Fungsi & Teks Percakapan NPC**:
   - Klik node utama NPC tersebut (yang bernama `NPC`).
   - Di panel Inspector paling atas, lihat bagian **Script Variables**.
   - `Npc Name`: Isi dengan nama karakter (misal: "Pak Tua").
   - `Dialogue Lines`: Klik tombol **Array**, lalu tambah elemen sesuai jumlah dialog. Isi setiap elemen dengan teks yang akan diucapkan NPC.
   - `Npc Type`: Ini adalah otak dari NPC tersebut!
     - Isi dengan `"Lore"` jika NPC hanya berfungsi untuk bercerita (setelah dialog selesai, tidak terjadi apa-apa).
     - Isi dengan `"Merchant"` jika Anda ingin memunculkan menu Toko (Beli/Jual) setelah dialog selesai.
     - Isi dengan `"Portal"` jika Anda ingin NPC ini memunculkan pilihan Yes/No untuk men-teleportasi (Warp) pemain ke Dungeon.

---

## 2. Panduan Membuat Musuh (Enemy) Baru
Musuh biasa diatur oleh `enemy.tscn` (tipe memukul/dekat) atau `ranged_enemy.tscn` (tipe menembak/jauh). Keduanya ada di folder `Scenes/Entities/`.

### Langkah-langkah (Contoh membuat monster baru):
1. Buka file `Scenes/Entities/enemy.tscn`. Di menu paling atas kiri, klik **Scene -> Save As...** dan simpan dengan nama baru, misalnya `Scenes/Entities/orc_enemy.tscn`.
2. Buka *scene* `orc_enemy.tscn` yang baru dibuat.
3. **Mengganti Visual**:
   - Klik node `Visual` (atau `Sprite3D`/`MeshInstance3D`) milik musuh tersebut, sesuaikan model atau *texture*-nya dengan wujud monster baru Anda.
   - Jangan lupa sesuaikan ukuran `CollisionShape3D` agar ukurannya pas dengan volume tubuh monster tersebut.
4. **Mengatur Kekuatan Musuh**:
   - Klik node `Enemy` paling atas.
   - Di panel Inspector (Script Variables), Anda bisa mengatur sesuka hati:
     - `Speed`: Kecepatan bergerak/mengejar pemain.
     - `Max Health`: Darah musuh (semakin besar semakin tebal).
     - `Damage`: Kerusakan yang diberikan ke HP pemain saat bersentuhan.
     - `Coin Drop Amount`: Jumlah koin yang pasti dijatuhkan saat musuh ini mati.
5. **Memunculkannya di Map**:
   - Tarik file `orc_enemy.tscn` ke dalam peta `Scenes/Maps/dungeon_2.tscn`.

---

## 3. Panduan Membuat Boss Enemy & Pola Serangannya
Boss memiliki pergerakan yang lebih pintar dan serangan yang lebih berbahaya (`Scenes/Entities/boss_enemy.tscn`).

### Langkah-langkah:
1. Sama seperti musuh biasa, duplikat `boss_enemy.tscn` menjadi `boss_dragon.tscn`.
2. Ganti wujud/visual naga Anda di dalam *scene* tersebut.
3. **Membuat *Script* Khusus Boss**:
   - Duplikat *script* `boss_enemy.gd` menjadi `boss_dragon.gd`.
   - Di *scene* `boss_dragon.tscn`, seret *script* `boss_dragon.gd` ke node paling atas untuk mengganti *script* bawaan.
4. **Membuat Pola Serangan Baru (Contoh: Menembak Melingkar)**:
   - Buka *script* `boss_dragon.gd`.
   - Tambahkan fungsi khusus untuk menembakkan proyektil melingkar (meng-*instantiate* `Scenes/Skills/enemy_projectile.tscn`).
   - Panggil fungsi tersebut di dalam blok fungsi `_process(delta)` pada saat pengaturan hitung mundur (*cooldown*) serangannya nol.
5. **Mengatur Hadiah (Drop)**:
   - Sesuaikan logika jatuhan koin/item di fungsi `drop_loot()`.

---

## 4. Panduan Menambah Item & Skill Melalui Database (Excel/CSV)

Karena arsitektur game ini sudah maju, Anda tidak perlu lagi menulis skrip satu per satu untuk membuat item atau skill baru! Anda cukup menyiapkan file **Excel (.xlsx)** atau **.csv**, lalu memberikannya kepada *Programmer AI* untuk diintegrasikan secara otomatis ke dalam *Node Database* (`Scenes/item_db.tscn` dan `Scenes/skill_db.tscn`).

### Struktur Tabel Database Item
Buatlah tabel dengan nama-nama kolom (*header*) berikut:

| Nama Kolom Excel | Format Isian | Penjelasan Singkat |
| :--- | :--- | :--- |
| **id** | Teks (Tanpa Spasi) | ID unik (contoh: `health_potion_1`, `iron_sword`). Ini menjadi *identifier* node. |
| **item_name** | Teks | Nama item yang akan dibaca oleh pemain (contoh: "Ramuan Nyawa"). |
| **description** | Teks | Deskripsi kegunaan atau cerita singkat (*lore*) item. |
| **type** | Teks | Isi dengan salah satu: `material`, `consumable`, `equipment`, `upgrade_item`, `key_item`. |
| **rarity** | Teks | Isi dengan salah satu: `common`, `rare`, `epic`, `legendary`, `mythic`. |
| **price** | Angka | Harga beli/jual dasar. |
| **effect_type** | Teks | Hanya untuk *consumable*. Isi dengan: `None`, `heal_hp`, `heal_mp`, atau `heal_ep`. |
| **effect_amount** | Angka | Jumlah HP/MP yang akan dipulihkan (misal: `50`). |
| **equipment_slot**| Teks | Hanya untuk perlengkapan. Isi dengan: `None`, `main_weapon`, `secondary_weapon`, `helm`, `armor`, `boots`, `accessory`, atau `artifact`. |
| **bonus_p_atk** | Angka | Tambahan serangan fisik (*Physical Attack*). |
| **bonus_p_def** | Angka | Tambahan pertahanan fisik (*Physical Defense*). |
| **bonus_str** | Angka | Tambahan stat dasar STR. |
| **bonus_int** | Angka | Tambahan stat dasar INT. |
| **bonus_max_hp** | Angka | Tambahan kapasitas darah maksimum. |
| **icon_frame** | Angka | Urutan kotak/frame dari `Assets/item_icon.png` (contoh: `264`). |
| **is_craftable** | TRUE/FALSE | Isi dengan `TRUE` jika item ini bisa dirakit di menu Crafting. |
| **craft_time** | Angka Desimal | Lama waktu (dalam detik) yang dibutuhkan untuk merakit item ini. |
| **req_mat_1** | Teks | ID material pertama yang dibutuhkan (misal: `wood`). |
| **req_amount_1** | Angka | Jumlah material pertama yang dibutuhkan. |
| **req_mat_2** | Teks | ID material kedua yang dibutuhkan (opsional). |
| **req_amount_2** | Angka | Jumlah material kedua yang dibutuhkan. |
| **req_mat_3** | Teks | ID material ketiga yang dibutuhkan (opsional). |
| **req_amount_3** | Angka | Jumlah material ketiga yang dibutuhkan. |

### Struktur Tabel Database Skill
Buatlah tabel lain khusus untuk *Skill/Jurus*:

| Nama Kolom Excel | Format Isian | Penjelasan Singkat |
| :--- | :--- | :--- |
| **id** | Teks (Tanpa Spasi) | ID unik (contoh: `fireball`, `heavy_slash`). |
| **skill_name** | Teks | Nama jurus. |
| **description** | Teks | Penjelasan efek mematikan dari jurus. |
| **req_level** | Angka | Level minimum karakter untuk membuka jurus ini (contoh: `5`). |
| **mp_cost** | Angka | Biaya *Mana Point* (MP) setiap kali dirapal. |
| **cast_time** | Angka Desimal | Waktu bersiap/merapal. Tulis `0.0` jika instan. |
| **effect_amount** | Angka | Jumlah murni kerusakan (*damage*) atau *heal* mentah. |
| **type** | Teks | Isi dengan salah satu: `instant`, `target_aoe`, atau `passive`. |
| **range** | Angka | Jarak lemparan jurus (dalam piksel, misal: `200`). |
| **aoe_radius** | Angka | Lebar ledakan area (misal: `50` piksel). |
| **effect_multiplier** | Angka Desimal | Rasio pengali *damage* dari status (misal `1.5` = 150%). |
| **icon_frame** | Angka | Urutan frame gambar dari `Assets/item_icon.png`. |

### Menambah Manual via Editor (Alternatif)
Jika Anda hanya ingin menambah 1-2 item tanpa menggunakan Excel, Anda bisa menambahkannya langsung dari Editor:
1. Buka `Scenes/item_db.tscn` (atau `Scenes/skill_db.tscn`).
2. Klik kanan pada node utama, lalu pilih **Add Child Node** -> `Sprite2D`.
3. Beri nama node tersebut sesuai ID (misal: `potion_merah`).
4. Tarik skrip `Scripts/item_data.gd` (atau `Scripts/skill_data.gd`) ke panel *Inspector* node tersebut (di bagian paling bawah).
5. Pasang gambar `item_icon.png` di bagian *Texture*, lalu sesuaikan properti *Animation* (*hframes*, *vframes*, *frame*) untuk menentukan ikonnya.
6. Anda kini bisa mengisi data statistik (nama, damage, rarity, dll) langsung dari kolom variabel di antarmuka Godot!

---

## 5. Panduan Menambah Item Material, Resource Node, & Resep Crafting (Tanpa Coding)

Sistem sudah dirancang agar Anda dapat menambahkan barang tambang, material hutan, tanaman, dan resep crafting dengan sangat mudah melalui antarmuka (Editor) Godot.

### Langkah 1: Mendaftarkan Item Baru ke Database
1. Buka *scene* **Scenes/item_db.tscn**.
2. Di dalam kotak *Scene Tree* sebelah kiri, cari *node* kategori **Material**. Di bawahnya terdapat contoh seperti iron_ore.
3. Klik kanan iron_ore lalu pilih **Duplicate** (atau tekan **Ctrl+D**).
4. Ganti nama *node* duplikat tersebut menjadi ID item baru Anda, misalnya **copper_ore** (pastikan menggunakan huruf kecil dan garis bawah/ *underscore*).
5. Klik *node* copper_ore tersebut, lalu perhatikan kotak **Inspector** di sebelah kanan.
6. Pada bagian **Sprite2D -> Frame**, ganti angkanya untuk memilih ikon batu tembaga yang sesuai dari *spritesheet*.
7. Gulir ke bawah di Inspector hingga menemukan variabel *Script* (Item Name, Description, Price, dll), lalu ubah nilainya menjadi "Copper Ore", "Batu tembaga", dst.
8. Simpan (Ctrl+S). Item ini sekarang sudah resmi ada di dalam *game*!

### Langkah 2: Menambahkan Batu Tambang / Pohon / Tumbuhan ke Peta
1. Buka peta tempat Anda ingin meletakkan sumber dayanya (misalnya Scenes/Maps/maincity.tscn).
2. Tarik *scene* **Scenes/LifeSkills/resource_node.tscn** (untuk batu/pohon) atau **Scenes/LifeSkills/foraging_node.tscn** (untuk tanaman cabut) ke dalam peta Anda.
3. Klik objek tersebut, lalu di dalam kotak **Inspector** sebelah kanan, cari variabel **Yield Item**.
4. Ketikkan secara manual ID item yang sudah Anda buat tadi: **copper_ore**.
5. Pada bagian **Sprite2D -> Frame**, sesuaikan dengan gambar fisik sebongkah batu tembaga atau pohon yang relevan.
6. Anda juga bisa menyesuaikan Required Tool (apakah butuh *pickaxe* atau *axe*) dan Respawn Time.
7. Selesai! Saat pemain memukulnya dengan alat yang tepat, sumber daya tersebut akan hancur dan memberikan copper_ore.

### Langkah 3: Menambahkan Resep Crafting (Membutuhkan Sedikit Coding)
Jika item tersebut digunakan untuk *crafting*, Anda hanya perlu menambahkan 1 baris teks resepnya ke dalam daftar CRAFTING_RECIPES di file **Scripts/global.gd**.

1. Buka file **Scripts/global.gd**.
2. Cari bagian kode const CRAFTING_RECIPES = { ... }.
3. Tambahkan baris baru untuk hasil rakitan Anda, contohnya membuat copper_ingot dari copper_ore dan kayu:
`gdscript
const CRAFTING_RECIPES = {
	"potion": {"materials": {"herb": 3, "wood": 1}, "time": 2.0},
	"copper_ingot": {"materials": {"copper_ore": 3, "wood": 1}, "time": 3.0}
}
`
*(Jangan lupa mendaftarkan ID copper_ingot di item_db.tscn juga agar itemnya dikenali sistem!)*

---

## PANDUAN BARU: Menambah Resep Crafting 100% Tanpa Coding

Kini Anda dapat membuat resep rakitan langsung dari Inspector tanpa mengedit global.gd!

1. Buka *scene* **Scenes/item_db.tscn**.
2. Klik item yang ingin Anda buatkan resepnya (misalnya node iron_sword).
3. Di panel **Inspector** sebelah kanan, gulir paling bawah hingga menemukan grup **Crafting Recipe**.
4. Centang **Is Craftable** (Nyala / *On*).
5. Atur **Craft Time** (misalnya 5.0 detik).
6. Masukkan nama ID material yang dibutuhkan, contohnya:
   - **Req Mat 1**: iron_ore
   - **Req Amount 1**: 5
   - **Req Mat 2**: wood
   - **Req Amount 2**: 2
7. Simpan *scene*! Game akan otomatis membacanya sebagai resep iron_sword. Anda hanya perlu memastikan item resep blueprint-nya ada agar pemain bisa mempelajarinya!

---

## 6. Panduan Menyetel Animasi Senjata & Skill Karakter (Sistem Dinamis 3D)

Game Nusvanir kini menggunakan sistem animasi 3D mutakhir yang tidak membutuhkan *hardcoding*. Skrip karakter akan secara otomatis melacak senjata apa yang sedang dipakai dan menyesuaikannya dengan *AnimationTree*.

### Langkah-langkah Menambah Animasi Senjata Baru:
1. Tentukan `weapon_type` pada senjata di `item_db.tscn` atau Excel (misalnya `battle_axe` atau `sword`).
2. Buka file *scene* karakter utama (`Scenes/Entities/player.tscn`) dan buka tab **AnimationTree**. 
3. Buat *state* baru di dalam State Machine, dan beri nama persis dengan format **`[weapon_type tanpa garis bawah]_[BaseState]`**.
   - **PENTING**: Sistem otomatis menghapus karakter garis bawah (`_`). Jika `weapon_type` adalah `battle_axe`, nama statenya menjadi `battleaxe`.
   - Contoh untuk kapak perang (`battle_axe`): `battleaxe_Idle`, `battleaxe_Run`, `battleaxe_Attack`.
   - Contoh untuk pedang (`sword`): `sword_Idle`, `sword_Run`, `sword_Attack`.
4. Hubungkan wujud animasi 3D `.glb` Anda ke masing-masing *state* tersebut.
6. Selesai! Jika pemain memakai `battle_axe`, maka *script* akan otomatis memainkan animasi kapak tersebut. Jika belum ada, karakter akan *fallback* menggunakan *state* `Idle` atau `Attack` biasa agar tidak *crash*.

### Langkah-langkah Mengatur Durasi Animasi Skill:
1. Jika Anda mendesain *skill* bernama "Meteoric Smash" (ID: `meteoric_smash`).
2. Masukkan durasi animasinya dengan membuat state di *AnimationTree* bernama sama, tapi tanpa spasi dan kapital di tiap awal kata (`MeteoricSmash`).
3. Sistem akan membaca berapa panjang (*length*) animasi tersebut dalam detik, lalu secara dinamis menjeda interaksi karakter (*is_animating_skill*) hingga animasinya selesai 100%. Anda tidak perlu mengira-ngira durasinya di dalam kodingan.

---

## 7. Panduan Menambah Senjata Baru (Modular Scene)

Mulai pembaruan terbaru, senjata dibuat menggunakan pendekatan *Modular Scene*. Artinya, setiap senjata adalah satu *scene* Godot mandiri yang menyimpan wujud fisik 3D dan area serangannya (*hitbox*).

### Langkah-langkah Menambah Senjata (Contoh: Kapak):
1. **Buat Scene Senjata**:
   - Di Godot, klik menu **Scene -> New Scene**, lalu pilih **3D Scene** (Node3D). Beri nama induknya, misalnya `AxeWeapon`.
   - Simpan *scene* ini (Ctrl+S) di folder `Scenes/Weapons/` (buat foldernya jika belum ada), misalnya dengan nama `axe.tscn`.
2. **Tambahkan Model 3D**:
   - Tarik model 3D kapak Anda (`.glb` atau `.obj`) ke dalam *scene* tersebut dari panel FileSystem. Sesuaikan posisinya agar gagang kapaknya pas berada di titik tengah (titik origin / 0,0,0).
3. **Tambahkan Hitbox (Area Serangan)**:
   - Klik kanan pada induk `AxeWeapon` -> **Add Child Node** -> `Area3D`. Beri nama `RightHandHitBox` (huruf kapital harus pas).
   - Tarik script `Scripts/Player/sword_hitbox.gd` ke dalam kotak *Script* di Inspector milik node `RightHandHitBox`.
   - Klik kanan pada `RightHandHitBox` -> **Add Child Node** -> `CollisionShape3D`.
   - Di panel Inspector, berikan bentuk *BoxShape3D* atau *CylinderShape3D*.
   - Atur posisi dan ukuran area transparannya agar menyelimuti mata kapak. (Area inilah yang akan mencederai musuh).
4. **Daftarkan Senjata di Database Item (`item_db.tscn` / Excel)**:
   - Buat item baru di database (baik via `item_db.tscn` langsung atau lewat file Excel).
   - Pastikan variabel/kolom `weapon_type` diisi dengan jenisnya (misal: `"axe"`, `"spear"`, dll).
   - Tambahkan variabel/kolom **`weapon_scene_path`**, lalu isi dengan path ke *scene* yang tadi dibuat (contoh: `"res://Scenes/Weapons/axe.tscn"`).
5. **(Opsional) Atur Animasi Senjata**:
   - Daftarkan animasi pukulan spesifik tipe kapak di *AnimationTree* `player.tscn` (sesuai petunjuk pada Bab 6), contoh penamaan state: `axe_Attack1`, `axe_Idle`.

Kini, setiap kali pemain memakai kapak tersebut (Equip) dari *Inventory*, karakter akan secara otomatis menggenggam *scene* kapak itu di tangannya, dan efek *damage* dari kapak akan langsung berfungsi tanpa perlu koding sama sekali!

---

## 8. Panduan Mengepaskan Posisi Model Senjata di Tangan Karakter

Saat Anda membuat *scene* senjata baru (Modular Scene), Anda perlu memastikan letak gagang senjatanya pas saat digenggam karakter. Cara terbaik dan paling rapi di Godot adalah dengan menyesuaikan **Transform (posisi dan rotasi)** di dalam *scene* senjata itu sendiri, bukan di dalam skrip.

### Alur Kerja (Workflow) Pengepasan Visual:
1. **Lakukan "Live Preview" Sementara di Scene Player**:
   - Buka *scene* Player (`player.tscn`).
   - Cari node `BoneAttachment3D` di kerangka tangan karakter (tempat senjata biasa dipasang).
   - *Drag and drop* (tarik) *scene* pedang/senjata Anda (contoh: `sword.tscn`) ke dalam node `BoneAttachment3D` tersebut sebagai anak (*child*). Ini hanya untuk tes visual, jangan disimpan.
   - Pastikan karakter sedang berada di pose diam (*Idle*) di `AnimationPlayer`.
2. **Geser dan Sesuaikan**:
   - Pilih node pedang yang baru saja Anda masukkan di *scene* Player.
   - Gunakan *Move Tool* (W) dan *Rotate Tool* (E) di editor untuk menggeser dan memutar senjatanya sampai benar-benar pas digenggam oleh tangan karakter.
   - Setelah pas, buka panel **Inspector -> Transform**.
   - Klik kanan pada **Position** lalu pilih **Copy** (Salin). Catat juga nilai **Rotation**-nya.
3. **Terapkan Secara Permanen di Scene Senjata**:
   - **Hapus** node pedang sementara tadi dari *scene* Player.
   - Buka kembali *scene* senjata Anda (misal `sword.tscn`).
   - Jangan ubah Root Node (`Node3D`). Pilih node anak yang berupa model visual, yaitu **`MeshInstance3D`** atau node visual utamanya.
   - *Paste* (Tempel) nilai **Position** dan **Rotation** yang sudah Anda dapatkan dari tes tadi ke properti *Transform* milik `MeshInstance3D` tersebut.
   - Simpan *scene*. 

Kini, kapan pun game berjalan dan senjata ini dipanggil (*spawn*) ke tangan karakter, posisinya akan selalu sejajar dan sempurna!

---

## 9. Panduan Mengganti Tampilan Visual Senjata (Efek & Partikel)

Karena menggunakan sistem **Modular Scene**, setiap jenis senjata memiliki *scene*-nya masing-masing. Artinya, membuat tampilan senjata yang berbeda-beda sangatlah mudah.

1. **Buat Scene Khusus Tiap Senjata**:
   - Jika Anda memiliki pedang biasa dan pedang api, buat dua *scene* terpisah: `iron_sword.tscn` dan `fire_sword.tscn`.
2. **Kustomisasi Visual**:
   - Buka `iron_sword.tscn` dan masukkan model 3D pedang besi biasa.
   - Buka `fire_sword.tscn` dan masukkan model 3D pedang keren. Di sini, Anda bebas menambahkan elemen Godot lainnya seperti partikel api (`GPUParticles3D`), cahaya bersinar (`OmniLight3D`), atau suara sabetan khusus (`AudioStreamPlayer3D`) yang menempel di senjata.
3. **Sambungkan ke ItemDB**:
   - Di `item_db.tscn` (atau file Excel database item), atur properti **`weapon_scene_path`** milik pedang besi ke `"res://Scenes/Weapons/iron_sword.tscn"`.
   - Atur **`weapon_scene_path`** milik pedang api ke `"res://Scenes/Weapons/fire_sword.tscn"`.

Dengan cara ini, saat pemain mengganti senjatanya di *Inventory*, sistem secara otomatis memuat *scene* utuh beserta seluruh efek visual, partikel, hingga bentuk *hitbox* unik yang ada di dalamnya!

---

## 10. Panduan Menambah Animasi Baru (dari Unity Asset Store / Mixamo)

Jika Anda membeli atau mengunduh paket animasi (misalnya untuk panah, tombak, atau pedang ganda) dari **Unity Asset Store** atau **Mixamo**, Anda tidak bisa langsung memasukkannya begitu saja ke Godot karena ada perbedaan format kerangka tulang (*Rigging/Skeleton*). Ikuti panduan ini agar animasinya bekerja sempurna di karakter Anda:

### Tahap 1: Ekspor dan Impor ke Godot
1. **Dapatkan File FBX**: Pastikan Anda memiliki file animasi dengan format `.fbx`.
2. **Masukkan ke Folder Proyek**: *Drag and drop* file `.fbx` tersebut ke folder `Assets/Animations/` di Godot. Godot akan secara otomatis melakukan proses *impor*.
3. **Ekstrak Animasi**:
   - Jangan langsung menggunakan file `.fbx` di *scene*!
   - Klik ganda (atau klik tab **Import**) pada file `.fbx` tersebut.
   - Di jendela *Advanced Import Settings*, pilih tab **Animation**.
   - Di sebelah kanan, cari ikon *Save* (Simpan) dan simpan animasinya sebagai file mandiri dengan format `.res` (misalnya `bow_attack.res`). File inilah yang akan kita gunakan.

### Tahap 2: Memasukkan Animasi ke Karakter Utama
1. Buka *scene* `Scenes/Entities/player.tscn`.
2. Pilih node **`AnimationPlayer`** (biasanya berada di dalam `Visuals/HeroModel`).
3. Di panel bawah (jendela Animation), klik tombol **Animation -> Manage Animations**.
4. Klik ikon folder (Load) atau **Add Library** untuk memasukkan file `.res` yang sudah diekstrak tadi ke dalam daftar animasi milik Player.
5. Beri nama yang sesuai di dalam `AnimationPlayer` (contoh: `bow/bow_attack`).

### Tahap 3: Memperbaiki Tulang (Retargeting) & Hitbox
Jika saat dijalankan karakter terlihat cacat/tulangnya patah, itu karena nama tulang dari Unity berbeda dengan struktur tulang karakter utama kita (`GeneralSkeleton`).
1. Buka file `.res` animasi tersebut, lalu di panel *Inspector* Anda akan melihat daftar **Track**.
2. Anda harus mengubah jalurnya. Jika dari Unity tertulis `Armature/Skeleton:RightArm`, ubah menjadi `GeneralSkeleton:RightArm`.
3. **Mengaktifkan Hitbox Senjata**:
   - Agar senjata Anda memiliki *damage* saat animasi menyerang berjalan, tambahkan **Call Method Track** di dalam animasi tersebut (di editor animasi panel bawah).
   - Arahkan *track* tersebut ke node `Player` utama.
   - Tambahkan *keyframe* di titik awal ayunan senjata (misal detik ke-0.2) dan panggil fungsi **`activate_weapon_hitbox()`**.
   - Tambahkan *keyframe* kedua di titik akhir ayunan (misal detik ke-0.6) dan panggil **`deactivate_weapon_hitbox()`**.

### Tahap 4: Menghubungkan ke Sistem Dinamis (AnimationTree)
1. Buka tab **AnimationTree** di *scene* `player.tscn`.
2. Klik kanan di dalam *State Machine* -> **Add Animation**. Pilih animasi yang tadi sudah Anda daftarkan di `AnimationPlayer` (misal `bow_attack`).
3. Ubah nama *node* (kotak animasinya) menjadi format sistem dinamis: **`[tipe_senjata]_[Aksi]`**.
   - Contoh: Jika di database `item_db` senjatanya ber-tipe `bow`, maka ubah nama kotaknya menjadi **`bow_Attack1`** atau **`bow_Idle`**.
4. Hubungkan panah transisinya sesuai dengan alur state machine (dari Any State, kembali ke Idle, dst).

Selesai! Sekarang ketika pemain memakai `bow`, sistem akan mencari *state* bernama `bow_Attack1` di AnimationTree dan memainkan animasi Unity Anda secara sempurna!

---

## 7. Panduan Sistem Status Karakter (Stats)

Status (Stats) pada karakter utama Anda terbagi menjadi tiga kelompok utama: **Stat Dasar (Core Base Stats)**, **Stat Turunan (Derived Combat Stats)**, dan **Stat Pasif/Tersembunyi (Hidden Stats)**. Sistem ini bekerja secara otomatis menghubungkan stat dasar dan bonus dari peralatan (Equipment).

### 7.1 Stat Dasar (Core Base Stats)
Ini adalah poin-poin utama yang bisa dinaikkan setiap kali karakter naik level (saat mengalokasikan stat point):
- **STR (Strength)**: Penentu utama besarnya Physical Attack (Atk) dan poin Energi (MaxEP).
- **AGI (Agility)**: Penentu kecepatan gerak (*Walk/Run Speed*), kecepatan pemulihan energi (*EP Regen*), dan rasio penghindaran (*Flee*).
- **VIT (Vitality)**: Penentu utama besarnya Max HP, Physical Defense (Def), dan sedikit menyumbang pada Magic Defense (Mdef).
- **INT (Intelligence)**: Penentu utama besarnya Magic Attack (Matk), Max MP, dan menyumbang pada Magic Defense (Mdef).
- **DEX (Dexterity)**: Penentu kecepatan serangan (*Attack Speed*), ketepatan serangan (*Hit/Accuracy*), dan kecepatan merapal sihir (*Casting Speed*).
- **LUK (Luck)**: Penentu utama besaran rasio serangan kritikal (*Critical Chance*).

### 7.2 Stat Turunan (Derived Combat Stats)
Ini adalah status hasil kalkulasi dari Stat Dasar dan bonus perlengkapan (Equipment) yang aktif digunakan. Stat ini bisa dilihat di menu layar UI karakter:
- **MaxHP**: Darah maksimal. (Formula: Base HP + (VIT x 10) + Bonus Equipment)
- **MaxMP**: Mana maksimal. (Formula: Base MP + (INT x 5) + Bonus Equipment)
- **Atk (Physical Attack)**: Kerusakan serangan senjata fisik. (Formula: Base Atk + (STR x 2) + Bonus Equipment)
- **Matk (Magic Attack)**: Kerusakan serangan sihir. (Formula: Base Matk + (INT x 2) + Bonus Equipment)
- **Def (Physical Defense)**: Daya tahan mengurangi damage fisik. (Formula: VIT + Bonus Equipment)
- **Mdef (Magic Defense)**: Daya tahan mengurangi damage sihir. (Formula: (VIT/2) + (INT/2) + Bonus Equipment)
- **Hit (Accuracy)**: Seberapa akurat serangan mengenai musuh. (Formula: (DEX x 2) + Bonus Equipment)
- **Flee (Evasion)**: Peluang untuk menghindar dari serangan. (Formula: (AGI x 2) + Bonus Equipment)
- **Critical (Critical Chance %)**: Persentase peluang serangan kritikal ganda (Damage x2). (Formula: (LUK x 1.0) + Bonus Equipment)
- **Aspd (Attack Speed)**: Kecepatan ayunan/tembakan senjata. (Formula: (AGI x 4.0) + Bonus Equipment)

### 7.3 Stat Pergerakan & Sistem (Hidden / System Stats)
Ini adalah status pendukung yang berjalan di latar belakang:
- **MaxEP (Energy Point)**: Kapasitas energi untuk melakukan *Roll/Dash* dan *Charge Attack*.
- **Energy Regen**: Seberapa cepat energi kembali penuh saat diam/berjalan.
- **Walk Speed & Run Speed**: Angka patokan kecepatan pergerakan karakter di ruang 3D.
- **Casting Speed**: Kecepatan menyelesaikan animasi merapal sebelum meluncurkan peluru sihir.

### 7.4 Cara Menambahkan Bonus Stat pada Item
Untuk menambahkan bonus stat pada sebuah senjata atau zirah, cukup atur nilai variabel di bagian `Equipment Stats` pada *Inspector* Godot (file `.tscn` dari item tersebut). Misalnya, mengisi `bonus_critical` = 5 pada sebuah pedang otomatis akan menaikkan *Critical Chance* karakter sebesar 5% ketika pedang tersebut dipakai, dan serangan karakter tersebut akan menghasilkan teks *damage* berwarna merah menyala dan kerusakannya dikali 2 saat kritikal!
