extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(11212)

	for g in [0, 1, 3, 6, 8, 13, 15]:
		if MV.balls_change(g):
			print("FAIL A: cambio en ", g, " juegos");ok = false
	for g in [7, 14, 21]:
		if not MV.balls_change(g):
			print("FAIL A: no cambia en ", g, " juegos");ok = false
	print("A cambio solo en multiplos de 7")


	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	s.surface = "clay"
	s.M.games = [3, 3]
	var cambio7: = false
	var juegos: = 0
	for f in 60 * 60 * 10:
		s.update(1.0 / 60.0)
		for ev in s.events:
			if ev.get("t") == "point" and ev.get("txt") == "JUEGO":
				juegos += 1
				var tot: int = s.M.games[0] + s.M.games[1]
				if tot == 7 and MV.balls_change(tot):
					cambio7 = true
				if tot != 7 and MV.balls_change(tot):
					print("FAIL B: cambio fuera del 7 (tot=", tot, ")");ok = false
		s.events.clear()
		if juegos >= 3:
			break
	print("B juegos=", juegos, " cambio_en_el_7=", cambio7)
	if not cambio7:
		print("FAIL B: no salto el cambio al llegar a 7 juegos");ok = false
	print("GATE112 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
