extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _measure(by: float, kind: String, n: int, inp_y: float, px: float, bx: float, spd0: float = 0.0) -> Dictionary:
	var nets: = 0; var cords: = 0; var spds: = 0.0; var cross: = []
	for i in range(n):
		var s = SimClass.new(false, CP, HP, "CPU", 1)
		s.state = "play"
		s.ball.in_play = true;s.ball.serving = false
		s.ball.held = false;s.ball.toss = false
		s.serve_unreturned = false
		s.pl[0].x = px;s.pl[0].z = 0.5;s.pl[0].speed = spd0
		s.ball.x = bx;s.ball.y = by;s.ball.z = 1.5
		s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = -6.0
		s.ball.last = 1;s.ball.bounces = 1
		s.inp.x = 0.0;s.inp.y = inp_y
		s.do_hit(s.pl[0], kind, false)
		spds += Vector3(s.ball.vx, s.ball.vy, s.ball.vz).length()
		var t: = 0.0; var dt = 1.0 / 120.0; var pz = s.ball.z
		while t < 1.5:
			s.step_ball(dt)
			t += dt
			if (pz - s.NZ) * (s.ball.z - s.NZ) < 0:
				cross.append(s.ball.y)
			pz = s.ball.z
			var done: = false
			for ev in s.events:
				if ev.get("t") == "net": nets += 1;done = true
				elif ev.get("t") == "netcord": cords += 1;done = true
				elif ev.get("t") == "bounce" or ev.get("t") == "point": done = true
			s.events.clear()
			if done: break
	var cy: = 0.0
	for v in cross: cy += v
	return {"nets": nets, "cords": cords, "spd": spds / n, "cy": cy / max(cross.size(), 1)}
func _init():
	randomize()
	var ok: = true
	var flat: = _measure(1.1, "drive", 150, 1.0, 0.0, 0.0)
	print("C1 plano comodo: red=", flat.nets, " pelusa=", flat.cords, " /150  spd=", snappedf(flat.spd, 0.1), " cruce=", snappedf(flat.cy, 0.01))
	if float(flat.nets + flat.cords) / 1.5 > 1.5: ok = false;print("FAIL plano comodo debe ser seguro")
	var st: = _measure(1.1, "drive", 250, 0.0, 2.5, 0.0)
	print("C2 estirada: red=", st.nets, " pelusa=", st.cords, " /250  spd=", snappedf(st.spd, 0.1), " cruce=", snappedf(st.cy, 0.01))
	var spct: float = float(st.nets + st.cords) / 2.5
	if spct < 0.5 or spct > 4.0: ok = false;print("FAIL estirada fuera de banda (0.5-4%)")
	if st.nets < 1: ok = false;print("FAIL ni una red seca en 250 estiradas")
	var dig: = _measure(0.5, "drive", 200, 0.0, 0.0, 0.0)
	print("C3 escarbada: red=", dig.nets, " pelusa=", dig.cords, " /200  cruce=", snappedf(dig.cy, 0.01))
	if float(dig.nets + dig.cords) / 2.0 > 15.0: ok = false;print("FAIL escarbada no jugable")
	var sl: = _measure(1.1, "slice", 150, 0.0, 0.0, 0.0)
	print("C4 slice: red=", sl.nets, " pelusa=", sl.cords, " /150")
	if sl.nets + sl.cords > 4: ok = false;print("FAIL slice debe ser seguro")
	print("GATE067 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
