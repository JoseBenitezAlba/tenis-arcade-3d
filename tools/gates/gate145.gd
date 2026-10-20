extends SceneTree

func _init():
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var pf: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not mv.contains("const TOSS_BALL_K: = 0.42"): print("FAIL: TOSS_BALL_K");fail += 1
	if not mv.contains("ball_vis_scale"): print("FAIL: ball_vis_scale");fail += 1
	if not pf.contains("celeb_name == \"Punch_Right\""): print("FAIL: racket Punch_Right");fail += 1
	if not sm.contains("clampf("): print("FAIL: sim");fail += 1
	print("gate145 ", "PASS" if fail == 0 else "FAIL")
	quit()
