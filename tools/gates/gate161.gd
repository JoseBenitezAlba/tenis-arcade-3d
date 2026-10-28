extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var cb: = FileAccess.get_file_as_string("res://scripts/court_builder.gd")
	if not cb.contains("bases de los postes"): print("FAIL: bases");fail += 1
	if not cb.contains("RACKETIA"): print("FAIL: marcas");fail += 1
	if cb.contains("\"SAQUE\", \"ACE\", \"SMASH\""): print("FAIL: mecanicas");fail += 1
	var court: = CourtBuilder.build("grass", true)
	var cables: = 0
	for c in court.get_children():
		if c is MeshInstance3D and absf(c.rotation.z) > 0.0001 and absf(c.position.z - CourtBuilder.NZ) < 0.01 and c.position.y > 0.8:
			cables += 1
	if cables < 10: print("FAIL: cable segs ", cables);fail += 1
	court.queue_free()
	print("gate161 ", "PASS" if fail == 0 else "FAIL")
	quit()
