extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(94094)

	var c1: float = MV.dust_trail_time("clay", 0.6)
	var c2: float = MV.dust_trail_time("clay", 0.4)
	var h1: float = MV.dust_trail_time("hard", 0.9)
	var h2: float = MV.dust_trail_time("hard", 0.6)
	var g1: float = MV.dust_trail_time("grass", 1.0)
	print("A clay0.6=", c1, " clay0.4=", c2, " hard0.9=", h1, " hard0.6=", h2, " grass1.0=", g1)
	if absf(c1 - 0.35) > 0.001 or c2 != 0.0 or absf(h1 - 0.12) > 0.001 or h2 != 0.0 or g1 != 0.0:
		print("FAIL A: mapeo de rastro incorrecto");ok = false

	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var botes: = 0
	var con: = 0
	for m in 4:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "bounce":
					botes += 1
					if float(ev.v) >= 0.5:
						con += 1
			s.events.clear()
	var frac: = float(con) / maxf(1.0, float(botes))
	print("B botes=", botes, " con_ritmo=", con, " frac=", snappedf(frac, 0.03))
	if frac < 0.5:
		print("FAIL B: los botes perdieron ritmo (regresion o gate vacio)");ok = false
	print("GATE094 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
