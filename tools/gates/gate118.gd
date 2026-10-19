extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
var ok: = true
var figs: = []
var frames: = 0
func _init() -> void :

	print("A f11=", MV.fatigue_from_rally(11), " f12=", MV.fatigue_from_rally(12), " f25=", MV.fatigue_from_rally(25))
	if MV.fatigue_from_rally(11) != 0.0 or MV.fatigue_from_rally(0) != 0.0 or absf(MV.fatigue_from_rally(12) - 1.0) > 0.001 or absf(MV.fatigue_from_rally(25) - 1.0) > 0.001:
		print("FAIL A: mapeo de fatiga incorrecto");ok = false

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
		figs.append({"fig": f, "fat": 1.0 if i == 0 else 0.0})
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.6, 4.4), Vector3(0, 0.85, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	for it in figs:
		var ent: = {"x": it.fig.position.x, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "drive", 
			"swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 0.0, "vz": 0.0, "prep_t": 0.0, 
			"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
			"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
			"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, 
			"plant_t": 0.0, "plant_dir": 0.0, "fatigue": it.fat}
		it.fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		var rx0: float = figs[0].fig.rotation.x
		var rx1: float = figs[1].fig.rotation.x
		print("B rotx: fatigado=", snappedf(rx0, 0.001), " fresco=", snappedf(rx1, 0.001))
		root.get_texture().get_image().save_png("/tmp/gate118.png")
		if absf(rx0 - rx1) < 0.05:
			print("FAIL B: la fatiga no se ve (rotx iguales)");ok = false
		print("GATE118 PASS" if ok else "GATE118 FAIL")
		quit(0 if ok else 1)
	return false
