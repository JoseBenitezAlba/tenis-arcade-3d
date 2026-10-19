extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(11010)

	if MV.grunt_serve_vol(0.3) != 0.0:
		print("FAIL A: saque flojo no debe grunir");ok = false
	if MV.grunt_serve_vol(0.9) <= MV.grunt_serve_vol(0.6) or MV.grunt_serve_vol(0.9) > 0.65:
		print("FAIL A: el grunt del saque debe crecer con la calidad");ok = false
	if MV.grunt_hit_vol(1.0, "drive") != 0.0 or MV.grunt_hit_vol(1.5, "drive") <= 0.0 or MV.grunt_hit_vol(0.0, "smash") <= 0.0:
		print("FAIL A: grunt de golpe mal mapeado");ok = false
	print("A serve_q0.9=", snappedf(MV.grunt_serve_vol(0.9), 0.01), " cargado=", snappedf(MV.grunt_hit_vol(1.5, "drive"), 0.01), " smash=", MV.grunt_hit_vol(0.0, "smash"))

	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var serves: = 0
	var grunts: = 0
	var smashes: = 0
	for m in 4:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "serve":
					serves += 1
					if MV.grunt_serve_vol(ev.get("q", 0.0)) > 0.0:
						grunts += 1
				elif ev.get("t") == "hit" and ev.get("kind") == "smash":
					smashes += 1
			s.events.clear()
	var frac: = float(grunts) / maxf(1.0, float(serves))
	print("B saques=", serves, " con_grunt=", grunts, " frac=", snappedf(frac, 0.02), " smashes=", smashes)
	if frac < 0.4 or frac > 1.0:
		print("FAIL B: el grunt suena siempre o nunca en el saque");ok = false
	if smashes < 1:
		print("FAIL B: no hubo smashes en 24 min de demo");ok = false
	print("GATE110 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
