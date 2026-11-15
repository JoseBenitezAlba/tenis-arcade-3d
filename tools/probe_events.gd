extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h = load("res://scripts/main.gd").new(); h._register_inputs()
	for test_seed in [42117, 8853]:
		seed(test_seed)
		var m = MatchView.new(); m.set_meta("surface","clay"); m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1})
		root.add_child(m); m.set_physics_process(false); await process_frame; seed(test_seed)
		var prev_body = [Vector3.INF, Vector3.INF]
		var body_hist = [[], []]
		var swing_prev = [0.0, 0.0]
		for i in 1600:
			m._physics_process(1.0/60)
			for a in 2:
				var f = m.rigs[a]; var e = m.sim.pl[a]
				var bi: int = f.skel.find_bone("Body")
				var v: Vector3 = f.skel.global_transform * f._current_global_pose(bi).origin
				var step: float = v.distance_to(prev_body[a]) if prev_body[a] != Vector3.INF else 0.0
				prev_body[a] = v
				body_hist[a].append(step)
				if e.swing > 0.0 and swing_prev[a] <= 0.0 and e.kind != "serve" and f.has_visual_contact:
					var pre: float = 0.0
					var n: int = 0
					for k in range(maxi(1, i-12), i): pre += body_hist[a][k-1]; n += 1
					pre = pre / maxf(1.0, n)
					print("EVENT seed=", test_seed, " actor=", a, " frame=", i, " kind=", e.kind, " side=", e.hit_side, " onset_step=", snappedf(step,0.001), " pre_mean=", snappedf(pre,0.001))
				swing_prev[a] = e.swing
		m._amb.stop(); m.queue_free(); await process_frame
	print("DONE"); quit()
