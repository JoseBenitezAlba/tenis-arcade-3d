extends SceneTree


const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	if PF.trail_alpha(2.0) != 0.0: print("FAIL: alfa en reposo");fail += 1
	if not (PF.trail_alpha(12.0) > 0.0 and PF.trail_alpha(25.0) > PF.trail_alpha(12.0)): print("FAIL: monotona");fail += 1
	if PF.trail_alpha(40.0) > 0.33: print("FAIL: tope");fail += 1
	if PF.trail_alpha(99.0) != 0.0: print("FAIL: salto de pose");fail += 1
	var pts: = [{"t": 0.0}, {"t": 0.1}, {"t": 0.3}]
	if PF.trail_prune(pts, 0.3, 0.14).size() != 1: print("FAIL: poda");fail += 1
	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	fig.swing_now = 1.0
	for i in 10:
		fig.position = Vector3(i * 0.3, 0, 0)
		fig._trail_step(1.0 / 60.0)
	print("puntos de estela: ", fig.trail_pts.size(), " superficies: ", fig.trail_im.get_surface_count() if fig.trail_im != null else -1)
	if fig.trail_pts.size() < 5: print("FAIL: sin puntos");fail += 1
	if fig.trail_im == null or fig.trail_im.get_surface_count() == 0: print("FAIL: sin malla");fail += 1
	fig.swing_now = 0.0
	for i in 30:
		fig._trail_step(1.0 / 60.0)
	if fig.trail_pts.size() != 0: print("FAIL: no se apaga");fail += 1
	if fig.trail_im.get_surface_count() != 0: print("FAIL: malla viva");fail += 1
	print("gate128 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
