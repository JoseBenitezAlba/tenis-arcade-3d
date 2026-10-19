extends SceneTree

const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	var a: Vector2 = PF.gaze_angles(Vector3(3, 0, 3))
	if not (a.x > 0.2 and a.x <= PF.GAZE_YAW): print("FAIL: yaw ", a);fail += 1
	if PF.gaze_angles(Vector3(0, 0, -3)) != Vector2.ZERO: print("FAIL: detras");fail += 1
	var b: Vector2 = PF.gaze_angles(Vector3(50, 40, 1))
	if abs(b.x) > PF.GAZE_YAW + 0.001 or abs(b.y) > PF.GAZE_PITCH + 0.001: print("FAIL: limites ", b);fail += 1
	if PF.gaze_angles(Vector3(-3, 0, 3)).x >= 0.0: print("FAIL: signo");fail += 1
	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	await process_frame
	var hi = fig.skel.find_bone("Head")
	var y0: float = fig.skel.get_bone_global_pose(hi).basis.get_euler().y
	fig.look_on = true
	fig.look_target = fig.to_global(Vector3(2.0, 1.2, 3.0))
	fig._apply_gaze()
	var y1: float = fig.skel.get_bone_global_pose(hi).basis.get_euler().y
	if abs(y1 - y0) < 0.2: print("FAIL: cabeza no gira ", y0, " ", y1);fail += 1
	fig.look_on = false
	fig.skel.clear_bones_global_pose_override()
	fig._apply_gaze()
	print("gate133 ", "PASS" if fail == 0 else "FAIL")
	quit()
