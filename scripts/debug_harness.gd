class_name DebugHarness
extends Node

# v0.31: harnesses de test/capturas extraidos de main.gd. Solo se usan con flags CLI.
# m = escena principal (sin tipo: acceso dinamico a sus miembros).
var m

const EARLY_RETURN := ["--simtest", "--servespeed", "--careertest", "--trainshots", "--tourneytest"]
const LATE := {
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
    "--v31shots": "_v31shots",
}

# Devuelve true si main debe cortar su _ready (el harness corre y termina solo).
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
        _menushots(args)  # sin return: main sigue y crea menus (comportamiento original)
    if args.has("--tourneytest"):
        _tourneytest()
        return true
    return false

# Tras crear los menus: lanza el harness en deferred si hay flag. True si hubo match.
func run_late(args: Array) -> bool:
    for flag in LATE:
        if args.has(flag):
            call_deferred(LATE[flag], args)
            return true
    return false

func _careertest() -> void:
    randomize()
    var c := Career.new()
    c.new_career("Test")
    # temporada completa: ganar todos los partidos
    for t in Career.CAL.size():
        c.start_tournament()
        var T: Dictionary = Career.TIERS[Career.CAL[c.data.tIdx].t]
        for r in T.rounds:
            var opp: Dictionary = c.current_opp()
            if opp.is_empty():
                print("ERROR: rival vacio t=", t, " r=", r)
                get_tree().quit(1)
            var res := c.on_career_end(true)
            print("T", t + 1, " R", r + 1, " vs ", opp.n.left(18), " -> ", res.msg.left(80))
    print("temporada fin: rank=", c.my_rank(), " pts=", c.data.pts, " titulos=", c.data.titles, " tIdx=", c.data.tIdx)
    c.end_season()
    # save/load roundtrip
    var c2 := Career.load_saved()
    if c2 == null or c2.data.name != "Test" or c2.data.season != 2:
        print("ERROR save/load")
        get_tree().quit(1)
    # derrota en primera ronda de la nueva temporada
    c2.start_tournament()
    var res2 := c2.on_career_end(false)
    print("derrota ok: ", res2.msg.left(90), " | hist=", c2.data.hist.size(), " tour null: ", c2.data.tour == null)
    # stats upgrade
    c2.data.free = 2
    var pw0: int = c2.data.stats.pw
    c2.data.stats.pw += 1
    c2.save()
    print("stats pw ", pw0, "->", c2.data.stats.pw)
    Career.delete_save()
    print("CAREER TEST OK")
    get_tree().quit(0)

# ---------- TEST: simulacion sin render ----------
func _simtest(args: Array) -> void:
    var secs := 120.0
    var i := args.find("--simtest")
    if i + 1 < args.size() and args[i + 1].is_valid_float():
        secs = args[i + 1].to_float()
    var sim := TennisSim.new(true, m.DIFF_PARAMS[1], {}, "CPU", 1)
    var dt := 1.0 / 120.0
    var t := 0.0
    var last_score := ""
    while t < secs and not sim.match_over:
        sim.update(dt)
        t += dt
        for ev in sim.events:
            if ev.t == "point":
                print("PUNTO w=", ev.w, " ", ev.txt, " | pts=", sim.M.pts, " games=", sim.M.games, " sets=", sim.M.sets, " t=", snapped(t, 0.01))
        sim.events.clear()
    print("FIN SIM: sets=", sim.M.sets, " games=", sim.M.games, " pts=", sim.M.pts, " over=", sim.match_over, " t=", snapped(t, 0.1))
    get_tree().quit(0)

func _servespeed() -> void:
    # medicion de velocidades de saque para calibrar el marcador km/h (v0.27)
    var sim := TennisSim.new(false, m.DIFF_PARAMS[1], {}, "CPU", 1)
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

func _training_shots(out: String) -> void:
    # minijuego de entrenamiento: punteria + saque en vuelo + latas caidas
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

func _trainshots(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--trainshots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    for fi in 10:
        await get_tree().process_frame
    await _training_shots(out)
    get_tree().quit(0)

# ---------- TEST: capturas de menús ----------
func _v31shots(args: Array) -> void:
    # v0.31: captura de la pantalla de carrera con el roster parodia
    var out := "/home/sandbox/godot/shots/v31"
    var i := args.find("--v31shots")
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

func _menushots(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--menushots")
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

func _tourneytest() -> void:
    m.sfx = SoundKit.new()
    add_child(m.sfx)
    m.menus = GameMenus.new(m.sfx)
    add_child(m.menus)
    await get_tree().process_frame
    var fails := 0
    # camino victoria completa
    m._tourney_new()
    if m.tourney.alive.size() != 8:
        print("FAIL alive inicial = ", m.tourney.alive.size()); fails += 1
    if m.tourney.bracket_text.size() != 4:
        print("FAIL bracket inicial = ", m.tourney.bracket_text.size()); fails += 1
    for r in 3:
        m._tourney_resolve(true, {"sets": [2 if r == 2 else 1, 0]})
    if not m.tourney.done or m.tourney.champion != "TÚ":
        print("FAIL campeon: done=", m.tourney.done, " champ=", m.tourney.champion); fails += 1
    print("WIN-PATH champ=", m.tourney.champion, " results=", m.tourney.results.size())
    # camino derrota en cuartos
    m._tourney_new()
    m._tourney_resolve(false, {"sets": [0, 1]})
    if not m.tourney.done or not m.tourney.eliminated or m.tourney.champion == "" or m.tourney.champion == "TÚ":
        print("FAIL eliminacion: done=", m.tourney.done, " elim=", m.tourney.eliminated, " champ=", m.tourney.champion); fails += 1
    print("LOSE-PATH champ=", m.tourney.champion, " eliminated=", m.tourney.eliminated)
    # reduccion de cuadro ronda a ronda
    m._tourney_new()
    m._tourney_resolve(true, {"sets": [1, 0]})
    if m.tourney.alive.size() != 4 or m.tourney.round != 1:
        print("FAIL semis: alive=", m.tourney.alive.size(), " round=", m.tourney.round); fails += 1
    if m.tourney.bracket_text.size() != 2:
        print("FAIL bracket semis = ", m.tourney.bracket_text.size()); fails += 1
    m._tourney_resolve(true, {"sets": [1, 0]})
    if m.tourney.alive.size() != 2 or m.tourney.round != 2:
        print("FAIL final: alive=", m.tourney.alive.size(), " round=", m.tourney.round); fails += 1
    if fails == 0:
        print("TOURNEYTEST OK")
    else:
        print("TOURNEYTEST FAILS=", fails)
    get_tree().quit(0 if fails == 0 else 1)

# ---------- TEST: capturas con render ----------
func _shots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--shots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    for fi in 30:
        await get_tree().process_frame
    print("m.menus visible=", m.menus.visible, " size=", m.menus.size, " root_box children=", m.menus.root_box.get_child_count(), " bg=", m.menus.get_child_count())
    await _grab(out + "/01_menu.png")

    await _training_shots(out)

    # partido demo (IA vs IA) en arcilla
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
    var ok := await _wait_until(func(): return m.match_view.sim.rally_hits >= 3, 30.0)
    print("rally ok: ", ok, " hits=", m.match_view.sim.rally_hits)
    await _grab(out + "/03_rally_arcilla.png")
    ok = await _wait_until(func(): return m.match_view.sim.rally_hits >= 6, 30.0)
    print("rally6 ok: ", ok, " hits=", m.match_view.sim.rally_hits)
    await _grab(out + "/04_rally_arcilla2.png")
    var okp := await _wait_until(func(): return m.match_view.sim.state == "point", 60.0)
    print("point ok: ", okp)
    if okp:
        await _wait_sim(0.6)
        await _grab(out + "/04b_celebracion.png")
    m.match_view.queue_free()
    m.match_view = null
    await get_tree().process_frame

    # demo en pista dura
    m.match_view = MatchView.new()
    m.match_view.set_meta("surface", "hard")
    m.match_view.set_meta("cpu_look", 3)
    m.match_view.set_meta("my_name", "TÚ")
    m.match_view.set_meta("cpu_label", "CPU · NORMAL")
    m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(m.match_view)
    await _wait_sim(2.4)
    await _grab(out + "/05_saque_dura.png")
    ok = await _wait_until(func(): return m.match_view.sim.rally_hits >= 4, 30.0)
    print("rally hard ok: ", ok)
    await _grab(out + "/06_rally_dura.png")
    m.match_view.queue_free()
    m.match_view = null
    await get_tree().process_frame

    # pantallas de carrera
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



func _faceshots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--faceshots")
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

func _matchprobe_harness(args: Array) -> void:
    # Sonda rapida de escena de partido SIN simulacion: construye el MatchView,
    # congela fisica de inmediato y captura vistas. ~segundos en llvmpipe.
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--matchprobe")
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
    # vista broadcast por defecto (la camara que pone el juego)
    await _grab(out + "/mp1_broadcast.png")
    # vista lateral a nivel de pista (zona silla arbitro / banquillos)
    m.match_view.cam.position = Vector3(10.5, 2.2, 0.0)
    m.match_view.cam.look_at(Vector3(0, 1.0, 0))
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/mp2_lateral.png")
    # vista detras de la linea de fondo
    m.match_view.cam.position = Vector3(0, 2.6, -13.5)
    m.match_view.cam.look_at(Vector3(0, 1.0, 2.0))
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/mp3_fondo.png")
    print("MATCHPROBE DONE")
    get_tree().quit(0)

func _replayshots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--replayshots")
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
    var okr := await _wait_until(func(): return m.match_view.sim.rally_hits >= 5, 600.0)
    print("REPLAY rally ok: ", okr, " hits=", m.match_view.sim.rally_hits)
    if okr:
        m.match_view.sim.award_point(0, "PUNTO", "test")
    var ok := await _wait_until(func(): return m.match_view.replaying, 120.0)
    print("REPLAY triggered: ", ok, " frames=", m.match_view.rec.size())
    for fi in 4:
        await get_tree().process_frame
    await _grab(out + "/r1_replay.png")
    await _wait_sim(1.5)
    await _grab(out + "/r2_replay.png")
    var ok2 := await _wait_until(func(): return not m.match_view.replaying, 120.0)
    print("REPLAY ended: ", ok2)
    await _wait_sim(1.0)
    await _grab(out + "/r3_tras_replay.png")
    print("REPLAYSHOTS DONE")
    get_tree().quit(0)

func _closeup_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--closeup")
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
    await _wait_until(func(): return m.match_view.sim.rally_hits >= 5, 25.0)
    m.match_view.set_physics_process(false)
    m.match_view.cam.position = Vector3(2.2, 1.7, -4.2)
    m.match_view.cam.look_at(Vector3(m.match_view.sim.pl[0].x, 1.1, m.match_view.sim.pl[0].z))
    await get_tree().process_frame
    await _grab(out + "/11_closeup.png")
    m.match_view.queue_free()
    m.match_view = null
    await get_tree().process_frame
    m.menus.visible = true

    # pantalla crear carrera
    m.menus.show_create()
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/09_carrera_crear.png")

    # pantalla fin de partido: partido no-demo forzado a match over
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
    var over_ok := await _wait_until(func(): return m.menus.visible and m.match_view == null, 10.0)
    print("over screen ok: ", over_ok)
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/10_victoria.png")
    print("SHOTS DONE")
    get_tree().quit(0)

func _wait_sim(secs: float) -> void:
    var t := 0.0
    while t < secs:
        await get_tree().physics_frame
        t += get_physics_process_delta_time()

func _wait_until(cond: Callable, max_secs: float) -> bool:
    var t := 0.0
    while t < max_secs:
        await get_tree().physics_frame
        t += get_physics_process_delta_time()
        if cond.call():
            return true
    return false

func _grab(path: String) -> void:
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    img.save_png(path)
    print("SHOT ", path)

func _boardcheck_harness(args: Array) -> void:
    var out := "/tmp/boardcheck.png"
    var i := args.find("--boardcheck")
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


# ---------- TEST: capturas de pista (vista TV + detalle de red) ----------
func _courtshot_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/court"
    var i := args.find("--courtshot")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    m.menus.visible = false
    var cam := Camera3D.new()
    add_child(cam)
    cam.fov = 50.0
    for surface in ["hard", "clay", "grass"]:
        var court := CourtBuilder.build(surface, true)
        add_child(court)
        for fi in 12:
            await get_tree().process_frame
        # vista TV: tras la linea de fondo, elevada, toda la pista
        cam.position = Vector3(0, 8.5, -7.2)
        cam.look_at(Vector3(0, 0.0, 14.5))
        cam.current = true
        await _grab(out + "/court_tv_" + surface + ".png")
        # detalle de red desde el lateral
        cam.position = Vector3(10.5, 2.6, CourtBuilder.NZ - 0.4)
        cam.look_at(Vector3(0, 0.7, CourtBuilder.NZ))
        await _grab(out + "/court_net_" + surface + ".png")
        # vista alta 3/4 para proporciones
        cam.position = Vector3(13.0, 13.0, -9.0)
        cam.look_at(Vector3(0, 0.0, CourtBuilder.NZ + 3.0))
        await _grab(out + "/court_34_" + surface + ".png")
        # cenital ortografica: mapeo exacto de la textura en la pista
        cam.projection = Camera3D.PROJECTION_ORTHOGONAL
        cam.size = 16.0
        cam.position = Vector3(0, 25.0, CourtBuilder.NZ)
        cam.rotation = Vector3(-PI / 2.0, 0, 0)
        await _grab(out + "/court_top_" + surface + ".png")
        cam.projection = Camera3D.PROJECTION_PERSPECTIVE
        # diagnostico UV: textura de calibrado por colores
        var dimg := Image.create(64, 128, false, Image.FORMAT_RGBA8)
        dimg.fill(Color(0.15, 0.15, 0.15))
        for gy in 128:
            for gx in 64:
                var cc := Color(0.15, 0.15, 0.15)
                if gy < 12: cc = Color(1, 0, 0)         # v~0: rojo
                elif gy >= 116: cc = Color(0, 1, 0)     # v~1: verde
                if gx < 8: cc = Color(0, 0, 1)          # u~0: azul
                elif gx >= 56: cc = Color(1, 1, 0)      # u~1: amarillo
                if gy >= 58 and gy < 70 and gx >= 26 and gx < 38: cc = Color(1, 1, 1)  # cruz central
                dimg.set_pixel(gx, gy, cc)
        var dtex := ImageTexture.create_from_image(dimg)
        var court_mi: MeshInstance3D = null
        for ch in court.get_children():
            if ch is MeshInstance3D and ch.mesh is BoxMesh and ch.mesh.size.x > 10.0:
                court_mi = ch
        if court_mi:
            var dm := StandardMaterial3D.new()
            dm.albedo_texture = dtex
            dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            var old_mat = court_mi.mesh.material
            court_mi.mesh.material = dm
            court_mi.visible = false
            cam.projection = Camera3D.PROJECTION_ORTHOGONAL
            cam.size = 16.0
            cam.position = Vector3(0, 25.0, CourtBuilder.NZ)
            cam.rotation = Vector3(-PI / 2.0, 0, 0)
            await get_tree().process_frame
            await get_tree().process_frame
            # restaurar: la pista visible NO es la caja (ver diagnostico)
            court_mi.visible = true
            court_mi.mesh.material = old_mat
            # volcado de TODAS las mallas visibles de la escena
            print("SCENE MESHES (", surface, "):")
            var stk2 := [get_tree().root]
            while stk2.size() > 0:
                var nd = stk2.pop_back()
                for cc in nd.get_children():
                    stk2.append(cc)
                if nd is MeshInstance3D and nd.visible and nd.mesh:
                    var aabb: AABB = nd.get_aabb()
                    var gpos := (nd as MeshInstance3D).global_position
                    if aabb.size.x > 5.0 or aabb.size.z > 5.0:
                        print("  M ", nd.name, " @", gpos, " aabb=", aabb, " mesh=", nd.mesh.get_class(), " mat=", (nd.mesh.material if nd.mesh is PrimitiveMesh else "array"))
            await _grab(out + "/court_uvdiag_" + surface + ".png")
            cam.projection = Camera3D.PROJECTION_PERSPECTIVE
        court.queue_free()
        await get_tree().process_frame
    get_tree().quit(0)


# ---------- TEST: cabezas (arbitro/jueces) siguiendo la bola ----------
func _watchtest_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/watch"
    var i := args.find("--watchtest")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    m.menus.visible = false
    var cam := Camera3D.new()
    add_child(cam)
    cam.fov = 40.0
    var court := CourtBuilder.build("hard", true)
    add_child(court)
    var ball := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.12
    sm.height = 0.24
    var bmat := StandardMaterial3D.new()
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
    # 1: arbitro de frente, bola a su derecha-baja (esquina cercana de pista)
    ball.global_position = Vector3(5.0, 1.2, 3.0)
    cam.position = Vector3(-4.0, 2.8, CourtBuilder.NZ)
    cam.look_at(Vector3(-7.2, 2.55, CourtBuilder.NZ))
    cam.current = true
    for f in 14:
        await get_tree().process_frame
    await _grab(out + "/watch_umpire_right.png")
    # 2: misma camara, bola al otro lado y lejos
    ball.global_position = Vector3(-5.0, 3.0, 22.0)
    for f in 6:
        await get_tree().process_frame
    await _grab(out + "/watch_umpire_left.png")
    # 3: juez cercano-izquierdo de frente, bola cruzada
    ball.global_position = Vector3(5.0, 1.0, 18.0)
    cam.position = Vector3(-5.6, 1.25, -0.4)
    cam.look_at(Vector3(-8.2, 0.72, -3.1))
    for f in 6:
        await get_tree().process_frame
    await _grab(out + "/watch_judge.png")
    get_tree().quit(0)


# ---------- TEST: rafaga de capturas durante un rally demo ----------
func _rallyshots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/rally"
    var i := args.find("--rallyshots")
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
    # esperar a que empiece un rally (tras el primer resto)
    var ok := await _wait_until(func(): return m.match_view.sim.rally_hits >= 2, 40.0)
    print("rally start ok: ", ok)
    for n in 8:
        await _wait_sim(0.28)
        await _grab(out + "/r" + str(n) + ".png")
        print("shot r", n, " state=", m.match_view.sim.state, " hits=", m.match_view.sim.rally_hits, " bally=", snappedf(m.match_view.sim.ball.y, 0.01))
    get_tree().quit(0)


func _trailshot_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/trail"
    var i := args.find("--trailshot")
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
    # forzar un golpe duro: bola en juego cerca de la CPU y smash directo
    var ok := await _wait_until(func(): return m.match_view.sim.state == "play" and m.match_view.sim.ball.in_play, 40.0)
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
    # harness visual: imponer vuelo duro para capturar la estela caliente
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





func _v29shots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/v29"
    var i := args.find("--v29shots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    m.menus.visible = false
    print("v29 harness start")
    # A) partida real (no demo): dejada del jugador -> popup sobre su cabeza
    m.match_view = MatchView.new()
    m.match_view.set_meta("surface", "hard")
    m.match_view.set_meta("day", true)
    m.match_view.set_meta("cpu_look", 2)
    m.match_view.set_meta("my_name", "TÚ")
    m.match_view.set_meta("cpu_label", "CPU · NORMAL")
    m.match_view.setup({"demo": false, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(m.match_view)
    await _wait_sim(3.0)
    var ok := true
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
    # B) pausa abierta: sin pista/banner/medidor por encima
    var pev := InputEventAction.new()
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
    # C) demo: recogepelotas y jueces girando el cuerpo a la bola
    m.match_view = MatchView.new()
    m.match_view.set_meta("surface", "hard")
    m.match_view.set_meta("day", true)
    m.match_view.set_meta("cpu_look", 2)
    m.match_view.set_meta("my_name", "TÚ")
    m.match_view.set_meta("cpu_label", "CPU · NORMAL")
    m.match_view.setup({"demo": true, "surface": "hard", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(m.match_view)
    ok = await _wait_until(func(): return m.match_view.sim.state == "play", 20.0)
    sim = m.match_view.sim
    sim.ball.in_play = false
    sim.ball.x = -6.0
    sim.ball.y = 0.4
    sim.ball.z = 16.0
    sim.ball.vx = 0.0; sim.ball.vy = 0.0; sim.ball.vz = 0.0
    await _wait_sim(1.0)
    await _grab(out + "/vida_izq.png")
    sim.ball.x = 6.0
    sim.ball.z = 14.0
    await _wait_sim(1.2)
    await _grab(out + "/vida_der.png")
    print("v29 C life shots ok=", ok)
    get_tree().quit(0)

func _judgetest_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/judge"
    var i := args.find("--judgetest")
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
    var ok := await _wait_until(func(): return m.match_view.sim.state == "play", 40.0)
    var sim = m.match_view.sim
    print("judgetest play ok: ", ok)
    # bola quieta a la izquierda del todo -> el juez cercano-derecho debe mirar a su izquierda
    sim.ball.in_play = false
    sim.ball.x = -6.0
    sim.ball.y = 0.4
    sim.ball.z = -2.0
    sim.ball.vx = 0.0; sim.ball.vy = 0.0; sim.ball.vz = 0.0
    await _wait_sim(0.6)
    await _grab(out + "/j_left.png")
    # y a la derecha del todo
    sim.ball.x = 6.0
    await _wait_sim(0.6)
    await _grab(out + "/j_right.png")
    print("judgetest done")
    get_tree().quit(0)

func _swingshot_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/swing"
    var i := args.find("--swingshot")
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
    var ok := await _wait_until(func(): return m.match_view.sim.state == "play" and m.match_view.sim.ball.in_play, 40.0)
    var sim = m.match_view.sim
    # bola facil al jugador cercano y golpe forzado para pillar el swing
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

func _racketshot_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/racket"
    var i := args.find("--racketshot")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    m.menus.visible = false
    var root3 := Node3D.new()
    add_child(root3)
    var env := WorldEnvironment.new()
    var ee := Environment.new()
    ee.background_mode = Environment.BG_COLOR
    ee.background_color = Color(0.35, 0.42, 0.55)
    ee.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    ee.ambient_light_color = Color(0.9, 0.9, 0.95)
    ee.ambient_light_energy = 0.8
    env.environment = ee
    root3.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(-0.7, 0.6, 0.0)
    root3.add_child(sun)
    var fig = PlayerFig.new(0, false)
    root3.add_child(fig)
    var cam := Camera3D.new()
    root3.add_child(cam)
    cam.current = true
    var views := [
        [Vector3(0.55, 0.52, 0.45), Vector3(0.30, 0.47, 0.02)],
        [Vector3(0.18, 0.50, 0.62), Vector3(0.28, 0.45, 0.0)],
        [Vector3(0.75, 0.50, 0.35), Vector3(0.28, 0.46, 0.0)],
        [Vector3(0.42, 0.40, 0.42), Vector3(0.28, 0.44, 0.0)],
    ]
    for n in views.size():
        cam.position = views[n][0]
        cam.look_at(views[n][1], Vector3.UP)
        await get_tree().process_frame
        await get_tree().process_frame
        await _grab(out + "/rk" + str(n) + ".png")
        print("shot rk", n)
    get_tree().quit(0)


func _careershot_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/m.career"
    var i := args.find("--careershot")
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


func _serveshot_harness(args: Array) -> void:
    # v0.27: capturas del medidor de saque (aguja amarilla/verde) y del marcador km/h
    var out := "/home/sandbox/godot/shots/serve"
    var i := args.find("--serveshot")
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
    await _wait_until(func(): return mv.sim.ball.toss_t >= 0.30, 2.0)
    await _grab(out + "/meter_mid.png")
    await _wait_until(func(): return mv.sim.ball.toss_t >= 0.49, 2.0)  # zona verde perfecta
    await _grab(out + "/meter_green.png")
    mv.sim.do_serve(mv.sim.pl[0], 0.97)
    mv.drain_events()
    await get_tree().process_frame
    await _grab(out + "/speed.png")
    print("SERVESHOT done, spd event=", mv.hud.speed_label.text)
    get_tree().quit(0)

func _bounceshot_harness(args: Array) -> void:
    # v0.28: dejada que muere rodando -> el punto se corta con "Dos botes" (captura del banner)
    var out := "/home/sandbox/godot/shots/bounce"
    var i := args.find("--bounceshot")
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
    # fuerza una dejada de la CPU que cae suave cerca de la red y muere rodando
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
    sim.launch(0.4, 11.885 - 1.6, 1.0, 1.2)  # dejada valida como las del propio juego
    sim.events.clear()
    var ok := await _wait_until(func(): return mv.banner_t > 0.0, 6.0)
    print("BOUNCESHOT banner=", ok)
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/dosbotes.png")
    print("BOUNCESHOT done")
    get_tree().quit(0)

func _looktest_harness(_args: Array) -> void:
    m.menus.visible = false
    var root3d := Node3D.new()
    add_child(root3d)
    var cam := Camera3D.new()
    root3d.add_child(cam)
    cam.position = Vector3(0, 2.0, 7.0)
    cam.look_at(Vector3(0, 1.0, 0))
    var sun := DirectionalLight3D.new()
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

func _v30shots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots/v30"
    var i := args.find("--v30shots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    m.menus.visible = false
    print("v30 harness start")
    # A) magnetismo: jugador desplazado 2m, pulsa golpear y la asistencia le coloca
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
    var ok := await _wait_until(func(): return sim.ball.last == 0, 1.5)
    print("v30 A magnetismo hit=", ok, " px=", sim.pl[0].x)
    await get_tree().process_frame
    await _grab(out + "/magnetismo.png")
    # B) derrape: carrera a tope a la derecha y corte a la izquierda
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
    # C) punto en demo: ganador SIN baile (idle), perdedor con gesto
    m.match_view = MatchView.new()
    m.match_view.set_meta("surface", "grass")
    m.match_view.set_meta("day", true)
    m.match_view.set_meta("cpu_look", 2)
    m.match_view.set_meta("my_name", "TU")
    m.match_view.set_meta("cpu_label", "CPU · NORMAL")
    m.match_view.setup({"demo": true, "surface": "grass", "AIP": m.DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(m.match_view)
    await _wait_sim(2.0)
    var okp := await _wait_until(func(): return m.match_view.sim.state == "point", 60.0)
    print("v30 C point ok=", okp)
    if okp:
        await _wait_sim(0.7)
        await _grab(out + "/punto_sin_baile.png")
    m.match_view.queue_free()
    m.match_view = null
    await get_tree().process_frame
    # D) medidor de saque: la barra es la CALIDAD real (llena = optimo, aguja verde)
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
    var okq := await _wait_until(func(): return sim2.ball.toss_t >= 0.50, 2.0)
    print("v30 D meter q peak ok=", okq, " toss_t=", sim2.ball.toss_t)
    await _grab(out + "/saque_medidor.png")
    m.match_view.queue_free()
    m.match_view = null
    await get_tree().process_frame
    print("v30 harness done")
    get_tree().quit()
