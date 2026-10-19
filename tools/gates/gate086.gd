extends SceneTree



const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var figs: = []
var frames: = 0
var ok: = true
func _init() -> void :
	seed(86086)


	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	var prev: = [0.0, 0.0]
	var edges: = [0, 0]
	for i in 60 * 90:
		s.update(1.0 / 60.0)
		s.events.clear()
		for j in 2:
			if prev[j] <= 0.0 and s.pl[j].burst > 0.0:
				edges[j] += 1
			prev[j] = s.pl[j].burst
	print("A flancos de burst en 90s demo: p0=", edges[0], " p1=", edges[1])
	if edges[0] + edges[1] < 3:
		print("FAIL A: el primer paso casi no dispara en rally");ok = false

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
		figs.append({"fig": f, "burst": i == 0})
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.6, 4.4), Vector3(0, 0.85, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	for it in figs:
		var ent: = {"x": it.fig.position.x, "z": 0.0, "near": true, "speed": 3.0, "run": 0.0, "kind": "drive", 
			"swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 0.0, "vz": -3.0, "prep_t": 0.0, 
			"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
			"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
			"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, 
			"plant_t": 0.0, "plant_dir": 0.0, 
			"burst": 0.16 if it.burst else 0.0}
		it.fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		var rx0: float = figs[0].fig.rotation.x
		var rx1: float = figs[1].fig.rotation.x
		print("B rotx: burst=", snappedf(rx0, 0.001), " base=", snappedf(rx1, 0.001))
		var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/gate086.png"
		root.get_texture().get_image().save_png(out)
		if absf(rx0 - rx1) < 0.03:
			print("FAIL B: el arranque no se ve (rotx iguales)");ok = false
		print("GATE086 " + ("PASS" if ok else "FAIL"))
		quit(0 if ok else 1)
	return false
