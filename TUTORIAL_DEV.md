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
1. Anda membuat tipe senjata baru di `item_db.tscn` bernama `battle_axe`.
2. Buka file *scene* karakter utama (`Scenes/Entities/player.tscn`).
3. Buka tab **AnimationTree**. 
4. Buat *state* baru di dalamnya, dan beri nama persis dengan format **`[Tipe_Senjata]_[Aksi]`**.
   - Contoh untuk kapak perang: `battle_axe_Idle`, `battle_axe_Walk`, `battle_axe_Run`, `battle_axe_Dash`, `battle_axe_Attack`, `battle_axe_HeavyAttack`.
5. Hubungkan wujud animasi 3D `.glb` Anda ke masing-masing *state* tersebut.
6. Selesai! Jika pemain memakai `battle_axe`, maka *script* akan otomatis memainkan animasi kapak tersebut. Jika belum ada, karakter akan *fallback* menggunakan *state* `Idle` atau `Attack` biasa agar tidak *crash*.

### Langkah-langkah Mengatur Durasi Animasi Skill:
1. Jika Anda mendesain *skill* bernama "Meteoric Smash" (ID: `meteoric_smash`).
2. Masukkan durasi animasinya dengan membuat state di *AnimationTree* bernama sama, tapi tanpa spasi dan kapital di tiap awal kata (`MeteoricSmash`).
3. Sistem akan membaca berapa panjang (*length*) animasi tersebut dalam detik, lalu secara dinamis menjeda interaksi karakter (*is_animating_skill*) hingga animasinya selesai 100%. Anda tidak perlu mengira-ngira durasinya di dalam kodingan.
