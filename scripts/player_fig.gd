class_name PlayerFig
extends Node3D





const MODELS: = [
	"res://models/Casual_2.glb", 
]



const SHORTS_MODEL: = "res://models/Casual_Hoodie.glb"
const LOOKS: = [
	{"shirt": "#2b7cd3", "shorts": "#1c2833", "skin": "#b07850", "hair": "#3a2a18"}, 
	{"shirt": "#f2f2f2", "shorts": "#3d5a80", "skin": "#a06b42", "hair": "#141414"}, 
	{"shirt": "#c93a32", "shorts": "#f2f2f2", "skin": "#b07850", "hair": "#1a1a1a"},
	{"shirt": "#f2a13c", "shorts": "#22303c", "skin": "#c98d62", "hair": "#7a4a1e"}, 
]
const P0: = {"shirt": "#c93a32", "shorts": "#f2f2f2", "skin": "#b07850", "hair": "#2a1d12"}
const CHAR_SCALE: = 1.083

var ap: AnimationPlayer
var skel: Skeleton3D
var inst: Node3D
var state: = ""
var blend: = 0.14

static func _mat(color: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m

static func _mat_kind(color: Color, kind: String) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
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
			m.rim = 0.16
			m.rim_tint = 0.3
		"shirt":
			m.roughness = 0.92
			m.rim_enabled = true
			m.rim = 0.22
			m.rim_tint = 0.5
		"pants":
			m.roughness = 0.85
			m.rim_enabled = true
			m.rim = 0.2
			m.rim_tint = 0.45
		"belt":
			m.roughness = 0.7
			m.albedo_color = color.darkened(0.45)
		"hair":
			m.roughness = 0.42
			m.metallic_specular = 0.75
	return m

static func _bone_name(skel: Skeleton3D, name: String) -> String:
	if skel == null or name == "":
		return name
	if skel.find_bone(name) >= 0:
		return name
	var alt: String = name.replace(".", "_")
	if alt.begins_with("Fist"):
		alt = "Wrist" + alt.trim_prefix("Fist")
	if name == "Body" and skel.find_bone("Body_2") >= 0:
		alt = "Body_2"
	if skel.find_bone(alt) >= 0:
		return alt
	return name

static func _remap_library(lib: AnimationLibrary, skel: Skeleton3D) -> AnimationLibrary:
	if lib == null or skel == null:
		return lib
	var out: = AnimationLibrary.new()
	for an in lib.get_animation_list():
		var res: Animation = lib.get_animation(an).duplicate()
		for ti in res.get_track_count():
			var tp: String = str(res.track_get_path(ti))
			if ":" not in tp:
				continue
			var base: String = tp.get_slice(":", 0)
			var bone: String = tp.get_slice(":", 1)
			var fixed: String = _bone_name(skel, bone)
			if fixed != bone:
				res.track_set_path(ti, NodePath(base + ":" + fixed))
		out.add_animation(an, res)
	return out

func _init(look: int, is_player0: bool) -> void :
	var pal: Dictionary = P0 if is_player0 else LOOKS[look % LOOKS.size()]
	inst = (load(MODELS[0]) as PackedScene).instantiate()
	inst.scale = Vector3.ONE * CHAR_SCALE
	add_child(inst)
	skel = inst.find_child("Skeleton3D", true, false)
	ap = inst.find_child("AnimationPlayer", true, false)


	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


	if ResourceLoader.exists("res://models/mocap_anims_mm.tres"):
		ap.add_animation_library("mocap", _remap_library(load("res://models/mocap_anims_mm.tres"), skel))
	# Las zancadas importadas son acciones de una sola vez. Repetir solo
	# locomocion y reposo; saques, golpes y reacciones deben acabar.
	var base_lib: AnimationLibrary = ap.get_animation_library("").duplicate(true)
	ap.remove_animation_library("")
	ap.add_animation_library("", base_lib)
	for nm in ["Idle", "Idle_Sword", "Idle_Neutral", "Run", "Run_Left", "Run_Right", "Run_Back", "Walk"]:
		if base_lib.has_animation(nm):
			base_lib.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
	_transplant_shorts()
	_apply_look(pal)
	_build_racket()
	_build_closed_hand(Color(pal.skin))
	_build_accessories()

var ankle_bones: Array = []

func _build_ankles(_skin_col: Color) -> void :

	for side in ["L", "R"]:
		var kb: int = skel.find_bone(_bone_name(skel, "LowerLeg." + side))
		var fb: int = skel.find_bone(_bone_name(skel, "Foot." + side))
		var sgn: = 1.0
		if kb >= 0 and fb >= 0:
			var rk: Transform3D = skel.get_bone_global_rest(kb)
			var rf: Transform3D = skel.get_bone_global_rest(fb)
			var rd: Vector3 = (rf.origin - rk.origin).normalized()
			sgn = 1.0 if rk.basis.y.normalized().dot(rd) >= 0.0 else -1.0
		ankle_bones.append([kb, fb, sgn])

func _fix_ankles() -> void :
	for ab in ankle_bones:
		var kb: int = ab[0]
		var fb: int = ab[1]
		if kb < 0 or fb < 0:
			continue
		var kp: Transform3D = skel.get_bone_global_pose(kb)
		var fp: Transform3D = skel.get_bone_global_pose(fb)
		var target: Vector3 = fp.origin + Vector3(0, 0.08, 0)
		var td: Vector3 = (target - kp.origin).normalized()
		var cd: Vector3 = kp.basis.y.normalized() * float(ab[2])
		if cd.dot(td) > 0.9995:
			continue
		var q: = Quaternion(cd, td)
		skel.set_bone_global_pose_override(kb, Transform3D(Basis(q) * kp.basis, kp.origin), 1.0, true)
	skel.force_update_all_bone_transforms()


func _apply_look(pal: Dictionary) -> void :
	var stack: = [inst]
	while stack.size() > 0:
		var n = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is MeshInstance3D and n.mesh:
			for i in n.mesh.get_surface_count():
				var m = n.mesh.surface_get_material(i)
				var nn: String = (m.resource_name if m else "")
				var nm: String = nn.to_lower()
				var col: = Color.WHITE
				var kind: = ""
				if "lightblue" in nm: col = Color(pal.shorts);kind = "pants"
				elif "lightbrown" in nm: col = Color(pal.shirt);kind = "shirt"
				elif "red_dark" in nm: col = shoe_dust_color(shoe_dust)

				elif "skin_darker" in nm: col = Color(pal.skin).darkened(0.25);kind = "skin"
				elif "eyebrows" in nm: col = Color(pal.hair);kind = "hair";n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				elif "eye" in nm or "white" in nm: continue
				elif "skin" in nm: col = Color(pal.skin);kind = "skin"
				elif "face" in nm: col = Color(pal.skin);kind = "face"
				elif "shirt" in nm: col = Color(pal.shirt);kind = "shirt"
				elif "pants" in nm: col = Color(pal.shorts);kind = "pants"
				elif "belt" in nm: col = Color(pal.shorts);kind = "belt"
				elif "hair" in nm: col = Color(pal.hair);kind = "hair";n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				else: continue
				var _mk: = _mat_kind(col, kind)
				n.set_surface_override_material(i, _mk)
				if "red_dark" in nm:
					shoe_mats.append(_mk)
				if kind == "shirt":
					shirt_mats.append({"m": _mk, "base": col})

func _transplant_shorts() -> void :


	if not ResourceLoader.exists(SHORTS_MODEL):
		return
	var donor: = (load(SHORTS_MODEL) as PackedScene).instantiate()
	var src: = donor.find_child("Casual_Legs", true, false) as MeshInstance3D
	var old: = skel.get_node_or_null("Casual2_Legs") as MeshInstance3D
	if src == null or old == null:
		donor.queue_free()
		return
	var legs: = MeshInstance3D.new()
	legs.name = "Shorts_Legs"
	legs.mesh = _shorts_tapered(src.mesh)
	legs.skin = src.skin
	legs.skeleton = NodePath("..")
	legs.cast_shadow = old.cast_shadow
	skel.add_child(legs)
	old.queue_free()
	donor.queue_free()

static func _shorts_tapered(mesh_src: Mesh) -> ArrayMesh:


	var dup: = ArrayMesh.new()
	var am: = mesh_src as ArrayMesh
	if am == null:
		return mesh_src
	for si in am.get_surface_count():
		var arrays: Array = am.surface_get_arrays(si).duplicate(true)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vi in verts.size():
			var v: = verts[vi]
			if v.y > 0.9:
				var k: = lerpf(1.0, 0.86, clampf((v.y - 0.9) / 0.15, 0.0, 1.0))
				verts[vi] = Vector3(v.x * k, v.y, 0.05 + (v.z - 0.05) * k)
		arrays[Mesh.ARRAY_VERTEX] = verts
		dup.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		dup.surface_set_material(si, am.surface_get_material(si))
	return dup

func _build_accessories() -> void :

	var white: = _mat(Color("#f4f4f6"))
	white.roughness = 0.95

	var ba_h: = BoneAttachment3D.new()
	ba_h.bone_name = "Head"
	skel.add_child(ba_h)
	var band: = MeshInstance3D.new()
	var tor: = TorusMesh.new()
	tor.inner_radius = 0.104
	tor.outer_radius = 0.126
	tor.ring_segments = 20
	tor.rings = 8
	band.mesh = tor
	band.material_override = white
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	band.scale = Vector3.ONE * (1.0 / CHAR_SCALE)
	band.position = Vector3(0, 0.15, 0)
	ba_h.add_child(band)

	for side in ["L"]:
		var ba: = BoneAttachment3D.new()
		ba.bone_name = _bone_name(skel, "Wrist." + side)
		skel.add_child(ba)
		var wb: = MeshInstance3D.new()
		var t2: = TorusMesh.new()
		t2.inner_radius = 0.032
		t2.outer_radius = 0.055
		t2.ring_segments = 14
		t2.rings = 6
		wb.mesh = t2
		wb.material_override = white
		wb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wb.scale = Vector3.ONE * (1.0 / CHAR_SCALE)

		wb.position = Vector3(0, 0.055, 0)
		ba.add_child(wb)

var shoe_mats: Array = []
var foot_bones: Array = []
var shoe_dust: = 0.0


static func shoe_dust_color(d: float) -> Color:
	return Color("#ececee").lerp(Color("#c9a25e"), clampf(d, 0.0, 1.0) * 0.75)



const TRAIL_LIFE: = 0.09
var racket_node: Node3D = null
var racket_hand_idx: int = -1
var racket_palm_idx: int = -1
# Agarre continental: el mango cruza la palma (perpendicular a los dedos),
# no la prolonga. La cara de la raqueta mantiene la orientacion de la mano.
# El mango sigue el eje real del puno cerrado, no -X de la mano: en el bind
# los dedos apuntan +Y y el interior de la palma mira (+0.67,0,-0.74), asi que
# el cilindro del puno queda en Y x n = (-0.74,0,-0.67). Alinear otra cosa
# dejaba el mango pasando junto a la muneca en vez de envuelto por los dedos.
const FIST_AXIS_HAND: = Vector3(-0.74, 0.0, -0.67)
var grip_basis: = _make_grip_basis()
static func _make_grip_basis() -> Basis:
	var gy: = FIST_AXIS_HAND.normalized()
	var gz: = (Vector3(0, 0, 1) - gy * gy.dot(Vector3(0, 0, 1))).normalized()
	var gx: = gy.cross(gz).normalized()
	return Basis(gx, gy, gz).orthonormalized()
# Centro del cilindro del puno en espacio de mano; lo mide _bake_fist().
var _fist_center_hand: = Vector3(0.010, 0.065, -0.011)
# Con el brazo colgando (espera/ready) la muneca orienta la raqueta vertical
# "bandera". carry_basis la bascula hacia delante para un porte natural;
# se funde a grip_basis en cuanto empieza la bola/elswing.
# Porte en espera (referencia de Jose 13:16): brazo relajado al costado y
# raqueta colgando con la cabeza ABAJO junto a la pierna. Se define en espacio
# de la FIGURA (no de la mano): con el brazo colgando la orientacion de la
# muneca varia y una base relativa a la mano puede quedar cabeza-arriba.
# y = direccion culata->cabeza (abajo y un pelo adelante), cara hacia el lado.
var carry_basis: = _make_carry_basis()
static func _make_carry_basis() -> Basis:
	var y: Vector3 = Vector3( - 0.10, - 1.0, - 0.15).normalized()
	var x: Vector3 = y.cross(Vector3(0.9, 0.0, 0.25)).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z).orthonormalized()
var carry_k: = 0.0
# Flexion procedural de los dedos de la mano de la raqueta alrededor del mango.
# Los clips mocap no animan dedos (bind pose abierta); se curvan por segmento.
const GRIP_CURL: = {"Index": [1.25, 0.95, 0.55], "Middle": [1.35, 1.0, 0.6], "Ring": [1.25, 0.95, 0.55], "Pinky": [1.05, 0.8, 0.45]}
const GRIP_THUMB: = [0.6, 0.45]
const GRIP_WRAP_SIGN: = 1.0
# Centro del puno respecto al nudillo corazon, en espacio del hueso de la mano
# (bind pose medida del modelo): interior de palma 2.8cm, 0.8cm hacia la muneca.
const GRIP_PALM_OFF: = Vector3(0.0188, - 0.008, - 0.0208)
var _grip_bones: = {}
var _thumb_bones: = []
var racket_force_hidden: = false
var swing_now: = 0.0
var trail_pts: Array = []
var trail_clock: = 0.0
var trail_mi: MeshInstance3D = null
var trail_im: ImmediateMesh = null

static func trail_alpha(speed: float) -> float:
	if speed > 45.0:
		return 0.0
	return clampf((speed - 6.0) / 14.0, 0.0, 1.0) * 0.32

static func trail_prune(pts: Array, now: float, life: float) -> Array:
	var out: Array = []
	for p in pts:
		if now - p.t <= life:
			out.append(p)
	return out

func _ensure_trail() -> void :
	if trail_mi != null:
		return
	trail_im = ImmediateMesh.new()
	trail_mi = MeshInstance3D.new()
	trail_mi.name = "RacketTrail"
	trail_mi.mesh = trail_im
	trail_mi.top_level = true
	trail_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tm: = StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.vertex_color_use_as_albedo = true
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.no_depth_test = false
	trail_mi.material_override = tm
	add_child(trail_mi)

var whoosh_pending: = 0.0
var whoosh_cd: = 0.0
var _wh_last: = Vector3.ZERO
var _wh_has: = false

static func whoosh_vol(spd: float) -> float:

	if spd < 14.0:
		return 0.0
	return clampf(0.35 + (spd - 14.0) / 26.0 * 0.65, 0.0, 1.0)

func _whoosh_step(dt: float) -> void :
	whoosh_cd = maxf(whoosh_cd - dt, 0.0)
	if swing_now <= 0.0 or racket_node == null:
		_wh_has = false
		return
	var pa: Vector3 = racket_node.to_global(Vector3(0, -0.86, 0))
	if _wh_has and dt > 0.0:
		var spd: float = (pa - _wh_last).length() / dt
		if spd < 45.0 and whoosh_cd <= 0.0 and whoosh_vol(spd) > 0.0:
			whoosh_pending = spd
			whoosh_cd = 0.5
	_wh_last = pa
	_wh_has = true

func _trail_step(dt: float) -> void :
	_whoosh_step(dt)
	if racket_node == null:
		return
	if racket_force_hidden:
		if trail_im != null:
			trail_im.clear_surfaces()
		if trail_mi != null:
			trail_mi.visible = false
		return
	trail_clock += dt
	if swing_now > 0.0:
		var pa: Vector3 = racket_node.to_global(Vector3(0, -0.8, 0))
		var pb: Vector3 = racket_node.to_global(Vector3(0, -0.62, 0))
		trail_pts.append({"a": pa, "b": pb, "t": trail_clock})
	trail_pts = trail_prune(trail_pts, trail_clock, TRAIL_LIFE)
	if trail_pts.size() < 2:
		if trail_im != null:
			trail_im.clear_surfaces()
		return
	_ensure_trail()
	trail_im.clear_surfaces()
	trail_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, trail_pts.size()):
		var p0: Dictionary = trail_pts[i - 1]
		var p1: Dictionary = trail_pts[i]
		var seg_dt: float = maxf(p1.t - p0.t, 0.0001)
		var spd: float = (p1.a - p0.a).length() / seg_dt
		var fade: float = 1.0 - (trail_clock - p1.t) / TRAIL_LIFE
		var al: float = trail_alpha(spd) * clampf(fade, 0.0, 1.0)
		var al0: float = al * 0.6
		var c0: = Color(1.0, 1.0, 1.0, al0)
		var c1: = Color(1.0, 1.0, 1.0, al)
		trail_im.surface_set_color(c0);trail_im.surface_add_vertex(p0.a)
		trail_im.surface_set_color(c0);trail_im.surface_add_vertex(p0.b)
		trail_im.surface_set_color(c1);trail_im.surface_add_vertex(p1.a)
		trail_im.surface_set_color(c0);trail_im.surface_add_vertex(p0.b)
		trail_im.surface_set_color(c1);trail_im.surface_add_vertex(p1.b)
		trail_im.surface_set_color(c1);trail_im.surface_add_vertex(p1.a)
	trail_im.surface_end()

var hop_age: = 99.0
var hop_h: = 0.0
var hop_landed: = false
const HOP_DUR: = 0.5

static func hop_y(age: float, h: float) -> float:
	if age < 0.0 or age >= HOP_DUR:
		return 0.0
	return h * sin(PI * age / HOP_DUR)

func hop(h: float) -> void :
	hop_age = 0.0
	hop_h = h
	hop_landed = false

var serve_toss: = -1.0
var look_on: = false
var look_target: = Vector3.ZERO
const GAZE_YAW: = 0.65
const GAZE_PITCH: = 0.3
const GAZE_W: = 0.7

static func gaze_angles(d: Vector3) -> Vector2:


	if d.length() < 0.05 or d.z < -0.5 * d.length():
		return Vector2.ZERO
	var yaw: float = clampf(atan2(d.x, d.z), - GAZE_YAW, GAZE_YAW)
	var hz: float = Vector2(d.x, d.z).length()
	var pitch: float = clampf(atan2( - d.y, maxf(hz, 0.001)), - GAZE_PITCH, GAZE_PITCH)
	return Vector2(yaw, pitch) * GAZE_W

func _apply_gaze() -> void :
	if not look_on or skel == null or celeb_t > 0.0:
		return
	var hi: = skel.find_bone("Head")
	if hi < 0:
		return
	var hp: Vector3 = skel.get_bone_global_pose(hi).origin
	var head_w: Vector3 = skel.to_global(hp)
	var d: Vector3 = to_local(look_target) - to_local(head_w)
	var a: Vector2 = gaze_angles(d)
	if a == Vector2.ZERO:
		return
	var g: = skel.get_bone_global_pose(hi)
	var rot: = Basis(Vector3.UP, a.x) * Basis(Vector3.RIGHT, a.y)
	skel.set_bone_global_pose_override(hi, Transform3D(rot * g.basis, g.origin), 1.0, true)

var punch_age: = 99.0
var punch_str: = 0.0
const PUNCH_DUR: = 0.16

static func punch_scale(age: float, st: float) -> Vector3:

	if age < 0.0 or age >= PUNCH_DUR or st <= 0.0:
		return Vector3.ONE
	var w: float = sin(PI * age / PUNCH_DUR) * clampf(st, 0.0, 1.0)
	return Vector3(1.0 - 0.018 * w, 1.0 + 0.045 * w, 1.0 - 0.018 * w)

func punch(spd: float) -> void :
	punch_age = 0.0
	punch_str = clampf(0.35 + spd / 45.0 * 0.65, 0.0, 1.0)

func _process(dt: float) -> void :
	if punch_age < PUNCH_DUR:
		punch_age += dt
		scale = punch_scale(punch_age, punch_str)
	elif scale != Vector3.ONE:
		scale = Vector3.ONE
	_trail_step(dt)

var shirt_mats: Array = []
var sweat: = 0.0


static func sweat_color(base: Color, s: float) -> Color:
	return base.darkened(clampf(s, 0.0, 1.0) * 0.28)

func set_sweat(s: float) -> void :
	sweat = clampf(s, 0.0, 1.0)
	for e in shirt_mats:
		e.m.albedo_color = sweat_color(e.base, sweat)

func set_leg_dust(d: float) -> void :
	shoe_dust = clampf(d, 0.0, 1.0)
	var c: Color = shoe_dust_color(shoe_dust)
	for m in shoe_mats:
		m.albedo_color = c

func _build_racket() -> void :
	racket_hand_idx = skel.find_bone(_bone_name(skel, "Hand.R"))
	if racket_hand_idx < 0:
		racket_hand_idx = skel.find_bone(_bone_name(skel, "Wrist.R"))
	# anclaje de posicion en la palma (base del dedo corazon): la muneca sola
	# dejaba el mango flotando fuera de la mano
	racket_palm_idx = skel.find_bone(_bone_name(skel, "Middle1.R"))
	var rk: = Node3D.new()
	rk.scale = Vector3.ONE
	rk.position = Vector3.ZERO
	rk.rotation = Vector3.ZERO
	var attachment: = BoneAttachment3D.new()
	attachment.bone_name = skel.get_bone_name(racket_hand_idx)
	skel.add_child(attachment)
	attachment.add_child(rk)
	rk.scale = Vector3.ONE / CHAR_SCALE
	racket_node = rk

	var dark: = _mat(Color("#191b20"))
	var light: = _mat(Color("#cfd2d8"))
	var red: = _mat(Color("#c93a32"))

	var handle: = MeshInstance3D.new()
	var hc: = CylinderMesh.new()
	hc.top_radius = 0.015
	hc.bottom_radius = 0.017
	hc.height = 0.24
	hc.radial_segments = 10
	hc.material = dark
	handle.mesh = hc
	handle.position = Vector3(0, 0.12, 0)
	rk.add_child(handle)

	var butt: = MeshInstance3D.new()
	var bc: = CylinderMesh.new()
	bc.top_radius = 0.021
	bc.bottom_radius = 0.022
	bc.height = 0.025
	bc.radial_segments = 10
	bc.material = dark
	butt.mesh = bc
	butt.position = Vector3(0, 0.005, 0)
	rk.add_child(butt)

	for sx in [-1.0, 1.0]:
		var a: = Vector3(0, 0.22, 0)
		var b: = Vector3(sx * 0.086, 0.455, 0)
		var seg: = b - a
		var arm: = MeshInstance3D.new()
		var ac: = CylinderMesh.new()
		ac.top_radius = 0.008
		ac.bottom_radius = 0.011
		ac.height = seg.length()
		ac.material = light
		arm.mesh = ac
		arm.position = (a + b) * 0.5
		arm.basis = _basis_along_y(seg.normalized())
		rk.add_child(arm)

	var head_rx: = 0.15
	var head_ry: = 0.177
	var head_cy: = 0.60
	var frame: = MeshInstance3D.new()
	var tm: = TorusMesh.new()
	tm.inner_radius = head_rx
	tm.outer_radius = 0.172
	tm.ring_segments = 8
	tm.rings = 36
	tm.material = red
	frame.mesh = tm
	frame.rotation.x = PI * 0.5
	frame.scale = Vector3(1.0, 1.0, head_ry / head_rx)
	frame.position = Vector3(0, head_cy, 0)
	rk.add_child(frame)

	var trim: = MeshInstance3D.new()
	var tt: = TorusMesh.new()
	tt.inner_radius = 0.143
	tt.outer_radius = 0.152
	tt.ring_segments = 6
	tt.rings = 36
	tt.material = light
	trim.mesh = tt
	trim.rotation.x = PI * 0.5
	trim.scale = Vector3(1.0, 1.0, head_ry / head_rx)
	trim.position = Vector3(0, head_cy, 0)
	rk.add_child(trim)

	var strings: = MeshInstance3D.new()
	strings.mesh = _ellipse_fan(head_rx - 0.012, head_ry - 0.012, 28)
	var sm: = StandardMaterial3D.new()
	sm.albedo_texture = TexGen.string_texture()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	strings.material_override = sm
	strings.position = Vector3(0, head_cy, 0)
	rk.add_child(strings)

	for m in rk.find_children("*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _basis_along_y(dir: Vector3) -> Basis:

	var up: = dir.normalized()
	var side: = up.cross(Vector3.FORWARD)
	if side.length() < 0.01:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var fwd: = side.cross(up).normalized()
	return Basis(side, up, fwd)

static func _ellipse_fan(rx: float, ry: float, segs: int) -> ArrayMesh:
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var a0: float = TAU * i / segs
		var a1: float = TAU * (i + 1) / segs
		var p0: = Vector3(cos(a0) * rx, sin(a0) * ry, 0.0)
		var p1: = Vector3(cos(a1) * rx, sin(a1) * ry, 0.0)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(0.5 + 0.5 * cos(a0), 0.5 - 0.5 * sin(a0)))
		st.add_vertex(p0)
		st.set_uv(Vector2(0.5 + 0.5 * cos(a1), 0.5 - 0.5 * sin(a1)))
		st.add_vertex(p1)
	st.generate_normals()
	return st.commit()

func _build_eyes() -> void :
	var ba: = BoneAttachment3D.new()
	ba.bone_name = "Head"
	skel.add_child(ba)
	var anchor: = Node3D.new()
	anchor.scale = Vector3.ONE * (0.01 / CHAR_SCALE)
	ba.add_child(anchor)
	var eye_mat: = StandardMaterial3D.new()
	eye_mat.albedo_color = Color("#241a12")
	eye_mat.roughness = 0.25
	for sx in [-1.0, 1.0]:
		var eye: = MeshInstance3D.new()
		var sm: = SphereMesh.new()
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

var last_spd: = 1.0
func _play(name: String, spd: float = 1.0) -> void :

	# Ajustar la cadencia aunque siga el mismo clip: antes se conservaba
	# la velocidad del primer paso al acelerar o frenar (pies deslizandose).
	ap.speed_scale = spd
	if state == name and signf(spd) == signf(last_spd):
		last_spd = spd
		return
	state = name
	last_spd = spd
	ap.play(name, blend)

func _play_seek(name: String, tau: float) -> void :
	ap.speed_scale = 1.0
	if state != name:
		state = name
		ap.play(name, 0.05)
	ap.seek(tau, true)


const LOB_ARM: = -1.1
const FOOT_LIFT: = 0.05
const RK_OPEN: = 0.9
const RK_REST_A: = 0.0
const RK_REST_Z: = 0.0
var rk_rest_k: = 0.0
const TOSS_ARM: = -2.0
const SERVE_ARM: = -0.8


# Los overrides globales no actualizan de forma fiable la pose consultada de
# los descendientes. Se aplica la misma delta a toda la rama, capturada antes
# de escribir, para que codo, muneca, piel y agarre compartan la misma cadena.
func _override_branch(bone: int, target: Transform3D, _amount: float = 1.0, _persistent: bool = true) -> void:
	var old: Transform3D = skel.get_bone_global_pose(bone)
	var delta: Transform3D = target * old.affine_inverse()
	var poses: Dictionary = {}
	for bi in skel.get_bone_count():
		var ancestor: int = bi
		while ancestor >= 0 and ancestor != bone:
			ancestor = skel.get_bone_parent(ancestor)
		if ancestor == bone:
			poses[bi] = delta * skel.get_bone_global_pose(bi)
	for bi in poses:
		skel.set_bone_global_pose_override(bi, poses[bi], 1.0, true)
	skel.force_update_all_bone_transforms()

func _raise_arm(ang: float, bone: String = "UpperArm.R") -> void :
	var bi: = skel.find_bone(_bone_name(skel, bone))
	if bi < 0:
		return
	var g: = skel.get_bone_global_pose(bi)
	_override_branch(bi, Transform3D(Basis(Vector3.RIGHT, ang) * g.basis, g.origin), 1.0, true)

func _bend_torso(k: float) -> void :
	for bn in ["Abdomen", "Torso"]:
		var bi: = skel.find_bone(bn)
		if bi >= 0:
			var q: = skel.get_bone_global_pose(bi).basis.get_rotation_quaternion()
			_override_branch(bi, Transform3D(Basis(q * Quaternion(Vector3.RIGHT, 0.45 * k)), skel.get_bone_global_pose(bi).origin), 1.0, true)

func _twist_torso(angle: float) -> void :
	for bn in ["Torso", "Abdomen"]:
		var bi: = skel.find_bone(bn)
		if bi >= 0:
			var g: = skel.get_bone_global_pose(bi)
			_override_branch(bi, Transform3D(Basis(Vector3.UP, angle) * g.basis, g.origin), 1.0, true)

func _serve_knees(k: float) -> void :
	if skel == null or k <= 0.01:
		return
	for side in [["UpperLeg.L", 1.0], ["UpperLeg.R", -1.0]]:
		var bi: = skel.find_bone(_bone_name(skel, side[0]))
		if bi < 0:
			continue
		var g: = skel.get_bone_global_pose(bi)
		var rot: = Basis(Vector3.RIGHT, -0.26 * k) * Basis(Vector3.BACK, 0.06 * k * float(side[1]))
		_override_branch(bi, Transform3D(rot * g.basis, g.origin))
	skel.force_update_all_bone_transforms()
	for bn in ["LowerLeg.L", "LowerLeg.R"]:
		var li: = skel.find_bone(_bone_name(skel, bn))
		if li < 0:
			continue
		var lg: = skel.get_bone_global_pose(li)
		_override_branch(li, Transform3D(Basis(Vector3.RIGHT, 0.55 * k) * lg.basis, lg.origin))
	skel.force_update_all_bone_transforms()
	for fn in ["Foot.L", "Foot.R"]:
		var fi: = skel.find_bone(_bone_name(skel, fn))
		if fi < 0:
			continue
		var fg: = skel.get_bone_global_pose(fi)
		_override_branch(fi, Transform3D(Basis(Vector3.RIGHT, -0.22 * k) * fg.basis, fg.origin))

func _ready_stance() -> void :
	if skel == null:
		return
	for side in [["UpperLeg.L", 1.0], ["UpperLeg.R", -1.0]]:
		var bi: = skel.find_bone(_bone_name(skel, side[0]))
		if bi < 0:
			continue
		var g: = skel.get_bone_global_pose(bi)
		var rot: = Basis(Vector3.RIGHT, -0.18) * Basis(Vector3.BACK, 0.08 * float(side[1]))
		_override_branch(bi, Transform3D(rot * g.basis, g.origin))
	skel.force_update_all_bone_transforms()
	for bn in ["LowerLeg.L", "LowerLeg.R"]:
		var li: = skel.find_bone(_bone_name(skel, bn))
		if li < 0:
			continue
		var lg: = skel.get_bone_global_pose(li)
		_override_branch(li, Transform3D(Basis(Vector3.RIGHT, 0.40) * lg.basis, lg.origin))
	skel.force_update_all_bone_transforms()
	for fn in ["Foot.L", "Foot.R"]:
		var fi: = skel.find_bone(_bone_name(skel, fn))
		if fi < 0:
			continue
		var fg: = skel.get_bone_global_pose(fi)
		_override_branch(fi, Transform3D(Basis(Vector3.RIGHT, -0.14) * fg.basis, fg.origin))
	_bend_torso(0.28)
	_raise_arm(-0.25, "UpperArm.R")
	_raise_arm(-0.30, "UpperArm.L")
	# brazo y raqueta relajados como en la espera de saque (referencia: cabeza
	# de la raqueta baja junto a la pierna, mango cruzando la palma)
	_serve_wait_arm(carry_k)

var celeb_t: = 0.0
var celeb_name: = ""
var rk_show_delay: = 0
var serve_ready: = false
var serve_ball_held: bool = false
var serve_ball_blend: float = 0.0
var serve_ball_source: Vector3 = Vector3.ZERO
var _held_ball_mesh: MeshInstance3D
var serve_release_offset: Vector3 = Vector3.ZERO
var serve_follow_t: = 0.0
var _serve_was_swing: = false
var _idle_t: = 0.0
const CELEB_ANIMS: = ["Wave", "Punch_Right", "Punch_Left", "Sword_Slash", "HitRecieve", "HitRecieve_2"]
var had_windup: = false

var eff_sp: = 0.0
var _last_px: = 0.0
var _last_pz: = 0.0
var _last_init: = false
var repositioning: bool = false
var _reposition_age: float = 0.0
var _reposition_duration: float = 0.42
var _reposition_from: Vector3
var _reposition_velocity: Vector3
const REPOSITION_TIME: float = 0.42



const WINDUP: = 0.3
const CONTACT_K: = 0.47

# Mapeo del saque medido sobre el clip mocap/Servicio fotograma a fotograma
# (toma jduribe del dataset Tennis-MoCap, ver CREDITS.md):
# trophy (raqueta detras de la cabeza) tau~1.61, contacto en extension
# plena tau~1.72, fin del follow-through tau~2.2.
const SERVE_TAU_READY: = 1.35
const SERVE_TAU_CONTACT: = 1.72
const SERVE_TAU_END: = 2.2


static func _serve_tau(kk: float) -> float:
	if kk <= CONTACT_K:
		return lerpf(SERVE_TAU_READY, SERVE_TAU_CONTACT, pow(kk / CONTACT_K, 1.4))
	var y: float = (kk - CONTACT_K) / (1.0 - CONTACT_K)
	return lerpf(SERVE_TAU_CONTACT, SERVE_TAU_END, 1.0 - pow(1.0 - y, 2.0))



static func _swing_clip(kind: String, hit_side: String) -> Array:


	match kind:
		"drop": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.38]

		"volley": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.45]




		"smash": return ["mocap/Servicio", 1.30, 1.70]
		"slice": return ["Sword_Slash", 0.92, 1.12]
		_: return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.95]


static func _ease_in_cubic(x: float) -> float:
	return x * x * x

static func _ease_out_cubic(x: float) -> float:
	var u: = 1.0 - clampf(x, 0.0, 1.0)
	return 1.0 - u * u * u

func celebrate(cname: String, dur: float) -> void :
	celeb_name = cname
	celeb_t = dur
	state = ""
	_play(celeb_name)

var _pose_air: float = 0.0
var _feet_follow_legs: bool = false

func update_from_sim(e, dt: float) -> void:
	_pose_air = 0.0
	_feet_follow_legs = false
	_update_pose(e, dt)
	_show_serve_ball()
	_sync_mocap_feet()
	if e.get("dive_t") == null or (e.dive_t <= 0.0 and e.getup_t <= 0.0):
		_ground_final_pose(eff_sp < 0.4 or state.begins_with("mocap/"))

func _show_serve_ball() -> void:
	if serve_ready and not serve_ball_held:
		serve_release_offset = Vector3.ZERO
	if _held_ball_mesh == null and serve_ball_held:
		var attach: = BoneAttachment3D.new()
		attach.bone_name = _bone_name(skel, "Wrist.L")
		skel.add_child(attach)
		_held_ball_mesh = MeshInstance3D.new()
		var sphere: = SphereMesh.new()
		sphere.radius = 0.055 / CHAR_SCALE
		sphere.height = 0.11 / CHAR_SCALE
		_held_ball_mesh.mesh = sphere
		var material: = StandardMaterial3D.new()
		material.albedo_color = Color("#e6ff4d")
		material.roughness = 0.9
		_held_ball_mesh.material_override = material
		_held_ball_mesh.position = Vector3(0.0, 0.075, 0.025)
		attach.add_child(_held_ball_mesh)
	if _held_ball_mesh != null:
		_held_ball_mesh.visible = serve_ball_held
		if serve_ball_held:
			serve_release_offset = _held_ball_mesh.global_position - serve_ball_source
			var attach: Node3D = _held_ball_mesh.get_parent()
			var palm: Vector3 = Vector3(0.0, 0.075, 0.025)
			_held_ball_mesh.position = attach.to_local(serve_ball_source).lerp(palm, serve_ball_blend)

func _bone_pose_now(bi: int) -> Transform3D:
	var pose: Transform3D = skel.get_bone_pose(bi)
	var parent: int = skel.get_bone_parent(bi)
	while parent >= 0:
		pose = skel.get_bone_pose(parent) * pose
		parent = skel.get_bone_parent(parent)
	return pose

# Este modelo lleva los pies como hijos de Root, no de las espinillas.
# El mocap anima las piernas pero no aporta posiciones para esos pies.
# Recuperar el enlace del bind evita dejar los zapatos clavados mientras
# la rodilla y el tobillo se mueven.
func _sync_mocap_feet() -> void:
	if not state.begins_with("mocap/") and not _feet_follow_legs:
		return
	for side in ["L", "R"]:
		var leg: int = skel.find_bone(_bone_name(skel, "LowerLeg." + side))
		var foot: int = skel.find_bone(_bone_name(skel, "Foot." + side))
		if leg < 0 or foot < 0:
			continue
		var link: Transform3D = skel.get_bone_global_rest(leg).affine_inverse() * skel.get_bone_global_rest(foot)
		var leg_pose: Transform3D = skel.get_bone_global_pose_override(leg)
		if leg_pose == Transform3D.IDENTITY:
			leg_pose = _bone_pose_now(leg)
		var ankle: Transform3D = leg_pose * link
		var planted: Basis = skel.get_bone_global_rest(foot).basis
		ankle.basis = planted.slerp(ankle.basis.orthonormalized(), 0.35 if _pose_air > 0.01 else 0.0)
		skel.set_bone_global_pose_override(foot, ankle, 1.0, true)

# Medir tras los ajustes. skel.global_transform ya contiene la figura.
func _ground_final_pose(allow_lower: bool) -> void:
	if skel == null:
		return
	skel.force_update_all_bone_transforms()
	var low: float = INF
	for bn in ["Foot.L", "Foot.R"]:
		var bi: int = skel.find_bone(_bone_name(skel, bn))
		if bi >= 0:
			var foot_pose: Transform3D = _bone_pose_now(bi)
			var override: Transform3D = skel.get_bone_global_pose_override(bi)
			if override != Transform3D.IDENTITY:
				foot_pose = override
			low = minf(low, (skel.global_transform * foot_pose.origin).y)
	if is_finite(low):
		var correction: float = 0.086 + _pose_air - low
		# No bajar al corredor cuando ambos pies estan en vuelo.
		if not allow_lower:
			correction = maxf(0.0, correction)
		position.y += clampf(correction, -0.45, 0.45)

func _update_pose(e, dt: float) -> void:
	ap.advance(dt)
	celeb_t = maxf(0.0, celeb_t - dt)
	serve_follow_t = maxf(0.0, serve_follow_t - dt)
	swing_now = e.swing
	if serve_toss >= 0.0:
		_serve_was_swing = false
	elif e.kind == "serve" and e.swing > 0.0:
		_serve_was_swing = true
	elif _serve_was_swing and e.kind == "serve" and e.swing <= 0.0:
		_serve_was_swing = false
		serve_follow_t = 0.30
	var _fatk: float = e.get("fat") if e.get("fat") != null else 0.0



	skel.clear_bones_global_pose_override()
	skel.force_update_all_bone_transforms()
	if e.swing <= 0.0 and e.want_t <= 0.0:
		had_windup = false


	if not _last_init:
		_last_init = true
		_last_px = e.x
		_last_pz = e.z
	var mvd: float = Vector2(e.x - _last_px, e.z - _last_pz).length()
	_last_px = e.x
	_last_pz = e.z

	var target_sp: float = minf(e.speed, mvd / maxf(dt, 0.0001) * 1.15 + 0.35)
	var target_pos: = Vector3(e.x, FOOT_LIFT, e.z)
	# Un salto de la simulacion al nuevo lado de saque no es movimiento de
	# juego. Completar todo el trayecto visual, sin el salto final de 2,2 m.
	if mvd > 0.75 and e.swing <= 0.0:
		repositioning = true
		_reposition_age = 0.0
		_reposition_from = position
		_reposition_duration = clampf(mvd / 7.0, REPOSITION_TIME, 1.2)
	# Nunca retrasar un golpe ni mantener su figura lejos del contacto.
	if e.swing > 0.0 or serve_toss >= 0.0:
		repositioning = false
	var previous_position: Vector3 = position
	if repositioning:
		_reposition_age = minf(_reposition_duration, _reposition_age + dt)
		var k: float = smoothstep(0.0, _reposition_duration, _reposition_age)
		position = _reposition_from.lerp(target_pos, k)
		_reposition_velocity = (position - previous_position) / maxf(dt, 0.0001)
		_reposition_velocity.y = 0.0
		target_sp = _reposition_velocity.length()
		if _reposition_age >= _reposition_duration:
			repositioning = false
	else:
		position = target_pos
		_reposition_velocity = Vector3.ZERO
	eff_sp = lerpf(eff_sp, target_sp, minf(1.0, dt * 14.0))


	var target_y: = FOOT_LIFT
	if e.wait_serve and e.swing <= 0.0 and e.want_t <= 0.0 and e.speed < 0.5:
		target_y = FOOT_LIFT + sin(_idle_t * 2.3) * 0.006
	position.y = lerpf(position.y, target_y, minf(1.0, dt * 14.0))

	if e.get("split_t") != null and e.split_t > 0.0 and e.swing <= 0.0 and e.get("dive_t") <= 0.0 and (e.get("getup_t") == null or e.getup_t <= 0.0):
		var sph: float = 1.0 - e.split_t / 0.32
		_pose_air = sin(sph * PI) * 0.09
		position.y = FOOT_LIFT + _pose_air

	if hop_age < HOP_DUR:
		hop_age += dt
		_pose_air = hop_y(hop_age, hop_h)
		position.y += _pose_air
		if hop_age >= HOP_DUR:
			hop_landed = true





	var facing: = 0.0 if e.near else PI


	if eff_sp > 5.6 and absf(e.vx) > absf(e.vz):
		facing = atan2(e.vx, e.vz)

	# Visual recovery only: simulation swing and hit windows stay unchanged.
	var _visual_elapsed: float = (0.4 if e.kind == "serve" else 0.34) - e.swing
	var _moving_recovery: bool = e.kind != "serve" and _visual_elapsed >= 0.1 and eff_sp > 0.4
	var _sw: bool = e.swing > 0.0 and not _moving_recovery
	var _serve_pose: bool = serve_ready or serve_toss >= 0.0 or (e.kind == "serve" and e.swing > 0.0)
	var face_target: float = facing
	if celeb_t > 0.0 or state in CELEB_ANIMS:
		face_target = 0.0
	if _serve_pose:
		face_target = facing + (0.65 if e.near else -0.65)
	if not _sw:
		rotation.y = lerp_angle(rotation.y, face_target, minf(1.0, dt * 9.0))

	var lean: = 0.0
	if e.speed > 3.5 and absf(e.vx) > absf(e.vz):
		lean = clampf( - e.vx, -7.0, 7.0) * 0.014

	if e.get("stumble_t") != null and e.stumble_t > 0.0 and e.get("stumble_dir") != null and e.stumble_dir != 0.0:
		lean = - e.stumble_dir * 0.28 * (e.stumble_t / 0.4)


	if _sw and e.get("plant_t") != null and e.plant_t > 0.0 and e.get("plant_dir") != null and e.plant_dir != 0.0:
		lean += e.plant_dir * 0.22 * clampf(e.plant_t / 0.35, 0.0, 1.0)
		lean = clampf(lean, -0.45, 0.45)


	if e.get("recov_lean") != null and e.recov_lean != 0.0 and e.get("recov") != null and e.recov > 0.0 and e.swing <= 0.0 and (e.get("dive_t") == null or e.dive_t <= 0.0):
		lean += e.recov_lean * clampf(e.recov / 0.5, 0.0, 1.0)
		lean = clampf(lean, -0.45, 0.45)



	var pitch: = 0.0
	if e.get("burst") != null and e.burst > 0.0 and e.swing <= 0.0:
		var bk: float = clampf(e.burst / 0.16, 0.0, 1.0)
		var dirz: float = signf(e.vz) if absf(e.vz) > 0.5 else 0.0
		pitch = dirz * 0.14 * bk * (-1.0 if e.near else 1.0)
		if absf(e.vx) > 0.5:
			lean += signf(e.vx) * 0.08 * bk


	if e.get("fatigue") != null and e.fatigue > 0.0 and e.speed < 0.5 and e.swing <= 0.0:
		pitch += 0.16 * clampf(e.fatigue, 0.0, 1.0)
	if eff_sp > 1.2 and e.swing <= 0.0 and (e.get("dive_t") == null or e.dive_t <= 0.0):
		var fwd: float = e.vz * (1.0 if e.near else -1.0)
		pitch += (0.055 if fwd > 0.0 else -0.02) * clampf(eff_sp / 6.5, 0.0, 1.0)
	rotation.x = lerpf(rotation.x, pitch, minf(1.0, dt * 10.0))
	rotation.z = lerpf(rotation.z, lean, minf(1.0, dt * 8.0))
	var sp: float = clampf(e.speed / 6.0, 0.0, 1.0)
	var swing_dur: float = 0.4 if e.kind == "serve" else 0.34
	var k: float = 1.0 - e.swing / swing_dur if e.swing > 0.0 else -1.0



	var elapsed: float = swing_dur - e.swing if e.swing > 0.0 else 99.0
	var hold_swing: bool = e.swing > 0.0 and (not _moving_recovery if e.kind != "serve" else (elapsed < 0.15 or e.speed <= 0.4))

	if e.get("dive_t") != null and e.dive_t > 0.0:
		var dp: float = clampf(1.0 - e.dive_t / 0.55, 0.0, 1.0)
		_play("Idle_Sword", 1.0)
		position.y -= 0.10 + 0.08 * (1.0 - dp)
		_bend_torso(0.32)
		_raise_arm(-0.30, "UpperArm.R")
		_raise_arm(-0.16, "UpperArm.L")
		return




	var contact_can_step: bool = e.get("contact_recovery") == true and e.getup_t <= 0.4 and eff_sp > 0.4
	if e.get("getup_t") != null and e.getup_t > 0.0 and e.swing <= 0.0 and not contact_can_step:
		if e.getup_t > 0.4:
			_play("Idle_Sword", 1.0)
			position.y -= 0.10
		else:
			if state != "getup":
				state = "getup"
				ap.play("Idle_Sword", 0.34)
			ap.seek(0.0, true)
		return
	if repositioning and e.swing <= 0.0:
		var v: Vector3 = _reposition_velocity
		var clip: String = "Run" if eff_sp > 2.8 else "Walk"
		if absf(v.x) > absf(v.z) * 1.15:
			clip = "Run_Left" if (v.x > 0.0) == e.near else "Run_Right"
		elif (v.z < 0.0) == e.near:
			clip = "Run_Back"
		_play(clip, clampf(eff_sp / 4.4, 0.7, 1.5))
		_place_racket(dt)
		return
	if serve_ready and e.swing <= 0.0:
		_play_seek("mocap/Servicio", 0.12)
		# Espera apoyada, con respiracion leve: el bote de pies anterior hacia
		# saltar al sacador en cada ciclo. El brazo queda bajo junto a la pierna.
		_idle_t += dt
		var bob: float = sin(_idle_t * 2.3)
		_bend_torso(0.025 + 0.01 * sin(_idle_t * 1.3))
		_serve_knees(0.08 + 0.025 * (0.5 + 0.5 * bob))
		_serve_wait_arm(1.0)
		position.y += 0.006 * bob
		_place_racket(dt)
		return

	if serve_toss >= 0.0 and e.swing <= 0.0:

		var toss_k: float = clampf(serve_toss, 0.0, 1.0)
		_play_seek("mocap/Servicio", lerpf(0.12, SERVE_TAU_READY, toss_k))
		_raise_arm(TOSS_ARM * 0.4 * _ease_out_cubic(clampf(serve_toss / 0.35, 0.0, 1.0)), "UpperArm.L")
		_serve_knees(0.24 * sin(toss_k * PI))
		_twist_torso(-0.26 * sin(toss_k * PI))
		_place_racket(dt)
		return
	if hold_swing and e.kind == "serve":

		var s_tau: float = _serve_tau(clampf(k, 0.0, 1.0))
		_play_seek("mocap/Servicio", s_tau)
		# El clip incluye una reverencia profunda (tau 1.15-1.6) que lee como
		# gesto roto; se contrarresta en parte para que pase por coil atletico.
		_bend_torso( - 0.75 * sin(PI * clampf((s_tau - 1.1) / 0.55, 0.0, 1.0)))

		# Overrides suavizados: el mocap ya baja el brazo de la bola y sube el
		# de la raqueta; las formulas a tope congelaban los brazos (efecto robot).
		_raise_arm(TOSS_ARM * 0.35 * (1.0 - _ease_in_cubic(clampf((k - 0.2) / 0.5, 0.0, 1.0))), "UpperArm.L")
		_raise_arm(SERVE_ARM * 0.35 * clampf(1.0 - absf(k - 0.55) / 0.3, 0.0, 1.0))
		var _sk: float = clampf(k, 0.0, 1.0)
		_pose_air = 0.12 * sin(_sk * PI)
		_twist_torso(0.32 * sin(_sk * PI))
	elif serve_follow_t > 0.0 and e.swing <= 0.0:
		var recovery: float = 1.0 - serve_follow_t / 0.30
		_play_seek("mocap/Servicio", lerpf(SERVE_TAU_END, 2.30, recovery))
		_place_racket(dt)
		return
	elif hold_swing:
		var hs: String = e.hit_side if "hit_side" in e else "fore"
		var sc: = _swing_clip(e.kind, hs)
		var kk: = clampf(k, 0.0, 1.0)
		var tau: float



		# Dinamica del golpe: preparacion pausada, aceleracion hasta el contacto
		# (k = CONTACT_K) y follow-through que sale rapido y termina suave.
		# tau(CONTACT_K) coincide con el mapeo anterior para no desplazar el contacto.
		if sc[0] == "mocap/Servicio":
			# Smash: mismo clip que el saque, mismo contacto medido y mismo arreglo
			# de la reverencia.
			tau = _serve_tau(kk)
		else:
			var span: float = sc[2] - sc[1]
			var e0: float = _ease_out_cubic(CONTACT_K)
			if kk <= CONTACT_K:
				var x: float = kk / CONTACT_K
				tau = sc[1] + span * e0 * pow(x, 1.6)
			else:
				var y: float = (kk - CONTACT_K) / (1.0 - CONTACT_K)
				tau = sc[1] + span * (e0 + (1.0 - e0) * (1.0 - pow(1.0 - y, 2.2)))
		_play_seek(sc[0], tau)
		if sc[0] == "mocap/Servicio":
			_bend_torso( - 0.75 * sin(PI * clampf((tau - 1.1) / 0.55, 0.0, 1.0)))



		var by: float = e.get("ball_y") if e.get("ball_y") != null else 1.0
		var low_k: float = clampf((0.95 - by) / 0.55, 0.0, 1.0)
		if low_k > 0.0:
			var env: float = clampf(1.0 - absf(kk - 0.47) / 0.53, 0.0, 1.0)
			_bend_torso(low_k * env)
		if e.kind == "lob" or e.kind == "toplob" or e.kind == "drop":


			var env2: float = clampf(1.0 - absf(kk - 0.5) / 0.5, 0.0, 1.0)
			if e.kind == "drop":
				_bend_torso(0.3 * env2)
			else:
				_bend_torso(-0.32 * env2 * (1.0 if e.kind == "lob" else 0.8))
				if kk > 0.5:
					_raise_arm(LOB_ARM * clampf((kk - 0.5) / 0.35, 0.0, 1.0) * (1.0 if e.kind == "lob" else 0.7))
				if kk > 0.45:
					position.y += 0.07 * clampf((kk - 0.45) / 0.3, 0.0, 1.0) * clampf((1.0 - kk) / 0.3, 0.0, 1.0)
	elif (e.want_t > 0.0 or e.prep_t > 0.0) and e.swing <= 0.0 and e.speed <= 2.2:





		var wk: float = clampf(1.0 - e.want_t / WINDUP, 0.0, 1.0) if e.want_t > 0.0 else clampf(1.0 - e.prep_t / 0.25, 0.0, 1.0) * 0.7
		var pkv = e.get("prep_k")
		if pkv != null:
			wk = maxf(wk, float(pkv) * 0.85)
		if e.want_t <= 0.0:
			var chg = e.get("charging")
			if chg != null and chg:
				wk = maxf(wk, 0.5 + 0.4 * float(e.get("charge")))
		var hsw: String = e.hit_side if "hit_side" in e else "fore"
		var scw: = _swing_clip(e.want, hsw)
		# El windup llega hasta el inicio de la ventana del golpe (scw[1]):
		# antes se quedaba en 0.48*scw[1] y el golpe empezaba con un salto
		# de ~medio segundo de clip (chasis visible).
		_play_seek(scw[0], (0.18 + wk * 0.82) * scw[1])
		had_windup = true


		var its: float = e.get("intent_side") if e.get("intent_side") != null else 0.0
		if its != 0.0:
			rotation.y += its * 0.22 * wk * (1.0 if e.near else -1.0)
	elif celeb_t > 0.0:
		_play(celeb_name)
	elif e.want_t > 0.0 and e.speed <= 2.2:
		_play("Idle_Sword")
	elif eff_sp > 0.9 and eff_sp <= 5.5 and absf(e.vx) > absf(e.vz) * 1.15:

		_play("Run_Left" if e.vx > 0.0 else "Run_Right", clampf(eff_sp / 3.4, 0.65, 1.6))
	elif eff_sp > 1.6 and ((e.vz < 0.0) if e.near else (e.vz > 0.0)) and absf(e.vz) > absf(e.vx) * 0.7:

		_play("Run_Back", clampf(eff_sp / 5.0, 0.7, 1.4))
	elif eff_sp > 6.5:
		_play("Run", clampf(eff_sp / 4.4, 1.0, 1.6) * (1.0 - 0.18 * _fatk))
	elif eff_sp > 2.8:
		_play("Run", clampf(eff_sp / 4.6, 0.6, 1.35) * (1.0 - 0.18 * _fatk))
	elif eff_sp > 1.6 and absf(e.vx) > absf(e.vz) * 1.2:


		_play("Run_Left" if e.vx > 0.0 else "Run_Right", clampf(eff_sp / 3.4, 0.7, 1.4))
	elif eff_sp > 0.4:

		_play("Walk", clampf(eff_sp / 2.2, 0.8, 1.6))
	else:
		_play("Idle_Sword")

	if _fatk > 0.55:
		_bend_torso(0.5 * clampf((_fatk - 0.55) / 0.45, 0.0, 1.0))
	var _stance_on: bool = state == "Idle_Sword" and eff_sp < 0.5 and e.swing <= 0.0 and celeb_t <= 0.0 and (e.get("split_t") == null or e.split_t <= 0.0) and (e.get("dive_t") == null or e.dive_t <= 0.0)
	if _stance_on:
		_feet_follow_legs = true
		_ready_stance()
		position.y -= 0.045
	# Espera de saque: brazo de raqueta relajado al costado (referencia Jose),
	# fundido con carry_k para que suba con el inicio del saque sin salto.
	if e.wait_serve and e.swing <= 0.0 and carry_k > 0.01:
		_serve_wait_arm(carry_k)
	_apply_gaze()
	_rk_rest(dt)
	if state in CELEB_ANIMS:
		_celebration_grip()
	# La raqueta se coloca AL FINAL, leyendo la pose definitiva de la mano tras
	# todas las poses procedurales: la culata no se despega del puno.
	_place_racket(dt)
	if racket_node != null and racket_node.visible:
		# _pose_grip_fingers(): sustituido por _bake_fist() (puno horneado en la malla)
		pass

func _celebration_legs() -> void :
	if skel == null:
		return
	for side in [["UpperLeg.L", 1.0], ["UpperLeg.R", -1.0]]:
		var bi: = skel.find_bone(_bone_name(skel, side[0]))
		if bi < 0:
			continue
		var g: = skel.get_bone_global_pose(bi)
		var rot: = Basis(Vector3.BACK, 0.22 * float(side[1]))
		_override_branch(bi, Transform3D(rot * g.basis, g.origin))

func _celebration_grip() -> void :
	if racket_node == null:
		return
	_raise_arm(-1.05, "UpperArm.R")


# Mano y raqueta comparten el BoneAttachment3D de la muneca.
func _place_racket(dt: float) -> void :
	if racket_node == null or racket_hand_idx < 0:
		return
	skel.force_update_all_bone_transforms()
	# BoneAttachment3D usa la transformacion final que tambien deforma la piel;
	# leer get_bone_global_pose en mitad del frame daba una muneca desfasada.
	var carry_target: float = 1.0 if (swing_now <= 0.0 and serve_toss < 0.0) else 0.0
	carry_k = move_toward(carry_k, carry_target, dt * 5.0)
	racket_node.basis = grip_basis.scaled(Vector3.ONE / CHAR_SCALE)
	racket_node.position = _fist_center_hand - grip_basis.y * 0.03 / CHAR_SCALE
	var a: Vector3 = Vector3(0, -0.025, 0)
	var b: Vector3 = _fist_center_hand + grip_basis * Vector3(-0.035, 0, 0.016) / CHAR_SCALE
	_wrist_bridge.position = (a + b) * 0.5
	_wrist_bridge.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	_wrist_bridge.scale = Vector3(1, a.distance_to(b), 1)
	_wrist_band.position = a.lerp(b, 0.34)
	_wrist_band.quaternion = _wrist_bridge.quaternion
	if state in CELEB_ANIMS:
		rk_show_delay = 0
	elif rk_show_delay > 0:
		rk_show_delay -= 1
	racket_node.visible = not racket_force_hidden and rk_show_delay <= 0
	if _wrist_bridge != null:
		_wrist_bridge.visible = racket_node.visible
		_wrist_band.visible = racket_node.visible


# Brazo de la raqueta relajado al costado durante la espera de saque
# (referencia visual de Jose: brazo abajo, raqueta baja junto a la pierna).
# Alinea un hueso (en espacio mundo) hacia una direccion objetivo dada en
# espacio local de la figura, fundida por k. Robusta ante la pose que traiga el
# clip: no depende de la orientacion previa del brazo.
func _align_bone_dir(bone: String, child: String, target_local: Vector3, k: float) -> void :
	var bi: int = skel.find_bone(_bone_name(skel, bone))
	var ci: int = skel.find_bone(_bone_name(skel, child))
	if bi < 0 or ci < 0:
		return
	var gp: Transform3D = skel.get_bone_global_pose(bi)
	var cp: Transform3D = skel.get_bone_global_pose(ci)
	var b0: Vector3 = skel.global_transform * gp.origin
	var c0: Vector3 = skel.global_transform * cp.origin
	var cd: Vector3 = (c0 - b0).normalized()
	var td: Vector3 = (global_transform.basis * target_local).normalized()
	if cd.dot(td) > 0.9995 or k <= 0.001:
		return
	var q: Quaternion = Quaternion.IDENTITY.slerp(Quaternion(cd, td), k)
	var wb: Basis = Basis(q) * (skel.global_transform.basis * gp.basis)
	_override_branch(bi, Transform3D((skel.global_transform.basis.inverse() * wb).orthonormalized(), gp.origin), 1.0, true)
	skel.force_update_all_bone_transforms()


func _serve_wait_arm(k: float) -> void :
	_align_bone_dir("UpperArm.R", "LowerArm.R", Vector3(0.14, -1.0, -0.08), k)
	_align_bone_dir("LowerArm.R", "Wrist.R", Vector3(0.10, -1.0, -0.22), k)
	# la izquierda tambien cuelga relajada (referencia), y despeja la vista del puno
	_align_bone_dir("UpperArm.L", "LowerArm.L", Vector3( - 0.16, -1.0, -0.06), k)
	var ball_arm: Vector3 = Vector3(-0.12, -1.0, -0.12).lerp(Vector3(-0.12, -0.22, 0.9), serve_ball_blend if serve_ball_held else 0.0)
	_align_bone_dir("LowerArm.L", "Wrist.L", ball_arm, k)
	# muneca orientada para que el mango cruce la palma (agarre martillo) y la
	# cabeza cuelgue baja junto a la pierna, con cualquier pose que traiga el clip
	_align_hand_axis(global_transform.basis * Vector3( - 0.10, - 1.0, - 0.15), k)


# Gira la mano de la raqueta para que el eje del mango (grip_basis.y en espacio
# del hueso de la mano) apunte a una direccion mundo dada. Asi el mango queda
# perpendicular a los dedos (cruza la palma) y los dedos pueden envolverlo.
func _align_hand_axis(target_world: Vector3, k: float) -> void :
	if skel == null or racket_hand_idx < 0:
		return
	var g: Transform3D = skel.get_bone_global_pose(racket_hand_idx)
	var wb: Basis = (skel.global_transform.basis * g.basis).orthonormalized()
	var cur: Vector3 = (wb * grip_basis.y).normalized()
	var td: Vector3 = target_world.normalized()
	if cur.dot(td) > 0.999 or k <= 0.001:
		return
	var q: Quaternion = Quaternion.IDENTITY.slerp(Quaternion(cur, td), k)
	_override_branch(racket_hand_idx, Transform3D((skel.global_transform.basis.inverse() * (Basis(q) * wb)).orthonormalized(), g.origin), 1.0, true)
	skel.force_update_all_bone_transforms()


# Puno y antebrazo low-poly sustituyen la piel derecha hasta el codo.
# La cadena de huesos, los clips y las reglas del juego no cambian.
var _closed_hand: Node3D
var _wrist_bridge: MeshInstance3D
var _wrist_band: MeshInstance3D
func _build_closed_hand(skin_color: Color) -> void:
	for mi in skel.find_children("*", "MeshInstance3D", true, false):
		var am: ArrayMesh = mi.mesh as ArrayMesh
		if am == null or mi.skin == null:
			continue
		var bind_map: Array = []
		for i in mi.skin.get_bind_count():
			var bone: int = mi.skin.get_bind_bone(i)
			if bone < 0:
				bone = skel.find_bone(mi.skin.get_bind_name(i))
			bind_map.append(bone)
		var dup: = ArrayMesh.new()
		for si in am.get_surface_count():
			var arrays: Array = am.surface_get_arrays(si).duplicate(true)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var removed: Dictionary = {}
			if bones.size() >= verts.size() * 4:
				var per: int = bones.size() / verts.size()
				for vi in verts.size():
					var hand_weight: float = 0.0
					var finger_weight: float = 0.0
					for k in per:
						var bi: int = bind_map[bones[vi * per + k]]
						if bi == racket_hand_idx or (bi >= 0 and skel.get_bone_name(bi).ends_with("_R") and ("Index" in skel.get_bone_name(bi) or "Middle" in skel.get_bone_name(bi) or "Ring" in skel.get_bone_name(bi) or "Pinky" in skel.get_bone_name(bi) or "Thumb" in skel.get_bone_name(bi))):
							hand_weight += weights[vi * per + k]
							if bi != racket_hand_idx: finger_weight += weights[vi * per + k]
					var forearm_weight: float = 0.0
					for k in per:
						if bind_map[bones[vi * per + k]] == skel.get_bone_parent(racket_hand_idx): forearm_weight += weights[vi * per + k]
					if finger_weight > 0.01 or hand_weight > 0.05 or forearm_weight > 0.05:
						removed[vi] = true
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var kept: = PackedInt32Array()
			for t in idx.size() / 3:
				var a: int = idx[t * 3]
				var b: int = idx[t * 3 + 1]
				var c: int = idx[t * 3 + 2]
				if not (removed.has(a) or removed.has(b) or removed.has(c)):
					kept.append_array(PackedInt32Array([a, b, c]))
			if kept.is_empty():
				continue
			arrays[Mesh.ARRAY_INDEX] = kept
			dup.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			dup.surface_set_material(dup.get_surface_count() - 1, am.surface_get_material(si))
		mi.mesh = dup
	_closed_hand = Node3D.new()
	racket_node.add_child(_closed_hand)
	# El origen de la raqueta esta 3cm por debajo del centro del agarre.
	_closed_hand.position.y = 0.03
	var mat: = _mat_kind(skin_color, "skin")
	var forearm_attach: = BoneAttachment3D.new()
	var elbow_idx: int = skel.get_bone_parent(racket_hand_idx)
	forearm_attach.bone_name = skel.get_bone_name(elbow_idx)
	skel.add_child(forearm_attach)
	var endpoint: Vector3 = skel.get_bone_rest(racket_hand_idx).origin
	var arm: = MeshInstance3D.new()
	var arm_mesh: = CylinderMesh.new()
	arm_mesh.top_radius = 0.032
	arm_mesh.bottom_radius = 0.045
	arm_mesh.height = endpoint.length() + 0.06
	arm_mesh.radial_segments = 9
	arm.mesh = arm_mesh
	arm.position = (endpoint - endpoint.normalized() * 0.06) * 0.5
	arm.quaternion = Quaternion(Vector3.UP, endpoint.normalized())
	arm.material_override = mat
	forearm_attach.add_child(arm)
	var elbow: = MeshInstance3D.new()
	var joint: = SphereMesh.new()
	joint.radius = 0.044
	joint.height = 0.088
	joint.radial_segments = 9
	joint.rings = 4
	elbow.mesh = joint
	elbow.material_override = mat
	elbow.position = -endpoint.normalized() * 0.03
	forearm_attach.add_child(elbow)
	var wrist: = MeshInstance3D.new()
	var wrist_mesh: = SphereMesh.new()
	wrist_mesh.radius = 0.033
	wrist_mesh.height = 0.066
	wrist_mesh.radial_segments = 9
	wrist_mesh.rings = 4
	wrist.mesh = wrist_mesh
	wrist.material_override = mat
	racket_node.get_parent().add_child(wrist)
	_wrist_bridge = MeshInstance3D.new()
	var bridge_mesh: = CylinderMesh.new()
	bridge_mesh.top_radius = 0.027
	bridge_mesh.bottom_radius = 0.037
	bridge_mesh.height = 1.0
	bridge_mesh.radial_segments = 10
	_wrist_bridge.mesh = bridge_mesh
	_wrist_bridge.material_override = mat
	racket_node.get_parent().add_child(_wrist_bridge)
	_wrist_band = MeshInstance3D.new()
	var band_mesh: = CylinderMesh.new()
	band_mesh.top_radius = 0.034
	band_mesh.bottom_radius = 0.035
	band_mesh.height = 0.022
	band_mesh.radial_segments = 10
	_wrist_band.mesh = band_mesh
	_wrist_band.material_override = _mat(Color("#f4f4f6"))
	racket_node.get_parent().add_child(_wrist_band)
	_hand_blob(Vector3(-0.009, 0, 0.025), Vector3(0.040, 0.049, 0.022), mat)
	# Transicion palma-muneca, oculta el corte sin ensanchar el puno.
	_hand_blob(Vector3(-0.040, 0, 0.013), Vector3(0.037, 0.031, 0.025), mat)
	for i in 4:
		var yy: float = -0.033 + i * 0.022
		var pts: Array[Vector3] = [Vector3(0.022, yy, 0.025), Vector3(0.033, yy, 0.003), Vector3(0.019, yy, -0.025), Vector3(-0.009, yy, -0.026)]
		for j in 3:
			_hand_link(pts[j], pts[j + 1], 0.0102 if i < 3 else 0.009, mat)
		for p in pts:
			_hand_blob(p, Vector3.ONE * (0.0104 if i < 3 else 0.0092), mat)
	# Pulgar opuesto, cruzado por fuera de los dedos, no un quinto dedo paralelo.
	_hand_link(Vector3(-0.035, -0.038, 0.017), Vector3(-0.025, -0.044, -0.012), 0.013, mat)
	_hand_link(Vector3(-0.025, -0.044, -0.012), Vector3(0.001, -0.022, -0.039), 0.0115, mat)
	_hand_blob(Vector3(0.001, -0.022, -0.039), Vector3(0.012, 0.013, 0.010), mat)

func _hand_blob(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi: = MeshInstance3D.new()
	var mesh: = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = size
	_closed_hand.add_child(mi)

func _hand_link(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var mi: = MeshInstance3D.new()
	var mesh: = CylinderMesh.new()
	mesh.top_radius = radius * 0.93
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	mi.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	_closed_hand.add_child(mi)

func _rk_rest(dt: float) -> void :
	if racket_node == null:
		return
	var rest: bool = state in ["Idle_Sword", "Walk", "Run", "Run_Left", "Run_Right", "Run_Back", "Punch_Right", "HitRecieve", "HitRecieve_2", "Wave", "Idle", "Idle_Neutral"]
	var tgt: float = 1.0 if rest else 0.0
	rk_rest_k = move_toward(rk_rest_k, tgt, dt * 14.0)
	if rk_rest_k > 0.0:
		pass

func head_world() -> Vector3:
	if skel != null:
		var hi: int = skel.find_bone(_bone_name(skel, "Head"))
		if hi >= 0:
			return skel.global_transform * skel.get_bone_global_pose(hi).origin
	return global_position + Vector3(0, 1.65, 0)

func racket_world() -> Vector3:
	if racket_node != null:
		return racket_node.global_position
	return global_position

func force_hide_racket(v: bool) -> void :
	racket_force_hidden = v
	if v:
		if trail_im != null:
			trail_im.clear_surfaces()
		if trail_mi != null:
			trail_mi.visible = false
		if racket_node != null:
			racket_node.visible = false

func racket_hidden_now() -> bool:
	return racket_node != null and not racket_node.visible
