extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(11313)

	if MV.leg_dust_next(0.0, "clay") != 0.025 or MV.leg_dust_next(0.99, "clay") != 1.0:
		print("FAIL A: paso de polvo en arcilla");ok = false
	if MV.leg_dust_next(0.5, "hard") != 0.5 or MV.leg_dust_next(0.5, "grass") != 0.5:
		print("FAIL A: no debe acumular fuera de arcilla");ok = false
	print("A paso y superficies OK")

	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	s.surface = "clay"
	var puntos: = 0
	for f in 60 * 60 * 4:
		s.update(1.0 / 60.0)
		for ev in s.events:
			if ev.get("t") == "point":
				puntos += 1
		s.events.clear()
	var esperado: float = minf(1.0, puntos * 0.025)
	print("B puntos_4min=", puntos, " polvo_esperado=", snappedf(esperado, 0.02))
	if esperado < 0.35 or esperado > 1.0:
		print("FAIL B: el polvo tardaria una eternidad o se pasaria");ok = false
	print("GATE113 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
