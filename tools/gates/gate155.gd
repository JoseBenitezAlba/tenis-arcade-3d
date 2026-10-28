extends SceneTree

func _init():
	var fail: = 0
	if TennisSim.rut_y(0.275) < 0.25: print("FAIL: rebote a ras de suelo");fail += 1
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("(0.4 if sim.ball.held else 1.0)"): print("FAIL: sombra");fail += 1
	print("gate155 ", "PASS" if fail == 0 else "FAIL")
	quit()
