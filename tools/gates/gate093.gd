extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(93002)

	var rallies: = 0
	var long10: = 0
	for m in 6:
		var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		var last_rh: = 0
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					last_rh = s.rally_hits
				elif ev.get("t") == "point" or ev.get("t") == "fault":
					rallies += 1
					if last_rh >= 10:
						long10 += 1
					last_rh = 0
			s.events.clear()
	var frac: = float(long10) / maxf(1.0, float(rallies))
	print("A rallies=", rallies, " >=10=", long10, " frac=", snappedf(frac, 0.03))
	if frac < 0.05 or frac > 0.35:
		print("FAIL A: oles fuera de banda (constantes o inexistentes)");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("ole"):
		print("FAIL B: falta stream ole");ok = false
	else:
		k.play("ole", 1.0)
		if int(k.play_counts.get("ole", 0)) != 1:
			print("FAIL B: play() no contabiliza ole");ok = false
	k.queue_free()
	print("GATE093 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
