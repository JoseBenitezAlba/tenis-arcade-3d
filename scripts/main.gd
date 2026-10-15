extends Node

const DebugHarness := preload("res://scripts/debug_harness.gd")

const DIFF_PARAMS := [
    {"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3, "risk": 0.35},
    {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5},
    {"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06, "risk": 0.7},
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
var pad_inv_x := false
var pad_inv_y := false

func _ready() -> void:
    randomize()
    _load_pad_settings()
    _register_inputs()
    var args := OS.get_cmdline_user_args()
    var dbg := DebugHarness.new()
    dbg.m = self
    add_child(dbg)
    if dbg.run_early(args):
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
    menus.pad_invert.connect(_on_pad_invert)
    menus.pad_inv_x = pad_inv_x
    menus.pad_inv_y = pad_inv_y
    menus.show_menu(career)
    dbg.run_late(args)

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
                var av: float = ev.av
                if m.axis == 0 and pad_inv_x:
                    av = -av
                elif m.axis == 1 and pad_inv_y:
                    av = -av
                m.axis_value = av
                InputMap.action_add_event(action, m)

func _load_pad_settings() -> void:
    # v0.32: ambos ejes arrancan en NORMAL en todas las plataformas; quien
    # tenga el mando al reves lo invierte desde el menu (se guarda).
    pad_inv_y = false
    var cfg := ConfigFile.new()
    if cfg.load("user://padcfg.cfg") == OK:
        pad_inv_x = cfg.get_value("pad", "inv_x", false)
        pad_inv_y = cfg.get_value("pad", "inv_y", pad_inv_y)

func set_pad_invert(axis_x: bool, inverted: bool) -> void:
    if axis_x:
        pad_inv_x = inverted
    else:
        pad_inv_y = inverted
    var cfg := ConfigFile.new()
    cfg.set_value("pad", "inv_x", pad_inv_x)
    cfg.set_value("pad", "inv_y", pad_inv_y)
    cfg.save("user://padcfg.cfg")
    for action in ["move_left", "move_right", "move_up", "move_down"]:
        for e in InputMap.action_get_events(action):
            if e is InputEventJoypadMotion:
                InputMap.action_erase_event(action, e)
    _add_joy_axes()

func _add_joy_axes() -> void:
    var axes := {
        "move_left": [0, -1.0],
        "move_right": [0, 1.0],
        "move_up": [1, -1.0],
        "move_down": [1, 1.0],
    }
    for action in axes:
        var m := InputEventJoypadMotion.new()
        m.axis = axes[action][0]
        var av: float = axes[action][1]
        if m.axis == 0 and pad_inv_x:
            av = -av
        elif m.axis == 1 and pad_inv_y:
            av = -av
        m.axis_value = av
        InputMap.action_add_event(action, m)

func _on_pad_invert(axis_x: bool, inverted: bool) -> void:
    set_pad_invert(axis_x, inverted)
    menus.pad_inv_x = pad_inv_x
    menus.pad_inv_y = pad_inv_y
    menus.show_menu(career)

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
        "AIP": Career.params_for(opp.r, int(opp.get("sty", 1))),
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
        "AIP": Career.params_for(opp.r, int(opp.get("sty", 1))),
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
    menus.pad_inv_x = pad_inv_x
    menus.pad_inv_y = pad_inv_y
    menus.show_menu(career)

