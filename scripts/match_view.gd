class_name MatchView
extends Node3D

# Nodo siempre activo para poder salir de la pausa: match_view es PAUSABLE y,
# con el arbol en pausa, deja de recibir input (bug: pausa sin salida).
class PauseGuard extends Node:
    var mv: Node

    func _unhandled_input(event: InputEvent) -> void:
        mv._on_pause_input(event)

signal match_finished(win: bool)
signal quit_to_menu

const L := 23.77
const NZ := L / 2.0
var sim: TennisSim
var court: Node3D
var crowd: CrowdFX
var rigs := []
var ball_mesh: MeshInstance3D
var ball_shadow: MeshInstance3D
var shadows := []
var ball_shadow_mat: StandardMaterial3D
var bounce_ring: MeshInstance3D
var bounce_ring_mat: StandardMaterial3D
var trail := []
var cam: Camera3D
# v0.32 VT3: camara broadcast mas alta y lejana
const CAM_POS := Vector3(0, 9.4, -16.8)
const CAM_FOV := 43.0
const CAM_LOOK_Y := 1.0
var hud: MatchHUD
var sfx: SoundKit
var dust_pool := []
# v0.33: superficie (polvo y marcas acordes), frenadas y marcas de bote
var surface := "clay"
var brake_cd := [0.0, 0.0]
var mark_pool := []
var banner_t := 0.0
const SERVE_KMH_K := 8.4  # v0.27: medido - CPU 1er saque ~195-205 km/h, plano q1 ~197, seguro ~158
var banner_dur := 0.0
var hint_t := 9.0
var demo := false
# v0.34: true cuando hay controles tactiles (solo web movil/tablet)
var touch_ui := false
var is_career := false
var paused_game := false
var pause_layer: CanvasLayer
var over_sent := false
var shake := 0.0
var hitstop_t := 0.0  # v0.26: micro-pausa de impacto en golpes duros
var _hint_hidden := false
# repeticion de punto
var rec := []
var replaying := false
var replay_pending := false
var replay_i := 0.0
var replay_test := false
var replay_side := 1.0
const REC_MAX := 2700
var rally_label: Label
var rally_best := 0
var rally_display := 0
var rally_change_t := 0.0
var camera_smooth_x := 0.0
var camera_smooth_z := 0.0
var contact_ring: MeshInstance3D
var contact_ring_mat: StandardMaterial3D
var player_condition: Label

func setup(cfg: Dictionary) -> void:
    demo = cfg.get("demo", false)
    is_career = cfg.get("career", false)
    var ps = cfg.get("PS", {})
    if typeof(ps) != TYPE_DICTIONARY:
        ps = {}
    sim = TennisSim.new(demo, cfg.AIP, ps, cfg.get("cpu_name", "CPU"), cfg.get("sets_to_win", 1))
    sim.surface = get_meta("surface", "clay")  # v0.33: fisicas por superficie
    process_mode = Node.PROCESS_MODE_PAUSABLE

func _ready() -> void:
    if sim == null:
        sim = TennisSim.new(true)
        sim.surface = get_meta("surface", "clay")
    surface = get_meta("surface", "clay")
    court = CourtBuilder.build(surface, get_meta("day", false))
    add_child(court)
    crowd = CrowdFX.new()
    add_child(crowd)
    crowd.build()

    sfx = SoundKit.new()
    add_child(sfx)

    # v0.22: defensivo - el meta debe ser int; un String rompia el rig del CPU
    var cpu_look_meta = get_meta("cpu_look", 2)
    var cpu_look_i: int = cpu_look_meta if typeof(cpu_look_meta) == TYPE_INT else 2
    rigs = [PlayerFig.new(0, true), PlayerFig.new(cpu_look_i, false)]
    for r in rigs:
        add_child(r)

    # bola
    ball_mesh = MeshInstance3D.new()
    var bs := SphereMesh.new()
    bs.radius = 0.17
    bs.height = 0.34
    var bm := StandardMaterial3D.new()
    bm.albedo_color = Color("#e6ff4d")
    bm.emission_enabled = true
    bm.emission = Color("#d8f040")
    bm.emission_energy_multiplier = 1.0
    bs.material = bm
    ball_mesh.mesh = bs
    add_child(ball_mesh)
    var _bw := court.get_node_or_null("BallWatcher")
    if _bw:
        _bw.ball = ball_mesh

    # sombras blob
    var sh_tex := TexGen.shadow_texture()
    for i in 3:
        var sh_mat := StandardMaterial3D.new()
        sh_mat.albedo_texture = sh_tex
        sh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        sh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        sh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        var q := MeshInstance3D.new()
        var qm := QuadMesh.new()
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

    # anillo de bote (prediccion del primer bote)
    bounce_ring_mat = StandardMaterial3D.new()
    bounce_ring_mat.albedo_texture = TexGen.ring_texture()
    bounce_ring_mat.albedo_color = Color(1.0, 0.95, 0.35, 0.85)
    bounce_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bounce_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bounce_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    bounce_ring = MeshInstance3D.new()
    var rq := QuadMesh.new()
    rq.size = Vector2(2.2, 2.2)
    rq.material = bounce_ring_mat
    bounce_ring.mesh = rq
    bounce_ring.rotation_degrees.x = -90
    bounce_ring.position.y = 0.075  # por encima de la losa (top 0.06) y de la sombra (0.07)
    bounce_ring.visible = false
    add_child(bounce_ring)

    contact_ring = MeshInstance3D.new()
    var cr_mesh := TorusMesh.new()
    cr_mesh.inner_radius = 0.38
    cr_mesh.outer_radius = 0.47
    contact_ring.mesh = cr_mesh
    contact_ring_mat = StandardMaterial3D.new()
    contact_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    contact_ring_mat.albedo_color = Color("#78e7ff")
    contact_ring_mat.emission_enabled = true
    contact_ring_mat.emission = Color("#38bfff")
    contact_ring.material_override = contact_ring_mat
    contact_ring.rotation.x = PI * 0.5
    contact_ring.position.y = 0.08
    contact_ring.visible = false
    add_child(contact_ring)

    # estela de la bola
    for i in 9:
        var t := MeshInstance3D.new()
        var ts := SphereMesh.new()
        ts.radius = 0.105
        ts.height = 0.21
        var tm := StandardMaterial3D.new()
        tm.albedo_color = Color(0.88, 1.0, 0.35, 0.42)
        tm.emission_enabled = true
        tm.emission = Color(0.88, 1.0, 0.35)
        tm.emission_energy_multiplier = 0.85
        tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        tm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # v0.32 VT3: estela luminosa
        ts.material = tm
        t.mesh = ts
        t.visible = false
        add_child(t)
        trail.append({"m": t, "mat": tm})

    # polvo al botar / correr
    for i in 40:
        var d := MeshInstance3D.new()
        var ds := SphereMesh.new()
        ds.radius = 0.05
        ds.height = 0.1
        var dm := StandardMaterial3D.new()
        dm.albedo_color = Color(1, 1, 1, 0.5)
        dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        ds.material = dm
        d.mesh = ds
        d.visible = false
        add_child(d)
        dust_pool.append({"m": d, "mat": dm, "life": 0.0, "max": 0.6, "v": Vector3.ZERO})

    # v0.33: marcas de bote tenues que se desvanecen (tierra deja huella)
    for i in 10:
        var mk := MeshInstance3D.new()
        var mc := CylinderMesh.new()
        mc.top_radius = 0.14
        mc.bottom_radius = 0.14
        mc.height = 0.006
        var mm := StandardMaterial3D.new()
        mm.albedo_color = Color(0.3, 0.2, 0.15, 0.0)
        mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mc.material = mm
        mk.mesh = mc
        mk.visible = false
        add_child(mk)
        mark_pool.append({"m": mk, "mat": mm, "life": 0.0, "max": 1.3})

    cam = Camera3D.new()
    cam.position = CAM_POS
    cam.fov = CAM_FOV
    add_child(cam)
    cam.look_at(Vector3(0, CAM_LOOK_Y, NZ))
    cam.make_current()

    hud = MatchHUD.new()
    hud.cam = cam
    add_child(hud)
    hud.set_names(get_meta("my_name", "TÚ"), get_meta("cpu_label", "CPU"))
    hud.update_score(sim.M)
    rally_label = Label.new()
    rally_label.position = Vector2(1040, 604)
    rally_label.size = Vector2(220, 54)
    rally_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    rally_label.add_theme_font_size_override("font_size", 23)
    rally_label.add_theme_color_override("font_color", Color("#ffe783"))
    rally_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.82))
    rally_label.add_theme_constant_override("outline_size", 6)
    rally_label.visible = false
    hud.add_child(rally_label)
    player_condition = Label.new()
    player_condition.position = Vector2(500, 608)
    player_condition.size = Vector2(280, 42)
    player_condition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    player_condition.add_theme_font_size_override("font_size", 20)
    player_condition.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    player_condition.add_theme_constant_override("outline_size", 5)
    player_condition.visible = false
    hud.add_child(player_condition)
    touch_ui = false
    if not demo:
        touch_ui = get_meta("force_touch", false) or TouchControls.should_show()
        if touch_ui:
            var tc := TouchControls.new()
            add_child(tc)
    if not demo:
        if touch_ui:
            hud.set_hint("Joystick mover · GOLPE / TOP / SLICE / GLOBO / DEJADA · II pausa")
        else:
            hud.set_hint("Mover · A/ESPACIO drive · X/I topspin · B/SHIFT slice · Y/Z globo · L dejada · START/P pausa")
    else:
        hud.set_hint("")

    pause_layer = CanvasLayer.new()
    pause_layer.layer = 30
    pause_layer.visible = false
    add_child(pause_layer)
    # v0.36: fondo oscuro - el texto de pausa ya no se funde con el partido
    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.03, 0.08, 0.72)
    dim.position = Vector2.ZERO
    dim.size = Vector2(1280, 720)
    pause_layer.add_child(dim)
    var pl := Label.new()
    pl.text = "PAUSA"
    pl.add_theme_font_size_override("font_size", 44)
    pl.add_theme_color_override("font_color", Color.WHITE)
    pl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    pl.add_theme_constant_override("outline_size", 10)
    pl.position = Vector2(0, 272)  # v0.25: centrado (antes y=56, chocaba con el banner)
    pl.size = Vector2(1280, 100)
    pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_layer.add_child(pl)
    var pl2 := Label.new()
    pl2.text = "P / START continuar · ESC menú"
    pl2.add_theme_font_size_override("font_size", 22)
    pl2.add_theme_color_override("font_color", Color("#9fb3e8"))
    pl2.position = Vector2(0, 328)
    pl2.size = Vector2(1280, 40)
    pl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_layer.add_child(pl2)
    var guard := PauseGuard.new()
    guard.mv = self
    guard.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(guard)

# v0.33: polvo y marca segun superficie
func dust_color(a: float) -> Color:
    if surface == "clay":
        # palido: el polvo de tierra batida se ve CLARO sobre la pista naranja
        return Color(0.92, 0.78, 0.64, a)
    if surface == "grass":
        return Color(0.50, 0.62, 0.38, a)
    return Color(0.62, 0.63, 0.66, a)

func mark_color() -> Color:
    if surface == "clay":
        return Color(0.38, 0.20, 0.12)
    if surface == "grass":
        return Color(0.12, 0.22, 0.10)
    return Color(0.10, 0.12, 0.16)

func spawn_mark(pos: Vector3) -> void:
    for mk in mark_pool:
        if mk.life <= 0.0:
            mk.life = 1.3
            mk.max = 1.3
            mk.m.visible = true
            mk.m.position = Vector3(pos.x, 0.004, pos.z)
            mk.mat.albedo_color = mark_color()
            mk.mat.albedo_color.a = 0.4
            return

func spawn_dust(pos: Vector3, n: int, col: Color, sc: float = 1.0) -> void:
    var c := 0
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

func _unhandled_input(event: InputEvent) -> void:
    if replaying:
        if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
            _end_replay()
        return


func _on_pause_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and not demo:
        if paused_game:
            paused_game = false
            get_tree().paused = false
            pause_layer.visible = false
            if _hint_hidden:
                hud.hint.visible = true
                _hint_hidden = false
        else:
            # v0.36: cerrar la repeticion antes de pausar (PAUSA sobre REPETICION ilegible)
            if replaying:
                _end_replay()
            paused_game = true
            get_tree().paused = true
            pause_layer.visible = true
            hud.hide_banner()  # v0.25: limpiar banners activos al abrir pausa (solapamiento)
            banner_t = 0.0
            # v0.29: ocultar el resto de anuncios (popups, pista, medidor) bajo la pausa
            hud.hide_popups()
            hud.hint.visible = false
            hud.serve_meter_hide()
            _hint_hidden = true
    elif event.is_action_pressed("quit") and paused_game:
        get_tree().paused = false
        paused_game = false
        quit_to_menu.emit()

func _physics_process(dt: float) -> void:
    if paused_game:
        return
    if replaying:
        _replay_tick(dt)
        return
    if not demo:
        sim.inp.x = Input.get_axis("move_left", "move_right")
        sim.inp.y = Input.get_axis("move_down", "move_up")
        # Ligeramente más ágil en cambios de dirección, estilo arcade.
        var move := Vector2(sim.inp.x, sim.inp.y).limit_length(1.0)
        sim.inp.x = move.x
        sim.inp.y = move.y
        if Input.is_action_just_pressed("drop"):
            sim.inp.y = -1.0
            sim.inp.hit = true
        elif Input.is_action_just_pressed("hit"):
            sim.inp.hit = true
        elif Input.is_action_just_pressed("lob"):
            sim.inp.lob = true
        elif Input.is_action_just_pressed("slice"):
            sim.inp.slice = true
        elif Input.is_action_just_pressed("topspin"):
            sim.inp.topspin = true
    var this_rally := sim.rally_hits if sim.state == "play" else 0
    rally_display = this_rally
    if this_rally >= 3:
        rally_label.visible = true
        rally_label.text = "RALLY  %02d   ·   BEST %02d" % [this_rally, rally_best]
        rally_label.modulate.a = 1.0
    elif rally_change_t > 0.0:
        rally_label.visible = true
        rally_change_t = maxf(0.0, rally_change_t - dt)
        rally_label.text = "RALLY BEST  %02d" % rally_best
        rally_label.modulate.a = minf(1.0, rally_change_t * 1.7)
    else:
        rally_label.visible = false
    if hitstop_t > 0.0:
        hitstop_t -= dt  # v0.26: congela el sim un instante (el mundo sigue respirando)
    else:
        sim.update(dt)
    drain_events()
    if (not demo or replay_test) and sim.state not in ["point", "over"] and sim.ball.in_play:
        rec.append({"b": Vector3(sim.ball.x, sim.ball.y, sim.ball.z), "p0": _snap(sim.pl[0]), "p1": _snap(sim.pl[1])})
        if rec.size() > REC_MAX:
            rec.pop_front()
    var exc: float = clampf(sim.rally_hits / 10.0, 0.0, 1.0) if sim.state not in ["point", "over"] else 0.0
    crowd.ball_pos = ball_mesh.position
    crowd.update(dt, exc)

    # visuales
    for i in 2:
        rigs[i].update_from_sim(sim.pl[i], dt)
        shadows[i].position.x = sim.pl[i].x
        shadows[i].position.z = sim.pl[i].z
        brake_cd[i] = maxf(0.0, brake_cd[i] - dt)
        var pv = sim.pl[i]
        if pv.speed > 3.0 and randf() < dt * 9.0:
            spawn_dust(Vector3(pv.x, 0, pv.z), 1, dust_color(0.25))
        # v0.33: frenada brusca - chango de direccion a toda velocidad levanta
        # una nube (el gesto clasico de la tierra batida)
        if brake_cd[i] <= 0.0 and pv.speed > 4.0 and pv.vx * pv.tvx + pv.vz * pv.tvz < 0.0:
            spawn_dust(Vector3(pv.x, 0, pv.z), 8, dust_color(0.6), 4.0)
            brake_cd[i] = 0.45
    ball_mesh.position = Vector3(sim.ball.x, sim.ball.y, sim.ball.z)
    ball_shadow.position.x = sim.ball.x
    ball_shadow.position.z = sim.ball.z
    var sh_scale: float = clampf(1.0 + sim.ball.y * 0.12, 1.0, 2.2)
    ball_shadow.scale = Vector3(sh_scale * 0.4, 1, sh_scale * 0.4)
    ball_shadow_mat.albedo_color.a = clampf(0.7 - sim.ball.y * 0.06, 0.12, 0.7)
    _update_bounce_ring()
    _update_contact_ring()
    var heat: float = sim.ball.hot  # v0.26: estela blanca en tiros duros
    for i in trail.size():
        var t = trail[i]
        if i < sim.ball.trail.size():
            t.m.visible = true
            t.m.position = sim.ball.trail[i]
            var f: float = float(i) / trail.size()
            t.mat.albedo_color = Color(0.88, 1.0, 0.35).lerp(Color(1, 1, 1), heat)
            t.mat.albedo_color.a = 0.05 + (0.16 + 0.45 * heat) * f
            t.mat.emission = t.mat.albedo_color
            t.mat.emission_energy_multiplier = 0.4 + 1.6 * heat
            var tsc: float = 1.0 + 0.8 * heat * f
            t.m.scale = Vector3(tsc, tsc, tsc)
        else:
            t.m.visible = false
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
    # camara sigue suave a la bola
    var target_x: float = clampf(sim.ball.x * 0.27 + sim.pl[0].x * 0.12, -3.4, 3.4)
    var target_z: float = CAM_POS.z + clampf((sim.ball.z - NZ) * 0.08, -1.0, 1.0)
    camera_smooth_x = lerpf(camera_smooth_x, target_x, minf(1.0, dt * 2.6))
    camera_smooth_z = lerpf(camera_smooth_z, target_z, minf(1.0, dt * 1.6))
    cam.position.x = camera_smooth_x
    cam.position.y = lerpf(cam.position.y, CAM_POS.y + clampf(sim.ball.y * 0.07, 0.0, 0.75), minf(1.0, dt * 1.4))
    cam.position.z = camera_smooth_z
    if shake > 0.0:
        shake = maxf(0.0, shake - dt)
        # v0.36: amplitud mayor - el pico fuerte dura ~0.05s y decae (pedido)
        cam.position.y += randf_range(-1.0, 1.0) * shake * 0.5
        cam.position.z = camera_smooth_z + randf_range(-1.0, 1.0) * shake * 0.22
    var focus := Vector3(sim.ball.x * 0.22, CAM_LOOK_Y + clampf(sim.ball.y * 0.04, 0.0, 0.35), lerpf(NZ, sim.ball.z, 0.12))
    cam.look_at(focus)

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
        # v0.30: la pista del saque se quedaba pegada toda la jugada (video usuario)
        if hud.hint.text == "¡Golpea cuando la bola esté arriba!" or hud.hint.text.begins_with("A / ESPACIO"):
            hud.set_hint("")

    if player_condition.visible:
        var condition_life: float = float(player_condition.get_meta("life", 0.0)) - dt
        player_condition.set_meta("life", condition_life)
        player_condition.modulate.a = clampf(condition_life / 0.2, 0.0, 1.0)
        if condition_life <= 0.0:
            player_condition.visible = false

    # v0.27: medidor de saque - visible mientras el jugador prepara/lanza, se oculta al golpear
    if not demo and sim.state == "serve" and sim.M.server == 0 and sim.serve_stage in ["ready", "toss"]:
        # v0.30: el medidor muestra la CALIDAD real del lanzamiento (feedback usuario:
        # "saco a mitad de barra y canta perfecto") - barra llena = punto optimo
        var sq: float = 1.0 - clampf(absf(sim.ball.toss_t - 0.50) / 0.45, 0.0, 1.0)
        hud.serve_meter_update(sq if sim.serve_stage == "toss" else 0.0)
    elif not demo:
        hud.serve_meter_hide()

func _snap(pl) -> Dictionary:
    return {"x": pl.x, "z": pl.z, "near": pl.near, "speed": pl.speed, "run": pl.run, "kind": pl.kind, "swing": pl.swing, "want_t": pl.want_t,
        "want": pl.want, "vx": pl.vx, "vz": pl.vz, "prep_t": 0.0, "wait_serve": false,
        "dive_t": pl.dive_t}

func _update_bounce_ring() -> void:
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
    bounce_ring_mat.albedo_color.a = lerpf(0.95, 0.55, k)

func _update_contact_ring() -> void:
    if demo or sim.state != "play" or not sim.ball.in_play or sim.ball.last == 0 or sim.ball.vz >= 0.0:
        contact_ring.visible = false
        return
    var e = sim.pl[0]
    var to_ball := Vector2(sim.ball.x - e.x, sim.ball.z - e.z)
    var distance := to_ball.length()
    var closing := -(sim.ball.vx * to_ball.x + sim.ball.vz * to_ball.y) / maxf(distance, 0.1)
    var eta := distance / maxf(closing, 4.0)
    var reachable := distance < 2.35 and sim.ball.y < 3.1 and eta < 0.75
    contact_ring.visible = reachable
    if reachable:
        contact_ring.position.x = sim.ball.x
        contact_ring.position.z = sim.ball.z
        var urgency := clampf(1.0 - eta / 0.75, 0.0, 1.0)
        var pulse := 0.92 + 0.12 * sin(Time.get_ticks_msec() * 0.012)
        contact_ring.scale = Vector3.ONE * (0.75 + urgency * 0.28) * pulse
        contact_ring_mat.albedo_color = Color("#86ebff").lerp(Color("#ffe05c"), urgency)
        contact_ring_mat.emission = contact_ring_mat.albedo_color

func _start_replay() -> void:
    if rec.size() < 10:
        rec.clear()
        return
    replaying = true
    replay_i = 0.0
    bounce_ring.visible = false
    hud.show_replay()
    for t in trail:
        t.m.visible = false
    # v0.36: camara de repeticion tipo spidercam - arranca YA por encima de la
    # grada (antes nacia a 3.2m dentro del publico y el primer plano era la
    # espalda gris de un espectador hasta que el lerp la sacaba de ahi)
    var side := 1.0
    if rec.size() > 0:
        var fl: Dictionary = rec[rec.size() - 1]
        side = -1.0 if fl.b.x < 0.0 else 1.0
    replay_side = side
    cam.position = Vector3(9.2 * side, 7.0, clampf(rec[0].b.z - NZ, -8.0, 8.0) * 0.55)
    cam.fov = 42.0
    cam.look_at(Vector3(rec[0].b.x * 0.7, 0.9, rec[0].b.z))

func _replay_tick(dt: float) -> void:
    replay_i += dt * 36.0  # v0.35: camara lenta en la repeticion (pedido del usuario)
    var idx := int(replay_i)
    if idx >= rec.size():
        _end_replay()
        return
    var f: Dictionary = rec[idx]
    # v0.36: travelling alto por dentro de la grada (x<11.3 queda libre de
    # publico; a 6.8m de altura las cabezas de la ultima fila no tapan la bola)
    var cam_target := Vector3(8.6 * replay_side, 6.8, clampf(f.b.z - NZ, -6.5, 6.5) * 0.55)
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

func _end_replay() -> void:
    replaying = false
    rec.clear()
    hud.hide_replay()
    cam.position = CAM_POS
    cam.fov = CAM_FOV
    cam.look_at(Vector3(0, CAM_LOOK_Y, NZ))

func _hot_level() -> int:
    # v0.35: puntos calientes - oro, tie-break tardio, bola de set, bola de partido
    var M = sim.M
    if M.tb:
        var hi := maxi(M.tb_pts[0], M.tb_pts[1])
        var dif := absi(M.tb_pts[0] - M.tb_pts[1])
        if hi >= 5 and dif <= 1:
            return 1
        return 0
    if M.pts[0] == 3 and M.pts[1] == 3:
        return 1
    for i in 2:
        if M.pts[i] == 3 and M.games[i] == 3:
            return 3 if M.sets[i] >= M.sets_to_win - 1 else 2
    return 0

var _serve_armed := false
var _murmur_step := 0  # v0.36: murmullo que crece con el rally (4+ golpes)

func drain_events() -> void:
    for ev in sim.events:
        match ev.t:
            "hit":
                if ev.get("spd", 0.0) >= 38.0:
                    # v0.36: hit-stop mas perceptible en golpes duros (pedido del usuario)
                    hitstop_t = 0.05
                    shake = maxf(shake, 0.16)
                var perfect: bool = ev.get("perfect", false) and ev.id == 0 and not demo
                sfx.play("hit_big" if (perfect or ev.kind == "smash" or ev.get("rise", false)) else "hit", 1.0)
                if ev.kind == "smash":
                    shake = 0.34  # v0.36: sacudida corta e intensa
                spawn_dust(Vector3(ev.x, ev.y, ev.z), 3, Color(1, 0.96, 0.7, 0.4))
                # v0.36: grada viva - el murmullo crece cada 4 golpes de rally
                if sim.state == "play" and sim.rally_hits >= 4:
                    var stp := int(sim.rally_hits / 4)
                    if stp > _murmur_step:
                        _murmur_step = stp
                        sfx.play("murmur", clampf(0.4 + 0.15 * stp, 0.4, 0.85))
                # v0.29: popups sobre la cabeza del muñeco, no flotando en la red
                var pwp := Vector3(sim.pl[ev.id].x, 0.0, sim.pl[ev.id].z)
                if perfect:
                    shake = 0.36
                    hud.popup_big("¡PERFECTO!", Color("#ffe27a"))  # v0.36: legible
                    player_condition.text = "CONTACTO PERFECTO"
                    player_condition.add_theme_color_override("font_color", Color("#ffe27a"))
                    player_condition.visible = true
                    player_condition.set_meta("life", 1.0)
                elif ev.id == 0 and not demo:
                    if ev.get("stretch", 0.0) > 0.9:
                        hud.popup("ESTIRADO", pwp, Color("#ffad7a"))
                        player_condition.text = "CONTACTO FORZADO"
                        player_condition.add_theme_color_override("font_color", Color("#ffad7a"))
                    elif ev.get("rise", false):
                        hud.popup("AL BOTE", pwp, Color("#b5e8ff"))
                        player_condition.text = "GOLPEA AL BOTE"
                        player_condition.add_theme_color_override("font_color", Color("#b5e8ff"))
                    else:
                        match ev.kind:
                            "smash":
                                hud.popup("¡SMASH!", pwp, Color("#ffd23f"))
                            "lob":
                                hud.popup("GLOBO", pwp, Color("#7ac7ff"))
                            "drop":
                                hud.popup("DEJADA", pwp, Color("#c8ffb0"))
                            "slice":
                                hud.popup("SLICE", pwp, Color("#9df4ee"))
                            "topspin":
                                hud.popup("TOPSPIN", pwp, Color("#ffb07a"))
                        player_condition.text = ev.kind.to_upper()
                        player_condition.add_theme_color_override("font_color", Color.WHITE)
                    player_condition.visible = true
                    player_condition.set_meta("life", 0.9)
            "serve":
                if _hot_level() >= 1 and not _serve_armed:
                    sfx.play("murmur", 0.8)  # v0.35: la grada contiene la respiracion en puntos calientes
                    _serve_armed = true
                elif _hot_level() == 0:
                    _serve_armed = false
                hud.serve_meter_hide()
                var skmh: int = int(round(ev.get("spd", 0.0) * SERVE_KMH_K))
                if skmh > 0 and not demo:
                    hud.show_serve_speed(skmh)
                if ev.get("q", 0.0) >= 0.88:
                    hitstop_t = 0.05  # v0.36: saque perfecto con mas pegada
                sfx.play("hit_big" if (ev.get("q", 0.0) >= 0.88) else "hit", 1.2)
                if ev.get("q", 0.0) >= 0.88 and ev.get("id", 1) == 0 and not demo:
                    shake = 0.34
                    hud.popup_big("¡SAQUE PERFECTO!", Color("#ffe27a"))  # v0.36: centro y grande (antes ilegible)
            "toss":
                # v0.36: la grada enmudece con el lanzamiento de bola
                sfx.hush()
                _murmur_step = 0
                sfx.play("serve")
            "bounce":
                if not demo or randf() < 0.3:
                    sfx.play("bounce", ev.v)
                # v0.33: mas polvo cuanto mas fuerte pica + marca tenue en la pista
                spawn_dust(Vector3(ev.x, 0.05, ev.z), 5 + int(ev.v * 4.0), dust_color(0.55), 2.0 + ev.v * 2.0)
                spawn_mark(Vector3(ev.x, 0.0, ev.z))
            "net":
                sfx.play("net")
            "dive":
                sfx.play("dive", 0.9)
                if ev.id == 0 and not demo:
                    shake = maxf(shake, 0.12)
            "sfx_point":
                if not demo:
                    sfx.play("point_win" if ev.w == 0 else "point_lose")
            "point":
                var is_err: bool = ev.txt in ["FUERA", "RED", "DOBLE FALTA"]
                if sim.rally_hits > rally_best:
                    rally_best = sim.rally_hits
                if sim.rally_hits >= 3:
                    rally_change_t = 1.4
                crowd.react(is_err)
                # v0.36: ovacion en los aces (saque bueno sin resto: 1 solo golpe)
                if sim.rally_hits == 1 and ev.txt == "PUNTO":
                    sfx.play("ovation", 0.9)
                    if ev.w == 0 and not demo:
                        hud.popup("¡ACE!", Vector3(sim.pl[0].x, 0.0, sim.pl[0].z), Color("#ffe27a"))
                if _hot_level() >= 1:
                    sfx.play("ovation", 0.85)  # v0.35: explosion de grada al cerrar punto caliente
                # v0.30: baile post-punto eliminado (orden del usuario) - solo queda
                # el gesto del que pierde el punto
                rigs[1 - ev.w].celebrate("tennis/Hit_Head" if is_err else "tennis/Hit_Chest", 2.0)
                hud.update_score(sim.M)
                var bcol: Color = Color("#ffd23f") if ev.txt == "SET" else (Color("#7dffa8") if ev.w == 0 else Color("#ff9c9c"))
                var big: bool = ev.txt in ["JUEGO", "SET", "PARTIDO"]
                hud.show_banner(ev.txt, ev.sub, bcol, big)
                banner_dur = 2.2 if ev.txt == "SET" else (1.8 if ev.txt == "JUEGO" else 1.2)
                banner_t = banner_dur
                if (not demo or replay_test) and sim.rally_hits >= 4 and rec.size() > 45:
                    replay_pending = true
                else:
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
