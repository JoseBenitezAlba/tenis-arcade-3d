extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var h = load("res://scripts/main.gd").new(); h._register_inputs()
	seed(72)
	var m = MatchView.new(); m.set_meta("surface","clay"); m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1})
	root.add_child(m); m.set_physics_process(false); await process_frame; seed(72)
	for i in 1390:
		m._physics_process(1.0/60)
		if (i >= 792 and i <= 816) or (i >= 1355 and i <= 1378):
			var f = m.rigs[1]; var e = m.sim.pl[1]
			print("f=", i, " st=", f.state, " gage=", snappedf(f._gait_age,0.01), " swing=", snappedf(e.swing,0.01), " sup_age=", snappedf(f._support_age,0.01), " sup_foot=", f._support_foot, " pend=", f._support_pending, " ap=", f.approach_active, " at=", snappedf(f.approach_time,0.01), " kind=", e.kind, " side=", e.hit_side)
	print("DONE"); quit()
