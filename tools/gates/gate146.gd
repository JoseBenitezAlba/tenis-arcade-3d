extends SceneTree

func _init():
	var fail: = 0
	var MV = load("res://scripts/match_view.gd")
	if MV.far_ball_k(10.0) != 1.0: print("FAIL: cerca no es 1");fail += 1
	if MV.far_ball_k(30.0) <= 1.1: print("FAIL: lejos no crece");fail += 1
	if MV.far_ball_k(100.0) > 1.5: print("FAIL: tope");fail += 1
	print("gate146 ", "PASS" if fail == 0 else "FAIL")
	quit()
