extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")

	if not sm.contains("var _rec_base: float = 0.05 if (not demo and e.id == 0) else 0.1"): print("FAIL: recov base");fail += 1
	if not sm.contains("0.7 if (not demo and e.id == 0) else 0.4, 1.0"): print("FAIL: rf floor");fail += 1

	if sm.count("kvx = 5.5 if (not demo and e.id == 0) else 4.2") != 1: print("FAIL: turn kx");fail += 1
	if sm.count("kvz = 5.5 if (not demo and e.id == 0) else 4.2") != 1: print("FAIL: turn kz");fail += 1
	if not sm.contains("(0.22 if (not demo and e.id == 0) else 0.18)"): print("FAIL: stretch k");fail += 1

	var pf: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if pf.contains("_ease_in_cubic(kk / 0.3) * sc[1]"): print("FAIL: swing tardio");fail += 1
	if not pf.contains("arranca en el frame de contacto"): print("FAIL: marca swing");fail += 1

	var mn: = FileAccess.get_file_as_string("res://scripts/main.gd")
	if not mn.contains("\"speed\": 6.8"): print("FAIL: cpu speed tocado");fail += 1
	print("gate163 ", "PASS" if fail == 0 else "FAIL")
	quit()
