extends SceneTree

func _init():
	var fail: = 0
	var fig: Node3D = CourtBuilder._fbx_figure("res://models/Suit_Male.fbx", Color("#274070"), Color("#222a40"), Color("#c98d62"), "tennis/Sitting_Idle", Color("#3a3230"), 0.56)
	root.add_child(fig)
	var ap: AnimationPlayer = fig.find_child("AnimationPlayer", true, false)
	var a: Animation = ap.get_animation("tennis/Sitting_Idle")
	var base: Node = ap.get_node(ap.root_node)
	var ok: = 0
	for i in a.get_track_count():
		var tp: NodePath = a.track_get_path(i)
		var nd: Node = base.get_node_or_null(NodePath(str(tp).get_slice(":", 0)))
		if nd is Skeleton3D and (nd as Skeleton3D).find_bone(str(tp).get_slice(":", 1)) >= 0:
			ok += 1

	if ok < a.get_track_count() - 3: print("FAIL: pistas sin resolver ", ok, "/", a.get_track_count());fail += 1
	ap.seek(0.5, true)
	var sk: = fig.find_child("Skeleton3D", true, false) as Skeleton3D
	sk.force_update_all_bone_transforms()
	var hy: float = sk.get_bone_global_pose(sk.find_bone("Hips")).origin.y
	var fy: float = sk.get_bone_global_pose(sk.find_bone("Foot.L")).origin.y
	print("hip-foot ", hy - fy)
	if hy - fy > 0.62: print("FAIL: cadera alta (de pie) ", hy - fy);fail += 1
	var PF = load("res://scripts/player_fig.gd")
	if PF.RK_REST_A < 1.2 or PF.RK_REST_A > 2.8: print("FAIL: reposo raqueta");fail += 1
	var src: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not ("get(e.kind, _rec_base)" in src): print("FAIL: recov");fail += 1
	print("gate152 ", "PASS" if fail == 0 else "FAIL")
	quit()
