extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(92002)

	var vol: = 0
	var lim: = 0
	var nokey: = 0
	var m: = 0
	while vol < 20 and m < 12:
		m += 1
		var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5, "style": "sv"}
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit" and ev.get("kind") == "volley":
					vol += 1
					if not ev.has("stretch"):
						nokey += 1
					elif float(ev.stretch) >= 1.3:
						lim += 1
			s.events.clear()
	print("A voleas=", vol, " al_limite=", lim, " sin_clave_stretch=", nokey)
	if vol < 10:
		print("FAIL A: pocas voleas para medir");ok = false
	if nokey > 0:
		print("FAIL A: eventos sin stretch");ok = false
	var frac: = float(lim) / maxf(1.0, float(vol))
	print("A fraccion al limite=", snappedf(frac, 0.03))
	if frac < 0.03 or frac > 0.6:
		print("FAIL A: fraccion fuera de banda (constante o inexistente)");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("swish"):
		print("FAIL B: falta stream swish");ok = false
	else:
		k.play("swish", 1.0)
		if int(k.play_counts.get("swish", 0)) != 1:
			print("FAIL B: play() no contabiliza swish");ok = false
	k.queue_free()
	print("GATE092 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
