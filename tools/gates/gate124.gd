extends SceneTree

func _init() -> void :
	var fail: = 0
	var court: Node3D = CourtBuilder.build("clay")
	root.add_child(court)
	var towels: = 0
	var bottles: = 0
	var stack: = [court]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and n.name.begins_with("BenchTowel"):
			towels += 1
			if absf(n.position.x) > 1.1 or n.position.y < 0.4 or n.position.y > 0.9:
				print("FAIL: toalla fuera del banco ", n.position);fail += 1
		if n is MeshInstance3D and n.name.begins_with("BenchBottle"):
			bottles += 1
			if absf(n.position.x - 0.6) < 0.35:
				print("FAIL: botella pisa la bolsa");fail += 1
	print("toallas=", towels, " botellas=", bottles)
	if towels != 4 or bottles != 2:
		print("FAIL: conteo");fail += 1
	print("gate124 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
