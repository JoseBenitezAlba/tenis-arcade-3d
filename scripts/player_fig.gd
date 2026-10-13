class_name PlayerFig
extends Node3D
# Jugador con modelo real (Quaternius CC0) + animaciones retargeteadas.
# Misma interfaz que PlayerRig: PlayerFig.new(look, is_player0), update_from_sim(e, dt)

const MODELS := [
    "res://models/Casual_Male.fbx",
    "res://models/Casual_Female.fbx",
    "res://models/Casual2_Male.fbx",
    "res://models/Casual3_Female.fbx",
    "res://models/Casual_Bald.fbx",
]
const LOOKS := [
    {"shirt": "#2b7cd3", "shorts": "#1c2833", "skin": "#e0a77a", "hair": "#3a2a18"},
    {"shirt": "#f2f2f2", "shorts": "#3d5a80", "skin": "#c98d5e", "hair": "#141414"},
    {"shirt": "#39b54a", "shorts": "#f2f2f2", "skin": "#8d5524", "hair": "#0d0d0d"},
    {"shirt": "#f2a13c", "shorts": "#22303c", "skin": "#e8b68d", "hair": "#7a4a1e"},
]
const P0 := {"shirt": "#e23b3b", "shorts": "#f2f2f2", "skin": "#e0a77a", "hair": "#3a2a18"}
const CHAR_SCALE := 0.806   # modelo 2.17m -> ~1.75m

var ap: AnimationPlayer
var skel: Skeleton3D
var inst: Node3D
var state := ""
var blend := 0.14

static func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.8
    return m

static func _mat_kind(color: Color, kind: String) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    match kind:
        "face":
            m.roughness = 0.55
            m.rim_enabled = true
            m.rim = 0.18
            m.rim_tint = 0.3
            m.disable_receive_shadows = true
        "skin":
            m.roughness = 0.55
            m.rim_enabled = true
            m.rim = 0.35
            m.rim_tint = 0.55
        "shirt":
            m.roughness = 0.92
        "pants":
            m.roughness = 0.85
        "belt":
            m.roughness = 0.7
            m.albedo_color = color.darkened(0.45)
        "hair":
            m.roughness = 0.42
            m.metallic_specular = 0.75
    return m

func _init(look: int, is_player0: bool) -> void:
    var pal: Dictionary = P0 if is_player0 else LOOKS[look % LOOKS.size()]
    var mi := (0 if is_player0 else look + 1) % MODELS.size()
    inst = (load(MODELS[mi]) as PackedScene).instantiate()
    inst.scale = Vector3.ONE * CHAR_SCALE
    add_child(inst)
    skel = inst.find_child("Skeleton3D", true, false)
    ap = inst.find_child("AnimationPlayer", true, false)
    if ResourceLoader.exists("res://models/tennis_anims.tres"):
        ap.add_animation_library("tennis", load("res://models/tennis_anims.tres"))
    _apply_look(pal)
    _build_racket()
    _build_eyes()

func _apply_look(pal: Dictionary) -> void:
    var stack := [inst]
    while stack.size() > 0:
        var n = stack.pop_back()
        for c in n.get_children(): stack.append(c)
        if n is MeshInstance3D and n.mesh:
            for i in n.mesh.get_surface_count():
                var m = n.mesh.surface_get_material(i)
                var nn: String = (m.resource_name if m else "")
                var nm: String = nn.to_lower()
                var col := Color.WHITE
                var kind := ""
                if "skin" in nm: col = Color(pal.skin); kind = "skin"
                elif "face" in nm: col = Color(pal.skin); kind = "face"
                elif "shirt" in nm: col = Color(pal.shirt); kind = "shirt"
                elif "pants" in nm: col = Color(pal.shorts); kind = "pants"
                elif "belt" in nm: col = Color(pal.shorts); kind = "belt"
                elif "hair" in nm: col = Color(pal.hair); kind = "hair"; n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
                else: continue
                n.set_surface_override_material(i, _mat_kind(col, kind))

func _build_racket() -> void:
    var ba := BoneAttachment3D.new()
    ba.bone_name = "Fist.R"
    skel.add_child(ba)
    var rk := Node3D.new()
    # espacio de hueso: 1 unidad mundo = 0.01; compensar escala del personaje
    rk.scale = Vector3.ONE * (0.01 / CHAR_SCALE)
    rk.rotation = Vector3(PI * 0.5, PI * 0.5, 0)  # v0.12: la raqueta cuelga del puno, no atraviesa el antebrazo
    rk.position = Vector3.ZERO
    ba.add_child(rk)
    # v0.27: raqueta remodelada - grip octogonal, cuello en V abierto, cordaje real
    var handle := MeshInstance3D.new()
    var hc := CylinderMesh.new()
    hc.top_radius = 0.015
    hc.bottom_radius = 0.017
    hc.height = 0.20
    hc.radial_segments = 8  # octogonal como un grip real
    hc.material = _mat(Color("#26221e"))  # overgrip oscuro
    handle.mesh = hc
    handle.position = Vector3(0, -0.085, 0)
    rk.add_child(handle)
    var butt := MeshInstance3D.new()
    var bc := CylinderMesh.new()
    bc.top_radius = 0.021
    bc.bottom_radius = 0.022
    bc.height = 0.025
    bc.radial_segments = 8
    bc.material = _mat(Color("#141210"))
    butt.mesh = bc
    butt.position = Vector3(0, 0.02, 0)
    rk.add_child(butt)
    # cuello en V: dos varillas del final del grip a los lados del aro
    var graphite := _mat(Color("#191b20"))
    for sx in [-1.0, 1.0]:
        var a := Vector3(0, -0.185, 0)
        var b := Vector3(sx * 0.062, -0.375, 0)
        var seg := b - a
        var arm := MeshInstance3D.new()
        var ac := CylinderMesh.new()
        ac.top_radius = 0.008
        ac.bottom_radius = 0.011
        ac.height = seg.length()
        ac.material = graphite
        arm.mesh = ac
        arm.position = (a + b) * 0.5
        arm.basis = _basis_along_y(seg.normalized())
        rk.add_child(arm)
    var frame := MeshInstance3D.new()
    var tm := TorusMesh.new()
    tm.inner_radius = 0.125
    tm.outer_radius = 0.15
    tm.material = graphite
    frame.mesh = tm
    frame.scale = Vector3(1.0, 1.22, 1.0)
    frame.position = Vector3(0, -0.44, 0)
    rk.add_child(frame)
    var strings := MeshInstance3D.new()
    var qm := QuadMesh.new()
    qm.size = Vector2(0.235, 0.29)
    var sm := StandardMaterial3D.new()
    sm.albedo_texture = TexGen.string_texture()
    sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sm.cull_mode = BaseMaterial3D.CULL_DISABLED
    qm.material = sm
    strings.mesh = qm
    strings.position = Vector3(0, -0.44, 0)
    rk.add_child(strings)

static func _basis_along_y(dir: Vector3) -> Basis:
    # orienta el eje Y local a lo largo de dir (para cilindros inclinados)
    var up := dir.normalized()
    var side := up.cross(Vector3.FORWARD)
    if side.length() < 0.01:
        side = up.cross(Vector3.RIGHT)
    side = side.normalized()
    var fwd := side.cross(up).normalized()
    return Basis(side, up, fwd)

func _build_eyes() -> void:
    var ba := BoneAttachment3D.new()
    ba.bone_name = "Head"
    skel.add_child(ba)
    var anchor := Node3D.new()
    anchor.scale = Vector3.ONE * (0.01 / CHAR_SCALE)
    ba.add_child(anchor)
    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color("#241a12")
    eye_mat.roughness = 0.25
    for sx in [-1.0, 1.0]:
        var eye := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.038
        sm.height = 0.076
        sm.radial_segments = 12
        sm.rings = 8
        eye.mesh = sm
        eye.material_override = eye_mat
        eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        eye.scale = Vector3(1.0, 1.2, 0.45)
        eye.position = Vector3(0.125 * sx, 0.32, 0.41)
        anchor.add_child(eye)

func _play(name: String, spd: float = 1.0) -> void:
    if state == name: return
    state = name
    ap.play(name, blend, spd)

func _play_seek(name: String, tau: float) -> void:
    if state != name:
        state = name
        ap.play(name, 0.05)
    ap.seek(tau, true)

var celeb_t := 0.0
var celeb_name := ""

func celebrate(cname: String, dur: float) -> void:
    celeb_name = cname
    celeb_t = dur
    state = ""
    _play(celeb_name)

func update_from_sim(e, dt: float) -> void:
    position = Vector3(e.x, 0, e.z)
    rotation.y = 0.0 if e.near else PI
    var sp: float = clampf(e.speed / 6.0, 0.0, 1.0)
    var swing_dur: float = 0.4 if e.kind == "serve" else 0.34
    var k: float = 1.0 - e.swing / swing_dur if e.swing > 0.0 else -1.0

    # v0.21: cancel de follow-through - pasado el impacto + 0.15s, si el
    # jugador se mueve las piernas mandan sobre la pose de raqueta (crossfade)
    var elapsed: float = swing_dur - e.swing if e.swing > 0.0 else 99.0
    var hold_swing: bool = e.swing > 0.0 and (elapsed < 0.15 or e.speed <= 0.4)
    if hold_swing and e.kind == "serve":
        # saque: lanzamiento (enter) + golpeo (shoot)
        if k < 0.55:
            _play_seek("tennis/Spell_Simple_Enter", clampf(k / 0.55, 0.0, 1.0) * 0.45)
        else:
            _play_seek("tennis/Spell_Simple_Shoot", clampf((k - 0.55) / 0.45, 0.0, 1.0) * 0.45)
    elif hold_swing:
        match e.kind:
            "drop":
                _play_seek("tennis/Punch_Cross", clampf(k, 0.0, 1.0) * 0.9)
            "smash":
                _play_seek("tennis/Spell_Simple_Shoot", clampf(k, 0.0, 1.0) * 0.45)
            _:
                _play_seek("tennis/Sword_Attack", clampf(k, 0.0, 1.0) * 1.35)
    elif celeb_t > 0.0:
        celeb_t -= dt
        _play(celeb_name)
    elif e.want_t > 0.0:
        _play("tennis/Sword_Idle")
    elif e.speed > 6.5:
        _play("tennis/Sprint", clampf(e.speed / 8.0, 0.8, 1.4))
    elif e.speed > 0.4:
        _play("tennis/Jog_Fwd", clampf(e.speed / 5.0, 0.7, 1.8))
    else:
        _play("tennis/Idle")
