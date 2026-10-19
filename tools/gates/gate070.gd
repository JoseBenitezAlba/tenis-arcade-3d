extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _measure(swing_left: float, n: int) -> Dictionary:
	var spds: = 0.0
	var tags: = {}
	for i in range(n):
		var s = SimClass.new(false, CP, HP, "CPU", 1)
		s.state = "play"
		s.ball.in_play = true;s.ball.serving = false
		s.ball.held = false;s.ball.toss = false
		s.serve_unreturned = false
		s.pl[0].x = 0.0;s.pl[0].z = 0.5;s.pl[0].speed = 0.0
		s.pl[0].swing = swing_left
		s.ball.x = 0.0;s.ball.y = 1.1;s.ball.z = 1.5
		s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = -6.0
		s.ball.last = 1;s.ball.bounces = 1
		s.inp.x = 0.0;s.inp.y = 0.0
		s.do_hit(s.pl[0], "drive", false)
		spds += Vector3(s.ball.vx, s.ball.vy, s.ball.vz).length()
		for ev in s.events:
			if ev.get("t") == "hit":
				var k: String = ev.get("tq", "ok")
				tags[k] = tags.get(k, 0) + 1
	return {"spd": spds / n, "tags": tags}
func _init():
	seed(70070)
	var justo: = _measure(0.28, 60)
	var pronto: = _measure(0.05, 60)
	print("justo: spd=", snappedf(justo.spd, 0.01), " tags=", justo.tags)
	print("pronto: spd=", snappedf(pronto.spd, 0.01), " tags=", pronto.tags)
	var ok: = true
	if justo.spd < pronto.spd * 1.08:
		print("FAIL: el timing justo no pega ", int((justo.spd / pronto.spd - 1.0) * 100), "% mas (min 8%)");ok = false
	if justo.tags.get("perfect+", 0) < 45:
		print("FAIL: perfect+ raro en el punto dulce: ", justo.tags.get("perfect+", 0), "/60");ok = false
	if pronto.tags.get("early", 0) < 45:
		print("FAIL: soltar pronto no se nota: ", pronto.tags.get("early", 0), "/60");ok = false
	print("GATE070 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
