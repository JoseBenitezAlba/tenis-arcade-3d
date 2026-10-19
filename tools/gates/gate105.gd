extends SceneTree





const CB: = preload("res://scripts/court_builder.gd")
var ok: = true
func _init() -> void :

	print("A cells noche=", CB.flood_cells(1), " dia=", CB.flood_cells(0), " tarde=", CB.flood_cells(2), " conos=", CB.flood_cones(1))
	if CB.flood_cells(1) != 24 or CB.flood_cells(0) != 0 or CB.flood_cells(2) != 0 or CB.flood_cones(1) != 4 or CB.flood_cones(0) != 0:
		print("FAIL A: mapeo de focos por hora incorrecto");ok = false

	for cfg in [[1, 24, 4], [0, 0, 0], [2, 0, 0]]:
		var court: = CB.build("clay", cfg[0])
		var cells: = 0
		var cones: = 0
		for ch in court.get_children():
			if ch.get_meta("flood", "") == "cell": cells += 1
			if ch.get_meta("flood", "") == "cone": cones += 1
		print("B tod=", cfg[0], " celdas=", cells, " conos=", cones)
		if cells != cfg[1] or cones != cfg[2]:
			print("FAIL B: la pista no lleva sus focos");ok = false
		court.free()
	print("GATE105 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
