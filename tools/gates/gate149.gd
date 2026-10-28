extends SceneTree

func _init():
	var fail: = 0
	var MV = load("res://scripts/match_view.gd")
	if MV.PLAYER_SHADOW_K < 1.2 or MV.PLAYER_SHADOW_K > 1.6: print("FAIL: factor de sombra");fail += 1
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("q.scale = Vector3(PLAYER_SHADOW_K"): print("FAIL: sombra no aplicada");fail += 1
	print("gate149 ", "PASS" if fail == 0 else "FAIL")
	quit()
