extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not mv.contains("if sim.state == \"serve\" and not sim.ball.held:"):
		print("FAIL: cap bola saque");fail += 1
	if not mv.contains("bk = minf(bk, 0.72)"):
		print("FAIL: cap 0.72");fail += 1
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not sm.contains("rec.x = -1.5 * sgn if near else 1.5 * sgn"):
		print("FAIL: prep restador");fail += 1
	var sim: = TennisSim.new(true, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
	var dt: = 1.0 / 120.0
	var t: = 0.0
	var serves: = 0
	var bad: = 0
	var last_state: = ""
	while t < 120.0 and serves < 12:
		t += dt
		sim.update(dt)
		if sim.state == "serve" and last_state != "serve" and sim.serve_stage == "ready":
			var r = sim.pl[1 - sim.M.server]
			if absf(r.x) > 3.0:
				bad += 1
			serves += 1
		last_state = sim.state
		sim.events.clear()
	if serves < 8:
		print("FAIL: pocos saques ", serves);fail += 1
	if bad > 0:
		print("FAIL: restador fuera ", bad);fail += 1
	print("gate158 ", "PASS" if fail == 0 else "FAIL")
	quit()
