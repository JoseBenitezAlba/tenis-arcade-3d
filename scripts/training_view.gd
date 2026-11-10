class_name TrainingView
extends Node3D




signal training_finished(score: int, total: int)
signal quit_to_menu

const NZ: = 11.885
const G: = 9.8

class FakeEnt:
	var x: = 0.0
	var z: = -1.2
	var near: = true
	var speed: = 0.0
	var kind: = "serve"
	var swing: = 0.0
	var want_t: = 0.0
	var wait_serve: = false
	var want: = "serve"
	var prep_t: = 0.0
	var vx: = 0.0
	var vz: = 0.0

var fig: PlayerFig
var crowd: CrowdFX
var sfx: SoundKit
var cam: Camera3D
var ball: MeshInstance3D
var marker: MeshInstance3D
var hud_lbl: Label
var help_lbl: Label
var targets: Array = []
var total_cans: = 0
var serves_left: = 10
var score: = 0
var bpos: = Vector3()
var bvel: = Vector3()
var ball_on: = false
var bounces: = 0
var net_hit: = false
var touched_net: = false
var legal_bounce: = false
var aim: = Vector2(0.0, 15.1)
var fake: = FakeEnt.new()
var phase: = 0
var wait_t: = 0.0
var finish_panel: PanelContainer
var crossed_net: = false
var scored_this_serve: = false
var popups: Array = []
var finish_t: = 0.0
var mode: = "cans"
var serve_side: = 1.4

func _mat_glow(c: Color, e: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = e
	m.emission_energy_multiplier = 1.4
	return m

func _mat(c: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	return m

func setup(cfg: Dictionary) -> void :
	mode = String(cfg.get("mode", "cans"))
	add_child(CourtBuilder.build(cfg.get("surface", "grass"), true))
	crowd = CrowdFX.new()
	add_child(crowd)
	crowd.build()
	sfx = SoundKit.new()
	add_child(sfx)
	fig = PlayerFig.new(cfg.get("look", 0), true)
	add_child(fig)

	cam = Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	cam.global_transform = Transform3D(Basis(), Vector3(0, 4.6, -8.2)).looking_at(Vector3(0, 0.8, 14.0), Vector3.UP)
	call_deferred("_activate_cam")

	ball = MeshInstance3D.new()
	var sm: = SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	ball.mesh = sm
	ball.material_override = _mat(Color("#d8f34a"))
	ball.visible = false
	add_child(ball)

	marker = MeshInstance3D.new()
	var tm: = TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.42
	marker.mesh = tm
	var mk: = StandardMaterial3D.new()
	mk.albedo_color = Color("#ffd23f")
	mk.emission_enabled = true
	mk.emission = Color("#ffd23f")
	marker.material_override = mk
	marker.rotation.x = PI * 0.5
	add_child(marker)
	_build_targets()
	_build_hud()

func _activate_cam() -> void :
	cam.make_current()

func _build_targets() -> void :
	targets.clear()
	if mode == "targets":
		var spots: = [Vector2(2.45, 14.6), Vector2(-2.45, 14.6), Vector2(2.45, 17.4), Vector2(-2.45, 17.4)]
		for sp in spots:
			var ring: = MeshInstance3D.new()
			var tm: = TorusMesh.new()
			tm.inner_radius = 0.55
			tm.outer_radius = 0.72
			ring.mesh = tm
			ring.material_override = _mat_glow(Color("#ffd23f"), Color("#ffb300"))
			ring.rotation.x = PI * 0.5
			ring.position = Vector3(sp.x, 0.035, sp.y)
			add_child(ring)
			var disc: = MeshInstance3D.new()
			var dm: = CylinderMesh.new()
			dm.top_radius = 0.5
			dm.bottom_radius = 0.5
			dm.height = 0.02
			disc.mesh = dm
			disc.material_override = _mat_glow(Color("#fff4b0"), Color("#ffd23f"))
			disc.position = Vector3(sp.x, 0.02, sp.y)
			add_child(disc)
			targets.append({"m": ring, "hit": false, "fall": 0.0, "base": ring.position, "r": 0.95, "kind": "target"})
	else:
		var can_cols: = [Color("#e33f2e"), Color("#f2f2f2"), Color("#2e7ae3"), Color("#f2a52e")]
		var spots: = [Vector2(2.05, 15.1), Vector2(-2.05, 15.1)]
		var ci: = 0
		for sp in spots:
			var glow: = MeshInstance3D.new()
			var gm: = TorusMesh.new()
			gm.inner_radius = 0.46
			gm.outer_radius = 0.58
			glow.mesh = gm
			glow.material_override = _mat_glow(Color("#ffe27a"), Color("#ffc400"))
			glow.rotation.x = PI * 0.5
			glow.position = Vector3(sp.x, 0.03, sp.y)
			add_child(glow)
			var offs: = [Vector2(-0.3, 0), Vector2(0.3, 0), Vector2(0, 0.3), Vector2(0, 0.02)]
			for k in 4:
				var can: = MeshInstance3D.new()
				var cm: = CylinderMesh.new()
				cm.top_radius = 0.16
				cm.bottom_radius = 0.16
				cm.height = 0.52
				cm.radial_segments = 12
				can.mesh = cm
				can.material_override = _mat_glow(can_cols[ci % can_cols.size()], can_cols[ci % can_cols.size()].darkened(0.25))
				var py: float = 0.28 if k < 3 else 0.82
				var px: float = sp.x + (offs[k].x if k < 3 else 0.0)
				var pz: float = sp.y + (offs[k].y if k < 3 else 0.02)
				can.position = Vector3(px, py, pz)
				add_child(can)
				targets.append({"m": can, "hit": false, "fall": 0.0, "base": can.position, "r": 0.44, "kind": "can", "vel": Vector3.ZERO})
				ci += 1
	total_cans = targets.size()
	_start_next_serve()

func _start_next_serve() -> void :
	var rx: = 0.0
	var n: = 0
	for tg in targets:
		if not tg.hit:
			rx += (tg.base as Vector3).x
			n += 1
	if n > 0:
		rx /= float(n)
	if absf(rx) > 0.15:
		serve_side = - signf(rx) * 1.4
	else:
		serve_side = - serve_side
	fake.x = serve_side
	fake.z = -1.0
	fig.position = Vector3(fake.x, 0.0, fake.z)
	aim = Vector2(clampf(rx, -3.8, 3.8), 15.1)
	phase = 0
	wait_t = 0.0

func _build_hud() -> void :
	var layer: = CanvasLayer.new()
	add_child(layer)
	hud_lbl = Label.new()
	hud_lbl.add_theme_font_size_override("font_size", 30)
	hud_lbl.add_theme_color_override("font_color", Color.WHITE)
	hud_lbl.add_theme_color_override("font_outline_color", Color("#101a33"))
	hud_lbl.add_theme_constant_override("outline_size", 8)
	hud_lbl.position = Vector2(28, 20)
	layer.add_child(hud_lbl)
	help_lbl = Label.new()
	help_lbl.add_theme_font_size_override("font_size", 16)
	help_lbl.add_theme_color_override("font_color", Color("#cfe0ff"))
	help_lbl.position = Vector2(28, 668)
	help_lbl.text = "1) WASD/flechas: mueve la diana  ·  2) ESPACIO: saca  ·  3) Derriba latas/dianas  ·  ESC: salir"
	layer.add_child(help_lbl)
	_refresh_hud()

func _refresh_hud() -> void :
	var mname: String = "DIANAS" if mode == "targets" else "LATAS"
	hud_lbl.text = ("ENTRENAMIENTO DE PRECISIÓN" if mode == "targets" else "ENTRENAMIENTO DE SAQUE") + " · SAQUES: " + str(serves_left) + " · " + mname + ": " + str(score) + "/" + str(total_cans) + " · LADO: " + ("IZQ" if serve_side < 0.0 else "DER")

func start_serve() -> void :
	if phase != 0 or serves_left <= 0:
		return
	phase = 1
	fake.swing = 0.4
	fake.kind = "serve"
	fake.wait_serve = false
	net_hit = false
	touched_net = false
	legal_bounce = false
	crossed_net = false
	scored_this_serve = false
	fig.position = Vector3(fake.x, 0.0, fake.z)

func _spawn_popup(txt: String, pos: Vector3) -> void :
	var l: = Label3D.new()
	l.text = txt
	l.font_size = 72
	l.outline_size = 18
	l.modulate = Color("#ffe27a")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos + Vector3(0.0, 1.0, 0.0)
	add_child(l)
	popups.append({"l": l, "t": 1.1})

func _launch_ball() -> void :
	var p0: = Vector3(fake.x, 2.45, fake.z + 0.4)
	var tgt: = Vector3(aim.x + randf_range(-0.18, 0.18), 0.0, aim.y + randf_range(-0.18, 0.18))
	var tf: = 0.92
	bpos = p0
	bvel = Vector3((tgt.x - p0.x) / tf, (0.0 - p0.y + 0.5 * G * tf * tf) / tf, (tgt.z - p0.z) / tf)

	var t_net: float = (NZ - p0.z) / bvel.z
	var y_net: float = p0.y + bvel.y * t_net - 0.5 * G * t_net * t_net
	if y_net < 1.09:
		net_hit = true
		touched_net = true
	ball_on = true
	bounces = 0
	ball.visible = true
	sfx.play("hit", 1.2)

func _end_serve() -> void :
	if not ball_on:
		return
	ball_on = false
	ball.visible = false
	serves_left -= 1
	_refresh_hud()
	phase = 2
	wait_t = 0.7

func _finish() -> void :
	phase = 3
	finish_t = 2.0
	var layer: = CanvasLayer.new()
	add_child(layer)
	finish_panel = PanelContainer.new()
	finish_panel.position = Vector2(340, 250)
	finish_panel.custom_minimum_size = Vector2(600, 200)
	var vb: = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	finish_panel.add_child(vb)
	var t: = Label.new()
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_color", Color("#ffd23f"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.text = ("ENTRENAMIENTO: " + str(score) + "/" + str(total_cans) + (" DIANAS" if mode == "targets" else " LATAS"))
	vb.add_child(t)
	var s2: = Label.new()
	s2.add_theme_font_size_override("font_size", 20)
	s2.add_theme_color_override("font_color", Color.WHITE)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s2.text = "¡Saque de campeon!" if score >= total_cans - 1 else ("Buen ritmo. Volviendo al menu..." if score >= 3 else "Toca practicar... Volviendo al menu...")
	vb.add_child(s2)
	var sc: = Label.new()
	sc.add_theme_font_size_override("font_size", 15)
	sc.add_theme_color_override("font_color", Color("#9fb3e8"))
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc.text = "ENTER para continuar"
	vb.add_child(sc)
	layer.add_child(finish_panel)
	training_finished.emit(score, total_cans)

func _physics_process(dt: float) -> void :
	if phase == 3:
		finish_t -= dt
		if finish_t <= 0.0 or Input.is_action_just_pressed("hit") or Input.is_key_pressed(KEY_ENTER):
			quit_to_menu.emit()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		quit_to_menu.emit()
		return

	if phase == 0:
		aim.x = clampf(aim.x + Input.get_axis("move_left", "move_right") * dt * 5.0, -4.0, 4.0)
		aim.y = clampf(aim.y + Input.get_axis("move_down", "move_up") * dt * 4.0, 12.6, 18.1)
		marker.position = Vector3(aim.x, 0.03, aim.y)
		if Input.is_action_just_pressed("hit"):
			start_serve()

	if phase == 1 and fake.swing > 0.0:
		var k_prev: float = 1.0 - fake.swing / 0.4
		fake.swing -= dt
		var k_now: float = 1.0 - fake.swing / 0.4
		if k_prev < 0.55 and k_now >= 0.55:
			_launch_ball()
		if fake.swing <= 0.0:
			fake.swing = 0.0
	fig.update_from_sim(fake, dt)

	if ball_on:
		bvel.y -= G * dt
		bpos += bvel * dt
		if not crossed_net and bpos.z > NZ + 0.15:
			crossed_net = true
		if net_hit and bpos.z >= NZ - 0.05 and bpos.y < 1.12:
			bvel = Vector3(bvel.x * 0.15, -0.5, - bvel.z * 0.2)
			sfx.play("net")
			net_hit = false
			crossed_net = false
		if bpos.y <= 0.11:
			bpos.y = 0.11
			bounces += 1
			if bounces == 1:
				sfx.play("bounce", 0.8)
				var _bs: float = - signf(fake.x)
				legal_bounce = bpos.z > NZ and bpos.z <= NZ + 6.4 and absf(bpos.x) <= 4.11 and bpos.x * _bs >= - 0.03
				bvel.y = - bvel.y * 0.62
				bvel.x *= 0.8
				bvel.z *= 0.8
			else:
				_end_serve()
		if bpos.z > 26.0 or absf(bpos.x) > 7.0:
			_end_serve()

		if crossed_net and legal_bounce and not touched_net:
			for tg in targets:
				if not tg.hit:
					var c: MeshInstance3D = tg.m
					var d: Vector3 = bpos - c.position
					if absf(d.y) < 0.7 and Vector2(d.x, d.z).length() < float(tg.get("r", 0.45)):
						tg.hit = true
						score += 1
						_refresh_hud()
						sfx.play("hit_perfect" if mode == "targets" else "point_win", 0.9)
						crowd.react(false)
						if String(tg.get("kind", "can")) == "can":
							tg.vel = Vector3(randf_range(-2.4, 2.4), randf_range(4.2, 6.2), randf_range(0.8, 3.0))
							_spawn_popup("¡LATA!", c.position)
						else:
							_spawn_popup("¡DIANA!", c.position)
		ball.position = bpos

	for tg in targets:
		if tg.hit:
			var c: MeshInstance3D = tg.m
			if String(tg.get("kind", "can")) == "can":
				if tg.get("vel") != null and tg.vel != Vector3.ZERO:
					tg.vel.y -= G * dt
					tg.base += tg.vel * dt
					if tg.base.y < 0.26:
						tg.base.y = 0.26
						tg.vel.y = absf(tg.vel.y) * 0.45
						tg.vel.x *= 0.7
						tg.vel.z *= 0.7
					c.position = tg.base
					c.rotation.x += dt * 7.0
					c.rotation.z += dt * 4.0
					if tg.base.y <= 0.27 and absf(tg.vel.y) < 0.6:
						tg.vel = Vector3.ZERO
						c.rotation.x = PI * 0.5
			else:
				tg.fall = minf(1.0, tg.fall + dt * 2.2)
				c.position = tg.base - Vector3(0, tg.fall * 0.12, 0)
				c.scale = Vector3.ONE * (1.0 - 0.35 * tg.fall)

	for i in range(popups.size() - 1, -1, -1):
		var p = popups[i]
		p.t -= dt
		p.l.position.y += dt * 0.8
		p.l.modulate.a = clampf(p.t / 0.5, 0.0, 1.0)
		if p.t <= 0.0:
			p.l.queue_free()
			popups.remove_at(i)

	if phase == 2:
		wait_t -= dt
		if wait_t <= 0.0:


			if serves_left <= 0 or score >= total_cans:
				_finish()
			else:
				_start_next_serve()
	crowd.update(dt, 0.25)
