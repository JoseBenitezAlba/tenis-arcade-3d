class_name PlayerRig
extends Node3D

# Jugador 3D articulado: hombro/codo, cadera/rodilla, raqueta en mano.
var palette := {}
var body: Node3D
var torso_pivot: Node3D
var head_grp: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var sho_l: Node3D
var sho_r: Node3D
var elb_l: Node3D
var elb_r: Node3D
var racket: Node3D

const LOOKS := [
    {"shirt": "#1fb87a", "shirt2": "#0f7a52", "shorts": "#f2f2f2", "cap": "#103a2a", "skin": "#e6b48a"},
    {"shirt": "#f0a020", "shirt2": "#b06a00", "shorts": "#222a40", "cap": "#ffffff", "skin": "#8a5a3a"},
    {"shirt": "#a05ae0", "shirt2": "#6a2fa8", "shorts": "#f0f0f0", "cap": "#2a1a40", "skin": "#d9a37a"},
    {"shirt": "#3a8be0", "shirt2": "#1f5aa8", "shorts": "#1b2540", "cap": "#ffffff", "skin": "#c98d62"},
    {"shirt": "#2f3a52", "shirt2": "#161c2e", "shorts": "#e8e8e8", "cap": "#ff5a5a", "skin": "#b97a52"},
]
const P0 := {"shirt": "#e23b3b", "shirt2": "#a82020", "shorts": "#f2f2f2", "cap": "#e23b3b", "skin": "#e0a77a"}

static func _m(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.75
    return m

func _capsule(r: float, h: float, mat: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var cm := CapsuleMesh.new()
    cm.radius = r
    cm.height = h
    cm.material = mat
    mi.mesh = cm
    return mi

func _init(look: int, is_player0: bool) -> void:
    palette = P0 if is_player0 else LOOKS[look % LOOKS.size()]
    var shirt := _m(Color(palette.shirt))
    var shirt2 := _m(Color(palette.shirt2))
    var shorts := _m(Color(palette.shorts))
    var skin := _m(Color(palette.skin))
    var capm := _m(Color(palette.cap))

    body = Node3D.new()
    add_child(body)

    # pelvis
    var pelvis := MeshInstance3D.new()
    var pb := BoxMesh.new()
    pb.size = Vector3(0.30, 0.16, 0.19)
    pb.material = shorts
    pelvis.mesh = pb
    pelvis.position = Vector3(0, 1.0, 0)
    body.add_child(pelvis)

    # torso (pivot a la cintura para poder rotar el tronco)
    torso_pivot = Node3D.new()
    torso_pivot.position = Vector3(0, 1.05, 0)
    body.add_child(torso_pivot)
    var chest := _capsule(0.155, 0.5, shirt)
    chest.position = Vector3(0, 0.22, 0)
    chest.scale = Vector3(1.15, 1.0, 0.75)
    torso_pivot.add_child(chest)
    var stripe := _capsule(0.16, 0.22, shirt2)
    stripe.position = Vector3(0, 0.05, 0)
    stripe.scale = Vector3(1.12, 1.0, 0.72)
    torso_pivot.add_child(stripe)
    var neck := MeshInstance3D.new()
    var nc := CylinderMesh.new()
    nc.top_radius = 0.045
    nc.bottom_radius = 0.05
    nc.height = 0.08
    nc.material = skin
    neck.mesh = nc
    neck.position = Vector3(0, 0.47, 0)
    torso_pivot.add_child(neck)

    # cabeza
    head_grp = Node3D.new()
    head_grp.position = Vector3(0, 0.52, 0)
    torso_pivot.add_child(head_grp)
    var head := MeshInstance3D.new()
    var hs := SphereMesh.new()
    hs.radius = 0.10
    hs.height = 0.21
    hs.material = skin
    head.mesh = hs
    head.position = Vector3(0, 0.06, 0.01)
    head_grp.add_child(head)
    var cap := MeshInstance3D.new()
    var cs := SphereMesh.new()
    cs.radius = 0.11
    cs.height = 0.16
    cs.material = capm
    cap.mesh = cs
    cap.position = Vector3(0, 0.10, 0)
    head_grp.add_child(cap)
    var brim := MeshInstance3D.new()
    var bb := BoxMesh.new()
    bb.size = Vector3(0.14, 0.015, 0.11)
    bb.material = capm
    brim.mesh = bb
    brim.position = Vector3(0, 0.085, 0.13)
    head_grp.add_child(brim)

    # brazos: hombro -> brazo -> codo -> antebrazo -> mano
    for s in [-1, 1]:
        var sho := Node3D.new()
        sho.position = Vector3(s * 0.185, 0.40, 0)
        torso_pivot.add_child(sho)
        var upper := _capsule(0.062, 0.30, shirt)
        upper.position = Vector3(0, -0.15, 0)
        sho.add_child(upper)
        var elb := Node3D.new()
        elb.position = Vector3(0, -0.31, 0)
        sho.add_child(elb)
        var fore := _capsule(0.048, 0.30, skin)
        fore.position = Vector3(0, -0.14, 0)
        elb.add_child(fore)
        var hand := MeshInstance3D.new()
        var hsp := SphereMesh.new()
        hsp.radius = 0.05
        hsp.height = 0.1
        hsp.material = skin
        hand.mesh = hsp
        hand.position = Vector3(0, -0.30, 0)
        elb.add_child(hand)
        if s < 0:
            sho_l = sho
            elb_l = elb
        else:
            sho_r = sho
            elb_r = elb

    # raqueta en la mano derecha
    racket = Node3D.new()
    racket.position = Vector3(0, -0.32, 0.02)
    elb_r.add_child(racket)
    var handle := MeshInstance3D.new()
    var hc := CylinderMesh.new()
    hc.top_radius = 0.016
    hc.bottom_radius = 0.019
    hc.height = 0.22
    hc.material = _m(Color("#3a2c1c"))
    handle.mesh = hc
    handle.position = Vector3(0, -0.09, 0)
    racket.add_child(handle)
    var throat := MeshInstance3D.new()
    var tc := CylinderMesh.new()
    tc.top_radius = 0.012
    tc.bottom_radius = 0.016
    tc.height = 0.12
    tc.material = _m(Color("#222222"))
    throat.mesh = tc
    throat.position = Vector3(0, -0.24, 0)
    racket.add_child(throat)
    var frame := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.125
    tm.outer_radius = 0.15
    tm.material = _m(Color("#1a1a22"))
    frame.mesh = tm
    frame.scale = Vector3(1.0, 1.25, 1.0)
    frame.position = Vector3(0, -0.44, 0)
    racket.add_child(frame)
    var strings := MeshInstance3D.new()
    var qm := QuadMesh.new()
    qm.size = Vector2(0.23, 0.30)
    var sm := StandardMaterial3D.new()
    sm.albedo_color = Color(1, 1, 1, 0.4)
    sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sm.cull_mode = BaseMaterial3D.CULL_DISABLED
    qm.material = sm
    strings.mesh = qm
    strings.position = Vector3(0, -0.44, 0)
    racket.add_child(strings)

    # piernas: cadera -> muslo -> rodilla -> espinilla -> pie
    for s in [-1, 1]:
        var hip := Node3D.new()
        hip.position = Vector3(s * 0.10, 0.94, 0)
        body.add_child(hip)
        var thigh := _capsule(0.076, 0.44, skin)
        thigh.position = Vector3(0, -0.21, 0)
        hip.add_child(thigh)
        # parte alta del muslo con pantalon
        var st := _capsule(0.085, 0.17, shorts)
        st.position = Vector3(0, -0.07, 0)
        hip.add_child(st)
        var knee := Node3D.new()
        knee.position = Vector3(0, -0.43, 0)
        hip.add_child(knee)
        var shin := _capsule(0.06, 0.44, skin)
        shin.position = Vector3(0, -0.20, 0)
        knee.add_child(shin)
        var shoe := MeshInstance3D.new()
        var sb := BoxMesh.new()
        sb.size = Vector3(0.11, 0.07, 0.24)
        sb.material = _m(Color.WHITE)
        shoe.mesh = sb
        shoe.position = Vector3(0, -0.44, 0.04)
        knee.add_child(shoe)
        if s < 0:
            hip_l = hip
            knee_l = knee
        else:
            hip_r = hip
            knee_r = knee

func update_from_sim(e, dt: float) -> void:
    position = Vector3(e.x, 0, e.z)
    rotation.y = 0.0 if e.near else PI
    var sp: float = clampf(e.speed / 6.0, 0.0, 1.0)
    var ph: float = e.run
    var swing_dur: float = 0.4 if e.kind == "serve" else 0.34
    var k: float = 1.0 - e.swing / swing_dur if e.swing > 0.0 else -1.0
    var serving: bool = e.kind == "serve" and e.swing > 0.0

    # piernas: carrera normal o paso lateral (shuffle) segun la direccion dominante
    var lateral := sp > 0.15 and absf(e.vx) > absf(e.vz) * 1.4
    if lateral:
        # defensa lateral: piernas en tijera de lado, cadera baja, sin braceo de carrera
        hip_l.rotation.x = 0.16 * sp
        hip_r.rotation.x = -0.16 * sp
        hip_l.rotation.z = sin(ph) * 0.38 * sp
        hip_r.rotation.z = sin(ph) * 0.38 * sp
        knee_l.rotation.x = (0.45 + maxf(0.0, sin(ph)) * 0.35) * sp
        knee_r.rotation.x = (0.45 + maxf(0.0, sin(ph + PI)) * 0.35) * sp
    else:
        hip_l.rotation.x = sin(ph) * 0.8 * sp
        hip_r.rotation.x = sin(ph + PI) * 0.8 * sp
        hip_l.rotation.z = 0.0
        hip_r.rotation.z = 0.0
        knee_l.rotation.x = maxf(0.0, sin(ph - 1.1)) * 1.15 * sp
        knee_r.rotation.x = maxf(0.0, sin(ph + PI - 1.1)) * 1.15 * sp
    var bob: float = absf(sin(ph)) * (0.035 if lateral else 0.05) * sp
    body.position.y = bob
    var arm_sp: float = sp * (0.35 if lateral else 1.0)

    var lk: float = minf(1.0, dt * 10.0)
    if serving and k >= 0.0:
        # saque: brazo izq lanza, derecho pega alto, tronco arqueado
        sho_l.rotation.x = lerpf(sho_l.rotation.x, PI * 0.92, lk)
        elb_l.rotation.x = lerpf(elb_l.rotation.x, 0.1, lk)
        var k2: float = clampf(k * 1.3, 0.0, 1.0)
        sho_r.rotation.x = lerpf(-2.7, -1.1, k2)
        elb_r.rotation.x = lerpf(1.6, 0.1, k2)
        torso_pivot.rotation.y = lerpf(-0.5, 0.5, k2)
        torso_pivot.rotation.x = lerpf(-0.18, 0.12, k2)
        racket.rotation.x = lerpf(1.2, 0.5, k2)
        knee_l.rotation.x = maxf(knee_l.rotation.x, 0.5 * (1.0 - k2))
        knee_r.rotation.x = maxf(knee_r.rotation.x, 0.5 * (1.0 - k2))
    elif k >= 0.0:
        # golpe: tronco rota, brazo derecho barre
        var sw: float = sin(k * PI * 0.5)
        var follow: float = maxf(0.0, k - 0.5) * 2.0
        sho_r.rotation.x = lerpf(1.3, -1.2, sw)
        elb_r.rotation.x = lerpf(1.3, 0.15, sw) + follow * 0.4
        torso_pivot.rotation.y = lerpf(-0.6, 0.55, sw)
        torso_pivot.rotation.x = lerpf(torso_pivot.rotation.x, 0.15 + sp * 0.1, lk)
        racket.rotation.x = lerpf(0.9, -0.4, sw)
        sho_l.rotation.x = lerpf(sho_l.rotation.x, -0.4, lk)
        elb_l.rotation.x = lerpf(elb_l.rotation.x, 0.9, lk)
    elif e.want_t > 0.0:
        # preparacion: armado atras
        sho_r.rotation.x = lerpf(sho_r.rotation.x, 1.25, lk)
        elb_r.rotation.x = lerpf(elb_r.rotation.x, 1.25, lk)
        torso_pivot.rotation.y = lerpf(torso_pivot.rotation.y, -0.6, lk)
        racket.rotation.x = lerpf(racket.rotation.x, 0.9, lk)
        sho_l.rotation.x = lerpf(sho_l.rotation.x, 0.3, lk)
        elb_l.rotation.x = lerpf(elb_l.rotation.x, 0.5, lk)
    else:
        # idle / carrera
        sho_r.rotation.x = lerpf(sho_r.rotation.x, 0.1 + sin(ph + PI) * 0.5 * arm_sp, lk)
        elb_r.rotation.x = lerpf(elb_r.rotation.x, 0.5 + 0.3 * arm_sp, lk)
        sho_l.rotation.x = lerpf(sho_l.rotation.x, sin(ph) * 0.55 * arm_sp, lk)
        elb_l.rotation.x = lerpf(elb_l.rotation.x, 0.45 + 0.3 * arm_sp, lk)
        torso_pivot.rotation.y = lerpf(torso_pivot.rotation.y, 0.0, lk)
        torso_pivot.rotation.x = lerpf(torso_pivot.rotation.x, 0.12 * sp, lk)
        racket.rotation.x = lerpf(racket.rotation.x, 0.25, lk)
