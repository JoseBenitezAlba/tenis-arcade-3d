extends SceneTree
# gate139: noche - luz de relleno en plano de celebracion, conos de foco tenues, sillas de juez con patas
func _init():
	var fail := 0
	var mv: String = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var cb: String = FileAccess.get_file_as_string("res://scripts/court_builder.gd")
	if not mv.contains("fill_light.light_energy"): print("FAIL: sin luz de relleno"); fail += 1
	if not cb.contains("0.022)"): print("FAIL: conos opacos"); fail += 1
	if not cb.contains("jleg"): print("FAIL: silla juez sin patas"); fail += 1
	var MV = load("res://scripts/match_view.gd")
	if MV.held_ball_scale(true, false, 0.0) > 0.5: print("FAIL: bola en mano grande"); fail += 1
	print("gate139 ", "PASS" if fail == 0 else "FAIL")
	quit()
