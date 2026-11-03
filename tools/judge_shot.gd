extends SceneTree
func _initialize() -> void :
	var court: = CourtBuilder.build("grass", false)
	root.add_child(court)
	var cam: = Camera3D.new()
	cam.fov = 45.0
	cam.far = 200.0
	root.add_child(cam)
	cam.look_at_from_position(Vector3(-4.2, 1.6, 27.6), Vector3(-6.7, 0.8, 27.2), Vector3.UP)
	cam.make_current()
	for i in 6:
		await process_frame
		await physics_frame
	root.get_texture().get_image().save_png("/tmp/judge_noche.png")
	print("JUDGE saved")
	quit(0)
