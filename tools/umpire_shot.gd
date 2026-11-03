extends SceneTree
func _initialize() -> void :
	var out: = "/tmp/ump"
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var court: = CourtBuilder.build("grass", false)
	root.add_child(court)
	var cam: = Camera3D.new()
	cam.fov = 45.0
	cam.far = 200.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(-3.5, 2.6, 8.4), Vector3(-7.0, 2.2, 11.885), Vector3.UP)
	cam.make_current()
	for i in 6:
		await process_frame
		await physics_frame
	root.get_texture().get_image().save_png(out + "_noche_cerca.png")
	cam.look_at_from_position(Vector3(0, 6.9, -11.8), Vector3(0, 1.0, 12.0), Vector3.UP)
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(out + "_noche_broadcast.png")
	print("UMP saved")
	quit(0)
