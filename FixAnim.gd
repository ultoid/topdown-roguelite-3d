@tool
extends EditorScript

var anim_path = "res://Assets/Models/Staff/staff_idle3.res"
var alamat_lengkap = "Visuals/PlayerVisual/GeneralSkeleton"

func _run():
	var anim = load(anim_path)
	if not anim:
		print("Gagal memuat animasi! Pastikan path-nya benar: " + anim_path)
		return
		
	var count = 0
	for i in range(anim.get_track_count()):
		var path = anim.track_get_path(i)
		var path_str = str(path)
		
		# Ambil nama tulang (berada di setelah titik dua, atau nama itu sendiri)
		var bone_name = ""
		if ":" in path_str:
			bone_name = path_str.split(":")[1]
		else:
			bone_name = path_str
			
		# Pasang alamat lengkapnya
		var new_path = alamat_lengkap + ":" + bone_name
		anim.track_set_path(i, NodePath(new_path))
		count += 1
			
	if count > 0:
		ResourceSaver.save(anim, anim_path)
		print("=========================================")
		print("SUKSES! Berhasil memperbaiki alamat pada " + str(count) + " tulang!")
		print("Silakan klik/buka ulang file animasinya di layar agar ter-refresh.")
		print("=========================================")
