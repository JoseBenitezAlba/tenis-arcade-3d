extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _mk() -> Object:
	return SimClass.new(false, HP, CP, "CPU", 1)


func _dist_after_hit(sep: float) -> float:
	var s = _mk()
	s.state = "play";s.ball.in_play = true;s.ball.serving = false
	s.serve_unreturned = false
	s.pl[0].x = 0.0;s.pl[0].z = 0.5
	s.ball.x = sep;s.ball.y = 1.1;s.ball.z = 1.5
	s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = -6.0
	s.ball.last = 1;s.ball.bounces = 1
	s.inp.x = 0.0;s.inp.y = 0.0
	s.do_hit(s.pl[0], "drive", false)
	var x0: float = s.pl[0].x
	var t: = 0.0; var dt = 1.0 / 60.0
	s.inp.x = 1.0
	while t < 0.7:

		s.pl[0].tvx = 6.1 * s.pl[0].run if "run" in s.pl[0] else 6.1
		s.update(dt);t += dt
		s.inp.x = 1.0
	return s.pl[0].x - x0
func _init():
	randomize()
	var ok: = true
	var dc: = 0.0; var ds: = 0.0
	for i in range(20):
		dc += _dist_after_hit(0.3)
		ds += _dist_after_hit(2.4)
	dc /= 20.0;ds /= 20.0
	print("C1 dist_comodo=", snappedf(dc, 0.01), " dist_estirado=", snappedf(ds, 0.01))
	if ds > dc * 0.85: ok = false;print("FAIL estirada no cuesta posicion")
	if dc < 1.2: ok = false;print("FAIL comodo demasiado lento")
	print("GATE064 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
