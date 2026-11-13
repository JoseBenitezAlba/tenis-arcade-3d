class_name DebugHarness
extends Node



var m

const EARLY_RETURN: = ["--simtest", "--servespeed", "--careertest", "--trainshots", "--tourneytest"]
const LATE: = {
	"--serveshot": "_serveshot_harness", "--bounceshot": "_bounceshot_harness", 
	"--racketshot": "_racketshot_harness", "--swingshot": "_swingshot_harness", 
	"--judgetest": "_judgetest_harness", "--v29shots": "_v29shots_harness", 
	"--v30shots": "_v30shots_harness", "--trailshot": "_trailshot_harness", 
	"--rallyshots": "_rallyshots_harness", "--courtshot": "_courtshot_harness", "--arcshot": "_arcshot_harness", "--movietest": "_movietest_harness", 
	"--watchtest": "_watchtest_harness", "--boardcheck": "_boardcheck_harness", 
	"--closeup": "_closeup_harness", "--replayshots": "_replayshots_harness", 
	"--looktest": "_looktest_harness", "--careershot": "_careershot_harness", 
	"--faceshots": "_faceshots_harness", "--matchprobe": "_matchprobe_harness", 
	"--shots": "_shots_harness", 
	"--latshot": "_latshot_harness", "--ballshot": "_ballshot_harness", "--topshot": "_topshot_harness", "--celnight": "_celnight_harness", "--startshot": "_startshot_harness", "--servepose": "_servepose_harness", "--gameshot": "_gameshot_harness", "--faulttest": "_faulttest_harness", "--prepshot": "_prepshot_harness", "--legshot": "_legshot_harness", "--rallylabel": "_rallylabel_harness", "--celshot": "_celshot_harness", "--rkshot": "_rkshot_harness", "--jshot": "_jshot_harness", "--seqshot": "_seqshot_harness", "--ppshot": "_ppshot_harness", "--cpuserve": "_cpuserve_harness", "--cpuserveclose": "_cpuserveclose_harness", "--audit169": "_audit169_harness", "--cap171": "_cap171_harness", "--gday": "_gday_harness", "--matchmovie": "_matchmovie_harness", "--windupchk": "_windupchk_harness", "--prepcheck": "_prepcheck_harness", "--pose178": "_pose178_harness", "--net178": "_net178_harness", "--full178": "_full178_harness",
	"--v31shots": "_v31shots", "--audit173": "_audit173_harness", 
	"--t13": "_t13_harness", 
	"--grip": "_grip_harness", 
	"--contact": "_contact_harness", "--serveclip": "_serveclip_harness", 
}


func run_early(args: Array) -> bool:
	if args.has("--simtest"):
		_simtest(args)
		return true
	if args.has("--servespeed"):
		_servespeed()
		return true
	if args.has("--careertest"):
		_careertest()
		return true
	if args.has("--trainshots"):
		_trainshots(args)
		return true
	if args.has("--menushots"):
		_menushots(args)
	if args.has("--tourneytest"):
		_tourneytest()
		return true
	return false


func run_late(args: Array) -> bool:
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("location.search", true)
		if q is String and "demo" in q:
			call_deferred("_webdemo_harness", args)
			return true
	for flag in LATE:
		if args.has(flag):
			call_deferred(LATE[flag], args)
			return true
	return false

func _webdemo_harness(_args: Array) -> void :
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var qq = JavaScriptBridge.eval("location.search", true)
	if qq is String and "fast" in qq:
		Engine.time_scale = 4.0
	var ok: = await _wait_until( func(): return m.match_view.sim.state == "serve", 30.0)
	print("WEBDEMO serve=", ok)
	for tick in 40:
		await get_tree().create_timer(5.0, true, false, true).timeout
		var s = m.match_view.sim
		print("WEBDEMO t", tick * 5 + 5, " state=", s.state, " hits=", s.rally_hits, " pts=", s.pts)

func _careertest() -> void :
	randomize()
	var c: = Career.new()
	c.new_career("Test")

	for t in Career.CAL.size():
		c.start_tournament()
		var T: Dictionary = Career.TIERS[Career.CAL[c.data.tIdx].t]
		for r in T.rounds:
			var opp: Dictionary = c.current_opp()
			if opp.is_empty():
				print("ERROR: rival vacio t=", t, " r=", r)
				get_tree().quit(1)
			var res: = c.on_career_end(true)
			print("T", t + 1, " R", r + 1, " vs ", opp.n.left(18), " -> ", res.msg.left(80))
	print("temporada fin: rank=", c.my_rank(), " pts=", c.data.pts, " titulos=", c.data.titles, " tIdx=", c.data.tIdx)
	c.end_season()

	var c2: = Career.load_saved()
	if c2 == null or c2.data.name != "Test" or c2.data.season != 2:
		print("ERROR save/load")
		get_tree().quit(1)

	c2.start_tournament()
	var res2: = c2.on_career_end(false)
	print("derrota ok: ", res2.msg.left(90), " | hist=", c2.data.hist.size(), " tour null: ", c2.data.tour == null)

	c2.data.free = 2
	var pw0: int = c2.data.stats.pw
	c2.data.stats.pw += 1
	c2.save()
	print("stats pw ", pw0, "->", c2.data.stats.pw)
	Career.delete_save()
	print("CAREER TEST OK")
	get_tree().quit(0)


func _simtest(args: Array) -> void :
	var secs: = 120.0
	var i: = args.find("--simtest")
	if i + 1 < args.size() and args[i + 1].is_valid_float():
		secs = args[i + 1].to_float()
	var sim: = TennisSim.new(true, m.DIFF_PARAMS[1], {}, "CPU", 1)
	var dt: = 1.0 / 120.0
	var t: = 0.0
	var last_score: = ""
	while t < secs and not sim.match_over:
		sim.update(dt)
		t += dt
		for ev in sim.events:
			if ev.t == "point":
				print("PUNTO w=", ev.w, " ", ev.txt, " | pts=", sim.M.pts, " games=", sim.M.games, " sets=", sim.M.sets, " t=", snapped(t, 0.01))
		sim.events.clear()
	print("FIN SIM: sets=", sim.M.sets, " games=", sim.M.games, " pts=", sim.M.pts, " over=", sim.match_over, " t=", snapped(t, 0.1))
	get_tree().quit(0)

func _servespeed() -> void :

	var sim: = TennisSim.new(false, m.DIFF_PARAMS[1], {}, "CPU", 1)
	for intent in [1.0, 0.0, -1.0]:
		for q in [0.5, 0.75, 0.9, 1.0]:
			sim.reset_serve_ball()
			sim.pl[0].x = 1.4
			sim.inp.x = 0.0
			sim.inp.y = intent
			sim.do_serve(sim.pl[0], q)
			var v: Vector3 = Vector3(sim.ball.vx, sim.ball.vy, sim.ball.vz)
			print("PLAYER intent=", intent, " q=", q, " spd=", snapped(v.length(), 0.01))
	for first in [true, false]:
		for i in 8:
			sim.M.server = 1
			sim.reset_serve_ball()
			sim.serve_fault = 0 if first else 1
			sim.ball.x = sim.pl[1].x
			sim.ball.z = sim.pl[1].z - 0.5
			sim.do_serve(sim.pl[1], 1.0)
			sim.M.server = 0
			var v2: Vector3 = Vector3(sim.ball.vx, sim.ball.vy, sim.ball.vz)
			print("CPU first=", first, " spd=", snapped(v2.length(), 0.01))
	get_tree().quit(0)

func _training_shots(out: String) -> void :

	if m.menus != null:
		m.menus.visible = false
	m.training_view = TrainingView.new()
	m.training_view.setup({"surface": "grass", "look": 0})
	add_child(m.training_view)
	for fi in 20:
		await get_tree().physics_frame
	await _grab(out + "/01b_entrenamiento.png")
	m.training_view.start_serve()
	for fi in 45:
		await get_tree().physics_frame
	await _grab(out + "/01c_saque_vuelo.png")
	for fi in 130:
		await get_tree().physics_frame
	await _grab(out + "/01d_latas.png")
	m.training_view.queue_free()
	m.training_view = null
	await get_tree().process_frame

func _trainshots(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--trainshots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	for fi in 10:
		await get_tree().process_frame
	await _training_shots(out)
	get_tree().quit(0)


func _v31shots(args: Array) -> void :

	var out: = "/home/sandbox/godot/shots/v31"
	var i: = args.find("--v31shots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	if m.sfx == null:
		m.sfx = SoundKit.new()
		add_child(m.sfx)
	m.career = Career.new()
	m.career.new_career("Pro")
	if m.menus == null:
		m.menus = GameMenus.new(m.sfx)
		add_child(m.menus)
	for fi in 10:
		await get_tree().process_frame
	m.menus.show_menu(m.career)
	for fi in 8:
		await get_tree().process_frame
	await _grab(out + "/roster.png")
	m.menus.tab = "rank"
	m.menus.show_hub("")
	for fi in 8:
		await get_tree().process_frame
	await _grab(out + "/ranking.png")
	Career.delete_save()
	get_tree().quit(0)

func _menushots(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--menushots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.sfx = SoundKit.new()
	add_child(m.sfx)
	m.menus = GameMenus.new(m.sfx)
	add_child(m.menus)
	for fi in 10:
		await get_tree().process_frame
	m.menus.show_menu(null)
	for fi in 6:
		await get_tree().process_frame
	await _grab(out + "/m1_home.png")
	m.menus.show_exhibition()
	for fi in 6:
		await get_tree().process_frame
	await _grab(out + "/m2_exhibition.png")
	m.menus.show_games()
	for fi in 6:
		await get_tree().process_frame
	await _grab(out + "/m3_games.png")
	m._on_tournament()
	for fi in 6:
		await get_tree().process_frame
	await _grab(out + "/m4_tourney.png")
	get_tree().quit(0)

func _tourneytest() -> void :
	m.sfx = SoundKit.new()
	add_child(m.sfx)
	m.menus = GameMenus.new(m.sfx)
	add_child(m.menus)
	await get_tree().process_frame
	var fails: = 0

	m._tourney_new()
	if m.tourney.alive.size() != 8:
		print("FAIL alive inicial = ", m.tourney.alive.size());fails += 1
	if m.tourney.bracket_text.size() != 4:
		print("FAIL bracket inicial = ", m.tourney.bracket_text.size());fails += 1
	for r in 3:
		m._tourney_resolve(true, {"sets": [2 if r == 2 else 1, 0]})
	if not m.tourney.done or m.tourney.champion != "TÚ":
		print("FAIL campeon: done=", m.tourney.done, " champ=", m.tourney.champion);fails += 1
	print("WIN-PATH champ=", m.tourney.champion, " results=", m.tourney.results.size())

	m._tourney_new()
	m._tourney_resolve(false, {"sets": [0, 1]})
	if not m.tourney.done or not m.tourney.eliminated or m.tourney.champion == "" or m.tourney.champion == "TÚ":
		print("FAIL eliminacion: done=", m.tourney.done, " elim=", m.tourney.eliminated, " champ=", m.tourney.champion);fails += 1
	print("LOSE-PATH champ=", m.tourney.champion, " eliminated=", m.tourney.eliminated)

	m._tourney_new()
	m._tourney_resolve(true, {"sets": [1, 0]})
	if m.tourney.alive.size() != 4 or m.tourney.round != 1:
		print("FAIL semis: alive=", m.tourney.alive.size(), " round=", m.tourney.round);fails += 1
	if m.tourney.bracket_text.size() != 2:
		print("FAIL bracket semis = ", m.tourney.bracket_text.size());fails += 1
	m._tourney_resolve(true, {"sets": [1, 0]})
	if m.tourney.alive.size() != 2 or m.tourney.round != 2:
		print("FAIL final: alive=", m.tourney.alive.size(), " round=", m.tourney.round);fails += 1
	if fails == 0:
		print("TOURNEYTEST OK")
	else:
		print("TOURNEYTEST FAILS=", fails)
	get_tree().quit(0 if fails == 0 else 1)


func _shots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--shots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	for fi in 30:
		await get_tree().process_frame
	print("m.menus visible=", m.menus.visible, " size=", m.menus.size, " root_box children=", m.menus.root_box.get_child_count(), " bg=", m.menus.get_child_count())
	await _grab(out + "/01_menu.png")

	await _training_shots(out)


	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(2.2)
	await _grab(out + "/02_saque_arcilla.png")
	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 3, 30.0)
	print("rally ok: ", ok, " hits=", m.match_view.sim.rally_hits)
	await _grab(out + "/03_rally_arcilla.png")
	ok = await _wait_until( func(): return m.match_view.sim.rally_hits >= 6, 30.0)
	print("rally6 ok: ", ok, " hits=", m.match_view.sim.rally_hits)
	await _grab(out + "/04_rally_arcilla2.png")
	var okp: = await _wait_until( func(): return m.match_view.sim.state == "point", 60.0)
	print("point ok: ", okp)
	if okp:
		await _wait_sim(0.6)
		await _grab(out + "/04b_celebracion.png")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame


	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("cpu_look", 3)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(2.4)
	await _grab(out + "/05_saque_dura.png")
	ok = await _wait_until( func(): return m.match_view.sim.rally_hits >= 4, 30.0)
	print("rally hard ok: ", ok)
	await _grab(out + "/06_rally_dura.png")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame


	m.menus.visible = true
	m.career = Career.new()
	m.career.new_career("Jugador")
	m.menus.career = m.career
	m.menus.show_hub("")
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/07_carrera_hub.png")
	m.menus.tab = "rank"
	m.menus.show_hub("")
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/08_carrera_ranking.png")
	Career.delete_save()
	m.career = null



func _faceshots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--faceshots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 0)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(2.0)
	m.match_view.set_physics_process(false)
	var fp = m.match_view.sim.pl[1]
	print("FACE far player pos=", fp.x, ",", fp.z)
	var fig = m.match_view.rigs[1]
	if fig == null:
		for c in m.match_view.get_children():
			print("MVCHILD ", c.name)
	else:
		var sk = fig.skel
		var hb = sk.find_bone("Head")
		print("HEAD bone global pose: ", sk.global_transform * sk.get_bone_global_pose(hb))
		var sc = (sk.global_transform * sk.get_bone_global_pose(hb)).basis.get_scale()
		print("HEAD bone world scale=", sc)
	m.match_view.cam.position = Vector3(fp.x + 0.35, 1.42, fp.z - 2.4)
	m.match_view.cam.look_at(Vector3(fp.x, 1.38, fp.z))
	await get_tree().process_frame
	await _grab(out + "/f1_cara_cpu.png")
	var np = m.match_view.sim.pl[0]
	m.match_view.cam.position = Vector3(np.x - 0.35, 1.42, np.z + 2.4)
	m.match_view.cam.look_at(Vector3(np.x, 1.38, np.z))
	await get_tree().process_frame
	await _grab(out + "/f2_cara_tu.png")
	print("FACESHOTS DONE")
	get_tree().quit(0)

func _matchprobe_harness(args: Array) -> void :


	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--matchprobe")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 0)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	m.match_view.set_physics_process(false)
	for fi in 3:
		await get_tree().process_frame

	await _grab(out + "/mp1_broadcast.png")

	m.match_view.cam.position = Vector3(10.5, 2.2, 0.0)
	m.match_view.cam.look_at(Vector3(0, 1.0, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/mp2_lateral.png")

	m.match_view.cam.position = Vector3(0, 2.6, -13.5)
	m.match_view.cam.look_at(Vector3(0, 1.0, 2.0))
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/mp3_fondo.png")
	print("MATCHPROBE DONE")
	get_tree().quit(0)

func _replayshots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--replayshots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 1)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	m.match_view.replay_test = true
	var okr: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 5, 600.0)
	print("REPLAY rally ok: ", okr, " hits=", m.match_view.sim.rally_hits)
	if okr:
		m.match_view.sim.award_point(0, "PUNTO", "test")
	var ok: = await _wait_until( func(): return m.match_view.replaying, 120.0)
	print("REPLAY triggered: ", ok, " frames=", m.match_view.rec.size())
	for fi in 4:
		await get_tree().process_frame
	await _grab(out + "/r1_replay.png")
	await _wait_sim(1.5)
	await _grab(out + "/r2_replay.png")
	var ok2: = await _wait_until( func(): return not m.match_view.replaying, 120.0)
	print("REPLAY ended: ", ok2)
	await _wait_sim(1.0)
	await _grab(out + "/r3_tras_replay.png")
	print("REPLAYSHOTS DONE")
	get_tree().quit(0)

func _closeup_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots"
	var i: = args.find("--closeup")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().process_frame
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 1)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_until( func(): return m.match_view.sim.rally_hits >= 5, 25.0)
	m.match_view.set_physics_process(false)
	m.match_view.cam.position = Vector3(2.2, 1.7, -4.2)
	m.match_view.cam.look_at(Vector3(m.match_view.sim.pl[0].x, 1.1, m.match_view.sim.pl[0].z))
	await get_tree().process_frame
	await _grab(out + "/11_closeup.png")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame
	m.menus.visible = true


	m.menus.show_create()
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/09_carrera_crear.png")


	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "PS": {"speed": 7.0, "T": 1.0, "err": 1.0}, "sets_to_win": 1})
	add_child(m.match_view)
	m.match_view.match_finished.connect(m._on_match_finished)
	await _wait_sim(0.5)
	m.match_view.sim.M.sets[0] = 1
	m.match_view.sim.match_over = true
	m.match_view.sim.state = "point"
	m.match_view.sim.state_t = 3.0
	var over_ok: = await _wait_until( func(): return m.menus.visible and m.match_view == null, 10.0)
	print("over screen ok: ", over_ok)
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/10_victoria.png")
	print("SHOTS DONE")
	get_tree().quit(0)

func _wait_sim(secs: float) -> void :
	var t: = 0.0
	while t < secs:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()

func _wait_until(cond: Callable, max_secs: float) -> bool:
	var t: = 0.0
	while t < max_secs:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if cond.call():
			return true
	return false

func _grab(path: String) -> void :
	await RenderingServer.frame_post_draw
	var img: = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path)

func _boardcheck_harness(args: Array) -> void :
	var out: = "/tmp/boardcheck.png"
	var i: = args.find("--boardcheck")
	if i + 1 < args.size():
		out = args[i + 1]
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	for fi in 20:
		await get_tree().process_frame
	m.match_view.set_physics_process(false)
	m.match_view.cam.position = Vector3(0, 2.5, 6.0)
	m.match_view.cam.look_at(Vector3(0, 1.0, 20.0))
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out)
	print("BOARDCHECK DONE")
	get_tree().quit(0)



func _courtshot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/court"
	var i: = args.find("--courtshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	var cam: = Camera3D.new()
	add_child(cam)
	cam.fov = 50.0
	for surface in ["hard", "clay", "grass"]:
		var court: = CourtBuilder.build(surface, true)
		add_child(court)
		for fi in 12:
			await get_tree().process_frame

		cam.position = Vector3(0, 8.5, -7.2)
		cam.look_at(Vector3(0, 0.0, 14.5))
		cam.current = true
		await _grab(out + "/court_tv_" + surface + ".png")

		cam.position = Vector3(10.5, 2.6, CourtBuilder.NZ - 0.4)
		cam.look_at(Vector3(0, 0.7, CourtBuilder.NZ))
		await _grab(out + "/court_net_" + surface + ".png")

		cam.position = Vector3(13.0, 13.0, -9.0)
		cam.look_at(Vector3(0, 0.0, CourtBuilder.NZ + 3.0))
		await _grab(out + "/court_34_" + surface + ".png")

		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 16.0
		cam.position = Vector3(0, 25.0, CourtBuilder.NZ)
		cam.rotation = Vector3( - PI / 2.0, 0, 0)
		await _grab(out + "/court_top_" + surface + ".png")
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE

		var dimg: = Image.create(64, 128, false, Image.FORMAT_RGBA8)
		dimg.fill(Color(0.15, 0.15, 0.15))
		for gy in 128:
			for gx in 64:
				var cc: = Color(0.15, 0.15, 0.15)
				if gy < 12: cc = Color(1, 0, 0)
				elif gy >= 116: cc = Color(0, 1, 0)
				if gx < 8: cc = Color(0, 0, 1)
				elif gx >= 56: cc = Color(1, 1, 0)
				if gy >= 58 and gy < 70 and gx >= 26 and gx < 38: cc = Color(1, 1, 1)
				dimg.set_pixel(gx, gy, cc)
		var dtex: = ImageTexture.create_from_image(dimg)
		var court_mi: MeshInstance3D = null
		for ch in court.get_children():
			if ch is MeshInstance3D and ch.mesh is BoxMesh and ch.mesh.size.x > 10.0:
				court_mi = ch
		if court_mi:
			var dm: = StandardMaterial3D.new()
			dm.albedo_texture = dtex
			dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var old_mat = court_mi.mesh.material
			court_mi.mesh.material = dm
			court_mi.visible = false
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = 16.0
			cam.position = Vector3(0, 25.0, CourtBuilder.NZ)
			cam.rotation = Vector3( - PI / 2.0, 0, 0)
			await get_tree().process_frame
			await get_tree().process_frame

			court_mi.visible = true
			court_mi.mesh.material = old_mat

			print("SCENE MESHES (", surface, "):")
			var stk2: = [get_tree().root]
			while stk2.size() > 0:
				var nd = stk2.pop_back()
				for cc in nd.get_children():
					stk2.append(cc)
				if nd is MeshInstance3D and nd.visible and nd.mesh:
					var aabb: AABB = nd.get_aabb()
					var gpos: = (nd as MeshInstance3D).global_position
					if aabb.size.x > 5.0 or aabb.size.z > 5.0:
						print("  M ", nd.name, " @", gpos, " aabb=", aabb, " mesh=", nd.mesh.get_class(), " mat=", (nd.mesh.material if nd.mesh is PrimitiveMesh else "array"))
			await _grab(out + "/court_uvdiag_" + surface + ".png")
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		court.queue_free()
		await get_tree().process_frame
	get_tree().quit(0)



func _t13_harness(args: Array) -> void :
	var i: = args.find("--t13")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/t13"
	var surface: String = "grass"
	for a in args:
		if a.begins_with("surface="):
			surface = a.split("=")[1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", surface)
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": surface, "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.state == "serve", 30.0)
	print("t13 serve state: ", ok)
	await _wait_sim(0.4)
	await _grab(out + "/00_ready_wide.png")
	# closeups of near player during the serve
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 30.0
	var p0: Vector3 = m.match_view.rigs[0].global_position
	jc.position = p0 + Vector3( - 3.1, 1.4, -1.2)
	jc.look_at(p0 + Vector3(0, 0.95, 0.3))
	jc.current = true
	await get_tree().process_frame
	await _grab(out + "/01_ready_side.png")
	for n in 14:
		await _wait_sim(0.14)
		await _grab(out + "/serve_%02d.png" % n)
	# back to match cam for rally wides
	m.match_view.cam.current = true
	for n in 16:
		await _wait_sim(0.45)
		await _grab(out + "/rally_%02d.png" % n)
		print("t13 rally ", n, " state=", m.match_view.sim.state, " hits=", m.match_view.sim.rally_hits)
	print("T13 DONE")
	get_tree().quit()


func _grip_harness(args: Array) -> void :
	var i: = args.find("--grip")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/grip"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(0.5)
	m.match_view.process_mode = Node.PROCESS_MODE_DISABLED
	var rg = m.match_view.rigs[0]
	m.match_view.rigs[1].visible = false
	rg.reparent(self)
	rg.position = Vector3.ZERO
	rg.rotation = Vector3.ZERO
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 28.0
	jc.current = true
	var wb: = WorldEnvironment.new()
	jc.position = Vector3( - 2.6, 1.5, 1.6)
	jc.look_at(Vector3(0, 0.95, 0))
	var cands: = [
		["id", Basis.IDENTITY],
		["xp90", Basis(Vector3.RIGHT, PI * 0.5)],
		["xm90", Basis(Vector3.RIGHT, - PI * 0.5)],
		["zp90", Basis(Vector3.FORWARD, PI * 0.5)],
		["zm90", Basis(Vector3.FORWARD, - PI * 0.5)],
		["x180", Basis(Vector3.RIGHT, PI)],
	]
	var poses: = [
		["ready", "Idle_Sword", 0.4],
		["fore", "mocap/Derecha", 1.8],
		["back", "mocap/Reves", 1.7],
		["serve", "mocap/Servicio", 1.05],
	]
	for c in cands:
		rg.grip_basis = c[1]
		for p in poses:
			rg.state = ""
			rg._play_seek(p[1], p[2])
			rg.ap.advance(0.2)
			rg.ap.pause()
			rg.ap.seek(p[2], true)
			if p[0] == "ready":
				rg._ready_stance()
			else:
				rg.skel.clear_bones_global_pose_override()
			rg.skel.force_update_all_bone_transforms()
			var hand_pose: Transform3D = rg.skel.get_bone_global_pose(rg.racket_hand_idx)
			var hp: Vector3 = rg.skel.global_transform * hand_pose.origin
			var hb: Basis = (rg.global_transform.basis.inverse() * rg.skel.global_transform.basis * hand_pose.basis).orthonormalized()
			rg.racket_node.basis = hb * rg.grip_basis
			rg.racket_node.position = rg.to_local(hp) + hb.y * -0.09
			await get_tree().process_frame
			await _grab(out + "/%s_%s.png" % [c[0], p[0]])
	print("GRIP DONE")
	get_tree().quit()


func _serveclip_harness(args: Array) -> void :
	var i: = args.find("--serveclip")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/serveclip"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	var fig: = PlayerFig.new(0, true)
	add_child(fig)
	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.4, 0.45)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.9)
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)
	var sun: = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3( - 50, 30, 0)
	add_child(sun)
	var cam: = Camera3D.new()
	add_child(cam)
	cam.fov = 35.0
	cam.position = Vector3( - 2.6, 1.5, 0.6)
	cam.look_at(Vector3(0, 1.0, 0))
	cam.current = true
	var n: = 0
	for t20 in range(18, 39):
		var tau: float = float(t20) / 20.0
		fig._play_seek("mocap/Servicio", tau)
		await get_tree().process_frame
		await get_tree().process_frame
		await _grab(out + "/clip_%02d.png" % n)
		n += 1
	print("SERVECLIP DONE")
	get_tree().quit()

func _contact_harness(args: Array) -> void :
	var i: = args.find("--contact")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/contact"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 30.0
	var n: = 0
	while n < 6:
		var ok: = await _wait_until( func(): return m.match_view.sim.pl[0].swing > 0.0 and m.match_view.sim.pl[0].kind != "serve", 60.0)
		if not ok:
			break
		await _wait_sim(0.10)
		var p0: Vector3 = m.match_view.rigs[0].global_position
		jc.position = p0 + Vector3( - 2.8, 1.5, -1.4)
		jc.look_at(p0 + Vector3(0, 0.95, 0.3))
		jc.current = true
		for k in 3:
			await _grab(out + "/hit_%d_%d.png" % [n, k])
			await _wait_sim(0.06)
		n += 1
	print("CONTACT DONE")
	get_tree().quit()


func _watchtest_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/watch"
	var i: = args.find("--watchtest")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	var cam: = Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	var court: = CourtBuilder.build("hard", true)
	add_child(court)
	var ball: = MeshInstance3D.new()
	var sm: = SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	var bmat: = StandardMaterial3D.new()
	bmat.albedo_color = Color("#c8e030")
	bmat.emission = Color("#c8e030")
	bmat.emission_energy_multiplier = 0.8
	sm.material = bmat
	ball.mesh = sm
	add_child(ball)
	var bw = court.get_node_or_null("BallWatcher")
	print("WATCHTEST BallWatcher: ", bw, " watchers: ", (bw.watchers.size() if bw else -1))
	if bw:
		bw.ball = ball

	ball.global_position = Vector3(5.0, 1.2, 3.0)
	cam.position = Vector3(-4.0, 2.8, CourtBuilder.NZ)
	cam.look_at(Vector3(-7.2, 2.55, CourtBuilder.NZ))
	cam.current = true
	for f in 14:
		await get_tree().process_frame
	await _grab(out + "/watch_umpire_right.png")

	ball.global_position = Vector3(-5.0, 3.0, 22.0)
	for f in 6:
		await get_tree().process_frame
	await _grab(out + "/watch_umpire_left.png")

	ball.global_position = Vector3(5.0, 1.0, 18.0)
	cam.position = Vector3(-5.6, 1.25, -0.4)
	cam.look_at(Vector3(-8.2, 0.72, -3.1))
	for f in 6:
		await get_tree().process_frame
	await _grab(out + "/watch_judge.png")
	get_tree().quit(0)



func _rallyshots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/rally"
	var i: = args.find("--rallyshots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)

	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 2, 40.0)
	print("rally start ok: ", ok)
	for n in 8:
		await _wait_sim(0.28)
		await _grab(out + "/r" + str(n) + ".png")
		print("shot r", n, " state=", m.match_view.sim.state, " hits=", m.match_view.sim.rally_hits, " bally=", snappedf(m.match_view.sim.ball.y, 0.01))
	get_tree().quit(0)


func _arcshot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/arc"
	var i: = args.find("--arcshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 2, 40.0)
	print("arcshot rally ok: ", ok)
	var sim = m.match_view.sim
	var z0: float = sim.ball.z
	var f: = 0
	var cap: = 0
	while cap < 18 and f < 240:
		await _wait_sim(1.0 / 30.0)
		f += 1
		var crossed: bool = (z0 - sim.NZ) * (sim.ball.z - sim.NZ) < 0.0
		if f >= 3 or crossed:
			await _grab(out + "/a" + str(cap) + ".png")
			cap += 1
			print("arc a", cap, " by=", snappedf(sim.ball.y, 0.02), " bz=", snappedf(sim.ball.z, 0.1))
	get_tree().quit(0)


func _movietest_harness(args: Array) -> void :
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 1, 40.0)
	print("movie rally ok: ", ok)
	await _wait_sim(40.0)
	print("movie done hits=", m.match_view.sim.rally_hits)
	get_tree().quit(0)


func _trailshot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/trail"
	var i: = args.find("--trailshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)

	var ok: = await _wait_until( func(): return m.match_view.sim.state == "play" and m.match_view.sim.ball.in_play, 40.0)
	var sim = m.match_view.sim
	sim.ball.x = sim.pl[1].x
	sim.ball.y = 1.4
	sim.ball.z = 16.0
	sim.ball.vx = 0.0
	sim.ball.vy = 0.0
	sim.ball.vz = -2.0
	sim.ball.last = 0
	sim.pl[1].x = 0.0
	sim.pl[1].z = 16.2
	sim.do_hit(sim.pl[1], "smash", true)

	sim.ball.vx = 0.0
	sim.ball.vy = 2.0
	sim.ball.vz = -48.0
	sim.ball.hot = 1.0
	print("trail forced ok: ", ok, " hot=", snappedf(sim.ball.hot, 0.01))
	for n in 3:
		await _grab(out + "/t" + str(n) + ".png")
		print("shot t", n, " hot=", snappedf(m.match_view.sim.ball.hot, 0.01), " bally=", snappedf(m.match_view.sim.ball.y, 0.01))
		await _wait_sim(0.05)
	get_tree().quit(0)





func _v29shots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/v29"
	var i: = args.find("--v29shots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	print("v29 harness start")

	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(3.0)
	var ok: = true
	var sim = m.match_view.sim
	sim.state = "play"
	sim.pl[0].x = 0.5
	sim.pl[0].z = 10.0
	sim.ball.x = 0.5
	sim.ball.y = 1.1
	sim.ball.z = 11.5
	sim.ball.vx = 0.0
	sim.ball.vy = 0.0
	sim.ball.vz = -6.0
	sim.ball.last = 1
	sim.ball.in_play = true
	sim.do_hit(sim.pl[0], "drop", false)
	print("v29 A drop forced ok=", ok)
	await _wait_sim(0.18)
	await _grab(out + "/popup_dejada.png")

	var pev: = InputEventAction.new()
	pev.action = "pause"
	pev.pressed = true
	m.match_view._on_pause_input(pev)
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/pausa_limpia.png")
	print("v29 B pause shot")
	m.match_view._on_pause_input(pev)
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame

	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	ok = await _wait_until( func(): return m.match_view.sim.state == "play", 20.0)
	sim = m.match_view.sim
	sim.ball.in_play = false
	sim.ball.x = -6.0
	sim.ball.y = 0.4
	sim.ball.z = 16.0
	sim.ball.vx = 0.0;sim.ball.vy = 0.0;sim.ball.vz = 0.0
	await _wait_sim(1.0)
	await _grab(out + "/vida_izq.png")
	sim.ball.x = 6.0
	sim.ball.z = 14.0
	await _wait_sim(1.2)
	await _grab(out + "/vida_der.png")
	print("v29 C life shots ok=", ok)
	get_tree().quit(0)

func _judgetest_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/judge"
	var i: = args.find("--judgetest")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.state == "play", 40.0)
	var sim = m.match_view.sim
	print("judgetest play ok: ", ok)

	sim.ball.in_play = false
	sim.ball.x = -6.0
	sim.ball.y = 0.4
	sim.ball.z = -2.0
	sim.ball.vx = 0.0;sim.ball.vy = 0.0;sim.ball.vz = 0.0
	await _wait_sim(0.6)
	await _grab(out + "/j_left.png")

	sim.ball.x = 6.0
	await _wait_sim(0.6)
	await _grab(out + "/j_right.png")
	print("judgetest done")
	get_tree().quit(0)

func _swingshot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/swing"
	var i: = args.find("--swingshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.state == "play" and m.match_view.sim.ball.in_play, 40.0)
	var sim = m.match_view.sim

	sim.pl[0].x = 0.5
	sim.pl[0].z = -14.0
	sim.ball.x = 0.5
	sim.ball.y = 1.1
	sim.ball.z = -11.5
	sim.ball.vx = 0.0
	sim.ball.vy = 0.0
	sim.ball.vz = -6.0
	sim.ball.last = 1
	sim.do_hit(sim.pl[0], "drive", false)
	print("swing forced ok: ", ok)
	for n in 6:
		await _grab(out + "/sw" + str(n) + ".png")
		print("shot sw", n)
		await _wait_sim(0.07)
	get_tree().quit(0)

func _racketshot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/racket"
	var i: = args.find("--racketshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	var root3: = Node3D.new()
	add_child(root3)
	var env: = WorldEnvironment.new()
	var ee: = Environment.new()
	ee.background_mode = Environment.BG_COLOR
	ee.background_color = Color(0.35, 0.42, 0.55)
	ee.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ee.ambient_light_color = Color(0.9, 0.9, 0.95)
	ee.ambient_light_energy = 0.8
	env.environment = ee
	root3.add_child(env)
	var sun: = DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.6, 0.0)
	root3.add_child(sun)
	var fig = PlayerFig.new(0, false)
	root3.add_child(fig)
	var cam: = Camera3D.new()
	root3.add_child(cam)
	cam.current = true
	var views: = [
		[Vector3(0.55, 0.52, 0.45), Vector3(0.3, 0.47, 0.02)], 
		[Vector3(0.18, 0.5, 0.62), Vector3(0.28, 0.45, 0.0)], 
		[Vector3(0.75, 0.5, 0.35), Vector3(0.28, 0.46, 0.0)], 
		[Vector3(0.42, 0.4, 0.42), Vector3(0.28, 0.44, 0.0)], 
	]
	for n in views.size():
		cam.position = views[n][0]
		cam.look_at(views[n][1], Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		await _grab(out + "/rk" + str(n) + ".png")
		print("shot rk", n)
	get_tree().quit(0)


func _careershot_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/m.career"
	var i: = args.find("--careershot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.career = Career.new()
	m.career.new_career("Jugador")
	m.menus.career = m.career
	m.career.start_tournament()
	m._on_career_match()
	await get_tree().process_frame
	await get_tree().process_frame
	var mv = m.match_view
	for n in 4:
		await _wait_sim(1.0)
		await _grab(out + "/c" + str(n) + ".png")
		var p0 = mv.sim.pl[0]
		var p1 = mv.sim.pl[1]
		print("shot c", n, " p0=(", p0.x, ",", p0.z, ") p1=(", p1.x, ",", p1.z, ") rig0pos=", mv.rigs[0].global_position, " rig1pos=", mv.rigs[1].global_position, " rig1vis=", mv.rigs[1].visible, " cpulook=", mv.get_meta("cpu_look", -1), " state=", mv.sim.state)
	get_tree().quit(0)


func _serveshot_harness(args: Array) -> void :

	var out: = "/home/sandbox/godot/shots/serve"
	var i: = args.find("--serveshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.career = Career.new()
	m.career.new_career("Jugador")
	m.menus.career = m.career
	m.career.start_tournament()
	m._on_career_match()
	await get_tree().process_frame
	await get_tree().process_frame
	var mv = m.match_view
	if mv.sim.state != "serve" or mv.sim.M.server != 0:
		print("SERVESHOT: estado inesperado ", mv.sim.state, " server=", mv.sim.M.server)
		get_tree().quit(1)
		return
	mv.sim.toss_ball()
	await _wait_until( func(): return mv.sim.ball.toss_t >= 0.3, 2.0)
	await _grab(out + "/meter_mid.png")
	await _wait_until( func(): return mv.sim.ball.toss_t >= 0.49, 2.0)
	await _grab(out + "/meter_green.png")
	mv.sim.do_serve(mv.sim.pl[0], 0.97)
	mv.drain_events()
	await get_tree().process_frame
	await _grab(out + "/speed.png")
	print("SERVESHOT done, spd event=", mv.hud.speed_label.text)
	get_tree().quit(0)

func _bounceshot_harness(args: Array) -> void :

	var out: = "/home/sandbox/godot/shots/bounce"
	var i: = args.find("--bounceshot")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.career = Career.new()
	m.career.new_career("Jugador")
	m.menus.career = m.career
	m.career.start_tournament()
	m._on_career_match()
	await get_tree().process_frame
	await get_tree().process_frame
	var mv = m.match_view

	var sim = mv.sim
	sim.state = "play"
	sim.ball.in_play = true
	sim.ball.held = false
	sim.ball.toss = false
	sim.ball.bounces = 0
	sim.ball.last = 1
	sim.ball.x = 0.3
	sim.ball.y = 1.2
	sim.ball.z = 15.0
	sim.ball.vx = 0.0
	sim.ball.vy = 0.0
	sim.ball.vz = 0.0
	sim.launch(0.4, 11.885 - 1.6, 1.0, 1.2)
	sim.events.clear()
	var ok: = await _wait_until( func(): return mv.banner_t > 0.0, 6.0)
	print("BOUNCESHOT banner=", ok)
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab(out + "/dosbotes.png")
	print("BOUNCESHOT done")
	get_tree().quit(0)

func _looktest_harness(_args: Array) -> void :
	m.menus.visible = false
	var root3d: = Node3D.new()
	add_child(root3d)
	var cam: = Camera3D.new()
	root3d.add_child(cam)
	cam.position = Vector3(0, 2.0, 7.0)
	cam.look_at(Vector3(0, 1.0, 0))
	var sun: = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root3d.add_child(sun)
	for i in 5:
		var f = PlayerFig.new(i, false)
		f.position = Vector3((i - 2) * 1.7, 0, 0)
		root3d.add_child(f)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _grab("/home/sandbox/godot/shots/looktest.png")
	get_tree().quit(0)

func _v30shots_harness(args: Array) -> void :
	var out: = "/home/sandbox/godot/shots/v30"
	var i: = args.find("--v30shots")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	print("v30 harness start")

	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(3.0)
	var sim = m.match_view.sim
	sim.state = "play"
	sim.M.server = 1
	sim.pl[0].x = -2.0
	sim.pl[0].z = -1.0
	sim.pl[0].vx = 0.0
	sim.pl[0].vz = 0.0
	sim.pl[1].x = 0.0
	sim.pl[1].z = 24.5
	sim.ball.held = false
	sim.ball.serving = false
	sim.ball.in_play = true
	sim.ball.last = 1
	sim.ball.x = 0.9
	sim.ball.y = 1.6
	sim.ball.z = 3.2
	sim.ball.vx = 0.0
	sim.ball.vy = 0.8
	sim.ball.vz = -13.0
	sim.inp.hit = true
	var ok: = await _wait_until( func(): return sim.ball.last == 0, 1.5)
	print("v30 A magnetismo hit=", ok, " px=", sim.pl[0].x)
	await get_tree().process_frame
	await _grab(out + "/magnetismo.png")

	sim.state = "play"
	sim.ball.in_play = false
	sim.ball.held = true
	sim.pl[0].x = 0.0
	sim.pl[0].z = 3.0
	Input.action_press("move_right")
	await _wait_sim(0.8)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await _wait_sim(0.13)
	print("v30 B derrape px=", sim.pl[0].x, " vx=", sim.pl[0].vx)
	await _grab(out + "/derrape.png")
	Input.action_release("move_left")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame

	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(2.0)
	var okp: = await _wait_until( func(): return m.match_view.sim.state == "point", 60.0)
	print("v30 C point ok=", okp)
	if okp:
		await _wait_sim(0.7)
		await _grab(out + "/punto_sin_baile.png")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame

	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(2.5)
	var sim2 = m.match_view.sim
	sim2.state = "serve"
	sim2.M.server = 0
	sim2.serve_stage = "ready"
	sim2.pl[0].x = 1.4
	sim2.pl[0].z = -1.2
	sim2.ball.held = false
	sim2.toss_ball()
	var okq: = await _wait_until( func(): return sim2.ball.toss_t >= 0.5, 2.0)
	print("v30 D meter q peak ok=", okq, " toss_t=", sim2.ball.toss_t)
	await _grab(out + "/saque_medidor.png")
	m.match_view.queue_free()
	m.match_view = null
	await get_tree().process_frame
	print("v30 harness done")
	get_tree().quit()


func _celnight_harness(args: Array) -> void :
	var i: = args.find("--celnight")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/cel"
	var tod: int = int(args[i + 2]) if i + 2 < args.size() else 1
	var surf: String = args[i + 3] if i + 3 < args.size() else "hard"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", surf)
	m.match_view.set_meta("tod", tod)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": surf, "AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(1.0)
	await _grab(out + "/00_start.png")
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 40.0
	jc.position = Vector3(-6.2, 1.5, -6.0)
	jc.look_at(Vector3(-8.0, 0.5, -2.9))
	jc.current = true
	await _grab(out + "/01_judge.png")
	jc.position = Vector3(-4.0, 1.4, 6.0)
	jc.look_at(Vector3(-5.6, 0.5, 20.4))
	jc.position = Vector3(5.0, 1.5, 17.6)
	jc.look_at(Vector3(5.6, 0.5, 21.0))
	await _grab(out + "/02_judge_far.png")
	jc.current = false
	jc.queue_free()
	var got: = {}
	var guard: = 0
	while got.size() < 2 and guard < 40:
		guard += 1
		var okp: = await _wait_until( func(): return m.match_view.sim.state == "point", 60.0)
		if not okp:
			break
		await _wait_sim(0.7)
		var w: int = m.match_view._point_winner
		if not got.has(w):
			got[w] = true
			await _grab(out + "/cel_w" + str(w) + "_a.png")
			await _wait_sim(0.9)
			await _grab(out + "/cel_w" + str(w) + "_b.png")
		await _wait_until( func(): return m.match_view.sim.state != "point", 20.0)
	print("CELNIGHT DONE ", got.keys())
	get_tree().quit()





func _faulttest_harness(args: Array) -> void :
	var sim: = TennisSim.new(false, m.DIFF_PARAMS[1], {"speed": 7.0, "T": 1.0, "err": 1.0}, "CPU", 1)
	sim.surface = "grass"
	sim.start_point()
	var dt: float = 1.0 / 60.0
	sim.inp.hit = true
	sim.update(dt)
	for i in 90:
		sim.update(dt)
		sim.events.clear()
	var ok1: bool = sim.M.pts == [0, 0] and sim.serve_fault == 1 and sim.state == "serve"
	sim.inp.hit = true
	sim.update(dt)
	var saw_serve: = false
	var bad_df: = false
	for i in 40:
		sim.update(dt)
		if sim.serve_stage == "toss" and sim.ball.toss_t > 0.42:
			sim.inp.hit = true
		for ev in sim.events:
			if ev.t == "serve":
				saw_serve = true
				print("SERVE_KMH ", snappedf(ev.get("spd", 0.0) * 3.6, 0.1))
			if ev.t == "point" and ev.get("txt", "") == "DOBLE FALTA" and not saw_serve:
				bad_df = true
		sim.events.clear()
	print("FAULTTEST first_ok=", ok1, " second_serve=", saw_serve, " bad_df=", bad_df)
	get_tree().quit(0 if ok1 and saw_serve and not bad_df else 1)

func _gameshot_harness(args: Array) -> void :
	var i: = args.find("--gameshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/gameshot"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "PS": {"speed": 7.0, "T": 1.0, "err": 1.0}, "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_sim(0.5)
	var sim = m.match_view.sim
	sim.state = "play"
	sim.M.server = 0
	sim.M.pts = [3, 0]
	sim.M.games = [0, 0]
	sim.award_point(0, "PUNTO", "")
	await _wait_sim(0.5)
	await _grab(out + "/00_cut.png")
	await _wait_sim(0.6)
	await _grab(out + "/01_celeb.png")
	print("GAMESHOT DONE")
	get_tree().quit()

func _servepose_harness(args: Array) -> void :
	var i: = args.find("--servepose")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/servepose"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	m.match_view.sim.M.server = 0
	m.match_view.sim.start_point()
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 34.0
	jc.current = true
	await _wait_sim(0.6)
	var p0: Vector3 = m.match_view.rigs[0].global_position
	jc.position = p0 + Vector3(2.4, 1.5, -3.4)
	jc.look_at(p0 + Vector3(0, 1.0, 1.0))
	await _grab(out + "/00_ready.png")
	m.match_view.sim.inp.hit = true
	for n in 10:
		await _wait_sim(0.06)
		await _grab(out + "/toss_%02d.png" % n)
	m.match_view.sim.inp.hit = true
	for n in 10:
		await _wait_sim(0.05)
		await _grab(out + "/hit_%02d.png" % n)
	print("SERVEPOSE DONE")
	get_tree().quit()

func _startshot_harness(args: Array) -> void :
	var i: = args.find("--startshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/st"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 35.0
	jc.current = true
	for fi in 6:
		var p0: Vector3 = m.match_view.rigs[0].global_position
		jc.position = p0 + Vector3(2.2, 0.9, 1.2)
		jc.look_at(p0 + Vector3(0, 0.7, 0))
		await _grab(out + "/f" + str(fi) + ".png")
		for k in 4:
			await get_tree().process_frame
	get_tree().quit()


func _prepshot_harness(args: Array) -> void :
	var i: = args.find("--prepshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/pr"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 40.0
	var n: = 0
	var last: = -1.0
	while n < 6:
		var sim = m.match_view.sim
		var e = sim.pl[0]
		if e.prep_k > 0.3 and e.swing <= 0.0 and e.want_t <= 0.0:
			var p0: Vector3 = m.match_view.rigs[0].global_position
			jc.current = true
			jc.position = p0 + Vector3(3.0, 1.3, 1.0)
			jc.look_at(p0 + Vector3(0, 0.9, 0))
			await _grab(out + "/p" + str(n) + "_k" + str(snappedf(e.prep_k, 0.01)) + ".png")
			n += 1
			for k in 6:
				await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()


func _legshot_harness(args: Array) -> void :
	var i: = args.find("--legshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/lg"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	var court: = CourtBuilder.build("hard", 0)
	add_child(court)
	var f: = PlayerFig.new(0, true)
	add_child(f)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 30.0
	jc.current = true
	f.position = Vector3(0, 0.05, 0)
	for an in ["Idle_Sword", "Run", "Wave", "HitRecieve"]:
		f.ap.play(an)
		f.ap.seek(0.3, true)
		f.ap.advance(0.0)
		f.skel.force_update_all_bone_transforms()
		for ang in [0.0, 1.2]:
			jc.position = Vector3(sin(ang) * 2.2, 0.6, cos(ang) * 2.2)
			jc.look_at(Vector3(0, 0.45, 0))
			for k in 3:
				await get_tree().process_frame
			await _grab(out + "/" + an + "_" + str(ang) + ".png")
	get_tree().quit()


func _rallylabel_harness(args: Array) -> void :
	var i: = args.find("--rallylabel")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/rl.png"
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", ("clay" if args.has("--clay") else "hard"))
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": ("clay" if args.has("--clay") else "hard"), "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 5 and m.match_view.sim.state == "play", 90.0)
	print("ok ", ok)
	await get_tree().process_frame
	await _grab(out)
	get_tree().quit()


func _celshot_harness(args: Array) -> void :
	var i: = args.find("--celshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/cs"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 35.0
	jc.current = true
	for nm in ["Wave", "Punch_Right", "Punch_Left", "Sword_Slash", "HitRecieve", "HitRecieve_2"]:
		var rg = m.match_view.rigs[1]
		rg.celebrate(nm, 3.0)
		for k in 14:
			await get_tree().process_frame
		var p0: Vector3 = rg.global_position
		jc.position = p0 + Vector3(0.0, 1.5, -3.2)
		jc.look_at(p0 + Vector3(0, 1.2, 0))
		await _grab(out + "/" + nm + ".png")
	get_tree().quit()


func _rkshot_harness(args: Array) -> void :
	var i: = args.find("--rkshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/rk"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 30.0
	jc.current = true
	var rg = m.match_view.rigs[0]
	m.match_view.process_mode = Node.PROCESS_MODE_DISABLED
	m.match_view.rigs[1].visible = false
	rg.reparent(self)
	rg.process_mode = Node.PROCESS_MODE_INHERIT
	print("RK ", rg.get_class(), " ", rg.ap.get_animation_list(), " act=", rg.ap.active, " spd=", rg.ap.speed_scale)
	var cases: = [["Punch_Right", 0.2, 0.0, 0.0], ["Punch_Right", 0.6, 0.0, 0.0], ["Punch_Right", 1.0, 0.0, 0.0], ["HitRecieve", 0.2, 0.0, 0.0], ["HitRecieve", 0.6, 0.0, 0.0], ["HitRecieve", 1.0, 0.0, 0.0], ["Wave", 0.3, 0.0, 0.0], ["Wave", 0.8, 0.0, 0.0], ["Wave", 1.4, 0.0, 0.0], ["Idle_Sword", 0.0, 0.0, 0.0], ["Idle", 0.0, 0.0, 0.0], ["Idle_Neutral", 0.0, 0.0, 0.0]]
	var n: = 0
	for c in cases:
		rg.state = ""
		rg._play_seek(c[0], c[1])
		rg.ap.advance(0.3)
		for k in 3:
			rg.ap.pause()
			rg.ap.seek(c[1], true)
			rg.skel.force_update_all_bone_transforms()
			var wi: int = rg.skel.find_bone("Wrist.R")
			rg.racket_node.get_parent().transform = rg.skel.get_bone_global_pose(wi)
			if c[2] == 99.0:
				rg.racket_node.rotation = Vector3(PI, 0.0, 0.0)
			else:
				rg.rk_rest_k = 1.0
				rg.state = c[0]
				rg._rk_rest(0.2)
			await get_tree().process_frame
		var p0: Vector3 = rg.global_position
		jc.position = p0 + Vector3(-4.0, 1.3, -1.8)
		jc.look_at(p0 + Vector3(0, 1.0, 0))
		var wi2: int = rg.skel.find_bone("Wrist.R")
		print("RK wrist ", wi2, " ", (rg.skel.global_transform * rg.skel.get_bone_global_pose(wi2)).origin, " racket ", rg.racket_node.global_position, " ba ", rg.racket_node.get_parent().get_class(), " ", rg.racket_node.get_parent().bone_name)
		print("RK cur ", rg.ap.current_animation, " pos ", rg.ap.current_animation_position)
		await _grab(out + "/%02d_%s_%s.png" % [n, str(c[0]).replace("/", "_"), str(c[1])])
		n += 1
	get_tree().quit()


func _jshot_harness(args: Array) -> void :
	var i: = args.find("--jshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/js"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 40.0
	jc.current = true
	var NZ: = 11.885
	var shots: = [["umpire", Vector3(-7.0, 2.6, NZ), Vector3(-4.0, 3.2, NZ + 3.0)], ["j0", Vector3(-8.0, 0.8, -2.9), Vector3(-6.0, 1.5, -5.0)], ["j2", Vector3(-5.6, 0.8, 26.7), Vector3(-3.5, 1.5, 24.5)]]
	for sh in shots:
		for k in 3:
			await get_tree().process_frame
		jc.position = sh[2]
		jc.look_at(sh[1])
		await _grab(out + "/" + sh[0] + ".png")
	get_tree().quit()


func _seqshot_harness(args: Array) -> void :
	var i: = args.find("--seqshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/sq"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_until( func(): return m.match_view.sim.state == "play", 60.0)
	for n in 14:
		var t0: = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 600:
			await get_tree().process_frame
		var r0 = m.match_view.rigs[0]
		print("RKS ", n, " st=", r0.state, " celeb=", r0.celeb_name, " ", r0.celeb_t, " vis=", r0.racket_node.visible, " k=", r0.rk_rest_k, " rot=", r0.racket_node.rotation, " sim=", m.match_view.sim.state)
		await _grab(out + "/s%02d.png" % n)
		if n == 13:
			var r1 = m.match_view.rigs[0]
			var wi: int = r1.skel.find_bone("Wrist.R")
			print("RKW wrist ", (r1.skel.global_transform * r1.skel.get_bone_global_pose(wi)).origin, " racket ", r1.racket_node.global_position, " fig ", r1.global_position, " rotY ", r1.rotation.y)
			var jc: = Camera3D.new()
			add_child(jc)
			jc.fov = 35.0
			jc.current = true
			for v in [Vector3(0, 1.4, -3.0), Vector3(3.0, 1.4, 0.0), Vector3(-3.0, 1.4, 0.0), Vector3(0, 1.4, 3.0)]:
				jc.position = r1.global_position + v
				jc.look_at(r1.global_position + Vector3(0, 1.0, 0))
				await get_tree().process_frame
				await _grab(out + "/z%d.png" % int(v.x + v.z * 2 + 10))
	get_tree().quit()


func _ppshot_harness(args: Array) -> void :
	var i: = args.find("--ppshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/pp"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	await _wait_until( func(): return m.match_view.sim.state == "point", 90.0)
	print("PP point reached, ball=", m.match_view.sim.ball.x, " ", m.match_view.sim.ball.y, " ", m.match_view.sim.ball.z, " held=", m.match_view.sim.ball.held)
	for n in 6:
		var t0: = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 350:
			await get_tree().process_frame
		print("PP ", n, " sim=", m.match_view.sim.state, " ball=", m.match_view.sim.ball.x, " ", m.match_view.sim.ball.y, " ", m.match_view.sim.ball.z, " vis=", m.match_view.ball_mesh.visible, " scale=", m.match_view.ball_mesh.scale, " pb=", m.match_view._pb_active)
		await _grab(out + "/p%d.png" % n)
	get_tree().quit()


func _cpuserveclose_harness(args: Array) -> void :
	var i: = args.find("--cpuserveclose")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/cpuserveclose"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "PS": {"speed": 7.0, "T": 1.0, "err": 1.0}, "sets_to_win": 1})
	m.match_view.sim.M.server = 1
	m.match_view.sim.prep_serve()
	m.match_view.sim.cpu_serve_at = m.match_view.sim.time + 0.8
	add_child(m.match_view)
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 34.0
	jc.current = true
	var p1: Vector3 = m.match_view.rigs[1].global_position
	jc.position = p1 + Vector3(2.2, 1.5, -4.0)
	jc.look_at(p1 + Vector3(0, 1.0, 0))
	for n in 18:
		await _wait_sim(0.2)
		await _grab(out + "/f%02d.png" % n)
	print("CPUSERVE CLOSE DONE")
	get_tree().quit()

func _cpuserve_harness(args: Array) -> void :
	var i: = args.find("--cpuserve")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/cs2"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	m.match_view.sim.M.server = 1
	m.match_view.sim.prep_serve()
	for n in 6:
		var t0: = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 500:
			await get_tree().process_frame
		print("CS ", m.match_view.sim.state, " ", m.match_view.sim.pl[0].x, " ", m.match_view.sim.pl[1].x, " ball ", m.match_view.sim.ball.x, " ", m.match_view.sim.ball.y, " ", m.match_view.sim.ball.z)
		await _grab(out + "/c%d.png" % n)
	get_tree().quit()

func _latshot_harness(args: Array) -> void :
	var i: = args.find("--latshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/lat"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 1)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	sim.demo = false
	sim.state = "play"
	sim.ball.in_play = true
	sim.ball.serving = false
	sim.ball.x = 3.0;sim.ball.y = 1.0;sim.ball.z = 20.0
	sim.ball.vx = 0.0;sim.ball.vy = 0.0;sim.ball.vz = 3.0
	sim.ball.last = 0;sim.ball.bounces = 1
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 28.0
	jc.current = true
	var shots: = [0.25, 0.45, 0.65, 0.85, 1.05, 1.3, 1.5, 1.7, 1.85, 2.0, 2.2, 2.5]
	var si: = 0
	var t: = 0.0
	var dt: = 1.0 / 60.0
	while t < 2.6:

		Input.action_release("move_left");Input.action_release("move_right")
		if t < 1.3:
			Input.action_press("move_right")
		elif t >= 1.7:
			Input.action_press("move_left")
		sim.demo = false
		if sim.state != "play":
			sim.state = "play"
			sim.ball.in_play = true
			sim.ball.serving = false
			sim.ball.x = 3.0;sim.ball.y = 1.0;sim.ball.z = 20.0
			sim.ball.vx = 0.0;sim.ball.vy = 0.0;sim.ball.vz = 3.0
			sim.ball.last = 0;sim.ball.bounces = 1
		await get_tree().process_frame
		t += dt
		var e = sim.pl[0]
		var rg = m.match_view.rigs[0]
		var p0: Vector3 = rg.global_position
		jc.position = Vector3(p0.x, 1.6, p0.z - 4.2)
		jc.look_at(p0 + Vector3(0, 1.0, 0))
		print("LAT t=%.2f x=%.2f vx=%.2f vz=%.2f sp=%.2f rotY=%.2f anim=%s" % [t, e.x, e.vx, e.vz, e.speed, rg.rotation.y, rg.get("state")])
		if si < shots.size() and t >= shots[si]:
			await _grab(out + ("/f%02d_t%.2f.png" % [si, t]))
			si += 1
	get_tree().quit()

func _ballshot_harness(args: Array) -> void :
	var i: = args.find("--ballshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/bs"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	sim.M.server = 1
	sim.prep_serve()
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 35.0
	jc.current = true
	var NZ: = 11.885
	jc.position = Vector3(2.5, 2.2, NZ + 13.8 + 3.5)
	jc.look_at(Vector3(0.0, 1.6, NZ + 11.0))
	var t0: = Time.get_ticks_msec()
	var n: = 0
	while n < 16:
		while Time.get_ticks_msec() - t0 < 300 * (n + 1):
			await get_tree().process_frame
		var mv = m.match_view
		print("BS n=%d state=%s held=%s toss=%s by=%.2f vis=%.2f far=%.2f scale=%.2f" % [n, sim.state, sim.ball.held, sim.ball.toss, sim.ball.y, mv.ball_vis_scale, mv.far_ball_k(jc.global_position.distance_to(mv.ball_mesh.global_position)), mv.ball_mesh.scale.x])
		await _grab(out + "/b%d.png" % n)
		n += 1
	get_tree().quit()

func _topshot_harness(args: Array) -> void :
	var i: = args.find("--topshot")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/ts"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[0], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	sim.M.server = 1
	sim.prep_serve()
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 22.0
	jc.current = true
	var NZ: = 11.885
	jc.position = Vector3(0.0, 20.0, -0.5)
	jc.look_at(Vector3(0.0, 0.0, -0.55))
	var t0: = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 700:
		await get_tree().process_frame
	print("TS rec x=", sim.pl[0].x, " z=", sim.pl[0].z)
	await _grab(out + "/top.png")
	get_tree().quit()

func _audit169_harness(args: Array) -> void :
	var i: = args.find("--audit169")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/a169"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	var t0: = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 900:
		await get_tree().process_frame

	sim.state = "serve";sim.state_t = 0.0;sim.M.server = 0;sim.prep_serve()
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 400:
		await get_tree().process_frame
	sim.inp.hit = true
	t0 = Time.get_ticks_msec()
	while not (sim.serve_stage == "toss" and sim.ball.toss_t >= 0.32) and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
	await _grab(out + "/a1_toss.png")
	t0 = Time.get_ticks_msec()
	while sim.serve_stage != "hit" and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120:
		await get_tree().process_frame
	await _grab(out + "/a2_strike.png")

	for attempt in 4:
		sim.state = "serve";sim.state_t = 0.0;sim.M.server = 1;sim.prep_serve()
		sim.inp.hit = false
		var ts0: float = sim.time
		while sim.ball.last != 1 and sim.state == "serve" and sim.time - ts0 < 6.0:
			var tx0: float = - sim.pl[1].x
			if tx0 - sim.pl[0].x < -0.5:
				Input.action_release("move_right")
				Input.action_press("move_left")
			elif tx0 - sim.pl[0].x > 0.5:
				Input.action_release("move_left")
				Input.action_press("move_right")
			else:
				Input.action_release("move_left")
				Input.action_release("move_right")
			await get_tree().process_frame
		Input.action_press("hit")
		var ts1: float = sim.time
		while sim.ball.last != 0 and (sim.state == "serve" or sim.state == "play") and sim.time - ts1 < 4.0:
			var dx2: float = sim.ball.x - sim.pl[0].x
			if dx2 < -0.4:
				Input.action_release("move_right")
				Input.action_press("move_left")
			elif dx2 > 0.4:
				Input.action_release("move_left")
				Input.action_press("move_right")
			else:
				Input.action_release("move_left")
				Input.action_release("move_right")
			await get_tree().process_frame
		Input.action_release("hit")
		Input.action_release("move_left")
		Input.action_release("move_right")
		if sim.ball.last == 0:
			break
		print("RET attempt ", attempt, " missed (state=", sim.state, " last=", sim.ball.last, ")")
		await get_tree().process_frame
	await _grab(out + "/b1_return_contact.png")
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 350:
		await get_tree().process_frame
	await _grab(out + "/b2_return_flight.png")
	print("RET last=", sim.ball.last, " state=", sim.state, " rally_hits=", sim.rally_hits)

	sim.state = "serve";sim.state_t = 0.0;sim.M.server = 0;sim.prep_serve()
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 400:
		await get_tree().process_frame
	var abx: float = 2.2
	var abz: float = sim.L - 6.0
	sim.events.append({"t": "serve", "id": 0, "q": 0.95, "spd": 53.0})
	await get_tree().physics_frame
	await get_tree().physics_frame
	sim.events.append({"t": "bounce", "x": abx, "z": abz, "v": 0.9})
	await get_tree().physics_frame
	await get_tree().physics_frame
	sim.rally_hits = 1
	sim.events.append({"t": "point", "w": 0, "txt": "PUNTO"})
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 450:
		await get_tree().process_frame
	await _grab(out + "/c1_ace.png")
	print("ACE srv_bounce_ok=", m.match_view._srv_bounce_ok, " pos=", m.match_view._srv_bounce)

	sim.state = "serve";sim.state_t = 0.0;sim.M.server = 1;sim.prep_serve()
	sim.pl[0].x = 4.6;sim.pl[0].z = 0.5
	sim.serve_fault = 0
	sim.fault("Fuera del cuadro")
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2200:
		await get_tree().process_frame
	await _grab(out + "/d1_second_serve.png")
	print("2ND rec x=", snappedf(sim.pl[0].x, 2), " z=", snappedf(sim.pl[0].z, 2), " fault=", sim.serve_fault)
	get_tree().quit()

func _cap171_harness(args: Array) -> void :
	var i: = args.find("--cap171")
	var out: String = args[i + 1] if i + 1 < args.size() else "/tmp/cap171"
	DirAccess.make_dir_recursive_absolute(out)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "clay")
	m.match_view.set_meta("tod", 0)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var mv = m.match_view
	var sim = mv.sim
	var t0: = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 900:
		await get_tree().process_frame
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 35.0
	jc.current = true
	var rg = mv.rigs[1]
	sim.state = "point";sim.state_t = 0.0
	rg.celebrate("Wave", 1.6)
	for k in 84:
		await get_tree().process_frame
	var p0: Vector3 = rg.global_position
	jc.position = p0 + Vector3(-1.2, 1.6, -3.0)
	jc.look_at(p0 + Vector3(0, 1.1, 0))
	await _grab(out + "/b2_wave_mid.png")
	for k in 18:
		await get_tree().process_frame
	await _grab(out + "/b2_wave_tail.png")
	rg.celebrate("HitRecieve_2", 1.3)
	for k in 30:
		await get_tree().process_frame
	jc.position = p0 + Vector3(1.2, 1.5, -3.0)
	jc.look_at(p0 + Vector3(0, 1.0, 0))
	await _grab(out + "/b2_fric_mid.png")
	for k in 51:
		await get_tree().process_frame
	await _grab(out + "/b2_fric_tail.png")
	jc.queue_free()
	sim.state = "point";sim.state_t = 0.0;rg.celeb_t = 0.0
	mv.spawn_skid(Vector3(1.5, 0.0, 3.0), 2.0, -3.0)
	mv.spawn_skid(Vector3(-2.0, 0.0, 5.0), -2.5, -2.0)
	for k in 20:
		await get_tree().process_frame
	await _grab(out + "/b5_skid.png")
	sim.M.pts = [0, 0]
	sim.state = "serve";sim.state_t = 0.0;sim.M.server = 1;sim.prep_serve();sim.cpu_serve_at = sim.time + 0.1
	t0 = Time.get_ticks_msec()
	while sim.serve_stage != "hit" and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	await _grab(out + "/b6_rec_deuce.png")
	sim.M.pts = [0, 1]
	sim.state = "serve";sim.state_t = 0.0;sim.M.server = 1;sim.prep_serve();sim.cpu_serve_at = sim.time + 0.1
	t0 = Time.get_ticks_msec()
	while sim.serve_stage != "hit" and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	await _grab(out + "/b6_rec_ad.png")
	print("CAP171_DONE rec.x deuce=", sim.pl[0].x)
	get_tree().quit()

func _audit173_harness(args: Array) -> void :
	var out: = "/tmp/audit173"
	var i: = args.find("--audit173")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_physics_steps_per_frame = 480
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	var hud = m.match_view.hud
	var tick: = 0
	sim.M.server = 1
	sim.prep_serve()
	var contact_tick: = -1
	var f1_shot: = 0
	var retries: = 0
	var f1_done: = false
	while not f1_done and retries < 8:
		await get_tree().physics_frame
		tick += 1
		var b = sim.ball
		var pl = sim.pl[0]
		if b.in_play and b.last == 1 and b.vz < 0.0:
			if b.x - pl.x > 0.3:
				Input.action_press("move_right")
			elif b.x - pl.x < -0.3:
				Input.action_press("move_left")
			else:
				Input.action_release("move_right")
				Input.action_release("move_left")
			if b.z < 5.0 and b.z > -1.0 and absf(b.x - pl.x) < 0.8 and pl.swing <= 0.0:
				Input.action_press("hit")
				await get_tree().physics_frame
				tick += 1
				Input.action_release("hit")
		if b.in_play and b.last == 0 and contact_tick < 0:
			contact_tick = tick
			Input.action_release("move_right")
			Input.action_release("move_left")
			print("CONTACTO A: vx=", snappedf(b.vx, 0.1), " vy=", snappedf(b.vy, 0.1), " vz=", snappedf(b.vz, 0.1))
		if contact_tick >= 0 and tick - contact_tick == 8 and f1_shot == 0:
			f1_shot = 1
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/01_retorno_A_vuelo.png")
			m.match_view.set_physics_process(true)
		if contact_tick >= 0 and tick - contact_tick >= 34 and f1_shot == 1:
			f1_shot = 2
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/02_retorno_A_tras_bote.png")
			m.match_view.set_physics_process(true)
			f1_done = true
		if sim.state == "point" and contact_tick < 0:
			retries += 1
			sim.M.server = 1
			sim.prep_serve()
		if tick > 6000 and contact_tick < 0:
			retries += 1
			sim.M.server = 1
			sim.prep_serve()
			tick = 0
	Input.action_release("move_right")
	Input.action_release("move_left")
	print("FASE1 ", "OK" if f1_done else "FALLO", " retries=", retries)
	if FileAccess.file_exists(out + "/04_let_banner_oculto.png"):
		print("FASE2 ya capturada, fin")
		get_tree().quit(0)
		return
	sim.M.server = 0
	sim.prep_serve()
	var serves: = 0
	var let_injected: = false
	var toss_armed: = false
	var banner_grabbed: = false
	var hide_tick: = -1
	var ticks2: = 0
	while true:
		await get_tree().physics_frame
		ticks2 += 1
		var b2 = sim.ball
		if sim.state != "serve" and sim.state != "over":
			sim.M.server = 0
			sim.prep_serve()
			sim.state = "serve"
		if sim.state == "serve" and sim.M.server != 0:
			sim.M.server = 0
			sim.prep_serve()
		if ticks2 % 300 == 0:
			print("WD2 t=", ticks2, " state=", sim.state, " stage=", sim.serve_stage, " held=", b2.held, " toss=", b2.toss, " serves=", serves)
		if sim.state == "serve" and sim.M.server == 0:
			if b2.held and not toss_armed:
				Input.action_press("hit")
				await get_tree().physics_frame
				ticks2 += 1
				Input.action_release("hit")
				toss_armed = true
			elif b2.toss and toss_armed and b2.toss_t >= 0.45 and not let_injected:
				Input.action_press("hit")
				await get_tree().physics_frame
				ticks2 += 1
				Input.action_release("hit")
				let_injected = true
				serves += 1

				sim.events.append({"t": "let"})
			elif b2.in_play and b2.last == 0 and toss_armed:
				toss_armed = false
				serves += 1
				print("SAQUE ", serves, " vz=", snappedf(b2.vz, 0.1), " vy=", snappedf(b2.vy, 0.1))
		if sim.state == "serve" and not b2.held and not b2.toss and not b2.in_play:
			toss_armed = false
		if not banner_grabbed and hud.banner.text == "LET" and hud.banner.modulate.a > 0.9:
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/03_let_banner.png")
			m.match_view.set_physics_process(true)
			banner_grabbed = true
			hide_tick = ticks2
			print("LET (evento inyectado) visto")
		if banner_grabbed and hide_tick >= 0 and ticks2 - hide_tick >= 110:
			await _grab(out + "/04_let_banner_oculto.png")
			print("LET AUTO-OCULTO OK")
			get_tree().quit(0)
			return
		if ticks2 > 3000 and not banner_grabbed:
			print("NO RESAQUE en ", ticks2, " ticks")
			get_tree().quit(1)
			return
		if ticks2 > 120000:
			print("TIMEOUT fase2 serves=", serves, " let=", banner_grabbed)
			get_tree().quit(1)
			return

func _gday_harness(args: Array) -> void :
	print("GDAY: enter")
	var out: = "/tmp/gday177"
	var i: = args.find("--gday")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	var m = get_parent()
	print("GDAY: parent=", m.name)
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TÚ")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	m.add_child(m.match_view)
	print("GDAY: match added, waiting sim")
	await _wait_sim(2.2)
	print("GDAY: sim waited, grabbing")
	await _grab(out + "/01_saque_hierba_dia.png")
	print("GDAY: grab1 done")
	var ok: = await _wait_until( func(): return m.match_view.sim.rally_hits >= 3, 25.0)
	print("gday rally ok: ", ok, " hits=", m.match_view.sim.rally_hits)
	await _grab(out + "/02_rally_hierba_dia.png")
	get_tree().quit(0 if ok else 1)

func _matchmovie_harness(args: Array) -> void :
	var dur: = 100.0
	var i: = args.find("--matchmovie")
	if i + 1 < args.size():
		dur = float(args[i + 1])
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU · NORMAL")
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var t: = 0.0
	while t < dur:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	print("matchmovie done hits=", m.match_view.sim.rally_hits, " state=", m.match_view.sim.state)
	get_tree().quit(0)

func _windupchk_harness(args: Array) -> void :
	var out: = "/tmp/windupchk"
	var i: = args.find("--windupchk")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_physics_steps_per_frame = 480
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "hard")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.set_meta("my_name", "TU")
	m.match_view.set_meta("cpu_label", "CPU")
	m.match_view.setup({"AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	sim.M.server = 1
	sim.prep_serve()
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 40.0
	jc.current = true
	var phase: = 0
	var hold_t: = 0
	var ticks: = 0
	while phase < 2 and ticks < 4000:
		await get_tree().physics_frame
		ticks += 1
		var b = sim.ball
		var pl = sim.pl[0]
		if b.in_play and b.last == 1 and b.vz < 0.0:
			if b.x - pl.x > 0.3:
				Input.action_press("move_right")
			elif b.x - pl.x < -0.3:
				Input.action_press("move_left")
			else:
				Input.action_release("move_right")
				Input.action_release("move_left")
		if phase == 0 and b.in_play and b.last == 1 and b.vz < 0.0 and b.z < 4.0 and b.z > 1.8:
			var p0: Vector3 = m.match_view.rigs[0].global_position
			jc.position = p0 + Vector3(1.4, 1.5, -2.6)
			jc.look_at(p0 + Vector3(0, 1.0, 0))
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/01_sin_input.png")
			m.match_view.set_physics_process(true)
			Input.action_release("move_right")
			Input.action_release("move_left")
			Input.action_press("hit")
			phase = 1
			print("WINDUPCHK fase1 ok z=", snappedf(b.z, 0.1))
		elif phase == 1:
			hold_t += 1
			if hold_t >= 14:
				var p1: Vector3 = m.match_view.rigs[0].global_position
				jc.position = p1 + Vector3(1.4, 1.5, -2.6)
				jc.look_at(p1 + Vector3(0, 1.0, 0))
				m.match_view.set_physics_process(false)
				await get_tree().process_frame
				await get_tree().process_frame
				await _grab(out + "/02_con_carga.png")
				Input.action_release("hit")
				phase = 2
				print("WINDUPCHK fase2 ok charging=", pl.charging, " charge=", snappedf(pl.charge, 0.01))
	Input.action_release("hit")
	Input.action_release("move_right")
	Input.action_release("move_left")
	get_tree().quit(0 if phase == 2 else 1)

func _prepcheck_harness(args: Array) -> void :
	var out: = "/tmp/prepcheck"
	var i: = args.find("--prepcheck")
	if i + 1 < args.size():
		out = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_physics_steps_per_frame = 480
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.set_meta("cpu_look", 2)
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	var sim = m.match_view.sim
	var jc: = Camera3D.new()
	add_child(jc)
	jc.fov = 42.0
	jc.current = true
	var got: = 0
	var ticks: = 0
	while got < 2 and ticks < 9000:
		await get_tree().physics_frame
		ticks += 1
		var b = sim.ball
		var cpu = sim.pl[1]
		if got == 0 and b.in_play and b.last == 0 and b.vz > 0.0 and cpu.prep_k > 0.45 and cpu.speed <= 2.2 and cpu.swing <= 0.0:
			var p0: Vector3 = m.match_view.rigs[1].global_position
			jc.position = p0 + Vector3(-3.0, 1.3, 0.4)
			jc.look_at(p0 + Vector3(0, 1.0, 0))
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/01_cpu_prep.png")
			m.match_view.set_physics_process(true)
			got = 1
			print("PREPCHECK cpu prep_k=", snappedf(cpu.prep_k, 0.01), " speed=", snappedf(cpu.speed, 0.1))
		elif got == 1 and b.in_play and b.last == 1 and b.vz < 0.0 and sim.pl[0].prep_k > 0.45 and sim.pl[0].speed <= 2.2 and sim.pl[0].swing <= 0.0:
			var p1: Vector3 = m.match_view.rigs[0].global_position
			jc.position = p1 + Vector3(1.5, 1.5, -2.8)
			jc.look_at(p1 + Vector3(0, 1.0, 0))
			m.match_view.set_physics_process(false)
			await get_tree().process_frame
			await get_tree().process_frame
			await _grab(out + "/02_near_prep.png")
			m.match_view.set_physics_process(true)
			got = 2
			print("PREPCHECK near prep_k=", snappedf(sim.pl[0].prep_k, 0.01))
	get_tree().quit(0 if got == 2 else 1)

func _pose178_harness(args: Array) -> void :
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.setup({"demo": true, "AIP": m.DIFF_PARAMS[1]})
	add_child(m.match_view)
	m.match_view.set_physics_process(false)
	var rig = m.match_view.rigs[1]
	var sim = m.match_view.sim
	var e = sim.pl[1]
	e.x = 0.0;e.z = 22.0;e.speed = 0.0;e.swing = 0.0
	e.prep_t = 0.25;e.prep_k = 0.7;e.want = "drive"
	rig.update_from_sim(e, 0.1)
	var cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(-3.0, 1.4, 22.4)
	cam.look_at(Vector3(0, 1.0, 22.0));cam.current = true
	DirAccess.make_dir_recursive_absolute("/tmp/poses178")
	for t in [0.18, 0.28, 0.38, 0.48]:
		rig.ap.play("mocap/Derecha", 0.0)
		rig.ap.seek(t, true)
		await _grab("/tmp/poses178/t" + str(t) + ".png")
	get_tree().quit()

func _net178_harness(args: Array) -> void :
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.setup({"demo": true, "AIP": m.DIFF_PARAMS[1]})
	add_child(m.match_view)
	m.match_view.set_physics_process(false)
	var sim = m.match_view.sim
	var b = sim.ball
	sim.state = "play";sim.serve_unreturned = false
	b.held = false;b.toss = false;b.in_play = true;b.serving = false
	b.x = 0.8;b.z = sim.NZ - 0.1;b.y = 0.7;b.vx = 0.4;b.vy = 0.0;b.vz = 15.0;b.last = 0
	var cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(4.0, 2.1, sim.NZ - 4.0)
	cam.look_at(Vector3(0.8, 0.3, sim.NZ));cam.current = true
	DirAccess.make_dir_recursive_absolute("/tmp/net178")
	for f in 90:
		sim.step_ball(1.0 / 60.0)
		b.hot = 0.0
		m.match_view.ball_mesh.position = Vector3(b.x, b.y, b.z)
		if f in [0, 30, 60, 89]:
			print("NET178 f=", f, " y=", b.y, " z=", b.z, " state=", sim.state, " pts=", sim.M.pts)
			await _grab("/tmp/net178/f" + str(f) + ".png")
	get_tree().quit()

func _full178_harness(args: Array) -> void :
	m.menus.visible = false
	m.match_view = MatchView.new()
	m.match_view.set_meta("surface", "grass")
	m.match_view.set_meta("day", true)
	m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
	add_child(m.match_view)
	m.match_view.set_physics_process(false)
	seed(178178)
	var sim = m.match_view.sim
	var pts = 0
	var ticks = 0
	var last_sample = -1
	var was_point = false
	DirAccess.make_dir_recursive_absolute("/tmp/full178")
	while ticks < 240000 and not sim.match_over:
		ticks += 1
		m.match_view._physics_process(1.0 / 60.0)
		if sim.state == "point" and not was_point:
			pts += 1
			print("FULL178 POINT ", pts, " hits=", sim.rally_hits, " games=", sim.M.games, " pts=", sim.M.pts)
		was_point = sim.state == "point"

		if pts in [0, 3, 7, 12, 18, 25, 35, 45, 55] and sim.state == "play" and sim.rally_hits >= 4 and pts != last_sample:
			last_sample = pts
			for j in 4:
				await _grab("/tmp/full178/p" + str(pts) + "_f" + str(j) + ".png")
				for f in 6: m.match_view._physics_process(1.0 / 60.0)

	print("FULL178 DONE match_over=", sim.match_over, " ticks=", ticks, " points=", pts, " sets=", sim.M.sets, " games=", sim.M.games)
	get_tree().quit()
