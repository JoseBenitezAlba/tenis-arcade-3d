extends SceneTree

func _init():
	var fail: = 0
	var MV = load("res://scripts/match_view.gd")
	if MV.BOUNCE_RING_FAR_A < 0.7 or MV.BOUNCE_RING_FAR_A > 0.95: print("FAIL: alfa lejano");fail += 1
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("lerpf(0.95, BOUNCE_RING_FAR_A, k)"): print("FAIL: no aplicado");fail += 1
	print("gate151 ", "PASS" if fail == 0 else "FAIL")
	quit()
