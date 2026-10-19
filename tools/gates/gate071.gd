extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
func _mk(risk: float) -> RefCounted:
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": risk, "react": 0.2}
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.ball.in_play = true;s.ball.serving = false
	s.ball.held = false;s.ball.toss = false
	s.serve_unreturned = false
	return s
func _feed(s, opp_net: bool) -> String:

	s.ball.x = 0.0;s.ball.y = 1.3;s.ball.z = 16.5
	s.ball.vx = 0.0;s.ball.vy = 1.5;s.ball.vz = 7.0
	s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
	s.pl[1].x = 0.0;s.pl[1].z = 18.5
	if opp_net:
		s.pl[0].x = 0.5;s.pl[0].z = 6.0
	else:
		s.pl[0].x = 3.2;s.pl[0].z = 0.0
	var dt = 1.0 / 60.0
	for f in range(60 * 4):
		s.update(dt)
		for ev in s.events:
			if ev.get("t") == "hit" and ev.get("id") == 1:
				return ev.get("kind", "?")
		s.events.clear()
	return "nohit"
func _run(opp_net: bool, risk: float, n: int) -> Dictionary:
	var kinds: = {}
	for i in range(n):
		var s = _mk(risk)
		var k: = _feed(s, opp_net)
		kinds[k] = kinds.get(k, 0) + 1
	return kinds
func _init():
	seed(71071)
	var ok: = true
	var a: = _run(true, 0.5, 200)
	print("A rival-subiendo: ", a)
	var ad: int = a.get("drop", 0)
	if ad < 8 or ad > 60:
		print("FAIL A: dejadas al que sube fuera de banda: ", ad, "/200");ok = false
	var b_hi: = _run(false, 0.9, 200)
	var b_lo: = _run(false, 0.1, 200)
	print("B agresiva: ", b_hi)
	print("B conservadora: ", b_lo)
	if b_hi.get("drop", 0) <= b_lo.get("drop", 0):
		print("FAIL B: la agresiva no deja mas que la conservadora");ok = false
	if b_lo.get("drop", 0) < 5:
		print("FAIL B: la conservadora no deja nada: ", b_lo.get("drop", 0));ok = false
	print("GATE071 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
