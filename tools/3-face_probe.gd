extends SceneTree
# Sonda rapida: un jugador, camara a la cara, una captura. Uso:
# xvfb-run -a godot -s tools/face_probe.gd -- <out.png>

func _initialize() -> void:
	var out := "/tmp/face_probe.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.65, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.98, 0.95)
	e.ambient_light_energy = 0.55
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 25, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.2
	w.add_child(sun)
	var fig := PlayerFig.new(0, false)
	w.add_child(fig)
	fig._play("tennis/Idle")
	var cam := Camera3D.new()
	cam.fov = 40.0
	w.add_child(cam)
	cam.look_at_from_position(Vector3(0.3, 1.58, 1.9), Vector3(0, 1.5, 0), Vector3.UP)
	cam.make_current()
	for i in 8:
		await process_frame
		await physics_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("PROBE SAVED ", out)
	quit(0)
