class_name MatchView
extends Node3D



class PauseGuard extends Node:
	var mv: Node

	func _unhandled_input(event: InputEvent) -> void :
		mv._on_pause_input(event)

signal match_finished(win: bool)
signal quit_to_menu

const L: = 23.77
const NZ: = L / 2.0
var sim: TennisSim
var court: Node3D
var crowd: CrowdFX
var rigs: = []
var ball_mesh: MeshInstance3D
var ball_mat: StandardMaterial3D
var seam_mat: StandardMaterial3D
var clay_tint: = 0.0
var leg_dust: = 0.0
var ball_shadow: MeshInstance3D
var ball_seam: MeshInstance3D
var shadows: = []
var ball_shadow_mat: StandardMaterial3D
var bounce_ring: MeshInstance3D
var bounce_ring_mat: StandardMaterial3D
var trail: = []
var flashes: = []
var flash_t: = 0.0
var sweat_v: = 0.0
var _fatigue: = 0.0
var cam: Camera3D
var fill_light: DirectionalLight3D
var night_mode: bool = false

const CAM_POS: = Vector3(0, 4.8, -9.8)
const CAM_FOV: = 41.0
const CAM_LOOK_Y: = 1.0
var hud: MatchHUD
var sfx: SoundKit
var dust_pool: = []
var ring_pool: = []

static func ring_params(spd: float) -> Vector2:

	var f: = clampf(spd / 45.0, 0.0, 1.0)
	return Vector2(0.55 + 0.95 * f, 0.7 + 0.3 * f)

func _make_ring_tex() -> ImageTexture:
	var img: = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r: = Vector2(x - 31.5, y - 31.5).length() / 31.5
			var a: = clampf(1.0 - absf(r - 0.75) / 0.24, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func spawn_ring(pos: Vector3, spd: float) -> void :
	var rp: = ring_params(spd)
	for r in ring_pool:
		if r.life <= 0.0:
			r.life = 0.2
			r.max = 0.2
			r.rad = rp.x
			r.a0 = rp.y
			r.m.position = pos
			r.m.visible = true
			r.m.scale = Vector3.ONE * 0.1
			return

func _tick_rings(dt: float) -> void :
	for ri in rigs.size():
		var rg = rigs[ri]
		if rg.hop_landed:
			rg.hop_landed = false
			spawn_dust(Vector3(rg.position.x, 0.0, rg.position.z), 4, dust_color(0.45), 1.8)
		if rg.whoosh_pending > 0.0:
			var wv: float = PlayerFig.whoosh_vol(rg.whoosh_pending)
			sfx.play("whoosh", wv * (1.0 if ri == 0 else 0.6), clampf(0.85 + rg.whoosh_pending * 0.008, 0.9, 1.2))
			rg.whoosh_pending = 0.0
	for r in ring_pool:
		if r.life > 0.0:
			r.life -= dt
			if r.life <= 0.0:
				r.m.visible = false
			else:
				var f: float = 1.0 - r.life / r.max
				r.m.scale = Vector3.ONE * (r.rad * 2.0) * (0.25 + 0.75 * sqrt(f))
				var c: Color = Color(1.0, 0.97, 0.8, r.a0 * (1.0 - f))
				r.mat.albedo_color = c
var dust_trail: = 0.0
var net_shake: = 0.0
var net_node: MeshInstance3D = null
var _amb: AudioStreamPlayer = null
var slide_t: = [0.0, 0.0]
var skid_pool: = []
const DECAL_Y: = 0.062
var _swing_prev: = [0.0, 0.0]

var surface: = "clay"
var brake_cd: = [0.0, 0.0]
var step_t: = [0.0, 0.0]
var burst_prev: = [0.0, 0.0]
var rally_label: Label
var rally_best: = 0
var rally_change_t: = 0.0
var mark_pool: = []
var banner_t: = 0.0
const SERVE_KMH_K: = 8.4
const HELD_BALL_K: = 0.3
const TOSS_BALL_K: = 0.42

static func held_ball_scale(held: bool, toss: bool, toss_t: float) -> float:
	if held:
		return HELD_BALL_K
	if toss:
		return lerpf(HELD_BALL_K, TOSS_BALL_K, clampf(toss_t / 0.35, 0.0, 1.0))
	return 1.0
const HIT_KMH_K: = 4.0  # v0.138: golpes de fondo (la gravedad arcade fija una velocidad minima alta; el factor de saque inflaba los peloteos)
var banner_dur: = 0.0
var hint_t: = 9.0
var demo: = false

var touch_ui: = false
var is_career: = false
var paused_game: = false
var pause_layer: CanvasLayer
var over_sent: = false
var shake: = 0.0
var hitstop_t: = 0.0
var ball_squash: = 0.0
var ball_vis_scale: = 1.0
var _point_winner: = -1
var _prev_sim_state: = ""
var _serve_blank: = 0.0
var _prev_state: = ""
var point_hot: = 0
var cam_look: = Vector3(0, 1.0, 11.885)
var _line_armed: = false
var _hint_hidden: = false

var rec: = []
var replaying: = false
var replay_pending: = false
var replay_i: = 0.0
var replay_test: = false
var replay_side: = 1.0
const REC_MAX: = 2700

func setup(cfg: Dictionary) -> void :
	demo = cfg.get("demo", false)
	clay_tint = 0.0
	leg_dust = 0.0
	is_career = cfg.get("career", false)
	var ps = cfg.get("PS", {})
	if typeof(ps) != TYPE_DICTIONARY:
		ps = {}
	sim = TennisSim.new(demo, cfg.AIP, ps, cfg.get("cpu_name", "CPU"), cfg.get("sets_to_win", 1))
	sim.surface = get_meta("surface", "clay")
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _ready() -> void :
	if sim == null:
		sim = TennisSim.new(true)
		sim.surface = get_meta("surface", "clay")
	surface = get_meta("surface", "clay")
	var tod_v = get_meta("tod", -1)
	court = CourtBuilder.build(surface, (0 if get_meta("day", false) else 1) if tod_v == -1 else tod_v)
	net_node = court.get_node_or_null("NetMesh")
	night_mode = ((0 if get_meta("day", false) else 1) if tod_v == -1 else tod_v) == 1
	fill_light = DirectionalLight3D.new()
	fill_light.shadow_enabled = false
	fill_light.light_energy = 0.0
	fill_light.light_color = Color("#fff0dc")
	add_child(fill_light)
	add_child(court)
	crowd = CrowdFX.new()
	add_child(crowd)
	crowd.build()

	sfx = SoundKit.new()
	add_child(sfx)
	_amb = AudioStreamPlayer.new()
	_amb.stream = sfx.streams["ambience"]
	_amb.volume_db = linear_to_db(0.08)
	add_child(_amb)
	_amb.play()


	var cpu_look_meta = get_meta("cpu_look", 2)
	var cpu_look_i: int = cpu_look_meta if typeof(cpu_look_meta) == TYPE_INT else 2
	rigs = [PlayerFig.new(0, true), PlayerFig.new(cpu_look_i, false)]
	for r in rigs:
		add_child(r)


	ball_mesh = MeshInstance3D.new()
	var bs: = SphereMesh.new()
	bs.radius = 0.17
	bs.height = 0.34
	var bm: = StandardMaterial3D.new()
	ball_mat = bm
	bm.albedo_color = Color("#e6ff4d")
	bm.emission_enabled = true
	bm.emission = Color("#d8f040")
	bm.emission_energy_multiplier = 1.0
	bs.material = bm
	ball_mesh.mesh = bs
	add_child(ball_mesh)


	ball_seam = MeshInstance3D.new()
	var ss: = SphereMesh.new()
	ss.radius = 0.172
	ss.height = 0.344
	var sm: = StandardMaterial3D.new()
	seam_mat = sm
	sm.albedo_texture = TexGen.ball_texture()
	sm.emission_enabled = true
	sm.emission = Color("#d8f040")
	sm.emission_energy_multiplier = 0.55
	ss.material = sm
	ball_seam.mesh = ss
	ball_mesh.add_child(ball_seam)
	var _bw: = court.get_node_or_null("BallWatcher")
	if _bw:
		_bw.ball = ball_mesh


	var sh_tex: = TexGen.shadow_texture()
	for i in 3:
		var sh_mat: = StandardMaterial3D.new()
		sh_mat.albedo_texture = sh_tex
		sh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var q: = MeshInstance3D.new()
		var qm: = QuadMesh.new()
		qm.size = Vector2(1.2, 1.2)
		qm.material = sh_mat
		q.mesh = qm
		q.rotation_degrees.x = -90
		q.position.y = 0.07
		add_child(q)
		if i < 2:
			shadows.append(q)
		else:
			ball_shadow = q
			ball_shadow_mat = sh_mat
	StaticShadows.add_to(self, sh_tex, NZ)


	bounce_ring_mat = StandardMaterial3D.new()
	bounce_ring_mat.albedo_texture = TexGen.ring_texture()


	bounce_ring_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0) if surface == "clay" else Color(1.0, 0.95, 0.35, 0.9)
	bounce_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bounce_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bounce_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bounce_ring = MeshInstance3D.new()
	var rq: = QuadMesh.new()
	rq.size = Vector2(2.2, 2.2)
	rq.material = bounce_ring_mat
	bounce_ring.mesh = rq
	bounce_ring.rotation_degrees.x = -90
	bounce_ring.position.y = 0.075
	bounce_ring.visible = false
	add_child(bounce_ring)


	for i in 9:
		var t: = MeshInstance3D.new()
		var ts: = SphereMesh.new()
		ts.radius = 0.105
		ts.height = 0.21
		var tm: = StandardMaterial3D.new()
		tm.albedo_color = Color(0.88, 1.0, 0.35, 0.42)
		tm.emission_enabled = true
		tm.emission = Color(0.88, 1.0, 0.35)
		tm.emission_energy_multiplier = 0.85
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ts.material = tm
		t.mesh = ts
		t.visible = false
		add_child(t)
		trail.append({"m": t, "mat": tm})



	for i in 14:
		var fm: = MeshInstance3D.new()
		var fq: = QuadMesh.new()
		fq.size = Vector2(0.4, 0.4)
		var fmat: = StandardMaterial3D.new()
		fmat.albedo_color = Color(1, 1, 1, 0.9)
		fmat.emission_enabled = true
		fmat.emission = Color(1, 1, 1)
		fmat.emission_energy_multiplier = 3.0
		fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		fmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		fq.material = fmat
		fm.mesh = fq
		fm.visible = false
		add_child(fm)

		var fpos: Vector3
		if i % 3 == 2:
			fpos = Vector3((13.0 if i % 2 == 0 else -13.0) + randf_range(-1.0, 1.0), randf_range(3.5, 8.0), randf_range(-10.0, 10.0))
		else:
			fpos = Vector3(randf_range(-12.0, 12.0), randf_range(3.5, 8.5), (14.5 if i % 2 == 0 else -14.5) + randf_range(-1.0, 1.0))
		flashes.append({"m": fm, "life": 0.0, "pos": fpos})

	var ring_tex: = _make_ring_tex()
	for i in 6:
		var ringm: = MeshInstance3D.new()
		var hitq: = QuadMesh.new()
		var ringmat: = StandardMaterial3D.new()
		ringmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ringmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ringmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		ringmat.albedo_texture = ring_tex
		ringmat.no_depth_test = true
		hitq.material = ringmat
		ringm.mesh = hitq
		ringm.visible = false
		add_child(ringm)
		ring_pool.append({"m": ringm, "mat": ringmat, "life": 0.0, "max": 0.2, "rad": 0.5, "a0": 0.5})


	for i in 40:
		var d: = MeshInstance3D.new()
		var ds: = SphereMesh.new()
		ds.radius = 0.05
		ds.height = 0.1
		var dm: = StandardMaterial3D.new()
		dm.albedo_color = Color(1, 1, 1, 0.5)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ds.material = dm
		d.mesh = ds
		d.visible = false
		add_child(d)
		dust_pool.append({"m": d, "mat": dm, "life": 0.0, "max": 0.6, "v": Vector3.ZERO})


	for i in 10:
		var mk: = MeshInstance3D.new()
		var mc: = CylinderMesh.new()
		mc.top_radius = 0.14
		mc.bottom_radius = 0.14
		mc.height = 0.006
		var mm: = StandardMaterial3D.new()
		mm.albedo_color = Color(0.3, 0.2, 0.15, 0.0)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mc.material = mm
		mk.mesh = mc
		mk.visible = false
		add_child(mk)
		mark_pool.append({"m": mk, "mat": mm, "life": 0.0, "max": 1.3})


	for i in 16:
		var sk: = MeshInstance3D.new()
		var sb: = BoxMesh.new()
		sb.size = Vector3(0.12, 0.005, 1.7)
		var skm: = StandardMaterial3D.new()
		skm.albedo_color = Color(0.3, 0.2, 0.15, 0.0)
		skm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sb.material = skm
		sk.mesh = sb
		sk.visible = false
		add_child(sk)
		skid_pool.append({"m": sk, "mat": skm, "life": 0.0, "max": 4.5})

	cam = Camera3D.new()
	cam.position = CAM_POS
	cam.fov = CAM_FOV
	add_child(cam)
	cam.look_at(Vector3(0, CAM_LOOK_Y, NZ))
	cam.make_current()

	hud = MatchHUD.new()
	hud.cam = cam
	add_child(hud)
	rally_label = Label.new()
	rally_label.position = Vector2(880, 604)
	rally_label.size = Vector2(380, 54)
	rally_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rally_label.add_theme_font_size_override("font_size", 23)
	rally_label.add_theme_color_override("font_color", Color("#ffe783"))
	rally_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.82))
	rally_label.add_theme_constant_override("outline_size", 6)
	rally_label.visible = false
	hud.add_child(rally_label)
	hud.set_names(get_meta("my_name", "TÚ"), get_meta("cpu_label", "CPU"))
	hud.update_score(sim.M)
	touch_ui = false
	if not demo:
		touch_ui = get_meta("force_touch", false) or TouchControls.should_show()
		if touch_ui:
			var tc: = TouchControls.new()
			add_child(tc)
	if not demo:
		if touch_ui:
			hud.set_hint("Joystick izquierdo mover · GOLPE / GLOBO / DEJADA a la derecha · II pausa")
		else:
			hud.set_hint("Stick/WASD mover · A/ESPACIO golpe · X/Z globo · B dejada · START pausa")
	else:
		hud.set_hint("")

	pause_layer = CanvasLayer.new()
	pause_layer.layer = 30
	pause_layer.visible = false
	add_child(pause_layer)

	var dim: = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	pause_layer.add_child(dim)
	var pl: = Label.new()
	pl.text = "PAUSA"
	pl.add_theme_font_size_override("font_size", 44)
	pl.add_theme_color_override("font_color", Color.WHITE)
	pl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	pl.add_theme_constant_override("outline_size", 10)
	pl.position = Vector2(0, 272)
	pl.size = Vector2(1280, 100)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_layer.add_child(pl)
	var pl2: = Label.new()
	pl2.text = "P / START continuar · ESC menú"
	pl2.add_theme_font_size_override("font_size", 22)
	pl2.add_theme_color_override("font_color", Color("#9fb3e8"))
	pl2.position = Vector2(0, 328)
	pl2.size = Vector2(1280, 40)
	pl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_layer.add_child(pl2)

	var pv: = Label.new()
	pv.text = GameMenus.VERSION
	pv.add_theme_font_size_override("font_size", 14)
	pv.add_theme_color_override("font_color", Color(0.62, 0.7, 0.92, 0.6))
	pv.position = Vector2(12, 696)
	pv.size = Vector2(120, 20)
	pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pause_layer.add_child(pv)
	var guard: = PauseGuard.new()
	guard.mv = self
	guard.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(guard)


func dust_color(a: float) -> Color:
	if surface == "clay":

		return Color(0.92, 0.78, 0.64, a)
	if surface == "grass":
		return Color(0.5, 0.62, 0.38, a)
	return Color(0.62, 0.63, 0.66, a)

func mark_color() -> Color:
	if surface == "clay":
		return Color(0.38, 0.2, 0.12)
	if surface == "grass":
		return Color(0.12, 0.22, 0.1)
	return Color(0.1, 0.12, 0.16)

func spawn_mark(pos: Vector3) -> void :
	var ma: float = mark_alpha(surface)
	if ma <= 0.0:
		return
	for mk in mark_pool:
		if mk.life <= 0.0:
			mk.life = 1.3
			mk.max = 1.3
			mk.m.visible = true
			mk.m.position = Vector3(pos.x, DECAL_Y, pos.z)
			mk.mat.albedo_color = mark_color()
			mk.mat.albedo_color.a = ma
			return



static func spin_dust_bias(spin: float, vz: float) -> Vector3:
	if spin <= -0.5:
		return Vector3(0.0, -0.6, signf(vz) * 3.2)
	if spin >= 0.7:
		return Vector3(0.0, 2.0, 0.0)
	return Vector3.ZERO

static func spin_dust_count(spin: float) -> int:
	if spin <= -0.5 or spin >= 0.7:
		return 4
	return 0

func spawn_dust_dir(pos: Vector3, n: int, col: Color, sc: float, bias: Vector3) -> void :
	var c: = 0
	for d in dust_pool:
		if d.life <= 0.0:
			d.life = randf_range(0.3, 0.6)
			d.max = 0.6
			d.m.visible = true
			d.m.scale = Vector3.ONE * sc
			d.m.position = pos + Vector3(randf_range(-0.15, 0.15), 0.05, randf_range(-0.15, 0.15))
			d.v = Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.2), randf_range(-1.5, 1.5)) + bias
			d.mat.albedo_color = col
			c += 1
			if c >= n:
				break

func spawn_dust(pos: Vector3, n: int, col: Color, sc: float = 1.0) -> void :
	var c: = 0
	for d in dust_pool:
		if d.life <= 0.0:
			d.life = randf_range(0.3, 0.6)
			d.max = 0.6
			d.m.visible = true
			d.m.scale = Vector3.ONE * sc
			d.m.position = pos + Vector3(randf_range(-0.15, 0.15), 0.05, randf_range(-0.15, 0.15))
			d.v = Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.2), randf_range(-1.5, 1.5))
			d.mat.albedo_color = col
			c += 1
			if c >= n:
				break

func _unhandled_input(event: InputEvent) -> void :
	if replaying:
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
			_end_replay()
		return


func _on_pause_input(event: InputEvent) -> void :
	if event.is_action_pressed("pause") and not demo:
		if paused_game:
			paused_game = false
			get_tree().paused = false
			pause_layer.visible = false
			if _hint_hidden:
				hud.hint.visible = true
				_hint_hidden = false
		else:

			if replaying:
				_end_replay()
			paused_game = true
			get_tree().paused = true
			pause_layer.visible = true
			hud.hide_banner()
			banner_t = 0.0

			hud.hide_popups()
			hud.hint.visible = false
			hud.serve_meter_hide()
			_hint_hidden = true
	elif event.is_action_pressed("quit") and paused_game:
		get_tree().paused = false
		paused_game = false
		quit_to_menu.emit()

func _physics_process(dt: float) -> void :
	if paused_game:
		return
	if replaying:
		_replay_tick(dt)
		return
	if not demo:
		sim.inp.x = Input.get_axis("move_left", "move_right")
		sim.inp.y = Input.get_axis("move_down", "move_up")
		if Input.is_action_just_pressed("drop"):
			sim.inp.y = -1.0
			sim.inp.hit = true
		elif Input.is_action_just_pressed("hit"):
			sim.inp.hit = true
		elif Input.is_action_just_pressed("lob"):
			sim.inp.lob = true

		if Input.is_action_just_released("hit"):
			sim.inp.hit_rel = true
	if hitstop_t > 0.0:
		hitstop_t -= dt
	else:
		sim.update(dt)
	drain_events()
	if ( not demo or replay_test) and sim.state not in ["point", "over"] and sim.ball.in_play:
		rec.append({"b": Vector3(sim.ball.x, sim.ball.y, sim.ball.z), "p0": _snap(sim.pl[0]), "p1": _snap(sim.pl[1])})
		if rec.size() > REC_MAX:
			rec.pop_front()
	var exc: float = clampf(sim.rally_hits / 10.0, 0.0, 1.0) if sim.state not in ["point", "over"] else 0.0
	_update_rally_label(dt)
	crowd.ball_pos = ball_mesh.position
	crowd.update(dt, exc)

	flash_t -= dt
	_fatigue = maxf(0.0, _fatigue - dt * 0.35)
	hud.set_score_glow(_hot_level())
	var hl_flash: int = _hot_level()
	if hl_flash >= 1 and flash_t <= 0.0 and flashes.size() > 0:
		flash_t = flash_gap(hl_flash)
		var fk = flashes[randi() % flashes.size()]
		fk.life = 0.09
		fk.m.position = fk.pos + Vector3(randf_range(-1.5, 1.5), randf_range(-0.8, 0.8), 0.0)
	for fk in flashes:
		if fk.life > 0.0:
			fk.life -= dt
			fk.m.visible = fk.life > 0.0
		elif fk.m.visible:
			fk.m.visible = false

	if _amb != null:
		var tgt: float = ambience_vol(exc, sim.state == "serve", sfx.muted)
		var cur: float = db_to_linear(_amb.volume_db)
		_amb.volume_db = linear_to_db(lerpf(cur, tgt, minf(1.0, dt * 3.0)))


	for i in 2:
		rigs[i].look_on = (sim.state == "play")
		rigs[i].serve_toss = clampf(sim.ball.toss_t / 0.5, 0.0, 1.0) if (sim.state == "serve" and sim.M.server == i and sim.serve_stage == "toss") else -1.0
		rigs[i].look_target = Vector3(sim.ball.x, sim.ball.y, sim.ball.z)
		rigs[i].update_from_sim(sim.pl[i], dt)
		shadows[i].position.x = sim.pl[i].x
		shadows[i].position.z = sim.pl[i].z
		brake_cd[i] = maxf(0.0, brake_cd[i] - dt)
		var pv = sim.pl[i]
		if pv.speed > 3.0 and randf() < dt * 9.0:
			spawn_dust(Vector3(pv.x, 0, pv.z), 1, dust_color(0.25))


		if brake_cd[i] <= 0.0 and pv.speed > 4.0 and pv.vx * pv.tvx + pv.vz * pv.tvz < 0.0:
			spawn_dust(Vector3(pv.x, 0, pv.z), 8, dust_color(0.6), 4.0)
			sfx.play(sfx.surf_name("skid", surface), 0.8 if surface == "clay" else 0.5)
			brake_cd[i] = 0.45

		if pv.burst > 0.0 and burst_prev[i] <= 0.0:
			spawn_dust(Vector3(pv.x, 0, pv.z), 3, dust_color(0.35), 2.0)
		burst_prev[i] = pv.burst


		if pv.swing > 0.0 and _swing_prev[i] <= 0.0:
			var st_: float = slide_time(surface, pv.speed)
			if st_ > 0.0:
				slide_t[i] = st_
				sfx.play(sfx.surf_name("skid", surface), 0.75)
				spawn_skid(Vector3(pv.x, 0.0, pv.z), pv.vx, pv.vz)
		_swing_prev[i] = pv.swing
		if slide_t[i] > 0.0:
			slide_t[i] -= dt
			if randf() < dt * 30.0:
				spawn_dust(Vector3(pv.x, 0, pv.z), 2, dust_color(0.5), 2.5)



		step_t[i] = maxf(0.0, step_t[i] - dt)
		if pv.speed > 2.2 and pv.recov <= 0.0 and step_t[i] <= 0.0:
			sfx.play(sfx.surf_name("step", surface), 0.22 if i == 0 else 0.15)
			step_t[i] = step_interval(pv.speed)
		elif pv.speed <= 2.2:
			step_t[i] = 0.0
	ball_mesh.position = Vector3(sim.ball.x, sim.ball.y, sim.ball.z)
	# v0.142: al pasar de punto a saque la camara aun vuelve desde el primer plano; la pelota
	# (y su rastro) se oculta unos instantes para que no cruce la camara enorme y lenta.
	if sim.state == "serve" and (_prev_sim_state == "point" or _prev_sim_state == "over"):
		_serve_blank = 0.75
	_prev_sim_state = sim.state
	_serve_blank = maxf(0.0, _serve_blank - dt)
	var blank: bool = _serve_blank > 0.0 and not replaying
	ball_mesh.visible = not blank
	ball_shadow.visible = not blank
	ball_seam.visible = not blank
	# v0.144: escala suavizada y tope bajo en el lanzamiento (antes la bola del saque parecia un balon)
	var bk: float = held_ball_scale(sim.ball.held, sim.ball.toss, sim.ball.toss_t)
	if bk < ball_vis_scale:
		ball_vis_scale = bk
	else:
		ball_vis_scale = lerpf(ball_vis_scale, bk, minf(1.0, dt * 18.0))
	if ball_squash > 0.0:
		ball_squash = maxf(0.0, ball_squash - dt)
		var sqk: float = ball_squash / 0.09
		ball_mesh.scale = Vector3(1.0 + 0.45 * sqk, 1.0 - 0.45 * sqk, 1.0 + 0.45 * sqk) * ball_vis_scale
	elif ball_mesh.scale != Vector3.ONE * ball_vis_scale:
		ball_mesh.scale = Vector3.ONE * ball_vis_scale


	var hsp: = Vector2(sim.ball.vx, sim.ball.vz).length()
	if hsp > 2.0 and sim.ball.in_play:
		var w: float = spin_rate(sim.ball.spin, hsp)
		var axis: = spin_axis(sim.ball.vx, sim.ball.vz)
		ball_seam.rotate(axis, w * dt)
	ball_shadow.position.x = sim.ball.x
	ball_shadow.position.z = sim.ball.z
	var sh_scale: float = clampf(1.0 + sim.ball.y * 0.12, 1.0, 2.2)
	ball_shadow.scale = Vector3(sh_scale * 0.4, 1, sh_scale * 0.4)
	ball_shadow_mat.albedo_color.a = clampf(0.7 - sim.ball.y * 0.06, 0.12, 0.7)
	_update_bounce_ring()

	if dust_trail > 0.0:
		dust_trail -= dt
		if sim.ball.y < 1.4 and randf() < dt * 26.0:
			spawn_dust(Vector3(sim.ball.x, 0.05, sim.ball.z), 1, dust_color(0.35), 1.2)

	if net_node != null:
		if net_shake > 0.0:
			net_shake -= dt
			net_node.position.z = sin(net_shake * 90.0) * 0.018 * (net_shake / 0.35)
		else:
			net_node.position.z = net_sway(Time.get_ticks_msec() / 1000.0, sim.state)
	var heat: float = sim.ball.hot
	var hb: float = hot_trail_boost(_hot_level())
	for i in trail.size():
		var t = trail[i]
		if i < sim.ball.trail.size() and not blank:
			t.m.visible = true
			t.m.position = sim.ball.trail[i]
			var f: float = float(i) / trail.size()

			t.m.scale = Vector3.ONE * (0.45 + 0.55 * f) * (0.8 + 0.7 * heat)
			t.mat.albedo_color = Color(0.88, 1.0, 0.35).lerp(Color(1, 1, 1), heat).lerp(Color(1.0, 0.82, 0.25), hb * 0.55)
			t.mat.albedo_color.a = (0.07 + (0.26 + 0.42 * heat) * f) * (1.0 + 0.6 * hb)
			t.mat.emission = t.mat.albedo_color
			t.mat.emission_energy_multiplier = 0.4 + 1.6 * heat + 1.4 * hb
			var tsc: float = 1.0 + (0.8 * heat + 0.3 * hb) * f
			t.m.scale = Vector3(tsc, tsc, tsc)
		else:
			t.m.visible = false
	_tick_rings(dt)
	for d in dust_pool:
		if d.life > 0.0:
			d.life -= dt
			if d.life <= 0.0:
				d.m.visible = false
			else:
				d.v.y -= 14.0 * dt
				d.m.position += d.v * dt
				if d.m.position.y < 0.0:
					d.m.position.y = 0.0
					d.v.y *= -0.3
				d.mat.albedo_color.a = clampf(d.life / d.max, 0.0, 1.0) * 0.5
	for mk in mark_pool:
		if mk.life > 0.0:
			mk.life -= dt
			if mk.life <= 0.0:
				mk.m.visible = false
			else:
				mk.mat.albedo_color.a = clampf(mk.life / mk.max, 0.0, 1.0) * 0.4
	for sk in skid_pool:
		if sk.life > 0.0:
			sk.life -= dt
			if sk.life <= 0.0:
				sk.m.visible = false
			else:
				sk.mat.albedo_color.a = clampf(sk.life / sk.max, 0.0, 1.0) * 0.7

	var closeup: bool = (sim.state == "point" or sim.state == "over") and _point_winner >= 0 and _point_winner <= 1
	var goal_pos: Vector3
	var goal_fov: float
	var goal_look: Vector3
	if closeup:
		var wp = sim.pl[_point_winner]
		var side_x: float = - signf(wp.x) * 2.2 if absf(wp.x) > 0.6 else 2.2

		var cam_z: float = wp.z + 3.6 if wp.near else wp.z - 3.6
		goal_pos = Vector3(wp.x + side_x, 1.7, cam_z)
		goal_fov = 36.0
		goal_look = Vector3(wp.x, 1.45, wp.z)
	else:


		var target_x: float = clampf(sim.ball.x * 0.35 + sim.pl[0].x * 0.15, -2.6, 2.6)
		goal_pos = Vector3(target_x, CAM_POS.y, CAM_POS.z)
		goal_fov = CAM_FOV
		goal_look = Vector3(sim.ball.x * 0.2, CAM_LOOK_Y, NZ)



		var push: float = cam_push(_hot_level(), sim.state)
		if push > 0.0:
			goal_pos = goal_pos.lerp(Vector3(goal_pos.x, goal_pos.y - 0.18, NZ), 0.06 * push)
			goal_fov -= 2.5 * push
	var cam_k: float = 3.2 if closeup else 2.2
	cam.position = cam.position.lerp(goal_pos, minf(1.0, dt * cam_k))
	cam.fov = lerpf(cam.fov, goal_fov, minf(1.0, dt * cam_k))
	cam_look = cam_look.lerp(goal_look, minf(1.0, dt * cam_k))
	if shake > 0.0 and not closeup:
		shake = maxf(0.0, shake - dt)

		cam.position.y = goal_pos.y + randf_range(-1.0, 1.0) * shake * 0.5
		cam.position.z = goal_pos.z + randf_range(-1.0, 1.0) * shake * 0.38
	elif shake > 0.0:
		shake = maxf(0.0, shake - dt)
	cam.look_at(cam_look)
	if fill_light != null:
		var fgoal: float = (0.95 if closeup else 0.0) if night_mode else 0.0
		fill_light.light_energy = lerpf(fill_light.light_energy, fgoal, minf(1.0, dt * 4.0))
		fill_light.global_transform = Transform3D(cam.global_transform.basis, cam.global_position)


	if not demo and sim.state == "serve" and _prev_state != "serve":
		var hl: int = _hot_level()
		point_hot = hl
		if hl >= 3:
			hud.popup_big("¡BOLA DE PARTIDO!", Color("#ffd23f"))
		elif hl == 2:
			hud.popup_big("¡BOLA DE SET!", Color("#ffd23f"))
	if demo and sim.state == "serve" and _prev_state != "serve":
		point_hot = _hot_level()
	_prev_state = sim.state

	if banner_t > 0.0:
		banner_t -= dt
		if banner_t <= 0.0:
			hud.hide_banner()
			if replay_pending:
				replay_pending = false
				_start_replay()
	if hint_t > 0.0 and not demo:
		hint_t -= dt
		if hint_t <= 0.0:
			hud.set_hint("")
	elif not demo and sim.state == "serve" and sim.M.server == 0 and sim.serve_stage != "hit":
		if touch_ui:
			hud.set_hint("GOLPE: lanzar la bola · otra vez para golpear" if sim.serve_stage == "ready" else "¡Golpea cuando la bola esté arriba!")
		else:
			hud.set_hint("A / ESPACIO: lanzar la bola · otra vez para golpear" if sim.serve_stage == "ready" else "¡Golpea cuando la bola esté arriba!")
	elif not demo and hint_t <= 0.0:

		if hud.hint.text == "¡Golpea cuando la bola esté arriba!" or hud.hint.text.begins_with("A / ESPACIO"):
			hud.set_hint("")


	if not demo and sim.state == "serve" and sim.M.server == 0 and sim.serve_stage in ["ready", "toss"]:


		var sq: float = 1.0 - clampf(absf(sim.ball.toss_t - 0.5) / 0.45, 0.0, 1.0)
		hud.set_meter_label("SAQUE")
		hud.serve_meter_update(sq if sim.serve_stage == "toss" else 0.0)
	elif not demo and sim.pl[0].charging and sim.pl[0].charge > 0.12:

		hud.set_meter_label("FUERZA")
		hud.serve_meter_update(sim.pl[0].charge)
	elif not demo:
		hud.serve_meter_hide()

func _snap(pl) -> Dictionary:
	return {"x": pl.x, "z": pl.z, "near": pl.near, "speed": pl.speed, "run": pl.run, "kind": pl.kind, "swing": pl.swing, "want_t": pl.want_t, 
		"want": pl.want, "vx": pl.vx, "vz": pl.vz, "prep_t": 0.0, "wait_serve": false, 
		"intent_side": pl.intent_side, 
		"dive_t": pl.dive_t, "getup_t": pl.getup_t, "stumble_t": pl.stumble_t, "stumble_dir": pl.stumble_dir, "hit_side": pl.hit_side, "ball_y": sim.ball.y, "recov": pl.recov, "recov_lean": pl.recov_lean, 
		"fatigue": _fatigue}

func _update_bounce_ring() -> void :
	if sim.state != "play":
		bounce_ring.visible = false
		return
	var pb: Dictionary = sim.predict_bounce()
	if not pb.ok:
		bounce_ring.visible = false
		return
	bounce_ring.visible = true
	bounce_ring.position.x = pb.x
	bounce_ring.position.z = pb.z
	var k: float = clampf(pb.t / 1.1, 0.0, 1.0)
	var sc: float = lerpf(0.35, 1.0, k)
	bounce_ring.scale = Vector3(sc, 1, sc)
	if surface == "clay":
		# v0.144: blanco puro y aro mas grueso con borde oscuro para que se lea sobre tierra
		bounce_ring_mat.albedo_color = Color(1.0, 1.0, 1.0, lerpf(1.0, 0.85, k))
	else:
		bounce_ring_mat.albedo_color = Color(1.0, 0.95, 0.35, lerpf(0.95, 0.72, k))

func _start_replay() -> void :
	if rec.size() < 10:
		rec.clear()
		return
	replaying = true
	replay_i = 0.0
	bounce_ring.visible = false
	hud.show_replay()
	for t in trail:
		t.m.visible = false



	var side: = 1.0
	if rec.size() > 0:
		var fl: Dictionary = rec[rec.size() - 1]
		side = -1.0 if fl.b.x < 0.0 else 1.0
	replay_side = side
	cam.position = Vector3(9.2 * side, 7.0, clampf(rec[0].b.z - NZ, -8.0, 8.0) * 0.55)
	cam.fov = 42.0
	cam.look_at(Vector3(rec[0].b.x * 0.7, 0.9, rec[0].b.z))

func _replay_tick(dt: float) -> void :
	replay_i += dt * 36.0
	var idx: = int(replay_i)
	if idx >= rec.size():
		_end_replay()
		return
	var f: Dictionary = rec[idx]


	var cam_target: = Vector3(8.6 * replay_side, 6.8, clampf(f.b.z - NZ, -6.5, 6.5) * 0.55)
	cam.position = cam.position.lerp(cam_target, minf(1.0, dt * 2.6))
	cam.look_at(Vector3(f.b.x * 0.75, 0.55, f.b.z))
	rigs[0].update_from_sim(f.p0, dt)
	rigs[1].update_from_sim(f.p1, dt)
	ball_mesh.position = f.b
	ball_shadow.position.x = f.b.x
	ball_shadow.position.z = f.b.z
	var sh_scale: float = clampf(1.0 + f.b.y * 0.12, 1.0, 2.2)
	ball_shadow.scale = Vector3(sh_scale * 0.4, 1, sh_scale * 0.4)
	ball_shadow_mat.albedo_color.a = clampf(0.5 - f.b.y * 0.05, 0.08, 0.5)
	shadows[0].position.x = f.p0.x
	shadows[0].position.z = f.p0.z
	shadows[1].position.x = f.p1.x
	shadows[1].position.z = f.p1.z
	crowd.ball_pos = Vector3(f.b.x, f.b.y, f.b.z)
	crowd.update(dt, 0.4)

func _end_replay() -> void :
	replaying = false
	rec.clear()
	hud.hide_replay()
	cam.position = CAM_POS
	cam.fov = CAM_FOV
	cam.look_at(Vector3(0, CAM_LOOK_Y, NZ))

func _pts_line() -> String:

	var M = sim.M
	if "tb" in M and M.tb:
		return str(M.tb_pts[0]) + " - " + str(M.tb_pts[1])
	var PT: = ["0", "15", "30", "40"]
	return PT[mini(3, M.pts[0])] + " - " + PT[mini(3, M.pts[1])]






static func dust_trail_time(surf: String, bv: float) -> float:
	if surf == "clay" and bv >= 0.5:
		return 0.35
	if surf == "hard" and bv >= 0.85:
		return 0.12
	return 0.0

static func cam_push(hot: int, state: String) -> float:
	return 1.0 if hot >= 1 and state == "serve" else 0.0

func _hot_level() -> int:

	var M = sim.M
	if M.tb:
		var hi: = maxi(M.tb_pts[0], M.tb_pts[1])
		var dif: = absi(M.tb_pts[0] - M.tb_pts[1])
		if hi >= 5 and dif <= 1:
			return 1
		return 0
	if M.pts[0] == 3 and M.pts[1] == 3:
		return 1
	for i in 2:
		if M.pts[i] == 3 and M.games[i] == 3:
			return 3 if M.sets[i] >= M.sets_to_win - 1 else 2
	return 0

var _serve_armed: = false
var _murmur_step: = 0










const BALL_YEL: = Color("#e6ff4d")
const BALL_CLAY: = Color("#c9a25e")







static func sweat_next(s: float, rally_hits: int) -> float:
	return clampf(s + float(rally_hits) * 0.005, 0.0, 1.0)

static func leg_dust_shake(d: float) -> float:
	return maxf(0.0, d - 0.3)

static func leg_dust_next(d: float, surf: String) -> float:
	return minf(1.0, d + 0.025) if surf == "clay" else d

static func balls_change(games_total: int) -> bool:
	return games_total > 0 and games_total % 7 == 0

static func clay_tint_next(t: float, surf: String) -> float:
	return minf(1.0, t + 0.05) if surf == "clay" else t

static func clay_ball_color(t: float) -> Color:
	return BALL_YEL.lerp(BALL_CLAY, clampf(t, 0.0, 1.0) * 0.55)

static func grunt_serve_vol(q: float) -> float:
	return clampf(0.2 + q * 0.45, 0.0, 0.65) if q >= 0.55 else 0.0

static func grunt_hit_vol(charge: float, kind: String) -> float:
	if kind == "smash":
		return 0.6
	return clampf(0.15 + (charge - 1.3) * 1.2, 0.0, 0.6) if charge >= 1.3 else 0.0

static func winner_celebration_plan(txt: String, hot: int) -> Array:
	if txt == "PARTIDO":
		return ["Punch_Right", 3.0]
	if txt == "SET":
		return ["Wave", 2.5]
	if txt == "JUEGO":
		return ["Wave", 1.6]
	if txt == "PUNTO" and hot >= 2:
		return ["Wave", 1.4]
	return []

static func crowd_point_plan(txt: String, rally_hits: int) -> Array:
	var out: = []


	if txt == "PUNTO" and rally_hits >= 14:
		out.append(["ovation", 0.9])
	if txt == "PUNTO" and rally_hits >= 3 and rally_hits < 8:

		out.append(["applause", clampf(0.2 + rally_hits * 0.03, 0.2, 0.45)])
	elif txt == "JUEGO":
		out.append(["ovation", 0.8])
	elif txt == "SET":
		out.append(["ovation", 1.0])
	elif txt == "PARTIDO":
		out.append(["ovation", 1.0])
		out.append(["force_ovation", 1.0])
	return out



static func slide_time(surf: String, speed: float) -> float:
	return 0.45 if surf == "clay" and speed > 5.0 else 0.0


func _update_rally_label(dt: float) -> void :
	var live: int = sim.rally_hits if sim.state == "play" else 0
	if live >= 3:
		rally_label.visible = true
		rally_label.text = "RALLY  %02d   ·   MEJOR %02d" % [live, maxi(rally_best, live)]
		rally_label.modulate.a = 1.0
	elif rally_change_t > 0.0:
		rally_label.visible = true
		rally_change_t = maxf(0.0, rally_change_t - dt)
		rally_label.text = "MEJOR RALLY  %02d" % rally_best
		rally_label.modulate.a = minf(1.0, rally_change_t * 1.7)
	else:
		rally_label.visible = false

static func rally_count_txt(rally_hits: int) -> String:
	if rally_hits >= 10:
		return "RALLY " + str(rally_hits)
	return ""



static func skid_alpha(surf: String) -> float:
	return 0.7 if surf == "clay" else 0.0

static func skid_angle(vx: float, vz: float) -> float:
	return atan2(vx, vz)

func spawn_skid(pos: Vector3, vx: float, vz: float) -> void :
	var sa: float = skid_alpha(surface)
	if sa <= 0.0:
		return
	var ang: float = skid_angle(vx, vz)
	var lat: = Vector3(cos(ang), 0.0, - sin(ang))
	var n: = 0
	for sk in skid_pool:
		if sk.life <= 0.0:
			sk.life = 4.5
			sk.max = 4.5
			sk.m.visible = true
			sk.m.position = Vector3(pos.x, DECAL_Y, pos.z) + lat * (0.14 if n == 0 else -0.14) - Vector3(vx, 0.0, vz).normalized() * 0.85
			sk.m.rotation.y = ang
			sk.mat.albedo_color = mark_color()
			sk.mat.albedo_color.a = sa
			n += 1
			if n >= 2:
				return



static func mark_alpha(surf: String) -> float:
	if surf == "clay":
		return 0.4
	if surf == "grass":
		return 0.15
	return 0.0



static func ambience_vol(exc: float, serving: bool, muted: bool) -> float:
	if muted:
		return 0.0
	if serving:
		return 0.03
	return 0.08 + 0.22 * clampf(exc, 0.0, 1.0)



static func fatigue_from_rally(hits: int) -> float:
	return 1.0 if hits >= 12 else 0.0



static func flash_gap(hl: int) -> float:
	return 0.0 if hl <= 0 else 0.5 - 0.1 * float(hl)



static func hot_trail_boost(hl: int) -> float:
	return clampf(float(hl) * 0.34, 0.0, 1.0)



static func mishit_shake(tq: String) -> float:
	return 0.1 if (tq == "late" or tq == "early") else 0.0



static func net_sway(t: float, state: String) -> float:
	if state != "point" and state != "serve":
		return 0.0
	return sin(t * 1.7) * 0.005

static func net_shake_time(kind: String) -> float:
	if kind == "net":
		return 0.35
	if kind == "netcord":
		return 0.18
	return 0.0


static func match_point_tension(hot_level: int) -> float:
	return 0.7 if hot_level >= 3 else 0.0





static func contact_weight(spd: float, tq: String) -> Vector2:
	var w: = clampf((spd - 22.0) / 20.0, 0.0, 1.0)
	if tq == "late" or tq == "early":
		w *= 0.45
	return Vector2(w * 0.05, w * 0.14)



static func spin_rate(spin: float, hsp: float) -> float:
	return clampf(spin, -1.2, 1.2) * hsp * 0.3


static func spin_axis(vx: float, vz: float) -> Vector3:
	var dir: = Vector3(vx, 0.0, vz).normalized()
	if dir.length() < 0.5:
		return Vector3.RIGHT
	return Vector3.UP.cross(dir).normalized()



static func step_interval(spd: float) -> float:
	return clampf(0.46 - spd * 0.035, 0.2, 0.45)

func drain_events() -> void :
	for ev in sim.events:
		match ev.t:
			"hit":



				var cw: Vector2 = contact_weight(ev.get("spd", 0.0), ev.get("tq", "ok"))
				hitstop_t = maxf(hitstop_t, cw.x)
				shake = maxf(shake, cw.y)
				if ev.get("spd", 0.0) >= 38.0:

					hitstop_t = maxf(hitstop_t, 0.05)
					shake = maxf(shake, 0.16)
				var hkmh: int = int(round(ev.get("spd", 0.0) * HIT_KMH_K))
				if hkmh > 0 and not demo:
					hud.show_speed_kmh(hkmh, false)
				var perfect: bool = ev.get("perfect", false) and ev.id == 0 and not demo
				var tper: bool = ev.get("tper", false) and ev.id == 0 and not demo
				var charged: float = ev.get("charge", 1.0)
				spawn_ring(Vector3(ev.x, ev.y, ev.z), ev.get("spd", 20.0))
				rigs[ev.id].punch(ev.get("spd", 20.0))
				if ev.kind == "smash":
					rigs[ev.id].hop(0.3)
				ball_squash = 0.09
				_line_armed = (ev.id == 0 and not demo)
				if ev.id == 0 and not demo and (ev.get("tq", "ok") == "late" or ev.get("tq", "ok") == "early"):
					sfx.play("hit_weak", 1.0)
					shake = maxf(shake, mishit_shake(ev.get("tq", "ok")))
				if charged >= 1.3 and ev.id == 0 and not demo:

					sfx.play("hit_charge", 1.15)
					sfx.play("grunt", grunt_hit_vol(charged, ev.kind), 1.0)
					hitstop_t = maxf(hitstop_t, 0.04)
					shake = maxf(shake, 0.22)
					sim.ball.hot = 1.0
					spawn_dust(Vector3(ev.x, ev.y, ev.z), 8, Color(1.0, 0.9, 0.45, 0.7), 1.6)
					if charged >= 1.55:
						hud.popup("¡MÁXIMO!", Vector3(sim.pl[0].x, 0.0, sim.pl[0].z), Color("#ffd23f"))
				elif not (ev.id == 0 and not demo and (ev.get("tq", "ok") == "late" or ev.get("tq", "ok") == "early")):


					var hs: = "hit"
					if tper:
						hs = "hit_perfect"
					elif perfect or ev.kind == "smash" or ev.get("rise", false):
						hs = "hit_big"
					elif ev.kind == "drop":
						hs = "hit_drop"
					elif ev.kind == "slice":
						hs = "hit_slice"
					elif ev.kind == "volley":
						hs = "hit_volley"
					sfx.play(hs, 1.0, clampf(0.85 + ev.get("spd", 25.0) * 0.008, 0.9, 1.2))
				if ev.kind == "smash":
					shake = 0.34
					sfx.play("grunt", grunt_hit_vol(0.0, ev.kind), 0.94 + 0.08 * float(ev.id))
				spawn_dust(Vector3(ev.x, ev.y, ev.z), 3, Color(1, 0.96, 0.7, 0.4))

				if sim.state == "play" and sim.rally_hits >= 4:
					var stp: = int(sim.rally_hits / 4)
					if stp > _murmur_step:
						_murmur_step = stp
						sfx.play("murmur", clampf(0.4 + 0.15 * stp, 0.4, 0.85))


				if sim.state == "play" and sim.rally_hits >= 10:
					var oln: = sim.rally_hits - 10
					sfx.play("ole", clampf(0.55 + 0.07 * oln, 0.55, 1.0), clampf(1.0 + 0.025 * oln, 1.0, 1.18))

				var pwp: = Vector3(sim.pl[ev.id].x, 0.0, sim.pl[ev.id].z)
				if perfect:
					shake = 0.42 if tper else 0.36
					hud.popup_big("¡PERFECTO!", Color("#ffe27a"))
				if tper:
					hitstop_t = maxf(hitstop_t, 0.05)
					spawn_dust(Vector3(ev.x, ev.y, ev.z), 6, Color(1.0, 0.95, 0.5, 0.8), 1.8)
				elif ev.id == 0 and not demo:
					if ev.get("jam", false):
						hud.popup("¡TRABADO!", pwp, Color("#ff9a6a"))
					match ev.kind:
						"smash":
							hud.popup("¡SMASH!", pwp, Color("#ffd23f"))
						"lob":
							hud.popup("GLOBO", pwp, Color("#7ac7ff"))
						"drop":
							hud.popup("DEJADA", pwp, Color("#c8ffb0"))
						"slice":
							hud.popup("SLICE", pwp, Color("#ffd9a0"))
						"volley":
							hud.popup("VOLEA", pwp, Color("#a0e8ff"))
						"toplob":
							hud.popup("GLOBO LIFTADO", pwp, Color("#ffb0d9"))
				if ev.get("rise", false) and ev.id == 0 and not demo:
					hud.popup("¡AL BOTE!", pwp, Color("#a0ffe0"))
				if ev.kind == "volley" and ev.get("stretch", 0.0) >= 1.3:
					sfx.play("swish", 1.0)

				if ev.kind == "smash" or ev.get("stretch", 0.0) >= 1.3 or charged >= 1.3:
					sfx.play("grunt", 0.55 if ev.id == 0 else 0.35, randf_range(0.9, 1.12))
			"serve":
				if _hot_level() >= 1 and not _serve_armed:
					sfx.play("murmur", 0.8)
					var tns: float = match_point_tension(_hot_level())
					if tns > 0.0:
						sfx.play("drum", tns)
					_serve_armed = true
				elif _hot_level() == 0:
					_serve_armed = false
				hud.serve_meter_hide()
				rigs[ev.get("id", 0)].hop(0.12 + 0.14 * clampf(ev.get("q", 0.5), 0.0, 1.0))
				var skmh: int = int(round(ev.get("spd", 0.0) * SERVE_KMH_K))
				if skmh > 0 and not demo:
					hud.show_speed_kmh(skmh, true)
				if ev.get("q", 0.0) >= 0.88:
					hitstop_t = 0.05
				sfx.play("hit_big" if (ev.get("q", 0.0) >= 0.88) else "hit", 1.2)
				var gs: float = grunt_serve_vol(ev.get("q", 0.0))
				if gs > 0.0:
					sfx.play("grunt", gs, 0.97 + 0.06 * float(ev.get("id", 0)))
				if ev.get("q", 0.0) >= 0.88 and ev.get("id", 1) == 0 and not demo:
					shake = 0.34
					hud.popup_side("¡SAQUE PERFECTO!", Color("#ffe27a"))
			"retoss":
				sfx.play("catch", 0.7)
			"toss":

				sfx.hush()
				_murmur_step = 0
				sfx.play("serve")
			"rut_bounce":
				sfx.play(sfx.surf_name("bounce", surface), 0.3)
			"bounce":
				if not demo or randf() < 0.3:
					sfx.play(sfx.surf_name("bounce", surface), ev.v)
				var nt: float = clay_tint_next(clay_tint, surface)
				if nt != clay_tint:
					clay_tint = nt
					ball_mat.albedo_color = clay_ball_color(clay_tint)
					seam_mat.albedo_color = clay_ball_color(clay_tint)


				if _line_armed:
					_line_armed = false
					var base_z: float = TennisSim.L if sim.pl[0].near else 0.0
					var opp_half: bool = (ev.z > TennisSim.NZ) == sim.pl[0].near
					var near_side: bool = absf(ev.x) >= 3.75 and absf(ev.x) <= 4.115
					var near_base: bool = absf(ev.z - base_z) <= 0.435
					if opp_half and sim.state == "play" and (near_side or near_base):
						hud.popup("¡A LA LÍNEA!", Vector3(ev.x, 0.0, ev.z), Color("#ffe27a"))
						sfx.play("crowd_ooh", 0.4)

				spawn_dust(Vector3(ev.x, 0.05, ev.z), 5 + int(ev.v * 4.0), dust_color(0.55), 2.0 + ev.v * 2.0)
				var sd_n: int = spin_dust_count(ev.get("sp", 0.0))
				if sd_n > 0:
					spawn_dust_dir(Vector3(ev.x, 0.05, ev.z), sd_n, dust_color(0.6), 1.6, spin_dust_bias(ev.get("sp", 0.0), ev.get("vz", 1.0)))
				dust_trail = dust_trail_time(surface, ev.v)
				spawn_mark(Vector3(ev.x, 0.0, ev.z))
			"netcord":

				sfx.play("tape")
				net_shake = maxf(net_shake, net_shake_time("netcord"))
				if not demo:
					sfx.play("crowd_ooh", 0.25)
			"net":
				sfx.play("net")
				net_shake = maxf(net_shake, net_shake_time("net"))
			"dive":
				sfx.play("dive", 0.9)
				sfx.play("crowd_ooh", 0.45)
				if ev.id == 0 and not demo:
					shake = maxf(shake, 0.12)
			"sfx_point":
				if not demo:
					sfx.play("point_win" if ev.w == 0 else "point_lose")
			"point":
				hud.hide_speed()
				_point_winner = ev.get("w", -1)
				_fatigue = fatigue_from_rally(sim.rally_hits)
				var is_err: bool = ev.txt in ["FUERA", "RED", "DOBLE FALTA"]
				crowd.react(is_err)


				if is_err:
					sfx.play("crowd_ooh", 0.6)
				if sim.rally_hits >= 8 and ev.txt == "PUNTO":
					sfx.play("applause", clampf(0.5 + sim.rally_hits * 0.03, 0.5, 0.95))
				if sim.rally_hits > rally_best:
					rally_best = sim.rally_hits
				if sim.rally_hits >= 3:
					rally_change_t = 1.4
				var rct: String = rally_count_txt(sim.rally_hits)
				if rct != "" and ev.txt == "PUNTO":
					hud.popup_side(rct, Color("#9ad4ff"))

				if sim.rally_hits == 1 and ev.txt == "PUNTO":
					sfx.play("ovation", 0.9)
					if ev.w == 0 and not demo:
						hud.popup("¡ACE!", Vector3(sim.pl[0].x, 0.0, sim.pl[0].z), Color("#ffe27a"))
				if _hot_level() >= 1:
					sfx.play("ovation", 0.85)


				for rx in crowd_point_plan(ev.txt, sim.rally_hits):
					if rx[0] == "force_ovation":
						crowd.force_ovation = true
						crowd.start_flashes(5.0)
					else:
						sfx.play(rx[0], rx[1])


				rigs[1 - ev.w].celebrate("HitRecieve" if is_err else "Wave", 1.3 if is_err else 2.0)

				var wp: Array = winner_celebration_plan(ev.txt, point_hot)
				if not wp.is_empty():
					rigs[ev.w].celebrate(wp[0], wp[1])
				hud.update_score(sim.M)

				var nd: float = leg_dust_next(leg_dust, surface)
				if nd != leg_dust:
					leg_dust = nd
					for r in rigs:
						r.set_leg_dust(leg_dust)

				var nsw: float = sweat_next(sweat_v, sim.rally_hits)
				if nsw != sweat_v:
					sweat_v = nsw
					for r in rigs:
						r.set_sweat(sweat_v)

				if ev.txt == "JUEGO" and ev.get("brk", false):
					hud.popup_big("¡BREAK!", Color("#ffd23f"))
					sfx.play("ovation", 0.9)

				if ev.txt == "PARTIDO" and ev.w == 0:
					sfx.play("match_win", 0.9)

				if ev.txt == "JUEGO" and surface == "clay" and leg_dust > 0.0:
					for i in 2:
						spawn_dust(Vector3(sim.pl[i].x, 0.12, sim.pl[i].z), 7, Color(0.79, 0.63, 0.36, 0.6), 1.1)
					leg_dust = leg_dust_shake(leg_dust)
					for r in rigs:
						r.set_leg_dust(leg_dust)

				if ev.txt == "JUEGO" and balls_change(sim.M.games[0] + sim.M.games[1]):
					clay_tint = 0.0
					ball_mat.albedo_color = BALL_YEL
					seam_mat.albedo_color = BALL_YEL
					if not demo:
						hud.popup_side("¡PELOTAS NUEVAS!", BALL_YEL)
				var bcol: Color = Color("#ffd23f") if ev.txt == "SET" else (Color("#7dffa8") if ev.w == 0 else Color("#ff9c9c"))
				var big: bool = ev.txt in ["JUEGO", "SET", "PARTIDO"]
				if ev.txt == "PUNTO":
					hud.show_point_card(ev.w == 0, _pts_line())
					banner_dur = 1.2
					banner_t = banner_dur
				else:
					hud.show_banner(ev.txt, ev.sub, bcol, big)
					banner_dur = 2.2 if ev.txt == "SET" else (1.8 if ev.txt == "JUEGO" else 1.2)
					banner_t = banner_dur



				rec.clear()
			"fault":
				sfx.play("fault")
				hud.show_banner("FALTA", ev.why, Color("#ffd23f"))
				banner_t = 0.9
				banner_dur = 0.9
			"over":
				over_sent = true
				match_finished.emit(sim.M.sets[0] > sim.M.sets[1])
	sim.events.clear()
