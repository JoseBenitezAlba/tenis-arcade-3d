extends SceneTree


const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _mk():
	var s = SimClass.new(false, HP, CP, "CPU", 1)
	s.start_point()
	return s
func _tap(charge: float) -> String:
	var s = _mk()
	s.state = "play"
	s.serve_stage = "rally"
	var e = s.pl[0]
	e.x = 0.0;e.z = -1.0
	s.ball.in_play = true
	s.ball.held = false;s.ball.toss = false
	s.ball.last = 1
	s.ball.x = 0.0;s.ball.y = 1.0;s.ball.z = 0.2
	s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = -18.0
	e.charging = true
	e.charge = charge
	s.inp.hit_rel = true
	s.human_control(e, 1.0 / 60.0)
	return e.kind
func _init() -> void :
	var fail: = 0
	for srv in [0, 1]:
		for pts in [0, 1]:
			var s = _mk()
			s.M.server = srv
			s.M.pts = [pts, 0]
			s.prep_serve()
			s.state = "serve"
			var e = s.pl[srv]
			var side: float = signf(e.x)
			for i in 240:
				e.tvx = - side * 6.0
				s.update_player(e, 1.0 / 60.0)
			if signf(e.x) != side: print("FAIL: cruza la marca central srv=", srv, " x=", e.x);fail += 1
			for i in 240:
				e.tvx = side * 6.0
				s.update_player(e, 1.0 / 60.0)
			if absf(e.x) > 4.11 or signf(e.x) != side: print("FAIL: borde x=", e.x);fail += 1
	var k1: = _tap(0.05)
	if k1 == "lob": print("FAIL: toque rapido es globo");fail += 1
	var k2: = _tap(0.9)
	print("toque: ", k1, " carga larga con bola encima: ", k2)
	print("gate134 ", "PASS" if fail == 0 else "FAIL")
	quit()
