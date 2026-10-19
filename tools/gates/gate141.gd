extends SceneTree
# gate141: v0.141 - indicador de rally en vivo con record, margen de contacto del jugador ampliado
func _init():
	var fail := 0
	var mv: String = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var sm: String = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not mv.contains("_update_rally_label") or not mv.contains("rally_best"): print("FAIL: sin indicador de rally"); fail += 1
	if not sm.contains("var hgx: = 1.65"): print("FAIL: margen de contacto"); fail += 1
	print("gate141 ", "PASS" if fail == 0 else "FAIL")
	quit()
