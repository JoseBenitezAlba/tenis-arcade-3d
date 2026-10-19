extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	var s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.M.pts = [3, 0]
	s.M.server = 1
	s.award_point(0, "PUNTO", "")
	var ev0: Dictionary = s.events[s.events.size() - 1]
	var brk_break: bool = ev0.get("brk", false)
	var txt0: String = ev0.get("txt", "")
	s.events.clear()
	s.state = "play"
	s.M.pts = [3, 0]
	s.M.server = 0
	s.award_point(0, "PUNTO", "")
	var ev1: Dictionary = s.events[s.events.size() - 1]
	var brk_hold: bool = ev1.get("brk", true)
	print("A break_al_resto=", brk_break, " txt=", txt0, " confirmando_saque=", brk_hold)
	if not brk_break or txt0 != "JUEGO" or brk_hold:
		print("FAIL A: la marca de break es incorrecta");ok = false

	seed(120)
	var s2 = SimClass.new(true, CP, HP, "CPU", 1)
	var juegos: = 0
	var breaks: = 0
	for i in 60 * 60 * 20:
		s2.update(1.0 / 60.0)
		for ev in s2.events:
			if ev.get("t") == "point" and ev.get("txt") == "JUEGO":
				juegos += 1
				if ev.get("brk", false):
					breaks += 1
		s2.events.clear()
		if juegos >= 8:
			break
	print("B juegos=", juegos, " breaks=", breaks)
	if juegos < 4 or breaks < 1:
		print("FAIL B: no hubo breaks en el partido simulado");ok = false
	print("GATE120 PASS" if ok else "GATE120 FAIL")
	quit(0 if ok else 1)
