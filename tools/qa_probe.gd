extends SceneTree

const AIPD: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}
const PSD: = {"speed": 6.2, "T": 1.0, "err": 1.0}

func kmh(spd: float) -> float:
	return spd * 4.0

func _mk(demo: bool = false) -> TennisSim:
	return TennisSim.new(demo, AIPD, PSD, "CPU", 1)

# Stage a ball + player and fire do_hit directly, return the hit event.
func _stage_hit(swing_preset: float, charge_pow: float, ball_y: float, ball_vy: float, up: bool, ai: bool, n: int) -> Dictionary:
	var sum_kmh: = 0.0
	var kinds: = {}
	var tqs: = {}
	var perf: = 0
	for i in n:
		var sim: = _mk()
		sim.state = "play"
		var e
		if ai:
			e = sim.pl[1]
			e.x = 0.0
			e.z = sim.L - 2.0
			sim.ball.x = 0.2
			sim.ball.z = sim.L - 2.7
			sim.ball.vz = 8.0
		else:
			e = sim.pl[0]
			e.x = 0.0
			e.z = 2.0
			sim.ball.x = 0.2
			sim.ball.z = 2.7
			sim.ball.vz = -8.0
		sim.ball.y = ball_y
		sim.ball.vx = 0.0
		sim.ball.vy = ball_vy
		sim.ball.last = 1 - e.id
		sim.ball.in_play = true
		sim.ball.bounces = 1
		e.swing = swing_preset
		e.charge_pow = charge_pow
		sim.inp.x = 0.0
		sim.inp.y = 0.6 if up else 0.0
		sim.do_hit(e, "drive", ai)
		for ev in sim.events:
			if ev.get("t") == "hit":
				sum_kmh += kmh(ev.get("spd", 0.0))
				kinds[ev.get("kind", "?")] = int(kinds.get(ev.get("kind", "?"), 0)) + 1
				tqs[ev.get("tq", "?")] = int(tqs.get(ev.get("tq", "?"), 0)) + 1
				if ev.get("perfect", false):
					perf += 1
		sim.events.clear()
	return {"kmh": sum_kmh / n, "kinds": kinds, "tqs": tqs, "perf": perf, "n": n}

func _p1() -> void :
	print("== P1 DRIVE TIMING (planted player, feed vz=-8 y=1.1 vy=-1) ==")
	var cases: Array = [
		["timed (swing just armed)", 0.3, 1.0, 1.1, -1.0, false],
		["early press (armed 0.25s)", 0.05, 1.0, 1.1, -1.0, false],
		["early + low/late ball", 0.05, 1.0, 0.5, -2.0, false],
		["timed + low/late ball", 0.3, 1.0, 0.5, -2.0, false],
		["charge full (hold 0.85s)", 0.3, 1.6, 1.1, -1.0, false],
		["timed UP (flat deep)", 0.3, 1.0, 1.1, -1.0, true],
		["early UP (flat deep)", 0.05, 1.0, 1.1, -1.0, true],
	]
	for c in cases:
		var r: Dictionary = _stage_hit(c[1], c[2], c[3], c[4], c[5], false, 20)
		print("P1 %-26s kmh=%6.1f kinds=%s tq=%s perf=%d/20" % [c[0], r.kmh, str(r.kinds), str(r.tqs), r.perf])
	print("== P1b CPU SAME FEED (mirror) ==")
	var rc: Dictionary = _stage_hit(0.3, 1.0, 1.1, -1.0, false, true, 20)
	print("P1b CPU drive same feed        kmh=%6.1f kinds=%s" % [rc.kmh, str(rc.kinds)])
	# smash comparability on high ball
	var rs_h: Dictionary = _stage_hit(0.3, 1.0, 2.5, 0.5, false, false, 20)
	var rs_c: Dictionary = _stage_hit(0.3, 1.0, 2.5, 0.5, false, true, 20)
	print("P1b player high ball y=2.5     kmh=%6.1f kinds=%s" % [rs_h.kmh, str(rs_h.kinds)])
	print("P1b CPU    high ball y=2.5     kmh=%6.1f kinds=%s" % [rs_c.kmh, str(rs_c.kinds)])

func _p2() -> void :
	print("== P2 SERVE INPUT FLOW ==")
	# (a) one press only
	var sim: = _mk()
	var dt: = 1.0 / 60.0
	var pressed: = false
	var fired_toss_t: = -1.0
	var guard: = 0
	while sim.state == "serve" and guard < 600:
		if sim.serve_stage == "ready" and not pressed:
			sim.inp.hit = true
			pressed = true
		sim.update(dt)
		var retosses: = 0
		for ev in sim.events:
			if ev.get("t") == "serve":
				fired_toss_t = sim.ball.toss_t
				print("P2a ONE PRESS: auto serve fired q=%.2f (BUG if seen)" % ev.get("q", -1.0))
			elif ev.get("t") == "retoss":
				retosses += 1
		if retosses > 0 and guard % 120 == 0:
			print("P2a ONE PRESS: retoss x%d, no auto-fire (correct), stage=%s" % [retosses, sim.serve_stage])
		sim.events.clear()
		guard += 1
	# (b) timed second press at toss apex
	for tgt in [0.3, 0.5, 0.7]:
		var s2: = _mk()
		var p2: = false
		var g2: = 0
		var done: = false
		while s2.state == "serve" and g2 < 600 and not done:
			if s2.serve_stage == "ready" and not p2:
				s2.inp.hit = true
				p2 = true
			elif s2.serve_stage == "toss" and s2.ball.toss_t >= tgt:
				s2.inp.hit = true
			s2.update(dt)
			for ev in s2.events:
				if ev.get("t") == "serve":
					print("P2b press@%.2f: serve q=%.3f kmh=%.1f" % [tgt, ev.get("q", -1.0), ev.get("spd", 0.0) * 8.4])
					done = true
			s2.events.clear()
			g2 += 1

func _serve_resolve(setup: String) -> Array:
	# Stage serve ball flight directly and resolve via update loop. Returns events seen.
	var sim: = _mk()
	sim.state = "serve"
	sim.serve_stage = "hit"
	sim.serve_unreturned = true
	sim.serve_fault = 0
	var b = sim.ball
	b.held = false
	b.toss = false
	b.in_play = true
	b.serving = true
	b.last = 0
	b.bounces = 0
	b.spin = 0.6
	match setup:
		"net":
			b.x = 0.5;b.y = 0.8;b.z = 4.0;b.vx = 0.0;b.vy = 0.5;b.vz = 18.0
		"long":
			b.x = 1.0;b.y = 2.2;b.z = 3.0;b.vx = 0.0;b.vy = 3.0;b.vz = 22.0
		"wide":
			b.x = 3.0;b.y = 2.2;b.z = 3.0;b.vx = 5.0;b.vy = 3.0;b.vz = 20.0
		"good":
			b.x = -2.0;b.y = 2.0;b.z = 3.0;b.vx = 0.0;b.vy = 1.0;b.vz = 16.0
		"let":
			b.x = -2.0;b.y = 2.0;b.z = 3.0;b.vx = 0.0;b.vy = 1.0;b.vz = 16.0
			b.serve_net = true
		"body":
			# ball arriving at the receiver's torso before bouncing
			var rp = sim.pl[1]
			b.x = rp.x + 0.1;b.y = 1.2;b.z = rp.z - 0.4;b.vx = 0.0;b.vy = 0.0;b.vz = 25.0
	var seen: Array = []
	var dt: = 1.0 / 60.0
	var guard: = 0
	while guard < 600:
		sim.update(dt)
		for ev in sim.events:
			var t: String = ev.get("t", "")
			if t in ["fault", "let", "point", "bounce", "net", "netcord", "body"]:
				seen.append(t + (":" + str(ev.get("why", ev.get("txt", ""))) if t in ["fault", "point"] else ""))
		sim.events.clear()
		if sim.state != "serve" or seen.size() > 0 and (seen[-1] as String).begins_with("point"):
			break
		if setup == "good" and sim.state == "play":
			break
		guard += 1
	return [sim.state, sim.serve_fault, seen]

func _p3() -> void :
	print("== P3 SERVE RULES MATRIX ==")
	for setup in ["good", "net", "long", "wide", "let", "body"]:
		var r: Array = _serve_resolve(setup)
		print("P3 %-5s -> state=%s serve_fault=%d events=%s" % [setup, r[0], r[1], str(r[2])])
	# double fault: two consecutive outs
	var sim: = _mk()
	var dt: = 1.0 / 60.0
	sim.state = "serve"
	sim.serve_stage = "hit"
	sim.serve_unreturned = true
	for attempt in 2:
		var b = sim.ball
		b.held = false;b.toss = false;b.in_play = true;b.serving = true;b.last = 0;b.bounces = 0;b.spin = 0.6
		b.x = 1.0;b.y = 2.2;b.z = 3.0;b.vx = 0.0;b.vy = 3.0;b.vz = 22.0
		sim.state = "serve"
		var g: = 0
		while sim.state == "serve" and g < 600:
			sim.update(dt)
			g += 1
			for ev in sim.events:
				var t: String = ev.get("t", "")
				if t == "fault":
					print("P3 DF attempt %d -> FAULT why=%s" % [attempt + 1, ev.get("why", "")])
				elif t == "point":
					print("P3 DF attempt %d -> POINT txt=%s w=%s" % [attempt + 1, ev.get("txt", ""), str(ev.get("w", -1))])
			sim.events.clear()
		if sim.state == "point":
			break

func _p4() -> void :
	print("== P4 RECOVERY ==")
	for who in ["human", "cpu"]:
		var sim: = _mk()
		sim.state = "play"
		var e
		if who == "human":
			e = sim.pl[0];e.x = 0.0;e.z = 2.0
			sim.ball.x = 1.9;sim.ball.z = 3.3;sim.ball.vz = -8.0
		else:
			e = sim.pl[1];e.x = 0.0;e.z = sim.L - 2.0
			sim.ball.x = 1.9;sim.ball.z = sim.L - 3.3;sim.ball.vz = 8.0
		sim.ball.y = 1.0
		sim.ball.vx = 0.0;sim.ball.vy = -0.5
		sim.ball.last = 1 - e.id;sim.ball.in_play = true;sim.ball.bounces = 1
		sim.do_hit(e, "drive", who == "cpu")
		sim.events.clear()
		var dt: = 1.0 / 60.0
		var t_full: = -1.0
		var min_rf: = 1.0
		var guard: = 0
		while guard < 240:
			sim.update_player(e, dt)
			# emulate recov multiplier formula to report
			if e.recov > 0.0:
				var rf: float = clampf(1.0 - e.recov / 0.26, 0.7 if (who == "human") else 0.4, 1.0)
				min_rf = minf(min_rf, rf)
			elif t_full < 0.0 and guard > 1:
				t_full = guard * dt
				break
			guard += 1
		print("P4 %-5s stretch-hit: recov control back at t=%.2fs min_speed_factor=%.2f (swing 0.34s incl.)" % [who, t_full, min_rf])
	# dive + getup
	var s3: = _mk()
	var e3 = s3.pl[0]
	s3.state = "play"
	e3.dive_t = 0.55
	var dt3: = 1.0 / 60.0
	var g3: = 0
	var full_t: = -1.0
	while g3 < 240:
		s3.update_player(e3, dt3)
		if e3.dive_t <= 0.0 and e3.getup_t <= 0.0:
			full_t = (g3 + 1) * dt3
			break
		g3 += 1
	print("P4 dive->getup full control at t=%.2fs (hit blocked during getup)" % full_t)

func _p5() -> void :
	print("== P5 CHARGE HOLD END-TO-END (CPU feeds drive, player holds A) ==")
	var dt: = 1.0 / 60.0
	for hold_mode in ["tap-once", "hold"]:
		var speeds: Array = []
		for trial in 10:
			var sim: = _mk()
			sim.state = "play"
			var p = sim.pl[0]
			p.x = 0.0;p.z = 2.0
			var c = sim.pl[1]
			c.x = 0.0;c.z = sim.L - 2.0
			# CPU hits a neutral drive toward the player
			sim.ball.x = 0.2;sim.ball.y = 1.1;sim.ball.z = sim.L - 2.7
			sim.ball.vx = 0.0;sim.ball.vy = -1.0;sim.ball.vz = -8.0
			sim.ball.last = 1;sim.ball.in_play = true;sim.ball.bounces = 1
			sim.do_hit(c, "drive", true)
			var feed_kmh: = 0.0
			for ev in sim.events:
				if ev.get("t") == "hit":
					feed_kmh = ev.get("spd", 0.0) * 4.0
			sim.events.clear()
			# player: press A as the ball crosses the net, hold (edge-only input model)
			var pressed: = false
			var released: = false
			var guard: = 0
			while guard < 600:
				if not pressed and sim.ball.z < sim.NZ:
					sim.inp.hit = true
					pressed = true
				if hold_mode == "tap-once" and pressed and not released:
					sim.inp.hit_rel = true
					released = true
				sim.update(dt)
				for ev in sim.events:
					if ev.get("t") == "hit" and ev.get("id", -1) == 0:
						speeds.append([feed_kmh, ev.get("spd", 0.0) * 4.0, ev.get("kind", "?"), ev.get("tq", "?"), ev.get("charge", 1.0)])
				sim.events.clear()
				if sim.state != "play" or sim.ball.last == 0:
					break
				guard += 1
		var s: = 0.0
		var ks: = {}
		for row in speeds:
			s += row[1]
			ks[row[2] + "/" + row[3]] = int(ks.get(row[2] + "/" + row[3], 0)) + 1
		print("P5 %-9s n=%d player_kmh_avg=%.1f kinds/tq=%s sample=%s" % [hold_mode, speeds.size(), s / maxf(1.0, speeds.size()), str(ks), str(speeds.slice(0, 3))])

func _initialize() -> void :
	seed(20261028)
	_p1()
	_p2()
	_p3()
	_p4()
	_p5()
	print("QA PROBE done")
	quit(0)
