class_name GameMenus
extends Control

const VERSION := "v0.26"

signal quick_match(surface: String, diff: int, sets: int, day: bool)
signal play_career_match
signal play_training
signal play_tournament
signal tourney_play_match
signal rematch
signal back_to_menu
signal career_deleted
signal pad_invert(axis_x: bool, inverted: bool)

const DIFFS := ["FÁCIL", "NORMAL", "DIFÍCIL"]
var surface := "clay"
var diff := 1
var sets := 1
var day := true
var career: Career
var tab := "cal"
var career_msg := ""
var career_msg_ok := true
var training_from := "career"
var pad_inv_x := false
var pad_inv_y := false
var root_box: VBoxContainer
var sfx: SoundKit
var focus_first: Control

func _init(p_sfx: SoundKit) -> void:
    sfx = p_sfx

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color("#070a14")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)
    var center := CenterContainer.new()
    center.custom_minimum_size = Vector2(1280, 720)
    scroll.add_child(center)
    root_box = VBoxContainer.new()
    root_box.alignment = BoxContainer.ALIGNMENT_CENTER
    root_box.add_theme_constant_override("separation", 12)
    center.add_child(root_box)
    var vl := Label.new()
    vl.text = VERSION
    vl.add_theme_font_size_override("font_size", 14)
    vl.add_theme_color_override("font_color", Color(0.62, 0.7, 0.92, 0.5))
    vl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    vl.offset_left = 12
    vl.offset_top = -26
    vl.offset_right = 90
    vl.offset_bottom = -6
    vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    add_child(vl)

func _btn(txt: String, gold := false, green := false) -> Button:
    var b := Button.new()
    b.text = txt
    b.custom_minimum_size = Vector2(200, 46)
    b.add_theme_font_size_override("font_size", 20)
    var mk := func(col: Color, border: Color) -> StyleBoxFlat:
        var s := StyleBoxFlat.new()
        s.bg_color = col
        s.border_color = border
        s.set_border_width_all(2)
        s.set_corner_radius_all(23)
        s.content_margin_left = 18
        s.content_margin_right = 18
        return s
    if green:
        b.add_theme_stylebox_override("normal", mk.call(Color("#14c25e"), Color("#0a7a3a")))
        b.add_theme_stylebox_override("hover", mk.call(Color("#3ddc82"), Color("#0a7a3a")))
        b.add_theme_stylebox_override("pressed", mk.call(Color("#0e9b4b"), Color("#0a7a3a")))
        b.add_theme_color_override("font_color", Color("#032312"))
        b.add_theme_color_override("font_hover_color", Color("#032312"))
    elif gold:
        b.add_theme_stylebox_override("normal", mk.call(Color("#ffa622"), Color("#a8620a")))
        b.add_theme_stylebox_override("hover", mk.call(Color("#ffc14d"), Color("#a8620a")))
        b.add_theme_stylebox_override("pressed", mk.call(Color("#d98a1a"), Color("#a8620a")))
        b.add_theme_color_override("font_color", Color("#2a1700"))
        b.add_theme_color_override("font_hover_color", Color("#2a1700"))
    else:
        b.add_theme_stylebox_override("normal", mk.call(Color("#121b3a"), Color("#3a4a80")))
        b.add_theme_stylebox_override("hover", mk.call(Color("#1c2a55"), Color("#5a6cb0")))
        b.add_theme_stylebox_override("pressed", mk.call(Color("#0d1430"), Color("#3a4a80")))
        b.add_theme_color_override("font_color", Color("#c9d6ff"))
        b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_stylebox_override("focus", mk.call(Color.TRANSPARENT, Color("#ffd23f")))
    return b

func _title(txt: String, size := 64, col := Color("#ffd23f")) -> Label:
    var l := Label.new()
    l.text = txt
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", col)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
    l.add_theme_constant_override("outline_size", 8)
    return l

func _sub(txt: String, size := 15, col := Color("#9fb3e8")) -> Label:
    var l := Label.new()
    l.text = txt
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", col)
    return l

func _panel() -> PanelContainer:
    var p := PanelContainer.new()
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#0b1431")
    s.border_color = Color("#2a3a70")
    s.set_border_width_all(1)
    s.set_corner_radius_all(12)
    s.content_margin_left = 16
    s.content_margin_right = 16
    s.content_margin_top = 12
    s.content_margin_bottom = 12
    p.add_theme_stylebox_override("panel", s)
    return p

func _row(controls: Array) -> HBoxContainer:
    var h := HBoxContainer.new()
    h.alignment = BoxContainer.ALIGNMENT_CENTER
    h.add_theme_constant_override("separation", 10)
    for c in controls:
        h.add_child(c)
    return h

func _clear() -> void:
    for c in root_box.get_children():
        c.queue_free()
    focus_first = null

func _opt_group(options: Array, current_idx: int, on_pick: Callable) -> HBoxContainer:
    var h := HBoxContainer.new()
    h.alignment = BoxContainer.ALIGNMENT_CENTER
    h.add_theme_constant_override("separation", 8)
    for i in options.size():
        var b := _btn(options[i], false)
        b.custom_minimum_size = Vector2(120, 40)
        if i == current_idx:
            b.add_theme_stylebox_override("normal", (func() -> StyleBoxFlat:
                var s := StyleBoxFlat.new()
                s.bg_color = Color("#ffa622")
                s.set_corner_radius_all(20)
                return s).call())
            b.add_theme_color_override("font_color", Color("#2a1700"))
        var idx := i
        b.pressed.connect(func():
            sfx.play("click")
            on_pick.call(idx))
        h.add_child(b)
    return h

# ---------- MENU PRINCIPAL ----------
func show_menu(p_career: Career) -> void:
    career = p_career
    _clear()
    root_box.add_child(_title("TENIS ARCADE 3D"))
    root_box.add_child(_sub("ELIGE MODO DE JUEGO"))
    var wt := _btn("WORLD TOUR", true)
    wt.custom_minimum_size = Vector2(340, 52)
    wt.pressed.connect(func():
        sfx.play("click")
        if career != null:
            show_hub("")
        else:
            show_create())
    root_box.add_child(_row([wt]))
    if career != null:
        root_box.add_child(_sub(career.data.name + " · #" + str(career.my_rank()) + " · Temporada " + str(int(career.data.season)), 14, Color("#ffe27a")))
    else:
        root_box.add_child(_sub("Crea tu jugador y conquista el circuito", 14, Color("#ffe27a")))
    var to := _btn("TORNEO")
    to.custom_minimum_size = Vector2(340, 52)
    to.pressed.connect(func(): sfx.play("click"); play_tournament.emit())
    root_box.add_child(_row([to]))
    root_box.add_child(_sub("Cuadro de 8 jugadores: cuartos, semifinal y final", 14))
    var ex := _btn("EXHIBICIÓN")
    ex.custom_minimum_size = Vector2(340, 52)
    ex.pressed.connect(func(): sfx.play("click"); show_exhibition())
    root_box.add_child(_row([ex]))
    root_box.add_child(_sub("Partido suelto: pista, rival, formato y hora a tu gusto", 14))
    var cg := _btn("MINIJUEGOS")
    cg.custom_minimum_size = Vector2(340, 52)
    cg.pressed.connect(func(): sfx.play("click"); show_games())
    root_box.add_child(_row([cg]))
    root_box.add_child(_sub("Juegos de habilidad en la pista", 14))
    root_box.add_child(_sub("AJUSTES DE MANDO", 15, Color("#ffe27a")))
    root_box.add_child(_row([_sub("Eje Y", 14), _opt_group(["NORMAL", "INVERTIDO"], 1 if pad_inv_y else 0, func(i):
        pad_invert.emit(false, i == 1))]))
    root_box.add_child(_row([_sub("Eje X", 14), _opt_group(["NORMAL", "INVERTIDO"], 1 if pad_inv_x else 0, func(i):
        pad_invert.emit(true, i == 1))]))
    root_box.add_child(_sub("Mando: stick mover · A golpe · X globo · B dejada · START pausa\nTeclado: WASD/flechas · ESPACIO golpe · Z globo · SHIFT dejada · P pausa", 13, Color("#8ea2d8")))
    wt.grab_focus()

# ---------- EXHIBICIÓN ----------
func show_exhibition() -> void:
    _clear()
    root_box.add_child(_title("EXHIBICIÓN", 44))
    root_box.add_child(_sub("PARTIDO SUELTO"))
    root_box.add_child(_row([_sub("Pista", 14), _opt_group(["ARCILLA", "CÉSPED", "DURA"], ["clay", "grass", "hard"].find(surface), func(i):
        surface = ["clay", "grass", "hard"][i]
        show_exhibition())]))
    root_box.add_child(_row([_sub("Rival", 14), _opt_group(DIFFS, diff, func(i):
        diff = i
        show_exhibition())]))
    root_box.add_child(_row([_sub("Formato", 14), _opt_group(["1 SET", "MEJOR DE 3"], sets - 1, func(i):
        sets = i + 1
        show_exhibition())]))
    root_box.add_child(_row([_sub("Hora", 14), _opt_group(["DÍA", "NOCHE"], 0 if day else 1, func(i):
        day = i == 0
        show_exhibition())]))
    var play := _btn("JUGAR", false, true)
    play.custom_minimum_size = Vector2(340, 52)
    play.pressed.connect(func():
        sfx.play("click")
        quick_match.emit(surface, diff, sets, day))
    root_box.add_child(_row([play]))
    var back := _btn("VOLVER")
    back.pressed.connect(func(): sfx.play("click"); show_menu(career))
    root_box.add_child(_row([back]))
    play.grab_focus()

# ---------- MINIJUEGOS ----------
func show_games(msg := "") -> void:
    _clear()
    root_box.add_child(_title("MINIJUEGOS", 44))
    root_box.add_child(_sub("JUEGOS DE HABILIDAD EN LA PISTA"))
    if msg != "":
        root_box.add_child(_sub(msg, 15, Color("#cfffc9")))
    var t1 := _btn("DERRIBO DE LATAS · SAQUE", false, true)
    t1.custom_minimum_size = Vector2(340, 52)
    t1.pressed.connect(func():
        sfx.play("click")
        training_from = "games"
        play_training.emit())
    root_box.add_child(_row([t1]))
    root_box.add_child(_sub("10 saques, 8 latas. Derriba todas las que puedas.", 14))
    var soon := _btn("GLOBOS AL ARCO · PRÓXIMAMENTE")
    soon.custom_minimum_size = Vector2(340, 52)
    soon.disabled = true
    root_box.add_child(_row([soon]))
    var soon2 := _btn("VOLEAS AL BOTE · PRÓXIMAMENTE")
    soon2.custom_minimum_size = Vector2(340, 52)
    soon2.disabled = true
    root_box.add_child(_row([soon2]))
    var back := _btn("VOLVER")
    back.pressed.connect(func(): sfx.play("click"); show_menu(career))
    root_box.add_child(_row([back]))
    t1.grab_focus()

# ---------- TORNEO ----------
func show_tourney(st: Dictionary, msg := "") -> void:
    _clear()
    root_box.add_child(_title("TORNEO", 44))
    var rn: String = ["Cuartos de final", "Semifinal", "FINAL"][st.round]
    var surf_name: String = {"clay": "Arcilla", "grass": "Césped", "hard": "Pista dura"}[st.surface]
    root_box.add_child(_sub(rn.to_upper() + " · " + surf_name + " · " + ("Día" if st.day else "Noche"), 16, Color("#ffe27a")))
    if msg != "":
        var mp := _panel()
        var ml := _sub(msg, 15, Color("#cfffc9"))
        ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ml.custom_minimum_size = Vector2(860, 0)
        mp.add_child(ml)
        root_box.add_child(mp)
    var card := _panel()
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 6)
    card.add_child(vb)
    if st.done:
        vb.add_child(_title("🏆 " + st.champion, 30, Color("#ffd23f")))
        if st.results.size() > 0:
            vb.add_child(_sub("Resultados:", 13))
        for r in st.results:
            vb.add_child(_sub(r, 14))
    else:
        for m in st.bracket_text:
            vb.add_child(_sub(m, 16, Color("#ffe27a") if m.find("TÚ") >= 0 else Color("#c9d6ff")))
    root_box.add_child(card)
    var btns := []
    var focus_btn: Control = null
    if not st.done and not st.eliminated:
        var pb := _btn("JUGAR PARTIDO", false, true)
        pb.custom_minimum_size = Vector2(260, 52)
        pb.pressed.connect(func(): sfx.play("click"); tourney_play_match.emit())
        btns.append(pb)
        focus_btn = pb
    else:
        var nb := _btn("NUEVO TORNEO", true)
        nb.custom_minimum_size = Vector2(260, 52)
        nb.pressed.connect(func(): sfx.play("click"); play_tournament.emit())
        btns.append(nb)
        focus_btn = nb
    var mb := _btn("MENÚ PRINCIPAL")
    mb.pressed.connect(func(): sfx.play("click"); back_to_menu.emit())
    btns.append(mb)
    root_box.add_child(_row(btns))
    if focus_btn:
        focus_btn.grab_focus()

# ---------- CARRERA: CREAR ----------
func show_create() -> void:
    _clear()
    root_box.add_child(_title("MODO CARRERA", 44))
    root_box.add_child(_sub("CREA TU JUGADOR"))
    var name_in := LineEdit.new()
    name_in.max_length = 14
    name_in.placeholder_text = "Tu nombre"
    name_in.text = career.data.name if career != null else ""
    name_in.custom_minimum_size = Vector2(320, 52)
    name_in.alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_in.add_theme_font_size_override("font_size", 24)
    root_box.add_child(_row([name_in]))
    root_box.add_child(_sub("Empiezas en el último puesto del ranking de 25 jugadores. 10 torneos por temporada."))
    var start := _btn("EMPEZAR CARRERA", false, true)
    start.pressed.connect(func():
        sfx.play("click")
        var nm := name_in.text.strip_edges()
        if nm == "":
            nm = "Jugador"
        if career == null:
            career = Career.new()
        career.new_career(nm)
        tab = "cal"
        show_hub(""))
    root_box.add_child(_row([start]))
    var back := _btn("VOLVER")
    back.pressed.connect(func(): sfx.play("click"); back_to_menu.emit())
    root_box.add_child(_row([back]))
    start.grab_focus()

# ---------- CARRERA: HUB ----------
func show_hub(msg: String, ok := true) -> void:
    if msg != "":
        career_msg = msg
        career_msg_ok = ok
    _clear()
    var d = career.data
    var head := _panel()
    var hb := HBoxContainer.new()
    hb.add_theme_constant_override("separation", 30)
    head.add_child(hb)
    var info := _sub(d.name + " · Temporada " + str(int(d.season)) + " · " + str(d.won) + "V-" + str(d.lost) + "D · " + str(d.titles) + " títulos", 18, Color.WHITE)
    hb.add_child(info)
    var rk := _sub("#" + str(career.my_rank()) + " · " + str(d.pts) + " pts", 20, Color("#ffd23f"))
    hb.add_child(rk)
    root_box.add_child(head)
    if career_msg != "":
        var mp := _panel()
        var ml := _sub(career_msg, 15, Color("#cfffc9") if career_msg_ok else Color("#ffd0d0"))
        ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ml.custom_minimum_size = Vector2(860, 0)
        mp.add_child(ml)
        root_box.add_child(mp)
        career_msg = ""
    var season_over: bool = d.tIdx >= Career.CAL.size()
    if not season_over:
        var idx: int = d.tour.idx if d.tour else d.tIdx
        var def: Dictionary = Career.CAL[idx]
        var T: Dictionary = Career.TIERS[def.t]
        var card := _panel()
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 6)
        card.add_child(vb)
        vb.add_child(_sub(T.n + " · " + ("Arcilla" if def.s == "clay" else "Pista dura") + " · " + str(int(pow(2, T.rounds))) + " jugadores", 13))
        var rd: String
        var opp = null
        if d.tour:
            rd = career.round_name(T, d.tour.round)
            opp = career.current_opp()
        else:
            rd = career.round_name(T, 0)
        vb.add_child(_title(def.n + " · " + rd, 26, Color.WHITE))
        if opp != null:
            var st := career.standings()
            var orank := 1
            for i in st.size():
                if st[i].n == opp.n:
                    orank = i + 1
            vb.add_child(_sub("Rival: " + opp.n + " (#" + str(orank) + ") " + Career.stars(opp.r), 15, Color("#ffe27a")))
        else:
            vb.add_child(_sub("Se sortea el cuadro al empezar. Cada ronda: 1 set (GS: mejor de 3 desde semis).", 13))
        var btns := []
        var pb := _btn("JUGAR " + ("PARTIDO" if d.tour else "TORNEO"), false, true)
        pb.pressed.connect(func(): sfx.play("click"); play_career_match.emit())
        btns.append(pb)
        var tb2 := _btn("ENTRENAMIENTO · SAQUE", true)
        tb2.pressed.connect(func():
            sfx.play("click")
            training_from = "career"
            play_training.emit())
        btns.append(tb2)
        if d.free > 0:
            var up := _btn("★ MEJORAR (" + str(int(d.free)) + ")", true)
            up.pressed.connect(func(): sfx.play("click"); tab = "stats"; show_hub(""))
            btns.append(up)
        vb.add_child(_row(btns))
        root_box.add_child(card)
    else:
        var st := career.standings()
        var card := _panel()
        var vb := VBoxContainer.new()
        card.add_child(vb)
        vb.add_child(_title("Fin de temporada " + str(d.season), 26, Color("#ffd23f")))
        vb.add_child(_sub("Terminas #" + str(career.my_rank()) + " con " + str(d.pts) + " puntos. Campeón: " + st[0].n + "."))
        var nb := _btn("NUEVA TEMPORADA", true)
        nb.pressed.connect(func():
            sfx.play("click")
            career.end_season()
            show_hub("Empieza la temporada " + str(career.data.season) + ". Los puntos se reducen a la mitad."))
        vb.add_child(_row([nb]))
        root_box.add_child(card)
    # pestañas
    var tabs := HBoxContainer.new()
    tabs.alignment = BoxContainer.ALIGNMENT_CENTER
    tabs.add_theme_constant_override("separation", 8)
    for t in [["cal", "CALENDARIO"], ["rank", "RANKING"], ["stats", "JUGADOR" + (" (" + str(d.free) + ")" if d.free > 0 else "")]]:
        var tb := _btn(t[1])
        tb.custom_minimum_size = Vector2(150, 36)
        var tid: String = t[0]
        if tid == tab:
            tb.add_theme_stylebox_override("normal", (func() -> StyleBoxFlat:
                var s := StyleBoxFlat.new()
                s.bg_color = Color("#3a5cd4")
                s.set_corner_radius_all(18)
                return s).call())
        tb.pressed.connect(func(): sfx.play("click"); tab = tid; show_hub(""))
        tabs.add_child(tb)
    root_box.add_child(tabs)
    var content := _panel()
    content.custom_minimum_size = Vector2(900, 250)
    root_box.add_child(content)
    if tab == "cal":
        content.add_child(_calendar_table())
    elif tab == "rank":
        content.add_child(_rank_table())
    else:
        content.add_child(_stats_table())
    var bot := []
    var mb := _btn("MENÚ PRINCIPAL")
    mb.pressed.connect(func(): sfx.play("click"); back_to_menu.emit())
    bot.append(mb)
    var del := _btn("BORRAR CARRERA")
    del.pressed.connect(func():
        sfx.play("click")
        Career.delete_save()
        career_deleted.emit())
    bot.append(del)
    root_box.add_child(_row(bot))

func _mk_row(cells: Array, widths: Array, cols: Array = [], bold := false) -> HBoxContainer:
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 6)
    for i in cells.size():
        var l := Label.new()
        l.text = str(cells[i])
        l.custom_minimum_size = Vector2(widths[i], 0)
        l.add_theme_font_size_override("font_size", 15)
        var col: Color = cols[i] if i < cols.size() and cols[i] != null else Color("#c9d6ff")
        l.add_theme_color_override("font_color", col)
        if bold:
            l.add_theme_color_override("font_color", Color("#ffe27a"))
        h.add_child(l)
    return h

func _calendar_table() -> VBoxContainer:
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 2)
    v.add_child(_mk_row(["#", "Torneo", "Categoría", "Resultado"], [40, 320, 160, 340], [Color("#8ea2d8"), Color("#8ea2d8"), Color("#8ea2d8"), Color("#8ea2d8")]))
    var d = career.data
    for i in Career.CAL.size():
        var def: Dictionary = Career.CAL[i]
        var T: Dictionary = Career.TIERS[def.t]
        var hi = d.hist[i] if i < d.hist.size() else null
        var res := "—"
        if hi != null:
            res = hi.res + " · +" + str(hi.pts)
        elif i == d.tIdx:
            res = "En juego" if d.tour else "Siguiente"
        v.add_child(_mk_row([i + 1, def.n, T.n, res], [40, 320, 160, 340], [], i == d.tIdx))
    return v

func _rank_table() -> VBoxContainer:
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 2)
    v.add_child(_mk_row(["#", "Jugador", "Nivel", "Puntos"], [40, 340, 140, 120], [Color("#8ea2d8"), Color("#8ea2d8"), Color("#8ea2d8"), Color("#8ea2d8")]))
    var st := career.standings()
    for i in st.size():
        var s = st[i]
        v.add_child(_mk_row([i + 1, s.n + (" (tú)" if s.me else ""), "—" if s.me else Career.stars(s.r), s.pts], [40, 340, 140, 120], [], s.me))
    return v

func _stats_table() -> VBoxContainer:
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 10)
    var d = career.data
    v.add_child(_sub("Puntos de mejora disponibles: " + str(d.free) + " (+2 por victoria, +1 por derrota)", 15, Color("#ffd23f")))
    for s in [["pw", "Potencia", "Golpes más rápidos y duros"], ["sp", "Velocidad", "Corres más rápido"], ["pr", "Precisión", "Menos errores al apuntar"]]:
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        var nm := _sub(s[1], 16, Color.WHITE)
        nm.custom_minimum_size = Vector2(110, 0)
        h.add_child(nm)
        var bar := ProgressBar.new()
        bar.min_value = 0
        bar.max_value = 10
        bar.value = d.stats[s[0]]
        bar.custom_minimum_size = Vector2(400, 22)
        bar.show_percentage = false
        h.add_child(bar)
        var val := _sub(str(d.stats[s[0]]), 16, Color.WHITE)
        val.custom_minimum_size = Vector2(30, 0)
        h.add_child(val)
        var plus := _btn("+")
        plus.custom_minimum_size = Vector2(44, 36)
        plus.disabled = d.free <= 0 or d.stats[s[0]] >= 10
        var key: String = s[0]
        plus.pressed.connect(func():
            sfx.play("click")
            if career.data.free > 0 and career.data.stats[key] < 10:
                career.data.stats[key] += 1
                career.data.free -= 1
                career.save()
            show_hub(""))
        h.add_child(plus)
        var desc := _sub(s[2], 12)
        desc.custom_minimum_size = Vector2(260, 0)
        h.add_child(desc)
        v.add_child(h)
    return v

# ---------- FIN DE PARTIDO ----------
func show_over(win: bool, sets0: int, sets1: int, cpu_label: String, career_result: Dictionary, is_career: bool) -> void:
    _clear()
    root_box.add_child(_title("¡VICTORIA!" if win else "DERROTA", 60, Color("#7dffa8") if win else Color("#ff9c9c")))
    root_box.add_child(_sub(("Ganas " if win else "Pierdes ") + ("contra " + cpu_label + " " if is_career else "") + "· " + str(sets0) + "-" + str(sets1) + " en sets", 20, Color.WHITE))
    if is_career and career_result.has("msg"):
        var mp := _panel()
        var ml := _sub(career_result.msg, 16, Color("#cfffc9") if career_result.ok else Color("#ffd0d0"))
        ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ml.custom_minimum_size = Vector2(700, 0)
        mp.add_child(ml)
        root_box.add_child(mp)
        var cont := _btn("CONTINUAR", false, true)
        cont.pressed.connect(func(): sfx.play("click"); show_hub(""))
        root_box.add_child(_row([cont]))
        cont.grab_focus()
    else:
        var again := _btn("REVANCHA", false, true)
        again.pressed.connect(func(): sfx.play("click"); rematch.emit())
        root_box.add_child(_row([again]))
        var menu := _btn("MENÚ")
        menu.pressed.connect(func(): sfx.play("click"); back_to_menu.emit())
        root_box.add_child(_row([menu]))
        again.grab_focus()
