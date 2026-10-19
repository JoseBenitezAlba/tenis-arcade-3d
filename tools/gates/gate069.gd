extends SceneTree


var figs: = []
var frames: = 0
func _init() -> void :
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
	var variants: Array = [
		{"recov": 0.0, "recov_lean": 0.0}, 
		{"recov": 0.56, "recov_lean": 0.28}, 
		{"recov": 0.2, "recov_lean": 0.28}, 
	]
	for i in 3:
		var f = Fig.new(0, true)
		f.position = Vector3((i - 1) * 2.4, 0.0, 0.0)
		root.add_child(f)
		figs.append({"fig": f, "v": variants[i]})
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.5, 4.2), Vector3(0, 0.85, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	for it in figs:
		var v: Dictionary = it.v
		var ent: = {"x": it.fig.position.x, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "drive", 
			"swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 0.0, "vz": 0.0, "prep_t": 0.0, 
			"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
			"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
			"recov": v.recov, "recov_lean": v.recov_lean}
		it.fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/gate069.png"
		for i in 3:
			print("rig", i, " rotz=", snappedf(figs[i].fig.rotation.z, 0.001))
		root.get_texture().get_image().save_png(out)
		print("GATE069 render ok -> ", out)
		return true
	return false
