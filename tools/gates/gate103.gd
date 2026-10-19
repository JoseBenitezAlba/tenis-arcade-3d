extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10303)

	print("A clay5.5=", MV.slide_time("clay", 5.5), " clay3=", MV.slide_time("clay", 3.0), " hard5=", MV.slide_time("hard", 5.0), " grass5=", MV.slide_time("grass", 5.0))
	if absf(MV.slide_time("clay", 5.5) - 0.45) > 0.001 or MV.slide_time("clay", 3.0) != 0.0 or MV.slide_time("hard", 5.0) != 0.0 or MV.slide_time("grass", 5.0) != 0.0:
		print("FAIL A: mapeo de deslizamiento incorrecto");ok = false

	var hits: = 0
	var fast: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 5:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					hits += 1
					if s.pl[ev.id].speed > 5.0:
						fast += 1
			s.events.clear()
	var frac: = float(fast) / maxf(1.0, float(hits))
	print("B golpes=", hits, " a_tope=", fast, " frac=", snappedf(frac, 0.03))
	if frac < 0.01 or frac > 0.18:
		print("FAIL B: la deslizada saldria sin parar o nunca");ok = false
	print("GATE103 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
