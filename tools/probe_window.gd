extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h = load("res://scripts/main.gd").new(); h._register_inputs()
	var cases = [[42117, 0, 1133], [42117, 0, 1293], [42117, 0, 1221]]
	for c in cases:
		seed(c[0])
		var m = MatchView.new(); m.set_meta("surface","clay"); m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1})
		root.add_child(m); m.set_physics_process(false); await process_frame; seed(c[0])
		var first: int = c[2] - 12; var last: int = c[2] + 17
		var previous := {}; var mx := {}; var onset_step := INF
		for i in last + 1:
			m._physics_process(1.0/60)
			if i < first: continue
			var f = m.rigs[c[1]]
			for bone in ["Body","UpperLeg_L","UpperArm_R","Head","Foot_L","Foot_R"]:
				var v: Vector3 = f.skel.global_transform * f._current_global_pose(f.skel.find_bone(bone)).origin
				if previous.has(bone):
					var step: float = v.distance_to(previous[bone]); mx[bone] = maxf(mx.get(bone, 0.0), step)
					if bone == "Body" and i == c[2] + 1: onset_step = step
				previous[bone] = v
		print("WINDOW seed=", c[0], " actor=", c[1], " event=", c[2], " onset_step=", snappedf(onset_step,0.001), " body_max=", snappedf(mx.get("Body",-1.0),0.001), " footL_max=", snappedf(mx.get("Foot_L",-1.0),0.001), " footR_max=", snappedf(mx.get("Foot_R",-1.0),0.001))
		m._amb.stop(); m.queue_free(); await process_frame
	print("DONE"); quit()
