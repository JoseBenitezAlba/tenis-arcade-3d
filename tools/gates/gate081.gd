extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var figs: = []
var frames: = 0
var ok: = true
func _mk():
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	return SimClass.new(true, CP, HP, "CPU", 1)
func _init() -> void :
	seed(81081)

	var s = _mk()
	s.state = "play"
	s.ball.in_play = true;s.ball.serving = false
	s.ball.held = false;s.ball.toss = false
	s.serve_unreturned = false
	s.pl[0].x = 0.0;s.pl[0].z = 6.0
	s.ball.x = 0.0;s.ball.y = 1.1;s.ball.z = 18.0
	s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = 5.0
	s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
	s.pl[1].x = 0.0;s.pl[1].z = 19.0;s.pl[1].swing = 0.0
	s.pl[1].vx = 4.0;s.pl[1].vz = 0.0;s.pl[1].speed = 4.0
	s.pl[1].plan = "";s.pl[1].plan_left = 0
	s.do_hit(s.pl[1], "drive", true)
	print("A carrera plant_t=", s.pl[1].plant_t, " dir=", s.pl[1].plant_dir)
	if s.pl[1].plant_t <= 0.0 or s.pl[1].plant_dir != 1.0:
		print("FAIL A: llegar en carrera no deja plant");ok = false
	var s2 = _mk()
	s2.state = "play"
	s2.ball.in_play = true;s2.ball.serving = false
	s2.ball.held = false;s2.ball.toss = false
	s2.serve_unreturned = false
	s2.pl[0].x = 0.0;s2.pl[0].z = 6.0
	s2.ball.x = 0.0;s2.ball.y = 1.1;s2.ball.z = 18.0
	s2.ball.vx = 0.0;s2.ball.vy = 0.0;s2.ball.vz = 5.0
	s2.ball.last = 0;s2.ball.bounces = 1;s2.ball.kind = "drive"
	s2.pl[1].x = 0.0;s2.pl[1].z = 19.0;s2.pl[1].swing = 0.0
	s2.pl[1].vx = 0.0;s2.pl[1].vz = 0.0;s2.pl[1].speed = 0.0
	s2.pl[1].plan = "";s2.pl[1].plan_left = 0
	s2.do_hit(s2.pl[1], "drive", true)
	if s2.pl[1].plant_t != 0.0:
		print("FAIL A: plantado no debe tener plant");ok = false

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
		figs.append({"fig": f, "plant": i == 0})
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.6, 4.4), Vector3(0, 0.85, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	for it in figs:
		var ent: = {"x": it.fig.position.x, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "drive", 
			"swing": 0.3, "want_t": 0.0, "want": "drive", "vx": 0.0, "vz": 0.0, "prep_t": 0.0, 
			"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
			"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
			"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, 
			"plant_t": 0.35 if it.plant else 0.0, "plant_dir": 1.0 if it.plant else 0.0}
		it.fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		var rz0: float = figs[0].fig.rotation.z
		var rz1: float = figs[1].fig.rotation.z
		print("B rotz: plant=", snappedf(rz0, 0.001), " base=", snappedf(rz1, 0.001))
		var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/gate081.png"
		root.get_texture().get_image().save_png(out)
		if absf(rz0 - rz1) < 0.05:
			print("FAIL B: el plant no se ve (rotz iguales)");ok = false
		print("GATE081 " + ("PASS" if ok else "FAIL"))
		quit(0 if ok else 1)
	return false
