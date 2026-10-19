extends SceneTree

func _init() -> void :
	var fail: = 0
	var f = load("res://scripts/player_fig.gd").new(0, true)
	root.add_child(f)
	await process_frame
	var rk: Node3D = f.racket_node
	var found: = 0
	for m in rk.find_children("*", "MeshInstance3D", true, false):
		if m.mesh is TorusMesh:
			found += 1
			var axis: Vector3 = (m.basis * Vector3.UP).normalized()
			if absf(absf(axis.z) - 1.0) > 0.01: print("FAIL: aro no coplanar con el cordaje ", axis);fail += 1
			if m.position.y > -0.5 or m.position.y < -0.65: print("FAIL: aro fuera de sitio ", m.position);fail += 1
		elif m.mesh is QuadMesh:
			var nrm: Vector3 = (m.basis * Vector3.BACK).normalized()
			if absf(absf(nrm.z) - 1.0) > 0.01: print("FAIL: cordaje fuera de plano");fail += 1
		elif m.mesh is CylinderMesh and abs(m.position.x) < 0.001 and m.mesh.height > 0.2:
			var ax: Vector3 = (m.basis * Vector3.UP).normalized()
			if absf(ax.y) < 0.99: print("FAIL: mango no va por Y");fail += 1
	if found != 2: print("FAIL: toros ", found);fail += 1
	print("gate135 ", "PASS" if fail == 0 else "FAIL")
	quit()
