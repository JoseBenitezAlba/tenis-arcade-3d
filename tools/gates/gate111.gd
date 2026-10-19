extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(11111)

	if MV.clay_tint_next(0.0, "clay") != 0.05 or MV.clay_tint_next(0.99, "clay") != 1.0:
		print("FAIL A: paso de tinte en arcilla");ok = false
	if MV.clay_tint_next(0.5, "hard") != 0.5 or MV.clay_tint_next(0.5, "grass") != 0.5:
		print("FAIL A: no debe tenir fuera de arcilla");ok = false
	var c0: Color = MV.clay_ball_color(0.0)
	var c1: Color = MV.clay_ball_color(1.0)
	if c0 != MV.BALL_YEL:
		print("FAIL A: tinte 0 debe ser la bola limpia");ok = false
	if c1.g <= c1.r * 0.55 or c1.g >= c0.g:
		print("FAIL A: el tinte debe ocresar sin apagar el amarillo");ok = false
	print("A limpia=", c0, " polvorienta=", c1)

	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for surf in ["clay", "hard"]:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = surf
		var botes: = 0
		for f in 60 * 60 * 4:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "bounce":
					botes += 1
			s.events.clear()
		var esperado: float = minf(1.0, botes * 0.05) if surf == "clay" else 0.0
		print("B ", surf, " botes=", botes, " tinte_esperado=", esperado)
		if surf == "clay" and esperado < 0.5:
			print("FAIL B: pocos botes en arcilla para ver el tinte");ok = false
	print("GATE111 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
