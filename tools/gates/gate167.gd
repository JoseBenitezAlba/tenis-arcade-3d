extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	if not sm.contains("rec.x = -1.5 * sgn if near else 1.5 * sgn"): print("FAIL: prep x");fail += 1
	if not sm.contains("clampf(e.x, -4.0, 4.0)"): print("FAIL: clamp restador");fail += 1
	if not sm.contains("if e.x > 4.7:"): print("FAIL: freno entre puntos");fail += 1
	if not sm.contains("h_behind"): print("FAIL: tardio");fail += 1
	if not mv.contains("_pb_active"): print("FAIL: bola visual");fail += 1

	var s = SimClass.new(false, {"speed": 7.0, "T": 1.0, "err": 1.0}, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, "CPU", 1)
	s.M.server = 1
	s.prep_serve()
	if absf(s.pl[0].x) != 1.5: print("FAIL: spawn restador x=", s.pl[0].x);fail += 1
	s.pl[0].x = 3.4;s.pl[0].z = -0.6
	s.inp.x = 1.0
	var dt: = 1.0 / 60.0
	for i in 60:
		s.update(dt);s.events.clear()
	if s.pl[0].x > 4.01: print("FAIL: restador en pasillo x=", s.pl[0].x);fail += 1

	s.state = "point";s.state_t = 0.0
	for i in 90:
		s.update(dt);s.events.clear()
	if absf(s.pl[0].x) > 5.18: print("FAIL: fuga lateral x=", s.pl[0].x);fail += 1
	if s.pl[0].z > TennisSim.NZ - 4.1: print("FAIL: fuga a la red z=", s.pl[0].z);fail += 1

	var s2 = SimClass.new(false, {"speed": 7.0, "T": 1.0, "err": 1.0}, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, "CPU", 1)
	s2.state = "play"
	s2.ball.in_play = true;s2.ball.serving = false;s2.ball.held = false;s2.ball.toss = false
	s2.ball.last = 1;s2.ball.bounces = 1
	s2.pl[0].x = 0.0;s2.pl[0].z = 1.0
	s2.ball.x = 0.0;s2.ball.y = 1.0;s2.ball.z = 0.0
	s2.ball.vx = 0.0;s2.ball.vy = 0.0;s2.ball.vz = -8.0
	s2.inp.hit = true
	var hit_id0: int = s2.ball.hit_id
	for i in 30:
		s2.update(dt);s2.events.clear()
	if s2.ball.hit_id != hit_id0: print("FAIL: bola pasada golpeada");fail += 1
	print("gate167 ", "PASS" if fail == 0 else "FAIL")
	quit()
