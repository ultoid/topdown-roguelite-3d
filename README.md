# 3D Action Roguelite RPG

Proyek ini adalah evolusi dari *Top Down Action Game* 2D menjadi petualangan 3D seutuhnya. Seluruh komponen logika, fisika pergerakan, hingga perhitungan jarak jangkauan proyektil dan *skill* yang asalnya dalam bentuk piksel (*Vector2*) kini telah ditranslasikan secara terukur ke dalam dimensi metrik 3D (*Vector3*).

Perubahan mendasar yang ada dalam sistem 3D ini meliputi penggantian `CharacterBody2D` menjadi `CharacterBody3D`, `CollisionShape` ke dimensi volumetrik (`BoxShape3D`, `CapsuleShape3D`, `CylinderShape3D`), serta penggunaan Node spasial untuk interaksi dunia, proyektil, dan musuh.

## To Do List
- [ ] Menyelesaikan Migrasi 2D ke 3D all component and system
  - [ ] Fix Skill Apprentice
  - [ ] Fix Skill Scout
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
