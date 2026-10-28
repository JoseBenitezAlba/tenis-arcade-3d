extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const DIFFS: = [
	{"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3, "risk": 0.35}, 
	{"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, 
	{"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06, "risk": 0.7}, 
]
func drain(s) -> Array:
	var e: Array = s.events.duplicate()
	s.events.clear()
	return e
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var mn: = FileAccess.get_file_as_string("res://scripts/menus.gd")
	if not sm.contains("_in_hit_win"): print("FAIL: helper ventana");fail += 1
	if not sm.contains("golpeo automatico al mantener pulsado"): print("FAIL: auto-fire");fail += 1
	if not sm.contains("el segundo saque recoloca"): print("FAIL: recolocar 2o saque");fail += 1
	if not sm.contains("el saque sale solo en el apice"): print("FAIL: saque auto");fail += 1
	if not mv.contains("_srv_bounce"): print("FAIL: posicion ACE");fail += 1
	if not mn.contains("mantén para cargar"): print("FAIL: texto controles");fail += 1
	var dt: = 1.0 / 60.0

	seed(42)
	var hits: = 0
	for trial in 24:
		var s = SimClass.new(false, DIFFS[1], {}, "CPU", 1)
		s.M.server = 1;s.prep_serve();s.cpu_serve_at = 0.05
		var phase: = 0
		var pressed: = false
		var t: = 0.0
		var done: = false
		while t < 6.0 and not done:
			if phase == 1 and not pressed:
				s.inp.hit = true;pressed = true
			s.update(dt);t += dt
			for e in drain(s):
				if e.get("t") == "serve": phase = 1
				if e.get("t") == "hit" and e.get("id") == 0: hits += 1;done = true
				if e.get("t") == "point" or e.get("t") == "fault": done = true
	if hits < 8: print("FAIL: resto con carga mantenida hits=", hits, "/24");fail += 1

	var s2 = SimClass.new(false, DIFFS[1], {}, "CPU", 1)
	s2.state = "play";s2.serve_stage = "rally";s2.serve_unreturned = false
	s2.ball.in_play = true;s2.ball.serving = false;s2.ball.held = false;s2.ball.toss = false
	s2.ball.last = 1;s2.ball.bounces = 1;s2.ball.spin = 0.6
	s2.pl[0].x = 0.0;s2.pl[0].z = -0.6
	s2.ball.x = 0.0;s2.ball.z = 0.6;s2.ball.vz = -6.0;s2.ball.y = 2.0;s2.ball.vy = -1.0;s2.ball.vx = 0.0
	s2.inp.hit = true
	var ok2: = false
	for i in 90:
		s2.update(dt)
		for e in drain(s2):
			if e.get("t") == "hit" and e.get("id") == 0: ok2 = true
		if ok2 or s2.state != "play": break
	if not ok2: print("FAIL: bola a y=2.0 sigue sin poder golpearse");fail += 1

	var s3 = SimClass.new(false, DIFFS[1], {}, "CPU", 1)
	s3.M.server = 0;s3.prep_serve()
	var served: = false
	var q3: = 0.0
	s3.inp.hit = true
	s3.update(dt);drain(s3)
	s3.inp.hit_rel = true
	for i in 240:
		s3.update(dt)
		for e in drain(s3):
			if e.get("t") == "serve" and e.get("id") == 0: served = true;q3 = e.q
		if served: break
	if not served: print("FAIL: saque con un solo toque no sale");fail += 1
	elif absf(q3 - 0.88) > 0.01: print("FAIL: calidad auto q=", q3);fail += 1

	var s4 = SimClass.new(false, DIFFS[1], {}, "CPU", 1)
	s4.M.server = 1;s4.prep_serve()
	s4.pl[0].x = 4.6;s4.pl[0].z = 0.5
	s4.fault("Fuera del cuadro")
	if absf(s4.pl[0].x) > 1.6: print("FAIL: restador sin recolocar x=", s4.pl[0].x);fail += 1
	if s4.serve_fault != 1: print("FAIL: serve_fault tras falta=", s4.serve_fault);fail += 1

	var s5 = SimClass.new(false, DIFFS[1], {}, "CPU", 1)
	s5.state = "play";s5.serve_stage = "rally";s5.serve_unreturned = false
	s5.ball.in_play = true;s5.ball.serving = false;s5.ball.held = false;s5.ball.toss = false
	s5.ball.last = 1;s5.ball.bounces = 0;s5.ball.spin = 0.6
	s5.pl[0].x = 0.0;s5.pl[0].z = 6.0
	s5.ball.x = 0.0;s5.ball.z = 12.0;s5.ball.vz = -12.0;s5.ball.y = 1.4;s5.ball.vx = 0.0
	s5.ball.vy = (1.2 - 1.4) / 0.55 + 0.5 * 25.4 * 0.55
	var kind5: = ""
	var pressed5: = false
	var t5: = 0.0
	while t5 < 3.0:
		var b5 = s5.ball
		if not pressed5 and b5.vz < 0.0 and absf(b5.z - s5.pl[0].z) < 1.1:
			s5.inp.y = -1.0
			s5.pl[0].vx = 5.0;s5.pl[0].speed = 5.0
			s5.inp.hit = true;pressed5 = true
		elif pressed5:
			s5.inp.hit_rel = true
		s5.update(dt);t5 += dt
		for e in drain(s5):
			if e.get("t") == "hit" and e.get("id") == 0: kind5 = str(e.get("kind"))
		if kind5 != "" or s5.state != "play": break
	if kind5 == "drop": print("FAIL: en movimiento aun sale dejada");fail += 1
	if kind5 == "": print("FAIL: en movimiento no hubo golpe");fail += 1
	if fail == 0: print("PASS")
	else: print("FAIL ", fail)
	quit(1 if fail > 0 else 0)
