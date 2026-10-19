extends SceneTree
var fig
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
	fig = Fig.new(0, true)
	root.add_child(fig)
	var cam: = Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(2.6, 1.5, 0.4), Vector3(0, 0.9, 0))
	cam.make_current()
func _process(_dt: float) -> bool:
	frames += 1
	var st: float = float(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 0.0
	var out: String = OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else "/tmp/fig_iso.png"
	var fat: float = float(OS.get_cmdline_user_args()[2]) if OS.get_cmdline_user_args().size() > 2 else 0.0
	var fat2: float = float(OS.get_cmdline_user_args()[3]) if OS.get_cmdline_user_args().size() > 3 else fat
	var fnow: float = fat if frames < 20 else fat2
	var ent: = {"x": 0.0, "z": 0.0, "near": true, "speed": 6.5, "run": 1.0, "kind": "drive", 
		"swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 6.5, "vz": 0.0, "prep_t": 0.0, 
		"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": st, "stumble_dir": 1.0, 
		"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": fnow}
	fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		print("figstate=", fig.state, " rotz=", snappedf(fig.rotation.z, 0.001), " stumble=", st)
		root.get_texture().get_image().save_png(out)
		return true
	return false
