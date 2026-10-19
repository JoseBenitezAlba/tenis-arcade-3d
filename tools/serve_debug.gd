extends SceneTree
func _initialize() -> void :
	for i in 10:
		var sim: = TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
		var dt: = 1.0 / 60.0
		var guard: = 0
		while guard < 60 * 6 and sim.state == "serve":
			var p = sim.pl[0]
			var bs: = - signf(p.x)
			sim.inp.y = 1.0
			sim.inp.x = 0.9 * bs
			if sim.serve_stage == "ready":
				sim.inp.hit = true
			elif sim.serve_stage == "toss" and sim.ball.toss_t >= 0.84:
				sim.inp.hit = true
			sim.update(dt)
			guard += 1
			for ev in sim.events:
				if ev.get("t") in ["serve", "fault", "net", "bounce", "point"]:
					print(i, " ", ev, " | ball y=%.2f z=%.2f x=%.2f" % [sim.ball.y, sim.ball.z, sim.ball.x])
			sim.events.clear()
	print("DEBUG done")
	quit(0)
