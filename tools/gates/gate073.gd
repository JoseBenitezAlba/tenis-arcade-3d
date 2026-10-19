extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
func _mk() -> RefCounted:
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5, "react": 0.2}
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.ball.in_play = true;s.ball.serving = false
	s.ball.held = false;s.ball.toss = false
	s.serve_unreturned = false
	return s
func _init():
	seed(73073)
	var ok: = true

	for plan in ["pina", "abierto"]:
		var s = _mk()
		s.pl[1].plan = plan;s.pl[1].plan_left = 3;s.pl[1].plan_side = 1.0
		var signs: = []
		for h in range(3):
			s.ball.x = 0.0;s.ball.y = 1.1;s.ball.z = 18.0
			s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = 5.0
			s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
			s.pl[1].x = 0.0;s.pl[1].z = 19.0;s.pl[1].swing = 0.0
			s.pl[1].speed = 0.0
			s.do_hit(s.pl[1], "drive", true)
			signs.append(signf(s.ball.vx))
			s.ball.in_play = true
		print(plan, " signos vx=", signs)
		if plan == "pina":
			if not (signs[0] == 1.0 and signs[1] == 1.0 and signs[2] == 1.0):
				print("FAIL A: pina no mantiene el lado: ", signs);ok = false
		else:
			if not (signs[0] != signs[1] and signs[1] != signs[2]):
				print("FAIL B: abierto no alterna: ", signs);ok = false

	var drops: = 0
	for i in range(40):
		var s = _mk()
		s.pl[1].plan = "dejada";s.pl[1].plan_left = 1;s.pl[1].plan_side = 1.0
		s.ball.x = 0.0;s.ball.y = 1.3;s.ball.z = 16.5
		s.ball.vx = 0.0;s.ball.vy = 1.5;s.ball.vz = 7.0
		s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
		s.pl[1].x = 0.0;s.pl[1].z = 18.5
		s.pl[0].x = 3.2;s.pl[0].z = 0.0
		var dt = 1.0 / 60.0
		for f in range(60 * 4):
			s.update(dt)
			var done: = false
			for ev in s.events:
				if ev.get("t") == "hit" and int(ev.get("id")) == 1:
					if str(ev.get("kind")) == "drop": drops += 1
					done = true
				elif ev.get("t") == "point" or ev.get("t") == "net":
					done = true
			s.events.clear()
			if done: break
	print("C cierre dejada: ", drops, "/40")
	if drops < 28:
		print("FAIL C: el plan dejada no cierra con dejada");ok = false
	print("GATE073 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
