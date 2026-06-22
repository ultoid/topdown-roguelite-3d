# 3D Action Roguelite RPG

Proyek ini adalah evolusi dari *Top Down Action Game* 2D menjadi petualangan 3D seutuhnya. Seluruh komponen logika, fisika pergerakan, hingga perhitungan jarak jangkauan proyektil dan *skill* yang asalnya dalam bentuk piksel (*Vector2*) kini telah ditranslasikan secara terukur ke dalam dimensi metrik 3D (*Vector3*).

Perubahan mendasar yang ada dalam sistem 3D ini meliputi penggantian `CharacterBody2D` menjadi `CharacterBody3D`, `CollisionShape` ke dimensi volumetrik (`BoxShape3D`, `CapsuleShape3D`, `CylinderShape3D`), serta penggunaan Node spasial untuk interaksi dunia, proyektil, dan musuh.

## To Do List
- [ ] Menyelesaikan Migrasi 2D ke 3D all component and system
  - [x] Fix Skill Apprentice
  - [x] Fix Skill Scout
- [ ] Melengkapi animasi model 3d
- [ ] Implementasi animasi ke game

## Change Log

### 20 Juni 2026
- Memperbaiki arah rotasi dan *lunge* pada skill `Fatal Blow` agar mengikuti arah kursor mouse.
- Memperbaiki lompatan pada skill `Implosion` dan menyempurnakan indikator lingkaran *pull* musuh dengan radius akurat 5 meter.
- Menambahkan indikator visual merah transparan pada radius 5 meter untuk skill `Provoke`.
- Memperbaiki bug visual sisa *render* 2D di mana icon pedang (atau *sprite* lainnya dari *Autoload* `ItemDB` & `SkillDB`) tidak sengaja melayang dan bocor ke UI versi 3D.
- Memperbaiki bug pada `PlayerHUD` di mana teks dan overlay gelap *cooldown* masih tertinggal di slot yang telah dikosongkan (contoh: mengganti *class* saat skill masih dalam masa *cooldown*).
- Menghapus pembuatan hitbox secara *hardcoded* dan memperbaiki hierarki rotasi `SwordHitBox` (menggunakan rotasi `Area3D` alih-alih `CollisionShape3D`) agar serangan bisa mengenai musuh dari segala arah.
- Memindahkan timing aktivasi hitbox pedang sepenuhnya ke dalam *AnimationPlayer* agar lebih responsif dan akurat terhadap visual ayunan pedang.
- Mengubah mekanisme deteksi damage pada skill `Impact Wave` (sabit energi) dari sinyal `body_entered` ke pengecekan radius metrik secara *real-time*, sekaligus memperbaiki rotasi visual sabit agar sesuai arah tembak.
- Merombak kontrol input pemain: Lari sekarang menggunakan *Hold Shift* + Arah (menggantikan *double tap*), *Dash* sekarang terikat pada tombol Spasi (sekaligus menghapus mekanik lompat), dan akurasi arah *dash* saat diam telah diperbaiki.
- Menyesuaikan *hitbox radius* pada skill `Cyclone Sweep` ke skala 3D (dari 0.4m menjadi 3.0m), mengembalikan fungsionalitas *damage* dan efek pantulan (*knockback*) secara penuh.

### 21 Juni 2026
- Merombak logika `Mana Burst` (Serangan *Charge* Rod) untuk menggunakan kalkulasi jarak (*distance check*) bebas *bug* alih-alih `Area3D`, memberikan *damage* instan serta efek pentalan (*knockback*) pasti sejauh 10 meter ke seluruh musuh dalam radius 2 meter. Mempercepat visual animasi menjadi 0.2 detik.
- Mengubah `Magic Charge` (Serangan *Charge* Staff) menjadi serangan *piercing* yang mampu menembus banyak musuh sekaligus. Tingkat fatal *damage* yang masuk kini dihitung dinamis berdasarkan seberapa tepat/akurat jalur proyektil mengenai pusat tubuh musuh.
- Memperbaiki bug "pukulan fisik bocor" (*melee damage leak*) di mana serangan proyektil (sihir/panah) secara tidak sengaja memicu *hitbox* pedang akibat berbagi animasi `Attack`, dengan mematikan status *hitbox* sementara selama merapal serangan jarak jauh.
- Mengubah sistem gerak saat merapal serangan: Pemain kini dikunci agar hanya bisa berjalan (tidak bisa lari) ketika sedang menahan *charge attack*, sekaligus membuat arah pandang karakter secara *real-time* terus membidik mengikuti kursor *mouse*.
- Membedakan jangkauan maksimal tembakan (*lifetime* proyektil) berdasarkan senjata: Staff dipatok pada jangkauan maksimal 15 meter, sementara Rod 10 meter.
- Menyesuaikan daya pantul (*knockback*) proyektil dasar dari Staff dan Rod menjadi lebih halus pada jarak tepat 0.5 meter.
- Memigrasi jajaran *Skill* khusus kelas **Apprentice** ke mekanika 3D secara komprehensif:
  - **Aqua Blast**: Ombak 3D radial kini menyapu musuh hingga ujung maksimal 5 meter tanpa *knockback* sisa berlebih, disertai efek *slow* pengurangan kecepatan 50%.
  - **Fire Bolt**: Menghadirkan proyektil bola api merah tajam berkecepatan 100km/jam dengan kemampuan kejar (*homing*), serta dilengkapi auto-lock pada radius 8 meter jika *cast* meleset.
  - **Sonic Boom**: Membenahi kalkulasi rotasi area kerucut 3D sejauh 5 meter agar presisi dengan bidikan *mouse*.
  - **Seismic Fissure**: Rentetan retakan memanjang dinamis kini akurat sejauh maksimal 10 meter, ledakan ujung diperbesar menjadi diameter 4m, dan menjebak musuh di dalamnya dengan efek *slow* berat hingga 90%.
  - **Holy Veil**: Menghapus render 2D usang penyebab *crash*, digantikan oleh silinder energi keemasan yang melindungi karakter.
  - **Hex**: Diselaraskan dengan sistem bidik jarak dekat Fire Bolt (5 meter) dan dihiasi dengan partikel ledakan kecil ungu penanda kutukan.
  - **Soul Drain**: Merombak eksekusi penyerapan HP; kini bola proyektil energi roh melesat keluar dari musuh yang terkutuk dan masuk ke tubuh pemain secara dramatis.
- Memoles sistem *Casting* dan Indikator: Lingkaran target merah sekarang dengan mulus terus menempel di kaki musuh bergerak selama jeda *casting*. Arah tatapan tubuh karakter juga kini interaktif mengikuti rotasi kursor *mouse* secara seketika meski tubuhnya terkunci saat sedang merapal mantra.
- **Refactoring Arsitektur Skrip**: Mengorganisir ulang struktur proyek dengan memindahkan ratusan file `.gd` ke dalam folder hierarkis yang lebih teratur (`Scripts/System/`, `Scripts/Player/`, `Scripts/Enemy/`, `Scripts/Skills/`, `Scripts/UI/`, `Scripts/Debug/`, dan `DevTools/`). Memperbarui secara presisi semua referensi file *path* lama di dalam `.tscn`, `.tres`, dan `project.godot` (Autoload) dengan aman.
- **Refactoring player.gd**: Memecah dan mendeligasikan modul *skill* tempur raksasa dari `player.gd` (memangkas lebih dari 700 baris kode) menjadi tiga *helper class* mandiri: `ApprenticeSkills`, `FighterSkills`, dan `ScoutSkills` di dalam folder baru `Scripts/PlayerClasses/`, guna memudahkan pembacaan dan pembaruan AI di masa mendatang.

### 22 Juni 2026
- Memigrasi jajaran *Skill* khusus kelas **Scout** ke mekanika 3D secara komprehensif:
  - **Falcon Dive**: Merombak total logika proyektil; karakter kini menembakkan **3 anak panah** awal berkecepatan 80 km/jam, diikuti **1 panah besar** penutup berkecepatan 100 km/jam yang disertai animasi karakter **melompat setinggi 1 meter**. Jangkauan *single-target* diperluas menjadi radius **8 meter**.
  - **Hunter's Mark**: Jangkauan penandaan target diperluas signifikan menjadi radius **12 meter**.
  - **Arrow Rain**: Skill hujan panah dirombak total — area *casting* kini selebar radius **10 meter**, anak panah jatuh secara **acak (random)** di banyak titik berbeda dalam zona radius **2 meter**, menggantikan mekanisme lama yang hanya menarget satu titik. *Damage* kini menggunakan kalkulasi jarak metrik bebas *bug*. Musuh yang terkena mendapat efek *chill* dan **super slow** (kecepatan tersisa 10%) sehingga kesulitan keluar dari area badai panah. **Tanpa efek knockback.**
  - **Phantom Strike**: Jangkauan serangan diperluas menjadi radius **5 meter**.
  - **Shadow Walk**: Saat aktif, karakter menjadi **transparan 50%** (menggunakan `GeometryInstance3D.transparency` untuk model 3D) dan **tidak bisa terdeteksi musuh** (musuh kehilangan jejak dan berhenti mengejar). Efek stealth **otomatis berakhir** ketika pemain melakukan serangan dasar, tembak proyektil, atau menggunakan skill serang.
- Menambahkan **persyaratan senjata** untuk skill `Falcon Dive` dan `Arrow Rain`: kedua skill kini hanya bisa digunakan jika pemain memakai *long bow* atau *crossbow*. Slot quick skill akan otomatis **menggelap dan menampilkan ikon 🔒** jika senjata yang terpasang tidak sesuai. Notif "Butuh Bow/Crossbow!" muncul saat skill diklik tanpa senjata yang sesuai.
