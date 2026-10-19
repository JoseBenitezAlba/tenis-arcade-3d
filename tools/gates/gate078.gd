extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :

	if MV.crowd_point_plan("PUNTO", 1).size() != 0 or MV.crowd_point_plan("PUNTO", 2).size() != 0:
		print("FAIL: rally corto no debe aplaudir");ok = false

	var a3 = MV.crowd_point_plan("PUNTO", 3)
	var a7 = MV.crowd_point_plan("PUNTO", 7)
	if a3.size() != 1 or a3[0][0] != "applause":
		print("FAIL: rally 3 sin cortesia");ok = false
	if a7.size() != 1 or a7[0][1] <= a3[0][1]:
		print("FAIL: la cortesia no crece con el rally");ok = false

	if MV.crowd_point_plan("PUNTO", 8).size() != 0:
		print("FAIL: rally 8 duplicaria aplauso");ok = false

	var j = MV.crowd_point_plan("JUEGO", 0)
	var st = MV.crowd_point_plan("SET", 0)
	var p = MV.crowd_point_plan("PARTIDO", 0)
	if j.size() != 1 or j[0][0] != "ovation" or j[0][1] < 0.7:
		print("FAIL: juego sin ovacion");ok = false
	if st.size() != 1 or st[0][1] < 0.95:
		print("FAIL: set sin ovacion plena");ok = false
	var has_force: = false
	for rx in p:
		if rx[0] == "force_ovation": has_force = true
	if not has_force:
		print("FAIL: partido sin force_ovation");ok = false
	if MV.crowd_point_plan("SET", 0)[0][1] < MV.crowd_point_plan("JUEGO", 0)[0][1]:
		print("FAIL: set debe sonar >= que juego");ok = false
	print("A cortesia 3=", a3, " 7=", a7, " juego=", j, " set=", st, " partido=", p.size())
	print("GATE078 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
