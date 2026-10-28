extends SceneTree

func _init():
	var fail: = 0
	for m in ["Casual_2", "Casual_Hoodie"]:
		var sc: Node = load("res://models/%s.glb" % m).instantiate()
		var sk: = sc.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk == null or sk.find_bone("Wrist.R") < 0: print("FAIL: sin Wrist.R en ", m);fail += 1
		sc.free()
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not ("_tut_n < 2" in mv): print("FAIL: tutorial");fail += 1
	if not ("_closeup_ok" in mv): print("FAIL: closeup");fail += 1
	var PF = load("res://scripts/player_fig.gd")
	if PF.RK_REST_A < 1.2 or PF.RK_REST_A > 2.8: print("FAIL: reposo raqueta");fail += 1
	print("gate153 ", "PASS" if fail == 0 else "FAIL")
	quit()
