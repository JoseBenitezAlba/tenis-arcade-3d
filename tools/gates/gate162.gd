extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("Punch_Left"): print("FAIL: punch_left");fail += 1
	if not mv.contains("HitRecieve_2"): print("FAIL: frustracion");fail += 1
	if not mv.contains("v0.162"): print("FAIL: marca");fail += 1
	if mv.contains("Sword_Slash"): print("FAIL: sword");fail += 1
	if mv.contains("\"Dance\""): print("FAIL: dance vetado");fail += 1

	var p_set: Array = MatchView.winner_celebration_plan("SET", 0, 1)
	if p_set.is_empty() or p_set[0] == "Wave": print("FAIL: set plan");fail += 1
	var p_pt: Array = MatchView.winner_celebration_plan("PUNTO", 2, 1)
	if p_pt.is_empty(): print("FAIL: punto plan");fail += 1
	var p_pt0: Array = MatchView.winner_celebration_plan("PUNTO", 0, 1)
	if not p_pt0.is_empty(): print("FAIL: punto frio");fail += 1
	print("gate162 ", "PASS" if fail == 0 else "FAIL")
	quit()
