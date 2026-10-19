extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	var wp: Array = MV.winner_celebration_plan("PARTIDO", 0)
	var ws: Array = MV.winner_celebration_plan("SET", 0)
	print("A partido=", wp, " set=", ws)
	if wp[0] != "Punch_Right" or ws[0] != "Wave":
		print("FAIL A: plan de celebracion incorrecto");ok = false

	var s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.M.sets_to_win = 2
	s.M.sets = [1, 0]
	s.M.games = [3, 1]
	s.M.pts = [3, 0]
	s.award_point(0, "PUNTO", "")
	var txt_match: String = s.events[s.events.size() - 1].get("txt", "")
	print("B1 txt_partido=", txt_match, " over=", s.match_over)
	if txt_match != "PARTIDO" or not s.match_over:
		print("FAIL B1: la victoria no emite PARTIDO");ok = false

	s.events.clear()
	s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.M.sets_to_win = 2
	s.M.sets = [0, 0]
	s.M.games = [3, 1]
	s.M.pts = [3, 0]
	s.award_point(0, "PUNTO", "")
	var txt_set: String = s.events[s.events.size() - 1].get("txt", "")
	print("B2 txt_set=", txt_set)
	if txt_set != "SET":
		print("FAIL B2: el set sigue emitiendo SET");ok = false

	s.events.clear()
	s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.M.sets_to_win = 2
	s.M.sets = [1, 0]
	s.M.tb = true
	s.M.tb_pts = [6, 4]
	s.M.tb_first_server = 0
	s.M.server = 0
	s.award_point(0, "PUNTO", "")
	var txt_tb: String = s.events[s.events.size() - 1].get("txt", "")
	print("B3 txt_tb_partido=", txt_tb, " over=", s.match_over)
	if txt_tb != "PARTIDO" or not s.match_over:
		print("FAIL B3: el tie-break de partido no emite PARTIDO");ok = false
	print("GATE121 PASS" if ok else "GATE121 FAIL")
	quit(0 if ok else 1)
