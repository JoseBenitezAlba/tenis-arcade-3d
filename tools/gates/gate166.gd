extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
func _initialize() -> void :
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/menus.gd")
	var mn: = FileAccess.get_file_as_string("res://scripts/main.gd")
	if not mv.contains("func _stats_panel"): print("FAIL: panel");fail += 1
	if not mv.contains("\"ESTADÍSTICAS\""): print("FAIL: titulo");fail += 1
	if not mn.contains("match_view.sim.stats"): print("FAIL: pase de stats");fail += 1
	var s = SimClass.new(false, {"speed": 7.0, "T": 1.0, "err": 1.0}, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, "CPU", 1)
	s.state = "serve";s.M.server = 0
	s.fault("RED");s.fault("RED")
	if s.stats[0].df != 1 or s.stats[0].first_total != 1: print("FAIL: doble falta ", s.stats[0]);fail += 1
	if s.stats[1].points != 1: print("FAIL: puntos");fail += 1
	s.state = "play";s.rally_hits = 5
	s.award_point(0, "PUNTO", "")
	if s.stats[0].winners != 1 or s.rally_max != 5: print("FAIL: winner");fail += 1
	s.state = "play";s.rally_hits = 1;s.M.server = 0
	s.award_point(0, "PUNTO", "")
	if s.stats[0].aces != 1: print("FAIL: ace");fail += 1
	s.state = "play";s.rally_hits = 3
	s.award_point(1, "FUERA", "")
	if s.stats[0].errors != 1: print("FAIL: error");fail += 1
	print("gate166 ", "PASS" if fail == 0 else "FAIL")
	quit()
