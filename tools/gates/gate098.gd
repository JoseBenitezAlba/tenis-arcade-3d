extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(98098)

	var nc: = 0
	var nt: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 16:  # v0.138: el tope de velocidad y la correccion del skim bajan las cintas por partido
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "netcord":
					nc += 1
				elif ev.get("t") == "net":
					nt += 1
			s.events.clear()
	print("A netcords=", nc, " nets=", nt)
	if nc < 2:
		print("FAIL A: la cinta casi no suena (gate vacio)");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("tape"):
		print("FAIL B: falta stream tape");ok = false
	else:
		k.play("tape", 1.0)
		if int(k.play_counts.get("tape", 0)) != 1:
			print("FAIL B: play() no contabiliza tape");ok = false
	k.queue_free()
	print("GATE098 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
