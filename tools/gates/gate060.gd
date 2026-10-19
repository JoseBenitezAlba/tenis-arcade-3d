extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _mk(demo: bool = false) -> Object:
	return SimClass.new(demo, HP, CP, "CPU", 1)
func _feed(s, px, pz, by, bvz, bounces: = 1) -> void :
	s.state = "play";s.ball.in_play = true;s.ball.serving = false
	s.serve_unreturned = false
	s.pl[0].x = px;s.pl[0].z = pz
	s.ball.x = px;s.ball.y = by;s.ball.z = pz + 1.0
	s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = bvz
	s.ball.last = 1;s.ball.bounces = bounces
func _init():
	var ok: = true

	var s = _mk()
	_feed(s, 0.0, 0.5, 1.2, -6.0)
	s.do_hit(s.pl[0], "toplob", false)
	print("C1 toplob vy=", snappedf(s.ball.vy, 0.1), " vz=", snappedf(s.ball.vz, 0.1), " spin=", s.ball.spin)
	if s.ball.spin < 1.0: ok = false;print("FAIL toplob sin spin")
	var s1 = _mk()
	_feed(s1, 0.0, 0.5, 1.2, -6.0)
	s1.do_hit(s1.pl[0], "lob", false)
	print("C1 globo  vy=", snappedf(s1.ball.vy, 0.1), " vz=", snappedf(s1.ball.vz, 0.1), " spin=", s1.ball.spin)
	if s.ball.vy > s1.ball.vy * 0.85: ok = false;print("FAIL toplob no es mas plano")
	if absf(s.ball.vz) < absf(s1.ball.vz) * 1.05: ok = false;print("FAIL toplob no corre mas")

	var s2 = _mk()
	_feed(s2, 0.0, 0.5, 2.5, -4.0, 1)
	s2.do_hit(s2.pl[0], "toplob", false)
	print("C2 bola alta kind=", s2.ball.kind)
	if s2.ball.kind == "smash": ok = false;print("FAIL toplob->smash")

	var s3 = _mk()
	_feed(s3, 1.0, 9.9, 1.4, -8.0, 0)
	s3.do_hit(s3.pl[0], "toplob", false)
	print("C3 red sin bote kind=", s3.ball.kind)
	if s3.ball.kind == "volley": ok = false;print("FAIL toplob->volley")

	var dt = 1.0 / 60.0
	var toplobs: = 0
	for run in range(6):
		var s4 = _mk(true)
		var t: = 0.0
		while t < 360.0:
			s4.update(dt);t += dt
			for ev in s4.events:
				if ev.get("t") == "hit" and ev.get("kind") == "toplob":
					toplobs += 1
			s4.events.clear()
	print("C4 toplobs CPU en 2x6min demo=", toplobs)
	if toplobs < 1: ok = false;print("FAIL CPU no usa toplob")
	print("GATE060 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
