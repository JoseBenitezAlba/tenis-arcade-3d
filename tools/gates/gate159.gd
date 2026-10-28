extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("\"#ffe14d\""): print("FAIL: AL BOTE");fail += 1
	var tx: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if tx.contains("\"#39b54a\""): print("FAIL: CPU verde");fail += 1
	if not tx.contains("\"#f5f0e6\""): print("FAIL: CPU blanca");fail += 1
	print("gate159 ", "PASS" if fail == 0 else "FAIL")
	quit()
