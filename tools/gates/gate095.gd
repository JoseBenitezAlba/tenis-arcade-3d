extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(95095)

	var hits: = 0
	var big: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5, "style": "sv"}
	var m: = 0
	while hits < 200 and m < 10:
		m += 1
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					hits += 1
					if ev.get("kind") == "smash" or float(ev.get("stretch", 0.0)) >= 1.3:
						big += 1
			s.events.clear()
	var frac: = float(big) / maxf(1.0, float(hits))
	print("A golpes=", hits, " de_entrega=", big, " frac=", snappedf(frac, 0.03))
	if frac < 0.03 or frac > 0.5:
		print("FAIL A: el grunido sonaria sin parar o nunca");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("grunt"):
		print("FAIL B: falta stream grunt");ok = false
	else:
		k.play("grunt", 1.0)
		if int(k.play_counts.get("grunt", 0)) != 1:
			print("FAIL B: play() no contabiliza grunt");ok = false
	k.queue_free()
	print("GATE095 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
