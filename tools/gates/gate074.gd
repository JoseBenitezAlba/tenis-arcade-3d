extends SceneTree





var figs: = []
var frames: = 0
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(74074)

	for side in [1.0, -1.0]:
		var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5, "react": 0.2}
		var s = SimClass.new(true, CP, HP, "CPU", 1)
		s.state = "play"
		s.ball.in_play = true;s.ball.serving = false
		s.ball.held = false;s.ball.toss = false
		s.serve_unreturned = false
		s.pl[0].x = 0.2;s.pl[0].z = 6.0;s.pl[0].vx = 0.0
		var good: = 0
		for i in range(10):
			s.ball.x = 0.0;s.ball.y = 1.1;s.ball.z = 18.0
			s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = 5.0
			s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
			s.ball.in_play = true
			s.pl[1].x = 0.0;s.pl[1].z = 19.0;s.pl[1].swing = 0.0;s.pl[1].speed = 0.0
			s.pl[1].plan = "";s.pl[1].plan_left = 0
			s.pl[1].intent_side = side
			s.do_hit(s.pl[1], "drive", true)
			if signf(s.ball.vx) == side: good += 1
		print("A side=", side, " al-lado=", good, "/10")
		if good < 7:
			print("FAIL A: el tiro no sigue la intencion");ok = false

	var sun: = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.7, 0.75, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.7
	env.environment = e
	root.add_child(env)
	var Fig = load("res://scripts/player_fig.gd")
	for i in 2:
		var f = Fig.new(0, true)
		f.position = Vector3((i - 0.5) * 2.4, 0.0, 0.0)
		root.add_child(f)
		figs.append({"fig": f, "side": 1.0 if i == 0 else -1.0})
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.6, 4.4), Vector3(0, 0.85, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	for it in figs:
		var ent: = {"x": it.fig.position.x, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "drive", 
			"swing": 0.0, "want_t": 0.15, "want": "drive", "vx": 0.0, "vz": 0.0, "prep_t": 0.0, 
			"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
			"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
			"recov": 0.0, "recov_lean": 0.0, "intent_side": it.side}
		it.fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		var ry0: float = figs[0].fig.rotation.y
		var ry1: float = figs[1].fig.rotation.y
		print("B roty: izda=", snappedf(ry0, 0.001), " dcha=", snappedf(ry1, 0.001))
		var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/gate074.png"
		root.get_texture().get_image().save_png(out)
		if absf(ry0 - ry1) < 0.1:
			print("FAIL B: la senal no se ve (roty iguales)");ok = false
		print("GATE074 " + ("PASS" if ok else "FAIL"))
		quit(0 if ok else 1)
	return false
