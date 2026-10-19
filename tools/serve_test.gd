extends SceneTree

const DIFFS: Array = [
	{"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3}, 
	{"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, 
	{"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06}, 
]

func _initialize() -> void :
	for di in DIFFS.size():
		_cpu(di, 5)
	_human("flat", 6, 0.5)
	_human("flat-maltiempo", 6, 0.8)
	_human("safe", 6, 0.5)
	print("SERVE done")
	quit(0)

func _cpu(di: int, n: int) -> void :
	var dt: = 1.0 / 60.0
	var serves: = 0
	var faults: = 0
	var dfs: = 0
	var aces: = 0
	var pts: = 0
	for m in n:
		var sim: = TennisSim.new(true, DIFFS[di], {}, "CPU", 1)
		var guard: = 0
		while not sim.match_over and guard < 60 * 60 * 30:
			sim.update(dt)
			guard += 1
			for ev in sim.events:
				if ev.get("t") == "serve":
					serves += 1
				elif ev.get("t") == "fault":
					faults += 1
				elif ev.get("t") == "point":
					pts += 1
					if ev.get("txt") == "DOBLE FALTA":
						dfs += 1
					elif sim.rally_hits <= 1:
						aces += 1
			sim.events.clear()
	print("SERVE CPU DIFF %d | saques %d faltas %d (%.0f%% 1saque) DF %d (%.1f%% pts) aces %d (%.0f%% pts) | pts %d" % [di, serves, faults, 100.0 * faults / maxf(1.0, float(serves)), dfs, 100.0 * dfs / maxf(1.0, float(pts)), aces, 100.0 * aces / maxf(1.0, float(pts)), pts])

func _human(mode: String, n: int, hit_at: float = 0.84) -> void :
	var dt: = 1.0 / 60.0
	var serves: = 0
	var faults: = 0
	var dfs: = 0
	var aces: = 0
	var hp: = 0
	var cp: = 0
	var ft_sum: = 0.0
	var ft_n: = 0
	for m in n:
		var sim: = TennisSim.new(false, DIFFS[1], {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
		var guard: = 0
		var serve_t: = -1.0
		while not sim.match_over and guard < 60 * 60 * 25:
			var p = sim.pl[0]
			if sim.state == "serve" and sim.M.server == 0:
				var bs: = - signf(p.x)
				if mode.begins_with("flat"):
					sim.inp.y = 1.0
					sim.inp.x = 0.9 * bs
				else:
					sim.inp.y = -1.0
					sim.inp.x = 0.0
				if sim.serve_stage == "ready":
					sim.inp.hit = true
				elif sim.serve_stage == "toss" and sim.ball.toss_t >= hit_at:
					sim.inp.hit = true
			elif sim.state == "play":
				var coming: bool = sim.ball.in_play and sim.ball.last != 0 and sim.ball.vz < 0
				if coming:
					var pred: Vector3 = sim.predict(p)
					sim.inp.x = clampf((pred.x - p.x) * 0.8, -1.0, 1.0)
					sim.inp.y = clampf((pred.z - p.z) * 0.4, -1.0, 1.0)
					var dx: float = absf(sim.ball.x - p.x)
					var dz: float = absf(sim.ball.z - p.z)
					if dx < 2.6 and dz < 2.4:
						sim.inp.hit = true
				else:
					sim.inp.x = clampf((0.0 - p.x) * 0.5, -1.0, 1.0)
					sim.inp.y = clampf((1.2 - p.z) * 0.3, -1.0, 1.0)
			sim.update(dt)
			guard += 1
			for ev in sim.events:
				if ev.get("t") == "serve" and sim.M.server == 0:
					serves += 1
					serve_t = sim.time
				elif ev.get("t") == "fault" and sim.M.server == 0:
					faults += 1
				elif ev.get("t") == "bounce" and serve_t >= 0.0:
					ft_sum += sim.time - serve_t
					ft_n += 1
					serve_t = -1.0
				elif ev.get("t") == "point":
					serve_t = -1.0
					if ev.get("txt") == "DOBLE FALTA" and int(ev.w) == 1:
						dfs += 1
					elif sim.rally_hits <= 1 and int(ev.w) == 0:
						aces += 1
					if int(ev.w) == 0:
						hp += 1
					else:
						cp += 1
			sim.events.clear()
	print("SERVE HUMANO %s | saques %d faltas %d (%.0f%%) DF %d aces %d | vuelo medio %.2fs | pts bot %d - cpu %d" % [mode, serves, faults, 100.0 * faults / maxf(1.0, float(serves)), dfs, aces, ft_sum / maxf(1.0, float(ft_n)), hp, cp])
