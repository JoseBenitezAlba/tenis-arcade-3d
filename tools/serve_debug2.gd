extends SceneTree
func _initialize() -> void :
	var sim: = TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
	var dt: = 1.0 / 60.0
	var guard: = 0
	while not sim.match_over and guard < 60 * 60 * 12:
		var p = sim.pl[0]
		if sim.state == "serve" and sim.M.server == 0:
			var bs: = - signf(p.x)
			sim.inp.y = 1.0
			sim.inp.x = 0.9 * bs
			if sim.serve_stage == "ready":
				sim.inp.hit = true
			elif sim.serve_stage == "toss" and sim.ball.toss_t >= 0.84:
				sim.inp.hit = true
		elif sim.state == "play":
			var coming: bool = sim.ball.in_play and sim.ball.last != 0 and sim.ball.vz < 0
			if coming:
				var pred: Vector3 = sim.predict(p)
				sim.inp.x = clampf((pred.x - p.x) * 0.8, -1.0, 1.0)
				sim.inp.y = clampf((pred.z - p.z) * 0.4, -1.0, 1.0)
				if absf(sim.ball.x - p.x) < 2.6 and absf(sim.ball.z - p.z) < 2.4:
					sim.inp.hit = true
			else:
				sim.inp.x = clampf((0.0 - p.x) * 0.5, -1.0, 1.0)
				sim.inp.y = clampf((1.2 - p.z) * 0.3, -1.0, 1.0)
		sim.update(dt)
		guard += 1
		for ev in sim.events:
			if ev.get("t") == "toss":
				print("TOSS t=%.2f stage=%s held=%s" % [sim.time, sim.serve_stage, sim.ball.held])
			if ev.get("t") == "fault":
				print("FALTA why=", ev.get("why"), " serve_fault=", sim.serve_fault, " stage=", sim.serve_stage, " toss=", sim.ball.toss, " held=", sim.ball.held, " ball x=%.2f y=%.2f z=%.2f srv.x=%.2f" % [sim.ball.x, sim.ball.y, sim.ball.z, sim.pl[sim.M.server].x])
			elif ev.get("t") == "serve":
				print("serve q=%.2f x=%.2f z=%.2f" % [ev.get("q", -1.0), sim.ball.x, sim.ball.z], " srv.x=%.2f" % sim.pl[0].x)
		sim.events.clear()
	print("done pts=", sim.M.pts)
	quit(0)
