extends SceneTree

func _init():
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if mv.contains("celebrate(\"HitRecieve\" if is_err else \"Wave\""): print("FAIL: perdedor celebra");fail += 1
	if not mv.contains("_idle_ball_t > 1.3"): print("FAIL: bola tras punto");fail += 1
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not sm.contains("clamp(e.z, -2.4, 0.9) if e.near else clamp(e.z, L - 0.9, L + 2.4)"): print("FAIL: receptor red");fail += 1
	var cb: = FileAccess.get_file_as_string("res://scripts/court_builder.gd")
	if not cb.contains("if ji < 2:"): print("FAIL: jueces camara");fail += 1
	print("gate154 ", "PASS" if fail == 0 else "FAIL")
	quit()
