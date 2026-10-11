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

func _ready() -> void:
    layer = 10
    # marcador
    var panel := PanelContainer.new()
    panel.position = Vector2(14, 606)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.03, 0.05, 0.11, 0.86)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.border_color = Color(1, 1, 1, 0.18)
    sb.set_border_width_all(1)
    sb.content_margin_left = 12
    sb.content_margin_right = 12
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", sb)
    add_child(panel)
    var grid := GridContainer.new()
    grid.columns = 4
    panel.add_child(grid)
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
        nm.add_theme_font_size_override("font_size", 16)
        nm.add_theme_color_override("font_color", Color.WHITE)
        nm.custom_minimum_size = Vector2(180, 0)
        nm.clip_text = true
        grid.add_child(nm)
        name_labels.append(nm)
        var row := []
        for j in 3:
            var v := Label.new()
            v.text = "0"
            v.add_theme_font_size_override("font_size", 19)
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
    banner.position = Vector2(0, 240)
    banner.size = Vector2(1280, 90)
    banner.add_theme_font_size_override("font_size", 72)
    banner.add_theme_color_override("font_color", Color.WHITE)
    banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    banner.add_theme_constant_override("outline_size", 10)
    add_child(banner)
    banner_sub = Label.new()
    banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_sub.position = Vector2(0, 330)
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

func set_names(n0: String, n1: String) -> void:
    name_labels[0].set_meta("base", n0.to_upper().substr(0, 14))
    name_labels[1].set_meta("base", n1.to_upper().substr(0, 16))
    name_labels[0].text = "  " + name_labels[0].get_meta("base")
    name_labels[1].text = "  " + name_labels[1].get_meta("base")

func update_score(M: Dictionary) -> void:
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

func show_banner(txt: String, sub: String, color: Color) -> void:
    banner.text = txt
    banner.add_theme_color_override("font_color", color)
    banner_sub.text = sub
    banner.modulate.a = 1.0
    banner_sub.modulate.a = 1.0

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

func _process(dt: float) -> void:
    if replay_tag != null and replay_tag.visible:
        replay_t += dt
        replay_tag.modulate.a = 1.0 if fmod(replay_t, 0.9) < 0.6 else 0.35
    for p in popup_pool:
        if p.active:
            p.age += dt
            if p.age > 0.9:
                p.active = false
                p.l.visible = false
            else:
                p.l.modulate.a = 1.0 - p.age / 0.9
                if cam:
                    var sp := cam.unproject_position(p.wp + Vector3(0, 2.2 + p.age * 0.6, 0))
                    p.l.position = sp - Vector2(40, 0)
