extends Node

const DIFF_PARAMS := [
    {"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3},
    {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15},
    {"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06},
]
const CPU_LABELS := ["CPU · FÁCIL", "CPU · NORMAL", "CPU · DIFÍCIL"]

var menus: GameMenus
var career: Career
var training_view: TrainingView
var tourney := {}
var in_tourney_match := false
var match_view: MatchView
var sfx: SoundKit
var last_cfg := {"surface": "clay", "diff": 1, "sets": 1}
var in_career_match := false

func _ready() -> void:
    randomize()
    _register_inputs()
    var args := OS.get_cmdline_user_args()
    if args.has("--simtest"):
        _simtest(args)
        return
    if args.has("--careertest"):
        _careertest()
        return
    if args.has("--trainshots"):
        _trainshots(args)
        return
    if args.has("--menushots"):
        _menushots(args)
    if args.has("--tourneytest"):
        _tourneytest()
        return
    sfx = SoundKit.new()
    add_child(sfx)
    career = Career.load_saved()
    menus = GameMenus.new(sfx)
    add_child(menus)
    menus.quick_match.connect(_on_quick_match)
    menus.play_career_match.connect(_on_career_match)
    menus.play_training.connect(_on_training)
    menus.play_tournament.connect(_on_tournament)
    menus.tourney_play_match.connect(_on_tourney_match)
    menus.rematch.connect(_on_rematch)
    menus.back_to_menu.connect(_to_menu)
    menus.career_deleted.connect(func():
        career = null
        _to_menu())
    menus.show_menu(career)
    if args.has("--boardcheck"):
        call_deferred("_boardcheck_harness", args)
    elif args.has("--closeup"):
        call_deferred("_closeup_harness", args)
    elif args.has("--replayshots"):
        call_deferred("_replayshots_harness", args)
    elif args.has("--faceshots"):
        call_deferred("_faceshots_harness", args)
    elif args.has("--shots"):
        call_deferred("_shots_harness", args)

func _register_inputs() -> void:
    var defs := {
        "move_left": [{"k": KEY_A}, {"k": KEY_LEFT}, {"ja": 0, "av": -1.0}],
        "move_right": [{"k": KEY_D}, {"k": KEY_RIGHT}, {"ja": 0, "av": 1.0}],
        "move_up": [{"k": KEY_W}, {"k": KEY_UP}, {"ja": 1, "av": -1.0}],
        "move_down": [{"k": KEY_S}, {"k": KEY_DOWN}, {"ja": 1, "av": 1.0}],
        "hit": [{"k": KEY_SPACE}, {"k": KEY_J}, {"jb": JOY_BUTTON_A}],
        "lob": [{"k": KEY_Z}, {"k": KEY_K}, {"jb": JOY_BUTTON_X}],
        "drop": [{"k": KEY_SHIFT}, {"jb": JOY_BUTTON_B}],
        "pause": [{"k": KEY_P}, {"jb": JOY_BUTTON_START}],
        "quit": [{"k": KEY_ESCAPE}, {"jb": JOY_BUTTON_BACK}],
        "ui_accept": [{"jb": JOY_BUTTON_A}],
        "ui_cancel": [{"jb": JOY_BUTTON_B}],
        "ui_up": [{"jb": JOY_BUTTON_DPAD_UP}],
        "ui_down": [{"jb": JOY_BUTTON_DPAD_DOWN}],
        "ui_left": [{"jb": JOY_BUTTON_DPAD_LEFT}],
        "ui_right": [{"jb": JOY_BUTTON_DPAD_RIGHT}],
    }
    for action in defs:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for ev in defs[action]:
            if ev.has("k"):
                var k := InputEventKey.new()
                k.physical_keycode = ev.k
                InputMap.action_add_event(action, k)
            elif ev.has("jb"):
                var b := InputEventJoypadButton.new()
                b.button_index = ev.jb
                InputMap.action_add_event(action, b)
            elif ev.has("ja"):
                var m := InputEventJoypadMotion.new()
                m.axis = ev.ja
                m.axis_value = ev.av
                InputMap.action_add_event(action, m)

func _start_match(cfg: Dictionary) -> void:
    if match_view:
        match_view.queue_free()
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", cfg.surface)
    match_view.set_meta("cpu_look", cfg.get("cpu_look", 2))
    match_view.set_meta("my_name", cfg.get("my_name", "TÚ"))
    match_view.set_meta("cpu_label", cfg.get("cpu_label", "CPU"))
    match_view.set_meta("day", cfg.get("day", false))
    match_view.setup(cfg)
    add_child(match_view)
    match_view.match_finished.connect(_on_match_finished)
    match_view.quit_to_menu.connect(_to_menu)

func _on_quick_match(surface: String, diff: int, sets: int, day: bool) -> void:
    last_cfg = {"surface": surface, "diff": diff, "sets": sets, "day": day}
    in_career_match = false
    _start_match({
        "surface": surface,
        "AIP": DIFF_PARAMS[diff],
        "PS": {"speed": 7.0, "T": 1.0, "err": 1.0},
        "demo": false,
        "career": false,
        "cpu_name": "CPU",
        "cpu_label": CPU_LABELS[diff],
        "cpu_look": diff + 1,
        "sets_to_win": sets,
        "day": day,
    })

func _on_career_match() -> void:
    if career.data.tour == null:
        career.start_tournament()
    var def: Dictionary = Career.CAL[career.data.tour.idx]
    var opp: Dictionary = career.current_opp()
    var st := career.standings()
    var orank := 1
    for i in st.size():
        if st[i].n == opp.n:
            orank = i + 1
    in_career_match = true
    var sets_to_win := 2 if (def.t == "GS" and career.data.tour.round >= 2) else 1
    _start_match({
        "surface": def.s,
        "AIP": Career.params_for(opp.r),
        "PS": career.player_from_stats(),
        "demo": false,
        "career": true,
        "cpu_name": opp.n.split(" ")[-1],
        "cpu_label": opp.n.split(" ")[-1],
        "cpu_look": abs(opp.n.hash()) % 5,
        "my_name": career.data.name,
        "sets_to_win": sets_to_win,
        "day": def.get("d", true),
    })

# ---------- TORNEO (cuadro de 8, no persistente) ----------
func _on_tournament() -> void:
    if tourney.is_empty() or tourney.get("done", false) or tourney.get("eliminated", false):
        _tourney_new()
    menus.visible = true
    menus.show_tourney(tourney)

func _tourney_new() -> void:
    var pool := Career.POOL0.duplicate()
    pool.shuffle()
    var picked := pool.slice(0, 7)
    var players := [{"n": "TÚ", "r": 0.8}]
    for pl in picked:
        players.append({"n": pl[0], "r": pl[1]})
    var surfaces := ["clay", "grass", "hard"]
    tourney = {
        "alive": players,
        "round": 0,
        "results": [],
        "surface": surfaces[randi() % 3],
        "day": randf() < 0.6,
        "done": false,
        "eliminated": false,
        "champion": "",
        "bracket_text": [],
    }
    _tourney_bracket_text()

func _tourney_bracket_text() -> void:
    var lines := []
    var alive: Array = tourney.alive
    for i in range(0, alive.size(), 2):
        var a: Dictionary = alive[i]
        var b: Dictionary = alive[i + 1]
        lines.append(a.n + "  vs  " + b.n)
    tourney.bracket_text = lines

func _on_tourney_match() -> void:
    var alive: Array = tourney.alive
    var me := -1
    for i in alive.size():
        if alive[i].n == "TÚ":
            me = i
    if me < 0:
        return
    var opp: Dictionary = alive[me + 1] if me % 2 == 0 else alive[me - 1]
    tourney["opp"] = opp
    in_career_match = false
    in_tourney_match = true
    var last: String = opp.n.split(" ")[-1]
    _start_match({
        "surface": tourney.surface,
        "AIP": Career.params_for(opp.r),
        "PS": {"speed": 7.0, "T": 1.0, "err": 1.0},
        "demo": false,
        "career": false,
        "cpu_name": last,
        "cpu_label": last,
        "cpu_look": abs(opp.n.hash()) % 5,
        "sets_to_win": 2 if tourney.round == 2 else 1,
        "day": tourney.day,
    })

func _sim_cpu(a: Dictionary, b: Dictionary) -> Dictionary:
    var pa: float = a.r / (a.r + b.r)
    return a if randf() < pa else b

func _tourney_resolve(win: bool, M: Dictionary) -> void:
    var alive: Array = tourney.alive.duplicate()
    var rname: String = ["Cuartos", "Semifinal", "Final"][tourney.round]
    var winners := []
    var msg := ""
    var score := str(M.sets[0]) + "-" + str(M.sets[1])
    for i in range(0, alive.size(), 2):
        var a: Dictionary = alive[i]
        var b: Dictionary = alive[i + 1]
        if a.n == "TÚ" or b.n == "TÚ":
            var opp: Dictionary = b if a.n == "TÚ" else a
            var w: Dictionary = a if win else b
            winners.append(w)
            var res_line: String = rname + ": TÚ " + score + " " + opp.n.split(" ")[-1]
            if not win:
                res_line = rname + ": " + opp.n.split(" ")[-1] + " " + str(M.sets[1]) + "-" + str(M.sets[0]) + " TÚ"
            tourney.results.append(res_line)
        else:
            var w2: Dictionary = _sim_cpu(a, b)
            var l2: Dictionary = b if w2 == a else a
            winners.append(w2)
            tourney.results.append(rname + ": " + w2.n + " 1-0 " + l2.n)
    if win:
        if tourney.round == 2:
            tourney.done = true
            tourney.champion = "TÚ"
            msg = "¡CAMPEÓN DEL TORNEO! Ganaste la final " + score + "."
        else:
            tourney.alive = winners
            tourney.round += 1
            _tourney_bracket_text()
            msg = "Ganaste " + score + ". Siguiente: " + ("la FINAL" if tourney.round == 2 else "las semifinales") + "."
    else:
        # eliminado: simular el resto del torneo para coronar campeón
        var rest := winners
        var r: int = tourney.round + 1
        while rest.size() > 1:
            var nw := []
            for i in range(0, rest.size(), 2):
                nw.append(_sim_cpu(rest[i], rest[i + 1]))
            rest = nw
            r += 1
        tourney.done = true
        tourney.eliminated = true
        tourney.champion = rest[0].n
        msg = "Caíste " + score + " en " + rname.to_lower() + ". El torneo siguió sin ti y el campeón fue " + tourney.champion + "."
    menus.show_tourney(tourney, msg)

func _on_training() -> void:
    if career == null:
        return
    menus.visible = false
    training_view = TrainingView.new()
    var surf := "grass"
    if career.data.tour != null:
        surf = Career.CAL[career.data.tour.idx].s
    training_view.setup({"surface": surf, "look": 0})
    add_child(training_view)
    training_view.quit_to_menu.connect(_on_training_quit)

func _on_training_quit() -> void:
    var sc := 0
    var tot := 0
    if training_view:
        sc = training_view.score
        tot = training_view.total_cans
        training_view.queue_free()
        training_view = null
    var msg := "Entrenamiento de saque: " + str(sc) + "/" + str(tot) + " latas derribadas."
    menus.visible = true
    if menus.training_from == "games":
        menus.training_from = "career"
        menus.show_games(msg)
        return
    if career != null and sc >= maxi(3, tot - 1):
        career.data.free += 1
        career.save()
        msg += " ¡Ganas +1 punto de mejora!"
    menus.show_hub(msg, true)

func _on_rematch() -> void:
    _on_quick_match(last_cfg.surface, last_cfg.diff, last_cfg.sets, last_cfg.get("day", true))

func _on_match_finished(win: bool) -> void:
    var M = match_view.sim.M
    var cpu_label: String = match_view.get_meta("cpu_label")
    if in_tourney_match:
        in_tourney_match = false
        match_view.queue_free()
        match_view = null
        menus.visible = true
        _tourney_resolve(win, M)
        return
    var res := {}
    if in_career_match:
        res = career.on_career_end(win)
    match_view.queue_free()
    match_view = null
    menus.visible = true
    menus.show_over(win, M.sets[0], M.sets[1], cpu_label, res, in_career_match)

func _to_menu() -> void:
    if match_view:
        match_view.queue_free()
        match_view = null
    in_career_match = false
    menus.visible = true
    menus.show_menu(career)

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
    var sim := TennisSim.new(true, DIFF_PARAMS[1], {}, "CPU", 1)
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

func _training_shots(out: String) -> void:
    # minijuego de entrenamiento: punteria + saque en vuelo + latas caidas
    if menus != null:
        menus.visible = false
    training_view = TrainingView.new()
    training_view.setup({"surface": "grass", "look": 0})
    add_child(training_view)
    for fi in 20:
        await get_tree().physics_frame
    await _grab(out + "/01b_entrenamiento.png")
    training_view.start_serve()
    for fi in 45:
        await get_tree().physics_frame
    await _grab(out + "/01c_saque_vuelo.png")
    for fi in 130:
        await get_tree().physics_frame
    await _grab(out + "/01d_latas.png")
    training_view.queue_free()
    training_view = null
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
func _menushots(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--menushots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    sfx = SoundKit.new()
    add_child(sfx)
    menus = GameMenus.new(sfx)
    add_child(menus)
    for fi in 10:
        await get_tree().process_frame
    menus.show_menu(null)
    for fi in 6:
        await get_tree().process_frame
    await _grab(out + "/m1_home.png")
    menus.show_exhibition()
    for fi in 6:
        await get_tree().process_frame
    await _grab(out + "/m2_exhibition.png")
    menus.show_games()
    for fi in 6:
        await get_tree().process_frame
    await _grab(out + "/m3_games.png")
    _on_tournament()
    for fi in 6:
        await get_tree().process_frame
    await _grab(out + "/m4_tourney.png")
    get_tree().quit(0)

func _tourneytest() -> void:
    sfx = SoundKit.new()
    add_child(sfx)
    menus = GameMenus.new(sfx)
    add_child(menus)
    await get_tree().process_frame
    var fails := 0
    # camino victoria completa
    _tourney_new()
    if tourney.alive.size() != 8:
        print("FAIL alive inicial = ", tourney.alive.size()); fails += 1
    if tourney.bracket_text.size() != 4:
        print("FAIL bracket inicial = ", tourney.bracket_text.size()); fails += 1
    for r in 3:
        _tourney_resolve(true, {"sets": [2 if r == 2 else 1, 0]})
    if not tourney.done or tourney.champion != "TÚ":
        print("FAIL campeon: done=", tourney.done, " champ=", tourney.champion); fails += 1
    print("WIN-PATH champ=", tourney.champion, " results=", tourney.results.size())
    # camino derrota en cuartos
    _tourney_new()
    _tourney_resolve(false, {"sets": [0, 1]})
    if not tourney.done or not tourney.eliminated or tourney.champion == "" or tourney.champion == "TÚ":
        print("FAIL eliminacion: done=", tourney.done, " elim=", tourney.eliminated, " champ=", tourney.champion); fails += 1
    print("LOSE-PATH champ=", tourney.champion, " eliminated=", tourney.eliminated)
    # reduccion de cuadro ronda a ronda
    _tourney_new()
    _tourney_resolve(true, {"sets": [1, 0]})
    if tourney.alive.size() != 4 or tourney.round != 1:
        print("FAIL semis: alive=", tourney.alive.size(), " round=", tourney.round); fails += 1
    if tourney.bracket_text.size() != 2:
        print("FAIL bracket semis = ", tourney.bracket_text.size()); fails += 1
    _tourney_resolve(true, {"sets": [1, 0]})
    if tourney.alive.size() != 2 or tourney.round != 2:
        print("FAIL final: alive=", tourney.alive.size(), " round=", tourney.round); fails += 1
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
    print("menus visible=", menus.visible, " size=", menus.size, " root_box children=", menus.root_box.get_child_count(), " bg=", menus.get_child_count())
    await _grab(out + "/01_menu.png")

    await _training_shots(out)

    # partido demo (IA vs IA) en arcilla
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "grass")
    match_view.set_meta("day", true)
    match_view.set_meta("cpu_look", 2)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU · NORMAL")
    match_view.setup({"demo": true, "surface": "grass", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    await _wait_sim(2.2)
    await _grab(out + "/02_saque_arcilla.png")
    var ok := await _wait_until(func(): return match_view.sim.rally_hits >= 3, 30.0)
    print("rally ok: ", ok, " hits=", match_view.sim.rally_hits)
    await _grab(out + "/03_rally_arcilla.png")
    ok = await _wait_until(func(): return match_view.sim.rally_hits >= 6, 30.0)
    print("rally6 ok: ", ok, " hits=", match_view.sim.rally_hits)
    await _grab(out + "/04_rally_arcilla2.png")
    var okp := await _wait_until(func(): return match_view.sim.state == "point", 60.0)
    print("point ok: ", okp)
    if okp:
        await _wait_sim(0.6)
        await _grab(out + "/04b_celebracion.png")
    match_view.queue_free()
    match_view = null
    await get_tree().process_frame

    # demo en pista dura
    match_view = MatchView.new()
    match_view.set_meta("surface", "hard")
    match_view.set_meta("cpu_look", 3)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU · NORMAL")
    match_view.setup({"demo": true, "surface": "hard", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    await _wait_sim(2.4)
    await _grab(out + "/05_saque_dura.png")
    ok = await _wait_until(func(): return match_view.sim.rally_hits >= 4, 30.0)
    print("rally hard ok: ", ok)
    await _grab(out + "/06_rally_dura.png")
    match_view.queue_free()
    match_view = null
    await get_tree().process_frame

    # pantallas de carrera
    menus.visible = true
    career = Career.new()
    career.new_career("Jugador")
    menus.career = career
    menus.show_hub("")
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/07_carrera_hub.png")
    menus.tab = "rank"
    menus.show_hub("")
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/08_carrera_ranking.png")
    Career.delete_save()
    career = null



func _faceshots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--faceshots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    await get_tree().process_frame
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "grass")
    match_view.set_meta("day", true)
    match_view.set_meta("cpu_look", 0)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU")
    match_view.setup({"demo": true, "surface": "grass", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    await _wait_sim(2.0)
    match_view.set_physics_process(false)
    var fp = match_view.sim.pl[1]
    print("FACE far player pos=", fp.x, ",", fp.z)
    var fig = match_view.rigs[1]
    if fig == null:
        for c in match_view.get_children():
            print("MVCHILD ", c.name)
    else:
        var sk = fig.skel
        var hb = sk.find_bone("Head")
        print("HEAD bone global pose: ", sk.global_transform * sk.get_bone_global_pose(hb))
        var sc = (sk.global_transform * sk.get_bone_global_pose(hb)).basis.get_scale()
        print("HEAD bone world scale=", sc)
    match_view.cam.position = Vector3(fp.x + 0.35, 1.42, fp.z - 2.4)
    match_view.cam.look_at(Vector3(fp.x, 1.38, fp.z))
    await get_tree().process_frame
    await _grab(out + "/f1_cara_cpu.png")
    var np = match_view.sim.pl[0]
    match_view.cam.position = Vector3(np.x - 0.35, 1.42, np.z + 2.4)
    match_view.cam.look_at(Vector3(np.x, 1.38, np.z))
    await get_tree().process_frame
    await _grab(out + "/f2_cara_tu.png")
    print("FACESHOTS DONE")
    get_tree().quit(0)

func _replayshots_harness(args: Array) -> void:
    var out := "/home/sandbox/godot/shots"
    var i := args.find("--replayshots")
    if i + 1 < args.size():
        out = args[i + 1]
    DirAccess.make_dir_recursive_absolute(out)
    await get_tree().process_frame
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "grass")
    match_view.set_meta("day", true)
    match_view.set_meta("cpu_look", 1)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU · NORMAL")
    match_view.setup({"demo": true, "surface": "grass", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    match_view.replay_test = true
    var okr := await _wait_until(func(): return match_view.sim.rally_hits >= 5, 600.0)
    print("REPLAY rally ok: ", okr, " hits=", match_view.sim.rally_hits)
    if okr:
        match_view.sim.award_point(0, "PUNTO", "test")
    var ok := await _wait_until(func(): return match_view.replaying, 120.0)
    print("REPLAY triggered: ", ok, " frames=", match_view.rec.size())
    for fi in 4:
        await get_tree().process_frame
    await _grab(out + "/r1_replay.png")
    await _wait_sim(1.5)
    await _grab(out + "/r2_replay.png")
    var ok2 := await _wait_until(func(): return not match_view.replaying, 120.0)
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
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "grass")
    match_view.set_meta("day", true)
    match_view.set_meta("cpu_look", 1)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU · NORMAL")
    match_view.setup({"demo": true, "surface": "grass", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    await _wait_until(func(): return match_view.sim.rally_hits >= 5, 25.0)
    match_view.set_physics_process(false)
    match_view.cam.position = Vector3(2.2, 1.7, -4.2)
    match_view.cam.look_at(Vector3(match_view.sim.pl[0].x, 1.1, match_view.sim.pl[0].z))
    await get_tree().process_frame
    await _grab(out + "/11_closeup.png")
    match_view.queue_free()
    match_view = null
    await get_tree().process_frame
    menus.visible = true

    # pantalla crear carrera
    menus.show_create()
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out + "/09_carrera_crear.png")

    # pantalla fin de partido: partido no-demo forzado a match over
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "hard")
    match_view.set_meta("cpu_look", 2)
    match_view.set_meta("my_name", "TÚ")
    match_view.set_meta("cpu_label", "CPU · NORMAL")
    match_view.setup({"demo": false, "surface": "hard", "AIP": DIFF_PARAMS[1], "PS": {"speed": 7.0, "T": 1.0, "err": 1.0}, "sets_to_win": 1})
    add_child(match_view)
    match_view.match_finished.connect(_on_match_finished)
    await _wait_sim(0.5)
    match_view.sim.M.sets[0] = 1
    match_view.sim.match_over = true
    match_view.sim.state = "point"
    match_view.sim.state_t = 3.0
    var over_ok := await _wait_until(func(): return menus.visible and match_view == null, 10.0)
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
    menus.visible = false
    match_view = MatchView.new()
    match_view.set_meta("surface", "grass")
    match_view.set_meta("day", true)
    match_view.set_meta("cpu_look", 2)
    match_view.set_meta("my_name", "TU")
    match_view.set_meta("cpu_label", "CPU")
    match_view.setup({"demo": true, "surface": "grass", "AIP": DIFF_PARAMS[1], "sets_to_win": 1})
    add_child(match_view)
    for fi in 20:
        await get_tree().process_frame
    match_view.set_physics_process(false)
    match_view.cam.position = Vector3(0, 2.5, 6.0)
    match_view.cam.look_at(Vector3(0, 1.0, 20.0))
    await get_tree().process_frame
    await get_tree().process_frame
    await _grab(out)
    print("BOARDCHECK DONE")
    get_tree().quit(0)
