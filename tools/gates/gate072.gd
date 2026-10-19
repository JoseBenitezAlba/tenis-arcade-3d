extends SceneTree




const SoundKit: = preload("res://scripts/sound_kit.gd")
func _init():
	var ok: = true
	var sk = SoundKit.new()
	root.add_child(sk)
	sk._ready()
	await process_frame
	for name in ["hit_perfect", "hit_drop", "hit_slice", "hit_volley", "crowd_ooh", "applause"]:
		if not sk.streams.has(name) or sk.streams[name].data.size() < 1000:
			print("FAIL C1: stream ", name, " falta o vacio");ok = false
	sk.play("hit_perfect", 1.0, 1.15)
	sk.play("applause", 0.8)
	await create_timer(0.1).timeout
	if sk.play_counts.get("hit_perfect", 0) != 1 or sk.play_counts.get("applause", 0) != 1:
		print("FAIL C2: play_counts ", sk.play_counts);ok = false
	var pitched: = false
	for c in sk.get_children():
		if c is AudioStreamPlayer and c.stream == sk.streams["hit_perfect"] and absf(c.pitch_scale - 1.15) < 0.001:
			pitched = true
	if not pitched:
		print("FAIL C2: pitch no aplicado");ok = false

	var d: PackedByteArray = sk.streams["applause"].data
	var win: = 441
	var energies: = []
	for w in range(0, d.size() / 2 - win, win):
		var e: = 0.0
		for i in range(w, w + win):
			var sm: = d.decode_s16(i * 2)
			e += abs(sm)
		energies.append(e / win)
	var mn: = 1e+18; var mx: = 0.0
	for e in energies:
		mn = minf(mn, e);mx = maxf(mx, e)
	print("applause energia min=", int(mn), " max=", int(mx))
	if mx < mn * 3.0:
		print("FAIL C3: el aplauso suena plano");ok = false
	print("GATE072 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
