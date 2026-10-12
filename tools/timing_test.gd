extends SceneTree
# v0.16: mide golpear AL BOTE (vy>1, agresivo) vs ESPERAR (vy<0, seguro).
# Uso: godot --headless -s tools/timing_test.gd -- [partidos]

const D := {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}

func _initialize() -> void:
	var n := 8
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	_run("rise", n)
	_run("wait", n)
	print("TIMING done")
	quit(0)

func _run(mode: String, n: int) -> void:
	var dt := 1.0 / 60.0
	var hp := 0
	var cp := 0
	var outs := {}
	var hits_rise := 0
	var hits_wait := 0
	var ft_rise := 0.0
	var ft_wait := 0.0
	for m in n:
		var sim := TennisSim.new(false, D, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
		var guard := 0
		var last_hit_t := -1.0
		var last_hit_rise := false
		while not sim.match_over and guard < 60 * 60 * 25:
			var p = sim.pl[0]
			if sim.state == "serve" and sim.M.server == 0:
				if sim.serve_stage == "ready":
					sim.inp.hit = true
				elif sim.serve_stage == "toss" and sim.ball.toss_t >= 0.36:
					sim.inp.hit = true
			elif sim.state == "play":
				var coming: bool = sim.ball.in_play and sim.ball.last != 0 and sim.ball.vz < 0
				if coming:
					var pred: Vector3 = sim.predict(p)
					sim.inp.x = clampf((pred.x - p.x) * 0.8, -1.0, 1.0)
					sim.inp.y = clampf((pred.z - p.z) * 0.4, -1.0, 1.0)
					var dx: float = absf(sim.ball.x - p.x)
					var dz: float = absf(sim.ball.z - p.z)
					if mode == "rise":
						if dx < 2.2 and dz < 2.0 and sim.ball.bounces >= 1 and sim.ball.vy > 1.0:
							sim.inp.hit = true
					else:
						if dx < 2.2 and dz < 2.0 and sim.ball.vy < 0.0 and sim.ball.y < 1.3:
							sim.inp.hit = true
				else:
					sim.inp.x = clampf((0.0 - p.x) * 0.5, -1.0, 1.0)
					sim.inp.y = clampf((1.2 - p.z) * 0.3, -1.0, 1.0)
			sim.update(dt)
			guard += 1
			for ev in sim.events:
				if ev.get("t") == "hit" and int(ev.id) == 0:
					last_hit_t = sim.time
					last_hit_rise = bool(ev.get("rise", false))
					if last_hit_rise:
						hits_rise += 1
					else:
						hits_wait += 1
				elif ev.get("t") == "bounce" and last_hit_t >= 0.0:
					var ft: float = sim.time - last_hit_t
					if last_hit_rise:
						ft_rise += ft
					else:
						ft_wait += ft
					last_hit_t = -1.0
				elif ev.get("t") == "point":
					last_hit_t = -1.0
					var w: String = ev.get("txt", "?")
					outs[w] = outs.get(w, 0) + 1
					if int(ev.w) == 0:
						hp += 1
					else:
						cp += 1
			sim.events.clear()
	var fr: float = ft_rise / maxf(1.0, float(hits_rise))
	var fw: float = ft_wait / maxf(1.0, float(hits_wait))
	print("TIMING %s | puntos bot %d - cpu %d (%.0f%%) | golpes rise %d (vuelo %.2fs) wait %d (vuelo %.2fs) | %s" % [mode, hp, cp, 100.0 * hp / maxf(1.0, float(hp + cp)), hits_rise, fr, hits_wait, fw, str(outs)])
