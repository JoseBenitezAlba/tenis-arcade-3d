extends SceneTree
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _init():
	randomize()
	pass
	var Fig = load("res://scripts/player_fig.gd")
	print("GATE-CODE swing_drive=", Fig._swing_clip("drive", "fore"), " CONTACT_K=", Fig.CONTACT_K)
	var Sim = load("res://scripts/sim.gd")

	var ret: = 0; var statue: = 0
	for i in range(80):
		var s = Sim.new(false, HP, CP, "CPU", 1)
		var cpu = s.pl[1]
		s.pl[0].x = 4.1;s.inp.x = 0.0;s.inp.y = 1.0
		var x0 = cpu.x; var z0 = cpu.z
		s.do_serve(s.pl[0], 1.0)
		var maxmove: = 0.0; var t = 0.0; var dt = 1.0 / 60.0
		while t < 2.2:
			s.update(dt);t += dt
			maxmove = max(maxmove, Vector2(cpu.x - x0, cpu.z - z0).length())
			if s.state == "point": break
		if s.ball.last == 1: ret += 1
		if s.ball.last != 1 and maxmove < 0.25: statue += 1
	print("A) bombazo 217: restos=", ret, " estatuas=", statue, " /80")

	var touch: = 0; var late: = 0; var st: = 0
	for i in range(60):
		var s = Sim.new(false, HP, CP, "CPU", 1)
		s.M.server = 1
		var cpu = s.pl[1]; var hum = s.pl[0]
		s.do_serve(cpu, 0.9)
		var t = 0.0; var dt = 1.0 / 60.0
		while t < 0.9:
			s.update(dt);t += dt
		var x0 = cpu.x; var z0 = cpu.z
		s.ball.last = 0;s.ball.hit_id += 1;s.ball.bounces = 0
		s.ball.x = hum.x;s.ball.z = -0.5;s.ball.y = 1.1
		s.launch(clamp(cpu.x + randf_range(-2.5, 2.5), -3.5, 3.5), randf_range(19.0, 22.5), randf_range(0.55, 0.8), 1.1)
		s.ball.serving = false
		var maxmove: = 0.0; var t2 = 0.0; var got: = false
		while t2 < 3.0:
			s.update(dt);t2 += dt
			maxmove = max(maxmove, Vector2(cpu.x - x0, cpu.z - z0).length())
			if s.ball.last == 1: got = true
			if s.state == "point": break
		if got: touch += 1
		elif maxmove < 0.3: st += 1
		else: late += 1
	print("B) plancha debil: CPU golpea=", touch, " tarde=", late, " estatua=", st, " /60")

	var dodged: = 0; var swung: = 0; var eaten: = 0; var letgo: = 0
	for i in range(60):
		var s = Sim.new(false, HP, CP, "CPU", 1)
		s.M.server = 1
		var cpu = s.pl[1]
		s.do_serve(cpu, 0.9)
		var t = 0.0; var dt = 1.0 / 60.0
		while t < 2.5 and s.state == "serve":
			s.update(dt);t += dt
		s.ball.last = 0;s.ball.hit_id += 1;s.ball.bounces = 0
		s.ball.x = cpu.x;s.ball.z = 2.0;s.ball.y = 1.2
		s.launch(cpu.x, cpu.z, 0.45, 1.2)
		s.ball.serving = false
		var saw_dodge: = false; var saw_letgo: = false; var saw_swing: = false; var t2 = 0.0
		while t2 < 1.5:
			s.update(dt);t2 += dt
			if cpu.dodge_for == s.ball.hit_id: saw_dodge = true
			if cpu.letgo_for == s.ball.hit_id: saw_letgo = true
			if cpu.swing > 0.0: saw_swing = true
			if s.state == "point": break
		if saw_dodge: dodged += 1
		elif saw_swing: swung += 1
		elif saw_letgo: letgo += 1
		else: eaten += 1
	print("C) bola-cuerpo rapida: esquiva=", dodged, " golpea=", swung, " deja_pasar(out)=", letgo, " COMIDA=", eaten, " /60")
	quit()
