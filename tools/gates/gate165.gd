extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var cb: = FileAccess.get_file_as_string("res://scripts/court_builder.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")

	if cb.count("umpire.scale = Vector3.ONE * 0.66") != 1: print("FAIL: umpire escala");fail += 1
	if cb.count("judge.scale = Vector3.ONE * 0.66") != 1: print("FAIL: juez escala");fail += 1
	if not cb.contains("\"tennis/Sitting_Idle\", Color(\"#8a8078\"), 0.42)"): print("FAIL: umpire cabeza");fail += 1

	if not mv.contains("lerpf(ball_vis_scale, bk, minf(1.0, dt * 4.5))"): print("FAIL: globo");fail += 1
	if not mv.contains("0.28 * sqk"): print("FAIL: squash");fail += 1
	if MatchView.far_ball_k(30.0) <= 1.1 or MatchView.far_ball_k(100.0) > 1.3: print("FAIL: far_k");fail += 1
	if MatchView.held_ball_scale(false, true, 0.35) < 0.5: print("FAIL: toss");fail += 1
	print("gate165 ", "PASS" if fail == 0 else "FAIL")
	quit()
