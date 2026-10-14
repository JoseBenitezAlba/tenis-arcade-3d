class_name MatchHUD
extends CanvasLayer

const PT := ["0", "15", "30", "40"]
var score_rows := []
var server_dots := []
var name_labels := []
var banner: Label
var banner_sub: Label
var hint: Label
var popup_pool := []
var cam: Camera3D
var replay_tag: Label
var replay_t := 0.0
# v0.27: medidor de saque estilo VT + marcador de velocidad
var serve_meter: Control
var serve_needle: ColorRect
var serve_fill: ColorRect
var serve_lock_t := 0.0
var speed_label: Label
var speed_t := 0.0

func _ready() -> void:
    layer = 10
    # marcador
    var panel := PanelContainer.new()
    panel.position = Vector2(14, 606)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.03, 0.05, 0.11, 0.88)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    # v0.32 VT3: borde sutil; acento amarillo TV como barra superior
    sb.border_color = Color(1, 1, 1, 0.14)
    sb.set_border_width_all(1)
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 10
    sb.content_margin_bottom = 10
    panel.add_theme_stylebox_override("panel", sb)
    add_child(panel)
    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 6)
    panel.add_child(vbox)
    var accent := ColorRect.new()
    accent.color = Color("#ffd23f")
    accent.custom_minimum_size = Vector2(0, 4)
    vbox.add_child(accent)
    var grid := GridContainer.new()
    grid.columns = 4
    vbox.add_child(grid)
    var head := ["", "SET", "JUEG", "PTS"]
    for htxt in head:
        var l := Label.new()
        l.text = htxt
        l.add_theme_font_size_override("font_size", 13)
        l.add_theme_color_override("font_color", Color("#8ea2d8"))
        l.custom_minimum_size = Vector2(52, 0)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        grid.add_child(l)
    for i in 2:
        var nm := Label.new()
        nm.add_theme_font_size_override("font_size", 18)
        nm.add_theme_color_override("font_color", Color.WHITE)
        nm.custom_minimum_size = Vector2(180, 0)
        nm.clip_text = true
        grid.add_child(nm)
        name_labels.append(nm)
        var row := []
        for j in 3:
            var v := Label.new()
            v.text = "0"
            v.add_theme_font_size_override("font_size", 21)
            v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            v.custom_minimum_size = Vector2(52, 0)
            grid.add_child(v)
            row.append(v)
        score_rows.append(row)
    score_rows[0][2].add_theme_color_override("font_color", Color("#ffd23f"))
    score_rows[1][2].add_theme_color_override("font_color", Color("#ffd23f"))

    # banner central
    banner = Label.new()
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.position = Vector2(0, 56)
    banner.size = Vector2(1280, 90)
    banner.add_theme_font_size_override("font_size", 44)
    banner.add_theme_color_override("font_color", Color.WHITE)
    banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    banner.add_theme_constant_override("outline_size", 10)
    add_child(banner)
    banner_sub = Label.new()
    banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_sub.position = Vector2(0, 112)
    banner_sub.size = Vector2(1280, 40)
    banner_sub.add_theme_font_size_override("font_size", 24)
    banner_sub.add_theme_color_override("font_color", Color.WHITE)
    banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    banner_sub.add_theme_constant_override("outline_size", 6)
    add_child(banner_sub)

    # pista de controles
    hint = Label.new()
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.position = Vector2(0, 14)
    hint.size = Vector2(1280, 34)
    hint.add_theme_font_size_override("font_size", 16)
    hint.add_theme_color_override("font_color", Color.WHITE)
    hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    hint.add_theme_constant_override("outline_size", 5)
    add_child(hint)

    for i in 4:
        var p := Label.new()
        p.add_theme_font_size_override("font_size", 26)
        p.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
        p.add_theme_constant_override("outline_size", 6)
        p.visible = false
        add_child(p)
        popup_pool.append({"l": p, "age": 0.0, "active": false, "wp": Vector3.ZERO})

    # medidor de saque (derecha, vertical): zona roja abajo, amarilla, verde perfecta, roja arriba
    serve_meter = Control.new()
    serve_meter.position = Vector2(1196, 200)
    serve_meter.visible = false
    add_child(serve_meter)
    var mbg := ColorRect.new()
    mbg.color = Color(0.02, 0.04, 0.10, 0.85)
    mbg.size = Vector2(26, 246)
    mbg.position = Vector2(-3, -3)
    serve_meter.add_child(mbg)
    # v0.30: la barra muestra la CALIDAD q del lanzamiento - verde arriba del todo
    var zones = [
        [0.000, 0.45, Color("#c33c3c")],
        [0.45, 0.70, Color("#e0a53c")],
        [0.70, 0.88, Color("#d8d24a")],
        [0.88, 1.000, Color("#49d96b")],
    ]
    for z in zones:
        var r := ColorRect.new()
        r.color = z[2]
        r.color.a = 0.88
        r.size = Vector2(20, 240.0 * (z[1] - z[0]))
        r.position = Vector2(0, 240.0 * (1.0 - z[1]))  # v0.27: crece hacia arriba estilo VT
        serve_meter.add_child(r)
    serve_fill = ColorRect.new()
    serve_fill.color = Color(1, 1, 1, 0.35)
    serve_fill.size = Vector2(20, 0)
    serve_fill.position = Vector2(0, 0)
    serve_meter.add_child(serve_fill)
    serve_needle = ColorRect.new()
    serve_needle.color = Color.WHITE
    serve_needle.size = Vector2(26, 4)
    serve_needle.position = Vector2(-3, -2)
    serve_meter.add_child(serve_needle)
    var mlab := Label.new()
    mlab.text = "SAQUE"
    mlab.position = Vector2(-14, -26)
    mlab.add_theme_font_size_override("font_size", 14)
    mlab.add_theme_color_override("font_color", Color.WHITE)
    mlab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    mlab.add_theme_constant_override("outline_size", 4)
    serve_meter.add_child(mlab)

    # velocidad del saque, junto al marcador
    speed_label = Label.new()
    speed_label.position = Vector2(14, 566)
    speed_label.add_theme_font_size_override("font_size", 20)
    speed_label.add_theme_color_override("font_color", Color("#9fd8ff"))
    speed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
    speed_label.add_theme_constant_override("outline_size", 6)
    speed_label.visible = false
    add_child(speed_label)

func set_names(n0: String, n1: String) -> void:
    name_labels[0].set_meta("base", n0.to_upper().substr(0, 14))
    name_labels[1].set_meta("base", n1.to_upper().substr(0, 16))
    name_labels[0].text = "  " + name_labels[0].get_meta("base")
    name_labels[1].text = "  " + name_labels[1].get_meta("base")

func update_score(M) -> void:  # sin tipo: acepta MatchState (v0.32) o Dictionary legado
    for i in 2:
        score_rows[i][0].text = str(M.sets[i])
        score_rows[i][1].text = str(M.games[i])
        score_rows[i][2].text = PT[mini(3, M.pts[i])]
        var base: String = name_labels[i].get_meta("base")
        name_labels[i].text = ("● " if M.server == i else "  ") + base

func show_replay() -> void:
    if replay_tag == null:
        replay_tag = Label.new()
        replay_tag.text = "  REPETICION"
        replay_tag.position = Vector2(14, 12)
        replay_tag.add_theme_font_size_override("font_size", 24)
        replay_tag.add_theme_color_override("font_color", Color(1, 1, 1))
        replay_tag.add_theme_color_override("font_outline_color", Color(0.5, 0, 0, 0.9))
        replay_tag.add_theme_constant_override("outline_size", 6)
        add_child(replay_tag)
    replay_tag.visible = true
    replay_t = 0.0

func hide_replay() -> void:
    if replay_tag != null:
        replay_tag.visible = false

func show_banner(txt: String, sub: String, color: Color, big := false) -> void:
    banner.text = txt
    banner.add_theme_color_override("font_color", color)
    banner.add_theme_font_size_override("font_size", 60 if big else 44)
    banner_sub.text = sub
    banner.modulate.a = 1.0
    banner_sub.modulate.a = 1.0

func hide_popups() -> void:
    for p in popup_pool:
        p.active = false
        p.l.visible = false

func hide_banner() -> void:
    banner.modulate.a = 0.0
    banner_sub.modulate.a = 0.0

func set_hint(t: String) -> void:
    hint.text = t

func popup(txt: String, wp: Vector3, color: Color) -> void:
    for p in popup_pool:
        if not p.active:
            p.active = true
            p.age = 0.0
            p.wp = wp
            p.l.text = txt
            p.l.add_theme_color_override("font_color", color)
            p.l.visible = true
            return

func serve_meter_update(p: float) -> void:
    if serve_meter == null:
        return
    serve_meter.visible = true
    p = clampf(p, 0.0, 1.0)
    serve_fill.size.y = 240.0 * p
    serve_fill.position.y = 240.0 * (1.0 - p)
    serve_needle.position.y = 240.0 * (1.0 - p) - 2.0
    # v0.30: p es la calidad q directamente (verde solo en la zona optima real)
    serve_needle.color = Color("#49d96b") if p >= 0.88 else (Color("#ffd23f") if p > 0.45 else Color("#ff6b6b"))

func serve_meter_hide() -> void:
    if serve_meter != null:
        serve_meter.visible = false

func show_serve_speed(kmh: int) -> void:
    speed_label.text = "SAQUE  %d km/h" % kmh
    speed_label.visible = true
    speed_label.modulate.a = 1.0
    speed_t = 2.2

func _process(dt: float) -> void:
    if speed_t > 0.0:
        speed_t -= dt
        if speed_t <= 0.0:
            speed_label.visible = false
        elif speed_t < 0.6:
            speed_label.modulate.a = speed_t / 0.6
    if replay_tag != null and replay_tag.visible:
        replay_t += dt
        replay_tag.modulate.a = 1.0 if fmod(replay_t, 0.9) < 0.6 else 0.35
    if speed_t > 0.0:
        speed_t -= dt
        if speed_t <= 0.0:
            speed_label.visible = false
        elif speed_t < 0.6:
            speed_label.modulate.a = speed_t / 0.6
    for p in popup_pool:
        if p.active:
            p.age += dt
            if p.age > 0.6:
                p.active = false
                p.l.visible = false
            else:
                p.l.modulate.a = 1.0 - p.age / 0.6
                if cam:
                    var sp := cam.unproject_position(p.wp + Vector3(0, 2.2 + p.age * 0.6, 0))
                    p.l.position = sp - Vector2(40, 0)
