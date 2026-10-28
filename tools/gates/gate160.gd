extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var cb: = FileAccess.get_file_as_string("res://scripts/court_builder.gd")
	if not cb.contains("focos apagados de dia"): print("FAIL: focos");fail += 1
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("\"CAMBIO DE LADOS\""): print("FAIL: cambio lados");fail += 1
	var court: = CourtBuilder.build("grass", true)
	var cells: = 0
	for c in court.get_children():
		pass
	court.queue_free()
	print("gate160 ", "PASS" if fail == 0 else "FAIL")
	quit()
