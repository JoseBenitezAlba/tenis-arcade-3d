class_name DebugHarness
extends Node



var m

const EARLY_RETURN: = ["--simtest", "--servespeed", "--careertest", "--trainshots", "--tourneytest"]
const LATE: = {
	"--serveshot": "_serveshot_harness", "--bounceshot": "_bounceshot_harness", 
	"--racketshot": "_racketshot_harness", "--swingshot": "_swingshot_harness", 
	"--judgetest": "_judgetest_harness", "--v29shots": "_v29shots_harness", 
	"--v30shots": "_v30shots_harness", "--trailshot": "_trailshot_harness", 
	"--rallyshots": "_rallyshots_harness", "--courtshot": "_courtshot_harness", 
	"--watchtest": "_watchtest_harness", "--boardcheck": "_boardcheck_harness", 
	"--closeup": "_closeup_harness", "--replayshots": "_replayshots_harness", 
	"--looktest": "_looktest_harness", "--careershot": "_careershot_harness", 
	"--faceshots": "_faceshots_harness", "--matchprobe": "_matchprobe_harness", 
	"--shots": "_shots_harness", 
	"--celnight": "_celnight_harness", "--startshot": "_startshot_harness", "--prepshot": "_prepshot_harness", "--legshot": "_legshot_harness", "--rallylabel": "_rallylabel_harness", "--celshot": "_celshot_harness", 
	"--v31shots": "_v31shots", 
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
	for flag in LATE:
		if args.has(flag):
			call_deferred(LATE[flag], args)
			return true
	return false

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
	for nm in ["Wave", "Punch_Right", "HitRecieve"]:
		var rg = m.match_view.rigs[1]
		rg.celebrate(nm, 3.0)
		for k in 14:
			await get_tree().process_frame
		var p0: Vector3 = rg.global_position
		jc.position = p0 + Vector3(0.0, 1.5, -3.2)
		jc.look_at(p0 + Vector3(0, 1.2, 0))
		await _grab(out + "/" + nm + ".png")
	get_tree().quit()
