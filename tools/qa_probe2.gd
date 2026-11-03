extends SceneTree

const AIPD: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}
const PSD: = {"speed": 6.2, "T": 1.0, "err": 1.0}

func _mk() -> TennisSim:
	return TennisSim.new(false, AIPD, PSD, "CPU", 1)

func _stage(kind: String, swing_preset: float, charge_pow: float, bx: float, by: float, bz: float, bvy: float, up: bool, ai: bool, n: int) -> Dictionary:
	var sum: = 0.0
	var kinds: = {}
	var tqs: = {}
	for i in n:
		var sim: = _mk()
		sim.state = "play"
		var e
		if ai:
			e = sim.pl[1];e.x = 0.0;e.z = sim.L - 2.0
			sim.ball.z = sim.L - bz;sim.ball.vz = 8.0
		else:
			e = sim.pl[0];e.x = 0.0;e.z = 2.0
			sim.ball.z = bz;sim.ball.vz = -8.0
		sim.ball.x = bx
		sim.ball.y = by
		sim.ball.vx = 0.0
		sim.ball.vy = bvy
		sim.ball.last = 1 - e.id
		sim.ball.in_play = true
		sim.ball.bounces = 1
		e.swing = swing_preset
		e.charge_pow = charge_pow
		sim.inp.x = 0.0
		sim.inp.y = 0.6 if up else 0.0
		sim.do_hit(e, kind, ai)
		for ev in sim.events:
			if ev.get("t") == "hit":
				sum += ev.get("spd", 0.0) * 4.0
				kinds[ev.get("kind", "?")] = int(kinds.get(ev.get("kind", "?"), 0)) + 1
				tqs[ev.get("tq", "-")] = int(tqs.get(ev.get("tq", "-"), 0)) + 1
		sim.events.clear()
	return {"kmh": sum / n, "kinds": kinds, "tqs": tqs}

func _p1() -> void :
	print("== P1x MORE KINDS/PENALTIES (player unless noted) ==")
	var r: Dictionary
	r = _stage("lob", 0.3, 1.0, 0.2, 1.1, 2.7, -1.0, false, false, 20)
	print("P1 lob planted                 kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])
	r = _stage("toplob", 0.3, 1.0, 0.2, 1.1, 2.7, -1.0, false, false, 20)
	print("P1 toplob planted              kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])
	r = _stage("drive", 0.05, 1.0, 1.6, 0.5, 3.6, -2.0, false, false, 20)
	print("P1 drive early+low+stretch0.8  kmh=%6.1f tq=%s" % [r.kmh, str(r.tqs)])
	r = _stage("drive", 0.05, 1.0, 1.9, 0.45, 3.9, -2.5, false, false, 20)
	print("P1 drive early+low+stretch1.2  kmh=%6.1f tq=%s" % [r.kmh, str(r.tqs)])
	r = _stage("volley", 0.3, 1.0, 0.3, 1.4, 9.0, -2.0, false, false, 20)
	print("P1 volley at net planted       kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])
	r = _stage("drive", 0.3, 1.0, 0.2, 2.4, 2.7, 0.5, false, true, 20)
	print("P1 CPU high y=2.4 (promotion?) kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])
	r = _stage("drive", 0.3, 1.0, 0.2, 2.9, 2.7, 0.5, false, true, 20)
	print("P1 CPU higher y=2.9            kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])
	r = _stage("volley", 0.3, 1.0, 0.2, 1.3, 8.8, -3.0, false, true, 20)
	print("P1 CPU volley at net           kmh=%6.1f kinds=%s" % [r.kmh, str(r.kinds)])

func _serve_shot(sim: TennisSim, x: float, y: float, z: float, vx: float, vy: float, vz: float, net: bool = false) -> void :
	sim.state = "serve"
	sim.serve_stage = "hit"
	sim.serve_unreturned = true
	var b = sim.ball
	b.held = false;b.toss = false;b.in_play = true;b.serving = true;b.last = 0;b.bounces = 0;b.spin = 0.6
	b.x = x;b.y = y;b.z = z;b.vx = vx;b.vy = vy;b.vz = vz;b.serve_net = net

func _resolve(sim: TennisSim) -> Array:
	var seen: Array = []
	var dt: = 1.0 / 60.0
	var guard: = 0
	var bzmax: = 0.0
	while guard < 900:
		sim.update(dt)
		bzmax = maxf(bzmax, sim.ball.z)
		for ev in sim.events:
			var t: String = ev.get("t", "")
			if t in ["fault", "let", "point", "net", "netcord", "body"]:
				seen.append(t + (":" + str(ev.get("why", ev.get("txt", ""))) if t in ["fault", "point"] else "") + (":w" + str(ev.get("w", -1)) if t == "point" else ""))
		sim.events.clear()
		if sim.state != "serve":
			break
		if (seen.size() > 0 and (seen[-1] as String).begins_with("fault")):
			break
		if (seen.size() > 0 and (seen[-1] as String) == "let"):
			break
		guard += 1
	return [sim.state, sim.serve_fault, seen, bzmax]

func _p3() -> void :
	print("== P3b SERVE RULES (corrected staging) ==")
	var sim: TennisSim
	sim = _mk();_serve_shot(sim, -2.0, 2.4, 8.0, 0.0, 4.0, 12.0)
	print("P3 good  -> %s" % str(_resolve(sim)))
	sim = _mk();_serve_shot(sim, -2.0, 2.4, 8.0, 0.0, 4.0, 12.0, true)
	print("P3 let   -> %s" % str(_resolve(sim)))
	sim = _mk();_serve_shot(sim, 0.0, 1.0, 10.5, 0.0, 0.2, 12.0)
	print("P3 net   -> %s" % str(_resolve(sim)))
	sim = _mk();_serve_shot(sim, 1.0, 2.2, 3.0, 0.0, 3.0, 22.0)
	print("P3 long  -> %s" % str(_resolve(sim)))
	sim = _mk();_serve_shot(sim, 3.0, 2.4, 8.0, 3.0, 4.0, 12.0)
	print("P3 wide  -> %s" % str(_resolve(sim)))
	sim = _mk();var rp = sim.pl[1];_serve_shot(sim, rp.x + 0.1, 1.2, rp.z - 0.4, 0.0, 0.0, 25.0)
	print("P3 body(1st serve) -> %s" % str(_resolve(sim)))
	sim = _mk();sim.serve_fault = 1;rp = sim.pl[1];_serve_shot(sim, rp.x + 0.1, 1.2, rp.z - 0.4, 0.0, 0.0, 25.0)
	print("P3 body(2nd serve) -> %s" % str(_resolve(sim)))
	sim = _mk();rp = sim.pl[1];_serve_shot(sim, rp.x + 0.1, 1.2, rp.z - 0.4, 0.0, 0.0, 25.0, true)
	print("P3 net+body(serve, let 22a) -> %s" % str(_resolve(sim)))
	sim = _mk();sim.serve_fault = 1;rp = sim.pl[1];_serve_shot(sim, rp.x + 0.1, 1.2, rp.z - 0.4, 0.0, 0.0, 25.0, true)
	print("P3 net+body(2nd serve, let no cancela falta) -> %s sf=%d" % [str(_resolve(sim)), sim.serve_fault])

func _p4() -> void :
	print("== P4b RECOVERY (fixed) ==")
	for who in ["human", "cpu"]:
		for st in ["neutral", "stretch1.4", "serve_ret_fast"]:
			var sim: = _mk()
			sim.state = "play"
			var e
			if who == "human":
				e = sim.pl[0];e.x = 0.0;e.z = 2.0
				sim.ball.z = 2.7;sim.ball.vz = -8.0
			else:
				e = sim.pl[1];e.x = 0.0;e.z = sim.L - 2.0
				sim.ball.z = sim.L - 2.7;sim.ball.vz = 8.0
			var bx: float = 0.2
			var in_vz: float = 8.0
			if st == "stretch1.4":
				bx = 1.9;sim.ball.z += (0.7 if who == "human" else - 0.7)
			if st == "serve_ret_fast":
				in_vz = 20.0
				sim.serve_unreturned = true
				sim.M.server = 1 - e.id
				sim.ball.vz = (-20.0 if who == "human" else 20.0)
				sim.ball.serving = true
			sim.ball.x = bx
			sim.ball.y = 1.1
			sim.ball.vx = 0.0
			sim.ball.vy = -1.0
			sim.ball.last = 1 - e.id
			sim.ball.in_play = true
			sim.ball.bounces = 1
			sim.do_hit(e, "drive", who == "cpu")
			var rec0: float = -1.0
			var dt: = 1.0 / 60.0
			var t: float = 0.0
			var min_rf: float = 1.0
			var guard: = 0
			while guard < 300:
				sim.update_player(e, dt)
				t += dt
				if rec0 < 0.0 and e.recov > 0.0:
					rec0 = e.recov
				if e.recov > 0.0:
					var rf: float = clampf(1.0 - e.recov / 0.26, 0.7 if who == "human" else 0.4, 1.0)
					min_rf = minf(min_rf, rf)
				elif rec0 >= 0.0:
					break
				guard += 1
			print("P4 %-5s %-14s recov0=%.2fs impaired_until=%.2fs (swing+recov) min_rf=%.2f" % [who, st, rec0, t, min_rf])

func _p5() -> void :
	print("== P5b CHARGE HOLD E2E (tracking player) ==")
	var dt: = 1.0 / 60.0
	for hold_mode in ["tap+instant-release", "hold-auto"]:
		var rows: Array = []
		for trial in 12:
			var sim: = _mk()
			sim.state = "play"
			var p = sim.pl[0]
			p.x = 0.0;p.z = 2.0
			var c = sim.pl[1]
			c.x = 0.0;c.z = sim.L - 2.0
			sim.ball.x = 0.2;sim.ball.y = 1.1;sim.ball.z = sim.L - 2.7
			sim.ball.vx = 0.0;sim.ball.vy = -1.0;sim.ball.vz = -8.0
			sim.ball.last = 1;sim.ball.in_play = true;sim.ball.bounces = 1
			sim.ball.held = false
			sim.do_hit(c, "drive", true)
			var feed_kmh: float = 0.0
			for ev in sim.events:
				if ev.get("t") == "hit":
					feed_kmh = ev.get("spd", 0.0) * 4.0
			sim.events.clear()
			var pressed: = false
			var released: = false
			var press_t: float = -1.0
			var t: float = 0.0
			var guard: = 0
			while guard < 900:
				t += dt
				# track predicted landing
				if sim.ball.in_play and sim.ball.last != 0 and sim.ball.vz < 0:
					var pr: Vector3 = sim.predict(p)
					sim.inp.x = clampf((pr.x - p.x) * 0.8, -1.0, 1.0)
					sim.inp.y = clampf((pr.z - p.z) * 0.4, -1.0, 1.0)
				else:
					sim.inp.x = 0.0;sim.inp.y = 0.0
				if not pressed and sim.ball.z < sim.NZ:
					sim.inp.hit = true
					pressed = true
					press_t = t
				if hold_mode == "tap+instant-release" and pressed and not released and t > press_t + 0.05:
					sim.inp.hit_rel = true
					released = true
				sim.update(dt)
				for ev in sim.events:
					if ev.get("t") == "hit" and ev.get("id", -1) == 0:
						rows.append([feed_kmh, ev.get("spd", 0.0) * 4.0, ev.get("kind", "?"), ev.get("tq", "?"), snappedf(ev.get("charge", 1.0), 0.01), snappedf(t - press_t, 0.01)])
					if ev.get("t") == "charge_fire":
						pass
				sim.events.clear()
				if sim.state != "play" or sim.ball.last == 0:
					break
				guard += 1
		var s: float = 0.0
		var ks: = {}
		for row in rows:
			s += row[1]
			ks[str(row[2]) + "/" + str(row[3])] = int(ks.get(str(row[2]) + "/" + str(row[3]), 0)) + 1
		print("P5 %-20s n=%d player_kmh_avg=%.1f (feed_avg n/a) kinds/tq=%s" % [hold_mode, rows.size(), s / maxf(1.0, rows.size()), str(ks)])
		for row in rows.slice(0, 4):
			print("    feed=%.0f out=%.0f kind=%s tq=%s charge=%s hold=%.2fs" % [row[0], row[1], row[2], row[3], row[4], row[5]])

func _p6() -> void :
	print("== P6 CPU SHOT DISTRIBUTION (full rally, bot player) ==")
	var dt: = 1.0 / 60.0
	var cpu_kmh: = {}
	var pl_kmh: = {}
	var n_sim: = 3
	for m in n_sim:
		var sim: = TennisSim.new(true, AIPD, PSD, "CPU", 1)
		var guard: = 0
		while not sim.match_over and guard < 60 * 60 * 20:
			sim.update(dt)
			guard += 1
			for ev in sim.events:
				if ev.get("t") == "hit":
					var k: = str(ev.get("kind", "?"))
					var v: float = ev.get("spd", 0.0) * 4.0
					var tab: = cpu_kmh if ev.get("id", 0) == 1 else pl_kmh
					if not tab.has(k):
						tab[k] = [0.0, 0.0, 0.0]
					tab[k][0] += 1.0
					tab[k][1] += v
					tab[k][2] = maxf(tab[k][2], v)
			sim.events.clear()
	for label in ["pl_kmh(demo bot)", "cpu_kmh"]:
		var tab: = pl_kmh if label.begins_with("pl") else cpu_kmh
		for k in tab.keys():
			var a: Array = tab[k]
			print("P6 %-16s %-7s n=%3d avg=%6.1f max=%6.1f" % [label, k, int(a[0]), a[1] / a[0], a[2]])

func _initialize() -> void :
	seed(20261028)
	_p1()
	_p3()
	_p4()
	_p5()
	_p6()
	print("QA PROBE2 done")
	quit(0)
