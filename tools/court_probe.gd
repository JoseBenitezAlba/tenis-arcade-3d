extends SceneTree
# Sonda de pista: CourtBuilder + 2 jugadores + publico 3D, sin sim ni HUD.
# xvfb-run -a godot -s tools/court_probe.gd -- <out_prefix>

func _initialize() -> void:
	var out := "/tmp/court_probe"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var court := CourtBuilder.build("grass", true)
	root.add_child(court)
	var crowd := CrowdFX.new()
	root.add_child(crowd)
	crowd.build()
	for k in 4:
		crowd.update(0.016, 0.0)
	var p0 := PlayerFig.new(0, true)
	p0.position = Vector3(0, 0, -2.0)
	root.add_child(p0)
	var p1 := PlayerFig.new(1, false)
	p1.position = Vector3(0.5, 0, 26.0)
	p1.rotation.y = PI
	root.add_child(p1)
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 200.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 6.9, -11.8), Vector3(0, 1.0, 12.0), Vector3.UP)
	cam.make_current()
	for i in 6:
		await process_frame
		await physics_frame
	root.get_texture().get_image().save_png(out + "_broadcast.png")
	print("PROBE broadcast saved")
	# vista lateral a nivel de pista
	cam.look_at_from_position(Vector3(11.0, 2.0, 11.9), Vector3(0, 1.0, 11.9), Vector3.UP)
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(out + "_lateral.png")
	print("PROBE lateral saved")
	quit(0)
