extends SceneTree

func _init():
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not sm.contains("split_t = 0.32") or not sm.contains("split_boost"): print("FAIL: split-step sim");fail += 1
	if mv.contains("split-step visual del receptor"): print("FAIL: hop duplicado");fail += 1
	if not mv.contains("hitstop_t"): print("FAIL: hitstop");fail += 1
	print("gate156 ", "PASS" if fail == 0 else "FAIL")
	quit()
