extends Node

const DIFF_PARAMS := [
    {"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3},
    {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15},
    {"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06},
]
const CPU_LABELS := ["CPU · FÁCIL", "CPU · NORMAL", "CPU · DIFÍCIL"]

var menus: GameMenus
var career: Career
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
    sfx = SoundKit.new()
    add_child(sfx)
    career = Career.load_saved()
    menus = GameMenus.new(sfx)
    add_child(menus)
    menus.quick_match.connect(_on_quick_match)
    menus.play_career_match.connect(_on_career_match)
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

func _on_rematch() -> void:
    _on_quick_match(last_cfg.surface, last_cfg.diff, last_cfg.sets, last_cfg.get("day", true))

func _on_match_finished(win: bool) -> void:
    var M = match_view.sim.M
    var cpu_label: String = match_view.get_meta("cpu_label")
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
