extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h = load("res://scripts/main.gd").new(); h._register_inputs()
	seed(42117)
	var m = MatchView.new(); m.set_meta("surface","clay"); m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1})
	root.add_child(m); m.set_physics_process(false); await process_frame; seed(42117)
	var prev := Vector3.INF
	for i in 300:
		m._physics_process(1.0/60)
		if i < 264: continue
		var f = m.rigs[0]; var e = m.sim.pl[0]
		var v: Vector3 = f.skel.global_transform * f._current_global_pose(f.skel.find_bone("Body")).origin
		var step: float = v.distance_to(prev) if prev != Vector3.INF else 0.0
		prev = v
		print("f=", i, " step=", snappedf(step,0.001), " st=", f.state, " gage=", snappedf(f._gait_age,0.01), " gk=", snappedf(f._gait_k,0.01), " swing=", snappedf(e.swing,0.01), " ap=", f.approach_active, " at=", snappedf(f.approach_time,0.01), " sup=", snappedf(f._support_age,0.01))
	print("DONE"); quit()
