extends SceneTree
# gate140: v0.140 - malla de piernas ligada al esqueleto, restador a 1.5 m del centro, bola en mano pequena, carga sin globo forzado
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _init():
	var fail := 0
	var f = load("res://scripts/player_fig.gd").new(0, true)
	root.add_child(f)
	await process_frame
	var l = f.skel.get_node_or_null("Shorts_Legs")
	if l == null or str(l.skeleton) != "..": print("FAIL: piernas sin skeleton ", l.skeleton if l else "null"); fail += 1
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	for k in 6:
		s.prep_serve()
		var rec = s.pl[1 - s.M.server]
		if absf(absf(rec.x) - 2.0) > 0.01: print("FAIL: restador x=", rec.x); fail += 1
		s.M.pts[0] += 1
	var MV = load("res://scripts/match_view.gd")
	if MV.held_ball_scale(true, false, 0.0) > 0.35: print("FAIL: bola en mano"); fail += 1
	var src: String = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if src.contains("var late: = e.charge >= 0.5"): print("FAIL: carga vuelve a globo"); fail += 1
	var pf: String = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if not pf.contains("prep_k"): print("FAIL: sin preparacion por proximidad"); fail += 1
	print("gate140 ", "PASS" if fail == 0 else "FAIL")
	quit()
