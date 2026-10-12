class_name TrainingView
extends Node3D

# Minijuego de entrenamiento estilo VT3: derriba las piramides de latas
# con el saque. 10 saques, punteria con stick/teclas, ESPACIO lanza.

signal training_finished(score: int, total: int)
signal quit_to_menu

const NZ := 11.885
const G := 9.8

class FakeEnt:
    var x := 0.0
    var z := -1.2
    var near := true
    var speed := 0.0
    var kind := "serve"
    var swing := 0.0
    var want_t := 0.0

var fig: PlayerFig
var crowd: CrowdFX
var sfx: SoundKit
var cam: Camera3D
var ball: MeshInstance3D
var marker: MeshInstance3D
var hud_lbl: Label
var help_lbl: Label
var targets: Array = []
var total_cans := 0
var serves_left := 10
var score := 0
var bpos := Vector3()
var bvel := Vector3()
var ball_on := false
var bounces := 0
var net_hit := false
var aim := Vector2(0.0, 15.1)
var fake := FakeEnt.new()
var phase := 0 # 0 apuntar, 1 sacando, 2 esperando siguiente, 3 fin
var wait_t := 0.0
var finish_panel: PanelContainer

func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.55
    return m

func setup(cfg: Dictionary) -> void:
    add_child(CourtBuilder.build(cfg.get("surface", "grass"), true))
    crowd = CrowdFX.new()
    add_child(crowd)
    crowd.build()
    sfx = SoundKit.new()
    add_child(sfx)
    fig = PlayerFig.new(cfg.get("look", 0), true)
    add_child(fig)
    # camara detras del sacador
    cam = Camera3D.new()
    cam.fov = 55.0
    add_child(cam)
    cam.global_transform = Transform3D(Basis(), Vector3(0, 4.6, -8.2)).looking_at(Vector3(0, 0.8, 14.0), Vector3.UP)
    call_deferred("_activate_cam")
    # bola
    ball = MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 0.11
    sm.height = 0.22
    ball.mesh = sm
    ball.material_override = _mat(Color("#d8f34a"))
    ball.visible = false
    add_child(ball)
    # marcador de punteria
    marker = MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.30
    tm.outer_radius = 0.42
    marker.mesh = tm
    var mk := StandardMaterial3D.new()
    mk.albedo_color = Color("#ffd23f")
    mk.emission_enabled = true
    mk.emission = Color("#ffd23f")
    marker.material_override = mk
    marker.rotation.x = PI * 0.5
    add_child(marker)
    _build_targets()
    _build_hud()

func _activate_cam() -> void:
    cam.make_current()

func _build_targets() -> void:
    var can_cols := [Color("#e33f2e"), Color("#f2f2f2"), Color("#2e7ae3"), Color("#f2a52e")]
    var spots := [Vector2(2.05, 15.1), Vector2(-2.05, 15.1)]
    var ci := 0
    for sp in spots:
        var offs := [Vector2(-0.34, 0), Vector2(0.34, 0), Vector2(0, 0.34), Vector2(0, -0.06)]
        for k in 4:
            var can := MeshInstance3D.new()
            var cm := CylinderMesh.new()
            cm.top_radius = 0.085
            cm.bottom_radius = 0.085
            cm.height = 0.26
            can.mesh = cm
            can.material_override = _mat(can_cols[ci % can_cols.size()])
            var py: float = 0.13 if k < 3 else 0.47
            var px: float = sp.x + (offs[k].x if k < 3 else 0.0)
            var pz: float = sp.y + (offs[k].y if k < 3 else 0.06)
            can.position = Vector3(px, py, pz)
            add_child(can)
            targets.append({"m": can, "hit": false, "fall": 0.0, "dir": Vector3(randf_range(-1, 1), 0, randf_range(-0.4, 0.4)).normalized(), "base": can.position})
            ci += 1
    total_cans = targets.size()

func _build_hud() -> void:
    var layer := CanvasLayer.new()
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
    help_lbl.text = "WASD/flechas: punteria · ESPACIO: saque · ESC: salir"
    layer.add_child(help_lbl)
    _refresh_hud()

func _refresh_hud() -> void:
    hud_lbl.text = "ENTRENAMIENTO DE SAQUE · SAQUES: " + str(serves_left) + " · LATAS: " + str(score) + "/" + str(total_cans)

func start_serve() -> void:
    if phase != 0 or serves_left <= 0:
        return
    phase = 1
    fake.swing = 0.4
    fake.kind = "serve"
    net_hit = false

func _launch_ball() -> void:
    var p0 := Vector3(fake.x, 2.45, fake.z + 0.4)
    var tgt := Vector3(aim.x + randf_range(-0.18, 0.18), 0.0, aim.y + randf_range(-0.18, 0.18))
    var tf := 0.92
    bpos = p0
    bvel = Vector3((tgt.x - p0.x) / tf, (0.0 - p0.y + 0.5 * G * tf * tf) / tf, (tgt.z - p0.z) / tf)
    # si no pasa la red, se queda corto
    var t_net: float = (NZ - p0.z) / bvel.z
    var y_net: float = p0.y + bvel.y * t_net - 0.5 * G * t_net * t_net
    if y_net < 1.09:
        # corrige la trayectoria para que impacte en la red
        net_hit = true
    ball_on = true
    bounces = 0
    ball.visible = true
    sfx.play("hit", 1.2)

func _end_serve() -> void:
    ball_on = false
    ball.visible = false
    serves_left -= 1
    _refresh_hud()
    phase = 2
    wait_t = 0.7

func _finish() -> void:
    phase = 3
    var layer := CanvasLayer.new()
    add_child(layer)
    finish_panel = PanelContainer.new()
    finish_panel.position = Vector2(340, 250)
    finish_panel.custom_minimum_size = Vector2(600, 200)
    var vb := VBoxContainer.new()
    vb.alignment = BoxContainer.ALIGNMENT_CENTER
    finish_panel.add_child(vb)
    var t := Label.new()
    t.add_theme_font_size_override("font_size", 40)
    t.add_theme_color_override("font_color", Color("#ffd23f"))
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    t.text = "ENTRENAMIENTO: " + str(score) + "/" + str(total_cans) + " LATAS"
    vb.add_child(t)
    var s2 := Label.new()
    s2.add_theme_font_size_override("font_size", 20)
    s2.add_theme_color_override("font_color", Color.WHITE)
    s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    s2.text = "¡Saque de campeon!" if score >= total_cans - 1 else ("Buen ritmo. Pulsa ENTER para volver." if score >= 3 else "Toca practicar... Pulsa ENTER para volver.")
    vb.add_child(s2)
    layer.add_child(finish_panel)
    training_finished.emit(score, total_cans)

func _physics_process(dt: float) -> void:
    if phase == 3:
        if Input.is_action_just_pressed("hit") or Input.is_key_pressed(KEY_ENTER):
            quit_to_menu.emit()
        return
    if Input.is_action_just_pressed("ui_cancel"):
        quit_to_menu.emit()
        return
    # punteria
    if phase == 0:
        aim.x = clampf(aim.x + Input.get_axis("move_left", "move_right") * dt * 5.0, -4.0, 4.0)
        aim.y = clampf(aim.y + Input.get_axis("move_down", "move_up") * dt * 4.0, 12.6, 18.1)
        marker.position = Vector3(aim.x, 0.03, aim.y)
        if Input.is_action_just_pressed("hit"):
            start_serve()
    # animacion del jugador (reutiliza la logica de PlayerFig con una entidad falsa)
    if phase == 1 and fake.swing > 0.0:
        var k_prev: float = 1.0 - fake.swing / 0.4
        fake.swing -= dt
        var k_now: float = 1.0 - fake.swing / 0.4
        if k_prev < 0.55 and k_now >= 0.55:
            _launch_ball()
        if fake.swing <= 0.0:
            fake.swing = 0.0
    fig.update_from_sim(fake, dt)
    # bola
    if ball_on:
        bvel.y -= G * dt
        bpos += bvel * dt
        if net_hit and bpos.z >= NZ - 0.05 and bpos.y < 1.12:
            bvel = Vector3(bvel.x * 0.15, -0.5, -bvel.z * 0.2)
            sfx.play("net")
            net_hit = false
        if bpos.y <= 0.11:
            bpos.y = 0.11
            bounces += 1
            if bounces == 1:
                sfx.play("bounce", 0.8)
                bvel.y = -bvel.y * 0.62
                bvel.x *= 0.8
                bvel.z *= 0.8
            else:
                _end_serve()
        if bpos.z > 26.0 or absf(bpos.x) > 7.0:
            _end_serve()
        # latas
        for tg in targets:
            if not tg.hit:
                var c: MeshInstance3D = tg.m
                var d: Vector3 = bpos - c.position
                if absf(d.y) < 0.55 and Vector2(d.x, d.z).length() < 0.42:
                    tg.hit = true
                    score += 1
                    _refresh_hud()
                    sfx.play("point_win")
                    crowd.react(false)
        ball.position = bpos
    # caida de latas
    for tg in targets:
        if tg.hit and tg.fall < 1.0:
            tg.fall = minf(1.0, tg.fall + dt * 2.2)
            var c: MeshInstance3D = tg.m
            c.rotation.x = tg.fall * PI * 0.5 * (1.0 if tg.dir.z >= 0.0 else -1.0)
            c.rotation.z = tg.fall * PI * 0.5 * tg.dir.x
            c.position = tg.base + Vector3(tg.dir.x, 0.0, tg.dir.z) * tg.fall * 0.35 - Vector3(0, tg.fall * 0.06, 0)
    # espera entre saques
    if phase == 2:
        wait_t -= dt
        if wait_t <= 0.0:
            # v0.22: fin inmediato al tumbar TODAS las latas (pleno),
            # aunque queden saques - antes el juego seguia sin objetivos
            if serves_left <= 0 or score >= total_cans:
                _finish()
            else:
                phase = 0
    crowd.update(dt, 0.25)
