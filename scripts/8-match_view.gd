class_name MatchView
extends Node3D

signal match_finished(win: bool)
signal quit_to_menu

const L := 23.77
const NZ := L / 2.0
var sim: TennisSim
var court: Node3D
var rigs := []
var ball_mesh: MeshInstance3D
var ball_shadow: MeshInstance3D
var shadows := []
var ball_shadow_mat: StandardMaterial3D
var trail := []
var cam: Camera3D
var hud: MatchHUD
var sfx: SoundKit
var dust_pool := []
var banner_t := 0.0
var banner_dur := 0.0
var hint_t := 9.0
var demo := false
var is_career := false
var paused_game := false
var pause_layer: CanvasLayer
var over_sent := false
var shake := 0.0

func setup(cfg: Dictionary) -> void:
    demo = cfg.get("demo", false)
    is_career = cfg.get("career", false)
    sim = TennisSim.new(demo, cfg.AIP, cfg.get("PS", {}), cfg.get("cpu_name", "CPU"), cfg.get("sets_to_win", 1))
    process_mode = Node.PROCESS_MODE_PAUSABLE

func _ready() -> void:
    if sim == null:
        sim = TennisSim.new(true)
    court = CourtBuilder.build(get_meta("surface", "clay"), get_meta("day", false))
    add_child(court)

    sfx = SoundKit.new()
    add_child(sfx)

    rigs = [PlayerRig.new(0, true), PlayerRig.new(get_meta("cpu_look", 2), false)]
    for r in rigs:
        add_child(r)

    # bola
    ball_mesh = MeshInstance3D.new()
    var bs := SphereMesh.new()
    bs.radius = 0.11
    bs.height = 0.22
    var bm := StandardMaterial3D.new()
    bm.albedo_color = Color("#d4ee3a")
    bm.emission_enabled = true
    bm.emission = Color("#c8e030")
    bm.emission_energy_multiplier = 0.6
    bs.material = bm
    ball_mesh.mesh = bs
    add_child(ball_mesh)

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

    # estela de la bola
    for i in 9:
        var t := MeshInstance3D.new()
        var ts := SphereMesh.new()
        ts.radius = 0.07
        ts.height = 0.14
        var tm := StandardMaterial3D.new()
        tm.albedo_color = Color(0.88, 1.0, 0.35, 0.2)
        tm.emission_enabled = true
        tm.emission = Color(0.88, 1.0, 0.35)
        tm.emission_energy_multiplier = 0.4
        tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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

    cam = Camera3D.new()
    cam.position = Vector3(0, 6.9, -11.8)
    cam.fov = 50.0
    add_child(cam)
    cam.look_at(Vector3(0, 0.4, NZ))
    cam.make_current()

    hud = MatchHUD.new()
    hud.cam = cam
    add_child(hud)
    hud.set_names(get_meta("my_name", "TÚ"), get_meta("cpu_label", "CPU"))
    hud.update_score(sim.M)
    if not demo:
        hud.set_hint("Stick/WASD mover · A/ESPACIO golpe · X/Z globo · B dejada · START pausa")
    else:
        hud.set_hint("")

    pause_layer = CanvasLayer.new()
    pause_layer.layer = 30
    pause_layer.visible = false
    add_child(pause_layer)
    var pl := Label.new()
    pl.text = "PAUSA"
    pl.add_theme_font_size_override("font_size", 72)
    pl.add_theme_color_override("font_color", Color.WHITE)
    pl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    pl.add_theme_constant_override("outline_size", 10)
    pl.position = Vector2(0, 300)
    pl.size = Vector2(1280, 100)
    pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_layer.add_child(pl)
    var pl2 := Label.new()
    pl2.text = "P / START continuar · ESC menú"
    pl2.add_theme_font_size_override("font_size", 22)
    pl2.add_theme_color_override("font_color", Color("#9fb3e8"))
    pl2.position = Vector2(0, 400)
    pl2.size = Vector2(1280, 40)
    pl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_layer.add_child(pl2)

func spawn_dust(pos: Vector3, n: int, col: Color) -> void:
    var c := 0
    for d in dust_pool:
        if d.life <= 0.0:
            d.life = randf_range(0.3, 0.6)
            d.max = 0.6
            d.m.visible = true
            d.m.position = pos + Vector3(randf_range(-0.1, 0.1), 0.05, randf_range(-0.1, 0.1))
            d.v = Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.2), randf_range(-1.5, 1.5))
            d.mat.albedo_color = col
            c += 1
            if c >= n:
                break

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") and not demo:
        if paused_game:
            paused_game = false
            get_tree().paused = false
            pause_layer.visible = false
        else:
            paused_game = true
            get_tree().paused = true
            pause_layer.visible = true
    elif event.is_action_pressed("quit") and paused_game:
        get_tree().paused = false
        paused_game = false
        quit_to_menu.emit()

func _physics_process(dt: float) -> void:
    if paused_game:
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
    sim.update(dt)
    drain_events()

    # visuales
    for i in 2:
        rigs[i].update_from_sim(sim.pl[i], dt)
        shadows[i].position.x = sim.pl[i].x
        shadows[i].position.z = sim.pl[i].z
        if sim.pl[i].speed > 3.0 and randf() < dt * 9.0:
            spawn_dust(Vector3(sim.pl[i].x, 0, sim.pl[i].z), 1, Color(1, 1, 1, 0.25))
    ball_mesh.position = Vector3(sim.ball.x, sim.ball.y, sim.ball.z)
    ball_shadow.position.x = sim.ball.x
    ball_shadow.position.z = sim.ball.z
    var sh_scale: float = clampf(1.0 + sim.ball.y * 0.12, 1.0, 2.2)
    ball_shadow.scale = Vector3(sh_scale * 0.4, 1, sh_scale * 0.4)
    ball_shadow_mat.albedo_color.a = clampf(0.5 - sim.ball.y * 0.05, 0.08, 0.5)
    for i in trail.size():
        var t = trail[i]
        if i < sim.ball.trail.size():
            t.m.visible = true
            t.m.position = sim.ball.trail[i]
            t.mat.albedo_color.a = 0.05 + 0.16 * float(i) / trail.size()
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
    # camara sigue suave a la bola
    var target_x: float = clampf(sim.ball.x * 0.35, -2.6, 2.6)
    cam.position.x = lerpf(cam.position.x, target_x, minf(1.0, dt * 2.2))
    if shake > 0.0:
        shake = maxf(0.0, shake - dt)
        cam.position.y = 6.9 + randf_range(-1.0, 1.0) * shake * 0.35
        cam.position.z = -11.8 + randf_range(-1.0, 1.0) * shake * 0.25
    cam.look_at(Vector3(sim.ball.x * 0.2, 0.4, NZ))

    if banner_t > 0.0:
        banner_t -= dt
        if banner_t <= 0.0:
            hud.hide_banner()
    if hint_t > 0.0 and not demo:
        hint_t -= dt
        if hint_t <= 0.0:
            hud.set_hint("")
    elif not demo and sim.state == "serve" and sim.M.server == 0 and sim.serve_stage != "hit":
        hud.set_hint("A / ESPACIO: lanzar la bola · otra vez para golpear" if sim.serve_stage == "ready" else "¡Golpea cuando la bola esté arriba!")

func drain_events() -> void:
    for ev in sim.events:
        match ev.t:
            "hit":
                sfx.play("hit_big" if ev.kind == "smash" else "hit", 1.0)
                if ev.kind == "smash":
                    shake = 0.25
                spawn_dust(Vector3(ev.x, ev.y, ev.z), 3, Color(1, 0.96, 0.7, 0.4))
                if ev.id == 0 and not demo:
                    match ev.kind:
                        "smash":
                            hud.popup("¡SMASH!", Vector3(ev.x, ev.y, ev.z), Color("#ffd23f"))
                        "lob":
                            hud.popup("GLOBO", Vector3(ev.x, ev.y, ev.z), Color("#7ac7ff"))
                        "drop":
                            hud.popup("DEJADA", Vector3(ev.x, ev.y, ev.z), Color("#c8ffb0"))
            "serve":
                sfx.play("hit", 1.2)
            "toss":
                sfx.play("serve")
            "bounce":
                if not demo or randf() < 0.3:
                    sfx.play("bounce", ev.v)
                spawn_dust(Vector3(ev.x, 0.05, ev.z), 4, Color(0.8, 0.7, 0.6, 0.35))
            "net":
                sfx.play("net")
            "sfx_point":
                if not demo:
                    sfx.play("point_win" if ev.w == 0 else "point_lose")
            "point":
                hud.update_score(sim.M)
                hud.show_banner(ev.txt, ev.sub, Color("#7dffa8") if ev.w == 0 else Color("#ff9c9c"))
                banner_dur = 1.9
                banner_t = 1.9
            "fault":
                sfx.play("fault")
                hud.show_banner("FALTA", ev.why, Color("#ffd23f"))
                banner_t = 1.1
                banner_dur = 1.1
            "over":
                over_sent = true
                match_finished.emit(sim.M.sets[0] > sim.M.sets[1])
    sim.events.clear()
