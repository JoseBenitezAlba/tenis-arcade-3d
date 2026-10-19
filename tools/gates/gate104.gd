extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10404)

	print("A clay=", MV.skid_alpha("clay"), " grass=", MV.skid_alpha("grass"), " hard=", MV.skid_alpha("hard"), 
		" ang(+z)=", snappedf(MV.skid_angle(0.0, 3.0), 0.01), " ang(+x)=", snappedf(MV.skid_angle(3.0, 0.0), 0.01))
	if MV.DECAL_Y <= 0.06:
		print("FAIL A: las calcas quedan bajo el plano de la pista (y=0.06)");ok = false
	if MV.skid_alpha("clay") != 0.7 or MV.skid_alpha("grass") != 0.0 or MV.skid_alpha("hard") != 0.0:
		print("FAIL A: solo la arcilla guarda surcos");ok = false
	if absf(MV.skid_angle(0.0, 3.0)) > 0.01 or absf(MV.skid_angle(3.0, 0.0) - PI / 2.0) > 0.01:
		print("FAIL A: el surco no sigue la direccion del arrastre");ok = false

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
	print("B golpes=", hits, " deslizadas=", fast, " frac=", snappedf(frac, 0.03))
	if frac < 0.01 or frac > 0.18:
		print("FAIL B: los surcos saldrian sin parar o nunca");ok = false
	print("GATE104 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
