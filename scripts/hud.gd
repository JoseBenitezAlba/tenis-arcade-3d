class_name MatchHUD
extends CanvasLayer

const PT: = ["0", "15", "30", "40"]
var score_rows: = []
var server_dots: = []
var name_labels: = []
var banner: Label
var banner_sub: Label
var hint: Label
var popup_pool: = []
var big_popup: Label
var side_popup: Label
var side_popup_t: = 0.0
var big_popup_t: = 0.0
var cam: Camera3D
var replay_tag: Label
var replay_t: = 0.0

var serve_meter: Control
var serve_needle: ColorRect
var serve_fill: ColorRect
var serve_lock_t: = 0.0
var speed_label: Label
var speed_t: = 0.0
var point_card: PanelContainer
var score_panel: PanelContainer
var score_sb: StyleBoxFlat
var _glow_level: = 0
var _glow_t: = 0.0
var point_card_title: Label
var point_card_pts: Label
var point_card_t: = 0.0

func _ready() -> void :
	layer = 10

	var panel: = PanelContainer.new()
	panel.position = Vector2(14, 606)
	var sb: = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.11, 0.88)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10

	sb.border_color = Color(1, 1, 1, 0.14)
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 12
	sb.set_border_width_all(1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	score_panel = panel
	score_sb = sb
	add_child(panel)
	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var accent: = ColorRect.new()
	accent.color = Color("#ffd23f")
	accent.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(accent)
	var grid: = GridContainer.new()
	grid.columns = 4
	vbox.add_child(grid)
	var head: = ["", "SET", "JUEG", "PTS"]
	for htxt in head:
		var l: = Label.new()
		l.text = htxt
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color("#8ea2d8"))
		l.custom_minimum_size = Vector2(52, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l)
	for i in 2:
		var nm: = Label.new()
		nm.add_theme_font_size_override("font_size", 18)
		nm.add_theme_color_override("font_color", Color.WHITE)
		nm.custom_minimum_size = Vector2(180, 0)
		nm.clip_text = true
		grid.add_child(nm)
		name_labels.append(nm)
		var row: = []
		for j in 3:
			var v: = Label.new()
			v.text = "0"
			v.add_theme_font_size_override("font_size", 21)
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.custom_minimum_size = Vector2(52, 0)
			grid.add_child(v)
			row.append(v)
		score_rows.append(row)
	name_labels[0].add_theme_color_override("font_color", Color("#ffffff"))
	name_labels[1].add_theme_color_override("font_color", Color("#c8d3ea"))
	score_rows[0][2].add_theme_color_override("font_color", Color("#ffd23f"))
	score_rows[1][2].add_theme_color_override("font_color", Color("#ffd23f"))


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


	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 14)
	hint.size = Vector2(1280, 34)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 5)
	add_child(hint)


	big_popup = Label.new()
	big_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_popup.position = Vector2(0, 132)
	big_popup.size = Vector2(1280, 60)
	big_popup.add_theme_font_size_override("font_size", 34)
	big_popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	big_popup.add_theme_constant_override("outline_size", 9)
	big_popup.visible = false
	add_child(big_popup)



	side_popup = Label.new()
	side_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	side_popup.position = Vector2(1280 - 320, 340)
	side_popup.size = Vector2(290, 40)
	side_popup.add_theme_font_size_override("font_size", 22)
	side_popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	side_popup.add_theme_constant_override("outline_size", 8)
	side_popup.visible = false
	add_child(side_popup)

	for i in 4:
		var p: = Label.new()
		p.add_theme_font_size_override("font_size", 17)
		p.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
		p.add_theme_constant_override("outline_size", 4)
		p.visible = false
		add_child(p)
		popup_pool.append({"l": p, "age": 0.0, "active": false, "wp": Vector3.ZERO})


	serve_meter = Control.new()
	serve_meter.position = Vector2(1236, 230)
	serve_meter.visible = false
	add_child(serve_meter)
	var mbg: = ColorRect.new()
	mbg.color = Color(0.02, 0.04, 0.1, 0.62)
	mbg.size = Vector2(14, 186)
	mbg.position = Vector2(-2, -3)
	serve_meter.add_child(mbg)

	var zones = [
		[0.0, 0.45, Color("#c33c3c")], 
		[0.45, 0.7, Color("#e0a53c")], 
		[0.7, 0.88, Color("#d8d24a")], 
		[0.88, 1.0, Color("#49d96b")], 
	]
	for z in zones:
		var r: = ColorRect.new()
		r.color = z[2]
		r.color.a = 0.75
		r.size = Vector2(10, 180.0 * (z[1] - z[0]))
		r.position = Vector2(0, 180.0 * (1.0 - z[1]))
		serve_meter.add_child(r)
	serve_fill = ColorRect.new()
	serve_fill.color = Color(1, 1, 1, 0.25)
	serve_fill.size = Vector2(10, 0)
	serve_fill.position = Vector2(0, 0)
	serve_meter.add_child(serve_fill)
	serve_needle = ColorRect.new()
	serve_needle.color = Color.WHITE
	serve_needle.size = Vector2(14, 3)
	serve_needle.position = Vector2(-2, -1)
	serve_meter.add_child(serve_needle)
	mlab = Label.new()
	mlab.text = "SAQUE"
	mlab.position = Vector2(-8, -26)
	mlab.add_theme_font_size_override("font_size", 11)
	mlab.add_theme_color_override("font_color", Color.WHITE)
	mlab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	mlab.add_theme_constant_override("outline_size", 4)
	serve_meter.add_child(mlab)


	speed_label = Label.new()
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_label.position = Vector2(1280 - 330, 646)
	speed_label.size = Vector2(316, 30)
	speed_label.add_theme_font_size_override("font_size", 20)
	speed_label.add_theme_color_override("font_color", Color.WHITE)
	speed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	speed_label.add_theme_constant_override("outline_size", 6)
	speed_label.visible = false
	add_child(speed_label)

func set_names(n0: String, n1: String) -> void :
	name_labels[0].set_meta("base", n0.to_upper().substr(0, 14))
	name_labels[1].set_meta("base", n1.to_upper().substr(0, 16))
	name_labels[0].text = "  " + name_labels[0].get_meta("base")
	name_labels[1].text = "  " + name_labels[1].get_meta("base")

func update_score(M) -> void :
	var in_tb: bool = "tb" in M and M.tb
	for i in 2:
		score_rows[i][0].text = str(M.sets[i])
		score_rows[i][1].text = str(M.games[i])

		score_rows[i][2].text = str(M.tb_pts[i]) if in_tb else PT[mini(3, M.pts[i])]
		var base: String = name_labels[i].get_meta("base")
		name_labels[i].text = ("● " if M.server == i else "  ") + base

func show_point_card(mine: bool, pts: String) -> void :

	if point_card == null:
		point_card = PanelContainer.new()
		var sb: = StyleBoxFlat.new()
		sb.bg_color = Color(0.28, 0.03, 0.05, 0.92)
		sb.border_color = Color(1, 1, 1, 0.25)
		sb.set_border_width_all(2)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		point_card.add_theme_stylebox_override("panel", sb)
		var vb: = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		point_card.add_child(vb)
		point_card_title = Label.new()
		point_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		point_card_title.add_theme_font_size_override("font_size", 30)
		point_card_title.add_theme_color_override("font_color", Color.WHITE)
		vb.add_child(point_card_title)
		point_card_pts = Label.new()
		point_card_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		point_card_pts.add_theme_font_size_override("font_size", 22)
		point_card_pts.add_theme_color_override("font_color", Color("#ffd23f"))
		vb.add_child(point_card_pts)
		add_child(point_card)
	var nm: String = name_labels[0].get_meta("base") if mine else name_labels[1].get_meta("base")
	point_card_title.text = "PUNTO  " + nm
	point_card_pts.text = pts
	point_card.visible = true
	point_card.modulate.a = 1.0
	point_card_t = 1.5

	call_deferred("_center_point_card")

func _center_point_card() -> void :
	if point_card != null:
		point_card.position = Vector2((1280.0 - point_card.size.x) / 2.0, 190.0)

func show_replay() -> void :
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

func hide_replay() -> void :
	if replay_tag != null:
		replay_tag.visible = false

func show_banner(txt: String, sub: String, color: Color, big: = false) -> void :
	banner.text = txt
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_font_size_override("font_size", 60 if big else 44)
	banner_sub.text = sub
	banner.modulate.a = 1.0
	banner_sub.modulate.a = 1.0

func hide_popups() -> void :
	for p in popup_pool:
		p.active = false
		p.l.visible = false

func hide_banner() -> void :
	banner.modulate.a = 0.0
	banner_sub.modulate.a = 0.0

func set_hint(t: String) -> void :
	hint.text = t

func popup_side(txt: String, color: Color) -> void :
	side_popup.text = txt
	side_popup.add_theme_color_override("font_color", color)
	side_popup.visible = true
	side_popup.modulate.a = 1.0
	side_popup_t = 1.15

func popup_big(txt: String, color: Color) -> void :
	big_popup.text = txt
	big_popup.add_theme_color_override("font_color", color)
	big_popup.visible = true
	big_popup.modulate.a = 1.0
	big_popup_t = 1.15

func popup(txt: String, wp: Vector3, color: Color) -> void :
	for p in popup_pool:
		if not p.active:
			p.active = true
			p.age = 0.0
			p.wp = wp
			p.l.text = txt
			p.l.add_theme_color_override("font_color", color)
			p.l.visible = true
			return

var mlab: Label

func set_meter_label(t: String) -> void :
	if mlab != null:
		mlab.text = t

func serve_meter_update(p: float) -> void :
	if serve_meter == null:
		return
	serve_meter.visible = true
	p = clampf(p, 0.0, 1.0)
	serve_fill.size.y = 180.0 * p
	serve_fill.position.y = 180.0 * (1.0 - p)
	serve_needle.position.y = 180.0 * (1.0 - p) - 1.0

	serve_needle.color = Color("#49d96b") if p >= 0.88 else (Color("#ffd23f") if p > 0.45 else Color("#ff6b6b"))

func serve_meter_hide() -> void :
	if serve_meter != null:
		serve_meter.visible = false

func show_speed_kmh(kmh: int, is_serve: bool) -> void :

	speed_label.text = ("SAQUE  %d km/h" % kmh) if is_serve else ("VELOCIDAD  %d km/h" % kmh)
	speed_label.visible = true
	speed_label.modulate.a = 1.0
	speed_t = 2.2


static func glow_alpha(level: int, t: float) -> float:
	return 0.0 if level < 2 else 0.55 + 0.35 * sin(t * 7.0)


static func vignette_target(level: int) -> float:
	if level >= 3:
		return 0.34
	if level == 2:
		return 0.22
	return 0.0

var vignette: TextureRect = null
var vignette_a: = 0.0

func _ensure_vignette() -> void :
	if vignette != null:
		return
	var g: = Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 1)])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gt: = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 0.5)
	gt.width = 256
	gt.height = 256
	vignette = TextureRect.new()
	vignette.name = "Vignette"
	vignette.texture = gt
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = 0.0
	add_child(vignette)
	move_child(vignette, 0)

func set_score_glow(level: int) -> void :
	_glow_level = level
	if vignette_target(level) > 0.0:
		_ensure_vignette()

func _process(dt: float) -> void :

	_glow_t += dt
	if vignette != null:
		vignette_a = move_toward(vignette_a, vignette_target(_glow_level), dt * 0.5)
		vignette.modulate.a = vignette_a
	if score_sb != null:
		var ga: float = glow_alpha(_glow_level, _glow_t)
		if ga > 0.0:
			score_sb.border_color = Color(1.0, 0.82, 0.3, ga)
			score_sb.set_border_width_all(2)
			score_sb.bg_color = Color(0.16, 0.11, 0.03, 0.92).lerp(Color(0.03, 0.05, 0.11, 0.88), 1.0 - ga)
		else:
			score_sb.border_color = Color(1, 1, 1, 0.14)
			score_sb.set_border_width_all(1)
			score_sb.bg_color = Color(0.03, 0.05, 0.11, 0.88)
	if side_popup_t > 0.0:
		side_popup_t -= dt
		if side_popup_t <= 0.0:
			side_popup.visible = false
		elif side_popup_t < 0.5:
			side_popup.modulate.a = side_popup_t / 0.5
	if speed_t > 0.0:
		speed_t -= dt
		if speed_t <= 0.0:
			speed_label.visible = false
		elif speed_t < 0.6:
			speed_label.modulate.a = speed_t / 0.6
	if replay_tag != null and replay_tag.visible:
		replay_t += dt
		replay_tag.modulate.a = 1.0 if fmod(replay_t, 0.9) < 0.6 else 0.35
	if side_popup_t > 0.0:
		side_popup_t -= dt
		if side_popup_t <= 0.0:
			side_popup.visible = false
		elif side_popup_t < 0.5:
			side_popup.modulate.a = side_popup_t / 0.5
	if speed_t > 0.0:
		speed_t -= dt
		if speed_t <= 0.0:
			speed_label.visible = false
		elif speed_t < 0.6:
			speed_label.modulate.a = speed_t / 0.6
	if point_card_t > 0.0:
		point_card_t -= dt
		if point_card != null:
			if point_card_t <= 0.0:
				point_card.visible = false
			elif point_card_t < 0.4:
				point_card.modulate.a = point_card_t / 0.4
	if big_popup_t > 0.0:
		big_popup_t -= dt
		if big_popup_t <= 0.0:
			big_popup.visible = false
		elif big_popup_t < 0.35:
			big_popup.modulate.a = big_popup_t / 0.35
	for p in popup_pool:
		if p.active:
			p.age += dt
			if p.age > 0.6:
				p.active = false
				p.l.visible = false
			else:
				p.l.modulate.a = 1.0 - p.age / 0.6
				if cam:
					var sp: = cam.unproject_position(p.wp + Vector3(0, 1.5 + p.age * 0.35, 0))
					p.l.position = sp - Vector2(26, 0)
