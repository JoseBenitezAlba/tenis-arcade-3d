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
var _skin_bind: Dictionary = {}
var _pose_overrides: Dictionary = {}

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


	ap.add_animation_library("newfore",load("res://models/actual_Derecha.tres"))
	ap.add_animation_library("newback",load("res://models/actual_Reves.tres"))
	ap.add_animation_library("articulated",load("res://models/serve_actual_experiment.tres"))
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
	# La pose de reposo del Skeleton incluye una pose importada distinta del
	# bind de la piel. Los zapatos deben reconstruirse desde el bind real.
	for mesh in skel.find_children("*", "MeshInstance3D", true, false):
		if mesh.skin == null:
			continue
		for index in mesh.skin.get_bind_count():
			var bone: int = mesh.skin.get_bind_bone(index)
			if bone < 0:
				bone = skel.find_bone(mesh.skin.get_bind_name(index))
			if bone >= 0:
				_skin_bind[bone] = mesh.skin.get_bind_pose(index).affine_inverse()
	_rebalance_arms()
	_transplant_shorts()
	_apply_look(pal)
	_build_racket()
	_build_closed_hand(Color(pal.skin))
	_build_accessories()
	_cache_foot_geometry()
	_cache_head_clearance()

# Shoe geometry in each foot bone's skin-bind space, measured once.
var _foot_points: Dictionary = {}
func _cache_foot_geometry() -> void:
	for mi in skel.find_children("*","MeshInstance3D",true,false):
		if mi.skin==null: continue
		var bone_map: Array = []
		for k in mi.skin.get_bind_count():
			var bone: int = mi.skin.get_bind_bone(k)
			if bone<0: bone=skel.find_bone(mi.skin.get_bind_name(k))
			bone_map.append(bone)
		for si in mi.mesh.get_surface_count():
			var a: Array = mi.mesh.surface_get_arrays(si)
			var vertices: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
			if bones.is_empty(): continue
			var per: int = bones.size()/vertices.size()
			for vi in vertices.size():
				for k in per:
					var bone: int = bone_map[bones[vi*per+k]]
					if bone<0 or not skel.get_bone_name(bone).begins_with("Foot_") or weights[vi*per+k]<0.999: continue
					if not _foot_points.has(bone): _foot_points[bone]=PackedVector3Array()
					_foot_points[bone].append(_skin_bind[bone].affine_inverse()*vertices[vi])

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
	var pa: Vector3 = racket_node.to_global(Vector3(0, 0.78, 0))
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
		var pa: Vector3 = racket_node.to_global(Vector3(0, 0.78, 0))
		var pb: Vector3 = racket_node.to_global(Vector3(0, 0.43, 0))
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

func _play_seek(name: String, tau: float, instant:bool=false) -> void :
	ap.speed_scale = 1.0
	if state != name or instant:
		state = name
		ap.play(name, 0.0 if instant else 0.05)
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
		_pose_overrides[bi] = poses[bi]
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
const SERVE_TAU_READY: = 1.30
const SERVE_TAU_CONTACT: = 1.60
const SERVE_TAU_END: = 2.15


static func _serve_tau(kk: float) -> float:
	if kk <= CONTACT_K:
		return lerpf(SERVE_TAU_READY, SERVE_TAU_CONTACT, pow(kk / CONTACT_K, 1.4))
	var y: float = (kk - CONTACT_K) / (1.0 - CONTACT_K)
	return lerpf(SERVE_TAU_CONTACT, SERVE_TAU_END, 1.0 - pow(1.0 - y, 2.0))



static func _swing_clip(kind: String, hit_side: String) -> Array:


	match kind:
		"drop": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.38]

		"volley": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.45]




		"smash": return ["articulated/Servicio", 1.30, 1.70]
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

var point_finished_visual:bool=false
var _previous_approach:bool=false
var _ground_miss_pose:Dictionary={}
var _ground_miss_age:float=9.0
const GAIT_CLIPS:Array[String]=["Walk","Run","Run_Back","Run_Left","Run_Right"]
# Apoyos medidos de cada clip (fracción del ciclo en que empieza el apoyo de
# cada pie): la fase se conserva al cambiar de clip para no reiniciar la
# zancada en tau=0 ni saltar de pie de apoyo. Ver gait_phase_probe.gd.
const GAIT_STRIKES:Dictionary={
	"Walk":[0.047,0.531],
	"Run":[0.453,0.0],
	"Run_Left":[0.0,0.453],
	"Run_Right":[0.453,0.0],
	"Run_Back":[0.328,0.813],
}
var _run_dir:String=""
var _run_dir_age:float=9.0
var _pending_gait:String=""
var _pending_age:float=0.0
var _pending_best:float=9.0
var _gait_from:Array=[]
var _gait_age:float=9.0
# Desajuste de apoyos al cambiar de clip: distancia entre los tobillos de la
# pose visual actual y los del clip nuevo en su fase equivalente, ambos en
# espacio del hueso Body. Cambiar en un momento de bajo desajuste evita el
# salto de pies que ni la fase ni la mezcla de 120ms absorben solas.
func _gait_switch_mismatch(clip:String,tau:float)->float:
	var anim:Animation=ap.get_animation(clip)
	var locals:Array=[]
	for bi in skel.get_bone_count():locals.append(skel.get_bone_rest(bi))
	for ti in anim.get_track_count():
		var path:NodePath=anim.track_get_path(ti)
		var bi:int=skel.find_bone(String(path.get_subname(0)))
		if bi<0:continue
		if anim.track_get_type(ti)==Animation.TYPE_ROTATION_3D:
			locals[bi].basis=Basis(anim.rotation_track_interpolate(ti,tau))
		elif anim.track_get_type(ti)==Animation.TYPE_POSITION_3D:
			locals[bi].origin=anim.position_track_interpolate(ti,tau)
	var worst:float=0.0
	for side in ["L","R"]:
		var knee:int=skel.find_bone(_bone_name(skel,"LowerLeg."+side))
		var foot:int=skel.find_bone(_bone_name(skel,"Foot."+side))
		if knee<0 or foot<0:continue
		var g:Transform3D=Transform3D.IDENTITY
		var chain:Array=[]
		var bi:int=knee
		while bi>=0:chain.push_front(bi);bi=skel.get_bone_parent(bi)
		for b in chain:g=g*locals[b]
		var link:Transform3D=_skin_bind[knee].affine_inverse()*_skin_bind[foot]
		var ankle_now:Transform3D=_current_global_pose(knee)*link
		var ankle_new:Transform3D=g*link
		worst=maxf(worst,ankle_now.origin.distance_to(ankle_new.origin))
	return worst
# Fase de zancada normalizada 0..1: [0,0.5) mitad con apoyo L, [0.5,1) apoyo R.
func _gait_stride_phase(clip:String,phi:float)->float:
	var a:Array=GAIT_STRIKES[clip]
	var tL:float=a[0];var tR:float=a[1]
	var llen:float=fposmod(tR-tL,1.0)
	var rlen:float=1.0-llen
	var d:float=fposmod(phi-tL,1.0)
	if d<llen:return 0.5*d/maxf(llen,0.001)
	return 0.5+0.5*(d-llen)/maxf(rlen,0.001)
func _gait_phase_from_stride(clip:String,s:float)->float:
	var a:Array=GAIT_STRIKES[clip]
	var tL:float=a[0];var tR:float=a[1]
	var llen:float=fposmod(tR-tL,1.0)
	var rlen:float=1.0-llen
	if s<0.5:return fposmod(tL+s*2.0*llen,1.0)
	return fposmod(tR+(s-0.5)*2.0*rlen,1.0)
# Cambio de clip de locomoción conservando fase y pie de apoyo. Reiniciar la
# zancada a tau=0 con ap.play() teletransporta los pies en carrera rápida.
func _play_gait(name:String,spd:float)->void:
	if state==name:
		ap.speed_scale=spd
		last_spd=spd
		return
	if state in GAIT_STRIKES and name in GAIT_STRIKES and ap.has_animation(state) and ap.has_animation(name):
		var lenA:float=ap.get_animation(state).length
		var phi:float=fposmod(ap.current_animation_position/maxf(lenA,0.001),1.0)
		var s:float=_gait_stride_phase(state,phi)
		var lenB:float=ap.get_animation(name).length
		_play(name,spd)
		ap.seek(_gait_phase_from_stride(name,s)*lenB,true)
		return
	_play(name,spd)
# Dirección de carrera por sector con histéresis: el eje del clip sigue la
# velocidad local también a alta velocidad, sin parpadear en las fronteras.
func _select_run_clip(gv:Vector3,dt:float)->String:
	_run_dir_age+=dt
	var theta:float=rad_to_deg(atan2(gv.x,gv.z))
	var at:float=absf(theta)
	var cand:String="Run"
	if at>=135.0:cand="Run_Back"
	elif theta>=45.0:cand="Run_Left"
	elif theta<=-45.0:cand="Run_Right"
	if _run_dir!="" and _run_dir_age<0.10:
		return _run_dir
	if _run_dir=="Run" and at<=60.0:cand="Run"
	elif _run_dir=="Run_Back" and at>=120.0:cand="Run_Back"
	elif _run_dir=="Run_Left" and theta>=30.0 and theta<=150.0:cand="Run_Left"
	elif _run_dir=="Run_Right" and theta<=-30.0 and theta>=-150.0:cand="Run_Right"
	return cand
func _blend_gait_change(dt:float)->void:
	if _gait_from.is_empty() or _gait_age>=0.12:return
	_gait_age+=dt
	var k:float=smoothstep(0.0,0.12,_gait_age)
	var target:Array=[]
	for bi in skel.get_bone_count():target.append(_current_global_pose(bi))
	_pose_overrides.clear()
	for bi in skel.get_bone_count():
		var parent:int=skel.get_bone_parent(bi)
		var old:Transform3D=_gait_from[bi] if parent<0 else _gait_from[parent].affine_inverse()*_gait_from[bi]
		var goal:Transform3D=target[bi] if parent<0 else target[parent].affine_inverse()*target[bi]
		var bn:String=skel.get_bone_name(bi)
		var lower:bool=bn in ["Root","Body"] or bn.begins_with("UpperLeg") or bn.begins_with("LowerLeg") or bn.begins_with("Foot")
		var local:Transform3D=old.interpolate_with(goal,k) if lower else goal
		if lower and parent>=0 and not bn in ["Root","Body"] and old.origin.length()>0.001 and goal.origin.length()>0.001:
			local.origin=local.origin.normalized()*lerpf(old.origin.length(),goal.origin.length(),k)
		_pose_overrides[bi]=local if parent<0 else _pose_overrides[parent]*local
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
func update_from_sim(e, dt: float) -> void:
	var gait_before:String=state
	var gait_pose:Array=[]
	if state in GAIT_CLIPS:
		for bi in skel.get_bone_count():gait_pose.append(_current_global_pose(bi))
	if _previous_approach and not approach_active and e.swing<=0.0 and _full_stroke_age>0.65:
		_ground_miss_pose=capture_visual_pose();_ground_miss_age=0.0
	if approach_active and not _previous_approach:
		_prep_side_set=false;_prep_progress=0.0;_prep_target_set=false;_prep_pose_age=0.0;_prep_previous_target.clear();_prep_switch_source.clear();_prep_switch_age=9.0;_prep_candidate_age=0.0
	_previous_approach=approach_active
	if e.swing>0.0 or serve_ready or serve_toss>=0.0:_ground_miss_age=9.0
	_pose_air = 0.0
	_closed_left.visible=false
	_open_left.visible=true
	for lm in _left_open_meshes:lm.visible=false
	upper_stroke_weight = 0.0
	upper_stroke_clip = ""
	_feet_follow_legs = false
	var was_serve_follow:bool=serve_follow_t>0.0
	var previous_visual:Dictionary=capture_visual_pose() if was_serve_follow else {}
	_update_pose(e, dt)
	if state in GAIT_CLIPS and gait_before in GAIT_CLIPS:
		if state!=gait_before:_gait_from=gait_pose;_gait_age=0.0
		_blend_gait_change(dt)
	else:_gait_from.clear();_gait_age=9.0
	if was_serve_follow and serve_follow_t<=0.0 and e.swing<=0.0:
		_reset_pose=previous_visual;_reset_age=0.0
	_show_serve_ball()
	_serve_wait_feet()
	_sync_mocap_feet()
	_prepare_serve_reach(e)
	if e.get("dive_t") == null or (e.dive_t <= 0.0 and e.getup_t <= 0.0):
		_ground_final_pose(eff_sp < 0.4 or state.begins_with("mocap/"))
	# _serve_spine_limit(e)
	_articulated_ground(e,dt)
	_ground_stroke_support(e,dt)
	_fit_serve_contact(e,dt)
	_blend_serve_reset(dt)
	_blend_ground_miss(dt)
	_guard_preparation_racket(e)
	_update_left_bridge()
	if not _closed_left.visible:
		var left: int=skel.find_bone("Wrist_L")
		_open_left.transform=_current_global_pose(left)*Transform3D(_skin_bind[left].basis.inverse(),Vector3.ZERO)
		_open_left.position=_current_global_pose(left).origin

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

func _current_global_pose(bone: int) -> Transform3D:
	# clear_bones_global_pose_override desactiva el ajuste, pero el getter
	# conserva su transformacion antigua. Solo consultar ajustes de este frame.
	return _pose_overrides[bone] if _pose_overrides.has(bone) else _bone_pose_now(bone)

# Este modelo lleva los pies como hijos de Root, no de las espinillas.
# El mocap anima las piernas pero no aporta posiciones para esos pies.
# Recuperar el enlace del bind evita dejar los zapatos clavados mientras
# la rodilla y el tobillo se mueven.
func _sync_mocap_feet() -> void:
	var mocap_pose: bool = state.begins_with("mocap/") or _feet_follow_legs
	for side in ["L", "R"]:
		var leg: int = skel.find_bone(_bone_name(skel, "LowerLeg." + side))
		var foot: int = skel.find_bone(_bone_name(skel, "Foot." + side))
		if leg < 0 or foot < 0:
			continue
		var link: Transform3D = _skin_bind[leg].affine_inverse() * _skin_bind[foot]
		var leg_pose: Transform3D = _current_global_pose(leg)
		var ankle: Transform3D = leg_pose * link
		if mocap_pose:
			var planted: Basis = _skin_bind[foot].basis
			ankle.basis = planted.slerp(ankle.basis.orthonormalized(), 0.35 if _pose_air > 0.01 else 0.0)
		else:
			# Conservar la rodadura de la zancada nativa, corrigiendo solo el
			# enlace al tobillo durante los fundidos entre clips.
			ankle.basis = _current_global_pose(foot).basis
		skel.set_bone_global_pose_override(foot, ankle, 1.0, true)
		_pose_overrides[foot] = ankle

# Base de saque con dos apoyos separados. La muestra inicial del mocap
# tiene los tobillos casi cruzados; seguirla no crea una base de apoyo.
func _serve_wait_feet() -> void:
	var k: float = 1.0 if serve_ready else (1.0 - smoothstep(0.0, 0.40, serve_toss) if serve_toss >= 0.0 else 0.0)
	if k <= 0.001 or repositioning:
		return
	for side in ["L", "R"]:
		var hip: int = skel.find_bone(_bone_name(skel, "UpperLeg." + side))
		var knee: int = skel.find_bone(_bone_name(skel, "LowerLeg." + side))
		var foot: int = skel.find_bone(_bone_name(skel, "Foot." + side))
		var hp: Transform3D = skel.get_bone_global_pose(hip)
		var kp: Transform3D = skel.get_bone_global_pose(knee)
		var link: Transform3D = _skin_bind[knee].affine_inverse() * _skin_bind[foot]
		var old_ankle: Vector3 = (kp * link).origin
		var target: Vector3 = Vector3(0.19 if side == "L" else -0.19, 0.03, 0.14 if side == "L" else -0.10)
		var top_length: float = hp.origin.distance_to(kp.origin)
		var low_length: float = kp.origin.distance_to(old_ankle)
		var axis: Vector3 = (target - hp.origin).normalized()
		var reach: float = minf(hp.origin.distance_to(target), top_length + low_length - 0.015)
		target = hp.origin + axis * reach
		var along: float = (top_length * top_length - low_length * low_length + reach * reach) / (2.0 * reach)
		var bend: Vector3 = (Vector3(0.0, 0.0, 1.0) - axis * axis.dot(Vector3(0.0, 0.0, 1.0))).normalized()
		var knee_target: Vector3 = hp.origin + axis * along + bend * sqrt(maxf(0.0, top_length * top_length - along * along))
		var upper_turn: Basis = Basis(Quaternion((kp.origin - hp.origin).normalized(), (knee_target - hp.origin).normalized()))
		var lower_turn: Basis = Basis(Quaternion((old_ankle - kp.origin).normalized(), (target - knee_target).normalized()))
		var hip_target: Transform3D = Transform3D(upper_turn * hp.basis, hp.origin)
		var knee_pose: Transform3D = Transform3D(lower_turn * kp.basis, knee_target)
		_pose_overrides[hip] = hp.interpolate_with(hip_target, k)
		_pose_overrides[knee] = kp.interpolate_with(knee_pose, k)
		_pose_overrides[knee].origin=(_pose_overrides[hip]*hp.affine_inverse())*kp.origin
		skel.set_bone_global_pose_override(hip, _pose_overrides[hip], 1.0, true)
		skel.set_bone_global_pose_override(knee, _pose_overrides[knee], 1.0, true)
	skel.force_update_all_bone_transforms()

# Medir tras los ajustes. skel.global_transform ya contiene la figura.
func _ground_final_pose(allow_lower: bool) -> void:
	if skel == null:
		return
	skel.force_update_all_bone_transforms()
	var low: float = INF
	for bn in ["Foot.L", "Foot.R"]:
		var bi: int = skel.find_bone(_bone_name(skel, bn))
		if bi >= 0:
			var foot_pose: Transform3D = _current_global_pose(bi)
			if _foot_points.has(bi):
				var world: Transform3D = skel.global_transform*foot_pose
				for point in _foot_points[bi]: low=minf(low,(world*point).y)
			else: low = minf(low, (skel.global_transform * foot_pose.origin).y-0.082)
	if is_finite(low):
		var correction: float = 0.004 + _pose_air - low
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



	_pose_overrides.clear()
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
		facing = lerp_angle(facing,atan2(e.vx,e.vz),smoothstep(5.6,7.0,eff_sp))

	# Visual recovery only: simulation swing and hit windows stay unchanged.
	var _visual_elapsed: float = (0.4 if e.kind == "serve" else 0.34) - e.swing
	var _moving_recovery: bool = e.kind != "serve" and _visual_elapsed >= 0.24 and eff_sp > 0.4
	var _sw: bool = e.swing > 0.0 and not _moving_recovery
	var _serve_pose: bool = serve_ready or serve_toss >= 0.0 or (e.kind == "serve" and e.swing > 0.0)
	var face_target: float = facing
	if celeb_t > 0.0 or state in CELEB_ANIMS:
		face_target = 0.0
	if _serve_pose:
		face_target = facing + (0.65 if e.near else -0.65)
	var ball_delta: Vector3 = look_target-Vector3(e.x,look_target.y,e.z)
	var watching_incoming:bool=(approach_active and approach_contact.y <= 2.15) or (has_visual_contact and e.swing>0.0 and _visual_elapsed<0.16)
	var watch_contact: bool = watching_incoming and look_on and not _serve_pose and celeb_t <= 0.0 and Vector2(ball_delta.x,ball_delta.z).length() < 6.5
	if watch_contact:
		var back: bool = e.hit_side == "back" if e.swing > 0.0 and has_visual_contact else not ((look_target.x < e.x) == e.near)
		var reference: float = 0.84 if back else -0.33
		if e.swing > 0.0 and has_visual_contact: ball_delta=visual_contact-Vector3(e.x,visual_contact.y,e.z)
		var arrival_weight:float=1.0-smoothstep(2.0,6.5,Vector2(ball_delta.x,ball_delta.z).length())
		face_target=lerp_angle(facing,atan2(ball_delta.x,ball_delta.z)-reference,arrival_weight)
		if has_visual_contact and e.swing > 0.0:
			rotation.y=lerp_angle(rotation.y,face_target,minf(1.0,dt*14.0))
		else:
			rotation.y=rotate_toward(rotation.y,face_target,dt*deg_to_rad(270.0))
	elif not _sw:
		rotation.y = rotate_toward(rotation.y, face_target, dt*deg_to_rad(270.0))

	var gait_velocity:Vector3=Vector3(e.vx,0.0,e.vz).rotated(Vector3.UP,-rotation.y)

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
	var moving_stroke: bool = e.kind != "serve" and e.swing > 0.0 and eff_sp > 0.4
	var hold_swing: bool = e.swing > 0.0 and (not moving_stroke if e.kind != "serve" else true)

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
		_play(clip, clampf(eff_sp / (1.45 if clip == "Walk" else 3.34), 0.15, 2.5))
		_place_racket(dt)
		return
	if serve_ready and e.swing <= 0.0:
		_play_seek("articulated/Servicio", 0.12)
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
		_play_seek("articulated/Servicio", lerpf(0.12, SERVE_TAU_CONTACT, toss_k))
		# Source toss arm retained.
		# Source knee loading retained.
		# Source body coil retained.
		_place_racket(dt)
		return
	if e.kind=="smash" and e.swing>0.0 and has_visual_contact:
		_play_seek("articulated/Servicio",SERVE_TAU_CONTACT+maxf(0.0,0.34-e.swing),e.swing>0.30)
		_place_racket(dt)
		return
	if hold_swing and e.kind == "serve":

		var s_tau: float = SERVE_TAU_CONTACT+maxf(0.0,0.24-e.swing)
		_play_seek("articulated/Servicio", s_tau)
		# El clip incluye una reverencia profunda (tau 1.15-1.6) que lee como
		# gesto roto; se contrarresta en parte para que pase por coil atletico.
		# Source spine retained.

		# Overrides suavizados: el mocap ya baja el brazo de la bola y sube el
		# de la raqueta; las formulas a tope congelaban los brazos (efecto robot).
		# Source arms retained.
		# Source racket arm retained.
		var _sk: float = clampf(k, 0.0, 1.0)
		_pose_air = 0.12 * sin(_sk * PI)
		# Source rotation retained.
	elif serve_follow_t > 0.0 and e.swing <= 0.0:
		var recovery: float = 1.0 - serve_follow_t / 0.30
		_play_seek("articulated/Servicio", SERVE_TAU_CONTACT+0.24+recovery*0.30)
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
		if sc[0] == "articulated/Servicio":
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
		if sc[0] == "articulated/Servicio":
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
	elif not point_finished_visual and (e.want_t > 0.0 or e.prep_t > 0.0) and e.swing <= 0.0 and e.speed <= 2.2:





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


		# Root yaw follows the visual target above, without accumulating
		# windup intent every frame.

	elif celeb_t > 0.0:
		_play(celeb_name)
	elif not point_finished_visual and e.want_t > 0.0 and e.speed <= 2.2:
		_play("Idle_Sword")
	elif eff_sp > 2.8:
		var rc: String = _select_run_clip(gait_velocity, dt)
		if rc != _run_dir:
			_run_dir = rc
			_run_dir_age = 0.0
		var rspd: float = clampf(eff_sp / (3.38 if rc == "Run_Back" else 3.34), 0.15, 2.5)
		if rc != state and state in GAIT_CLIPS:
			if _pending_gait != rc:
				_pending_gait = rc
				_pending_age = 0.0
				_pending_best = 9.0
			_pending_age += dt
			var lenA: float = ap.get_animation(state).length
			var phi: float = fposmod((ap.current_animation_position + dt * ap.speed_scale) / maxf(lenA, 0.001), 1.0)
			var tauB: float = _gait_phase_from_stride(rc, _gait_stride_phase(state, phi)) * ap.get_animation(rc).length
			var mism: float = _gait_switch_mismatch(rc, tauB)
			_pending_best = minf(_pending_best, mism)
			# Esperar el mejor momento de apoyo dentro de un límite que se
			# acorta cuando el clip actual ya apunta lejos de la velocidad:
			# sostener un eje equivocado es peor que un cambio algo brusco.
			var axis: Vector3 = Vector3(0, 0, 1)
			if state == "Run_Back": axis = Vector3(0, 0, -1)
			elif state == "Run_Left": axis = Vector3(1, 0, 0)
			elif state == "Run_Right": axis = Vector3(-1, 0, 0)
			var off: float = absf(rad_to_deg(atan2(axis.cross(gait_velocity).y, axis.dot(gait_velocity))))
			var cap: float = lerpf(0.12, 0.45, clampf(1.0 - (off - 25.0) / 55.0, 0.0, 1.0))
			if mism <= maxf(0.22, _pending_best * 1.15) and _pending_age >= 0.12 or _pending_age >= cap:
				_play_gait(rc, rspd)
				_pending_gait = ""
			else:
				ap.speed_scale = rspd
		else:
			_pending_gait = ""
			_play_gait(rc, rspd)
	elif eff_sp > 0.9 and absf(gait_velocity.x) > absf(gait_velocity.z) * 1.15:
		_run_dir = ""
		_play_gait("Run_Left" if gait_velocity.x > 0.0 else "Run_Right", clampf(eff_sp / 3.34, 0.15, 2.5))
	elif eff_sp > 1.6 and gait_velocity.z < 0.0 and absf(gait_velocity.z) > absf(gait_velocity.x) * 0.7:
		_run_dir = ""
		_play_gait("Run_Back", clampf(eff_sp / 3.38, 0.15, 2.5))
	elif eff_sp > 0.4:
		_run_dir = ""
		_play_gait("Walk", clampf(eff_sp / 1.45, 0.15, 2.0))
	else:
		_run_dir = ""
		_play("Idle_Sword")

	# La transferencia de cuerpo completo se aplica al terminar esta base.

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

# El desplazamiento conserva las piernas del clip de carrera. El gesto de
# tronco y brazos termina sobre esa base, sin cortarlo a los 100 ms.
# Solo rotaciones locales: las articulaciones conservan sus longitudes.
var upper_stroke_weight: float = 0.0
var upper_stroke_clip: String = ""

func _layer_moving_stroke(e, k: float) -> void:
	var sc: Array = _swing_clip(e.kind, e.hit_side if "hit_side" in e else "fore")
	var tau: float
	if sc[0] == "articulated/Servicio":
		tau = _serve_tau(clampf(k, 0.0, 1.0))
	else:
		var split: float = _ease_out_cubic(CONTACT_K)
		var phase: float
		if k <= CONTACT_K:
			phase = split * pow(clampf(k / CONTACT_K, 0.0, 1.0), 1.6)
		else:
			phase = split + (1.0 - split) * (1.0 - pow(1.0 - clampf((k - CONTACT_K) / (1.0 - CONTACT_K), 0.0, 1.0), 2.2))
		tau = lerpf(sc[1], sc[2], phase)
	upper_stroke_weight = smoothstep(0.0, 0.09, e.swing)
	upper_stroke_clip = sc[0]
	_layer_upper_rotation(sc[0], tau, upper_stroke_weight)

func _layer_upper_rotation(clip: String, tau: float, weight: float) -> void:
	if not ap.has_animation(clip) or weight <= 0.0:
		return
	# AnimationPlayer lleva el clip de locomocion. Leer su pose actual antes
	# de escribir la capa y reconstruir el giro del tronco del golpe completo.
	ap.advance(0.0)
	var locals: Array[Transform3D] = []
	for bi in skel.get_bone_count():
		locals.append(skel.get_bone_pose(bi))
	var stroke: Array[Transform3D] = locals.duplicate()
	var anim: Animation = ap.get_animation(clip)
	for ti in anim.get_track_count():
		if anim.track_get_type(ti) != Animation.TYPE_ROTATION_3D or not anim.track_is_enabled(ti):
			continue
		var path: NodePath = anim.track_get_path(ti)
		if path.get_subname_count() == 0:
			continue
		var bi: int = skel.find_bone(String(path.get_subname(0)))
		if bi >= 0:
			stroke[bi].basis = Basis(anim.rotation_track_interpolate(ti, tau))
	var abdomen: int = skel.find_bone("Abdomen")
	if abdomen < 0:
		return
	var parent: int = skel.get_bone_parent(abdomen)
	var desired: Transform3D = stroke[abdomen]
	var cursor: int = parent
	while cursor >= 0:
		desired = stroke[cursor] * desired
		cursor = skel.get_bone_parent(cursor)
	var parent_pose: Transform3D = _bone_pose_now(parent)
	stroke[abdomen].basis = parent_pose.basis.inverse() * desired.basis
	for bi in skel.get_bone_count():
		var ancestor: int = bi
		while ancestor >= 0 and ancestor != abdomen:
			ancestor = skel.get_bone_parent(ancestor)
		if ancestor == abdomen:
			var from: Quaternion = locals[bi].basis.get_rotation_quaternion()
			var to: Quaternion = stroke[bi].basis.get_rotation_quaternion()
			skel.set_bone_pose_rotation(bi, from.slerp(to, weight))
	skel.force_update_all_bone_transforms()

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
var _left_bridge:MeshInstance3D
var _open_left: Node3D
var _closed_left: Node3D
var _left_open_meshes: Array[MeshInstance3D] = []
var _left_closed_basis: Basis
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
		var left_mesh: = ArrayMesh.new()
		for si in am.get_surface_count():
			var arrays: Array = am.surface_get_arrays(si).duplicate(true)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var removed: Dictionary = {}
			var left_removed: Dictionary = {}
			if bones.size() >= verts.size() * 4:
				var per: int = bones.size() / verts.size()
				for vi in verts.size():
					var hand_weight: float = 0.0
					var left_weight: float = 0.0
					var finger_weight: float = 0.0
					for k in per:
						var bi: int = bind_map[bones[vi * per + k]]
						if bi>=0 and (skel.get_bone_name(bi)=="Wrist_L" or (skel.get_bone_name(bi).ends_with("_L") and ("Index" in skel.get_bone_name(bi) or "Middle" in skel.get_bone_name(bi) or "Ring" in skel.get_bone_name(bi) or "Pinky" in skel.get_bone_name(bi) or "Thumb" in skel.get_bone_name(bi)))):left_weight+=weights[vi*per+k]
						if bi == racket_hand_idx or (bi >= 0 and skel.get_bone_name(bi).ends_with("_R") and ("Index" in skel.get_bone_name(bi) or "Middle" in skel.get_bone_name(bi) or "Ring" in skel.get_bone_name(bi) or "Pinky" in skel.get_bone_name(bi) or "Thumb" in skel.get_bone_name(bi))):
							hand_weight += weights[vi * per + k]
							if bi != racket_hand_idx: finger_weight += weights[vi * per + k]
					var forearm_weight: float = 0.0
					for k in per:
						if bind_map[bones[vi * per + k]] == skel.get_bone_parent(racket_hand_idx): forearm_weight += weights[vi * per + k]
					if left_weight>0.05:left_removed[vi]=true
					if finger_weight > 0.01 or hand_weight > 0.05:
						removed[vi] = true
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var kept: = PackedInt32Array()
			var left_indices: = PackedInt32Array()
			for t in idx.size() / 3:
				var a: int = idx[t * 3]
				var b: int = idx[t * 3 + 1]
				var c: int = idx[t * 3 + 2]
				if left_removed.has(a) or left_removed.has(b) or left_removed.has(c):
					left_indices.append_array(PackedInt32Array([a,b,c]))
				elif not (removed.has(a) or removed.has(b) or removed.has(c)):
					kept.append_array(PackedInt32Array([a, b, c]))
			if not left_indices.is_empty():
				var la: Array=arrays.duplicate(true);la[Mesh.ARRAY_INDEX]=left_indices
				left_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,la)
				left_mesh.surface_set_material(left_mesh.get_surface_count()-1,am.surface_get_material(si))
			if kept.is_empty():
				continue
			arrays[Mesh.ARRAY_INDEX] = kept
			dup.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			dup.surface_set_material(dup.get_surface_count() - 1, am.surface_get_material(si))
		mi.mesh = dup
		if left_mesh.get_surface_count()>0:
			var lm:MeshInstance3D=mi.duplicate();lm.mesh=left_mesh;mi.get_parent().add_child(lm);_left_open_meshes.append(lm)
	_closed_hand = Node3D.new()
	racket_node.add_child(_closed_hand)
	# El origen de la raqueta esta 3cm por debajo del centro del agarre.
	_closed_hand.position.y = 0.03
	var mat: = _mat_kind(skin_color, "skin")
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

	_closed_left=_closed_hand.duplicate()
	skel.add_child(_closed_left)
	_closed_left.visible=false
	_open_left=Node3D.new();skel.add_child(_open_left)
	var closed:Node3D=_closed_hand;_closed_hand=_open_left
	# Open support hand, same palm/finger proportions as the racket fist.
	_hand_blob(Vector3(0.04,0,0),Vector3(0.046,0.018,0.046),mat)
	for i in 4:
		var z:float=-0.030+i*0.021
		var finger:float=0.067 if i in [1,2] else 0.054
		var a:Vector3=Vector3(0.070,0,z)
		var b:Vector3=Vector3(0.070+finger*0.55,-0.006,z*1.08)
		var c:Vector3=Vector3(0.070+finger,-0.016,z*1.16)
		_hand_link(a,b,0.009,mat);_hand_link(b,c,0.008,mat);_hand_blob(c,Vector3.ONE*0.008,mat)
	_hand_link(Vector3(0.023,0,0.035),Vector3(0.058,-0.010,0.070),0.012,mat)
	_hand_link(Vector3(0.058,-0.010,0.070),Vector3(0.080,-0.020,0.077),0.010,mat)
	_closed_hand=closed
	_left_bridge=MeshInstance3D.new();skel.add_child(_left_bridge)
	var bridge:CylinderMesh=CylinderMesh.new();bridge.top_radius=0.026;bridge.bottom_radius=0.033;bridge.height=1.0;bridge.radial_segments=10
	_left_bridge.mesh=bridge;_left_bridge.material_override=mat

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

# Candidato de articulacion: objetivos del brazo y apoyo se resuelven sobre
# las longitudes del bind. No se modifica la pelota ni la posicion del jugador.
var _contact_previous: float = 0.0
var _contact_anchor: Vector3
var _contact_side: String = "R"
var _contact_velocity: Vector3 = Vector3.ZERO
var tennis_contact_weight: float = 0.0
var visual_contact: Vector3 = Vector3.ZERO
var has_visual_contact: bool = false

func register_contact(point: Vector3) -> void:
	visual_contact = point
	has_visual_contact = true
	_support_pending=true

func _tennis_contact_pose(e, _dt: float) -> void:
	tennis_contact_weight = 0.0
	if e.swing <= 0.0: has_visual_contact = false
	if (e.kind in ["serve", "smash"] and e.swing > 0.0) or serve_ready or serve_toss >= 0.0 or celeb_t > 0.0 or e.dive_t > 0.0 or e.getup_t > 0.0:
		_contact_previous = e.swing
		return
	var prep: float = float(e.get("prep_k")) if e.get("prep_k") != null else 0.0
	var elapsed: float = maxf(0.0, 0.34 - e.swing)
	var stroke: bool = e.swing > 0.0
	var weight: float = smoothstep(0.18, 0.58, prep) if not stroke else smoothstep(0.0, 0.12, e.swing)
	if weight < 0.001:
		_contact_previous = e.swing
		return
	var back: bool = e.hit_side == "back"
	if not stroke and look_on:
		back = not ((look_target.x < e.x) == e.near)
	if stroke and e.swing > _contact_previous:
		_contact_side = "L" if back else "R"
		_contact_velocity = Vector3(e.vx,0,e.vz)
		var stride: float = clampf(_contact_velocity.length()*0.085,0.0,0.58)
		_contact_anchor = global_transform * Vector3(0.20 if back else -0.20,0,0)
		_contact_anchor += _contact_velocity.normalized()*stride
		_contact_anchor.y = 0.086
	_contact_previous = e.swing
	tennis_contact_weight = weight
	# Bajar la pelvis facilita flexion de rodillas sin estirar las piernas.
	var body: int = skel.find_bone(_bone_name(skel, "Body"))
	var low: float = clampf((1.0 - visual_contact.y) / 0.6,0.0,1.0) if stroke and has_visual_contact else 0.0
	_contact_shift_branch(body, Vector3(0.0, -(0.075 + 0.12 * low) * weight, 0.0))
	var phase: float = clampf(elapsed / 0.25, 0.0, 1.0) if stroke else 0.0
	var prepare: float = clampf(prep / 0.75, 0.0, 1.0)
	var yaw: float = lerpf(0.65 if back else -0.65, 0.08, smoothstep(0.72, 1.0, prep)) if not stroke else lerpf(0.08, -0.55 if back else 0.65, smoothstep(0.0, 1.0, phase))
	yaw *= prepare if not stroke else 1.0
	var abdomen: int = skel.find_bone("Abdomen")
	var original: Dictionary = {}
	for bi in skel.get_bone_count(): original[bi] = _current_global_pose(bi)
	var base: Transform3D = original[abdomen]
	var target: Transform3D = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.07 + 0.25 * low) * _skin_bind[abdomen].basis, base.origin)
	for bi in skel.get_bone_count():
		if _contact_descendant(bi, abdomen):
			var ideal: Transform3D = target * _skin_bind[abdomen].affine_inverse() * _skin_bind[bi]
			var mixed: Transform3D = original[bi].interpolate_with(ideal, weight)
			if bi != abdomen:
				var pi: int = skel.get_bone_parent(bi)
				mixed.origin = _current_global_pose(pi) * (original[pi].affine_inverse() * original[bi].origin)
			_pose_overrides[bi] = mixed
	# La preparacion termina ANTES del contacto. swing empieza en el impacto,
	# no al iniciar otra preparacion con la pelota ya saliendo.
	var wrist: Vector3
	var axis: Vector3
	var left: Vector3
	if back:
		wrist = Vector3(0.22,1.24,0.23).lerp(Vector3(-0.20,1.37,0.28), smoothstep(0.0,1.0,phase))
		axis = Vector3(0.78,0.05,0.35).lerp(Vector3(-0.70,0.55,0.12), smoothstep(0.0,1.0,phase)).normalized()
		if not stroke:
			var down: float = smoothstep(0.72,1.0,prep)
			wrist = Vector3(0.20,1.20,-0.10).lerp(wrist,down)
			axis = Vector3(0.5,0.3,-0.7).lerp(axis,down).normalized()
		left = wrist + axis * 0.09
	else:
		wrist = Vector3(-0.36,1.16,0.29).lerp(Vector3(0.14,1.38,0.25), smoothstep(0.0,1.0,phase))
		axis = Vector3(-0.78,0.02,0.35).lerp(Vector3(0.50,0.62,0.05), smoothstep(0.0,1.0,phase)).normalized()
		if not stroke:
			var down: float = smoothstep(0.72,1.0,prep)
			wrist = Vector3(-0.31,1.14,-0.18).lerp(wrist,down)
			axis = Vector3(-0.5,0.10,-0.7).lerp(axis,down).normalized()
		left = Vector3(0.31,1.22,0.18).lerp(Vector3(0.31,1.06,-0.02),phase)
	if stroke and has_visual_contact:
		var contact_local: Vector3 = skel.global_transform.affine_inverse() * visual_contact
		var impact_axis: Vector3 = (contact_local - Vector3(0.0,1.0,0.0)).normalized()
		var contact_wrist: Vector3 = contact_local - impact_axis * 0.57 / CHAR_SCALE
		wrist = contact_wrist.lerp(wrist,smoothstep(0.0,0.75,phase))
		axis = impact_axis.lerp(axis,smoothstep(0.0,0.75,phase)).normalized()
		if back: left = wrist + axis * 0.09
	_contact_arm("R", wrist, Vector3(-0.42,1.10,0.05), weight)
	_contact_arm("L", left, Vector3(0.42,1.10,0.02), weight)
	var hand_pose: Transform3D = _pose_overrides[racket_hand_idx]
	var face: Vector3 = (Vector3.FORWARD - axis * axis.dot(Vector3.FORWARD)).normalized()
	var rack_basis: Basis = Basis(axis.cross(face).normalized(), axis, face).orthonormalized()
	var hand_basis: Basis = rack_basis * grip_basis.inverse()
	_contact_set_branch(racket_hand_idx, Transform3D(hand_pose.basis.orthonormalized().slerp(hand_basis.orthonormalized(),weight),hand_pose.origin))
	# Apoyo corto, liberado antes de que la traslacion pueda forzar la pierna.
	if weight > 0.0:
		var support: float = (1.0 - smoothstep(0.10,0.24,elapsed)) * weight if stroke else 0.0
		for side in ["L","R"]:
			var target_world: Vector3 = global_transform*Vector3(0.20 if side == "L" else -0.20,0,0)
			target_world -= _contact_velocity.normalized()*clampf(_contact_velocity.length()*0.05,0.0,0.35)
			target_world.y = 0.15
			var target_foot: Vector3 = skel.global_transform.affine_inverse()*target_world
			if side == _contact_side:
				target_foot = skel.global_transform.affine_inverse() * _contact_anchor
			var hip: int = skel.find_bone(_bone_name(skel,"UpperLeg."+side))
			var knee: int = skel.find_bone(_bone_name(skel,"LowerLeg."+side))
			var foot: int = skel.find_bone(_bone_name(skel,"Foot."+side))
			var from: Vector3 = _current_global_pose(foot).origin
			var goal: Vector3 = from.lerp(target_foot,support)
			var direction: Vector3 = skel.global_transform.basis.inverse()*_contact_velocity.normalized()
			var pole: Vector3 = Vector3(goal.x,0.5,0)+direction*0.8
			_contact_limb(hip,knee,foot,goal,pole)
			var fp: Transform3D = _pose_overrides[foot]
			fp.basis = fp.basis.orthonormalized().slerp(_skin_bind[foot].basis.orthonormalized(),support)
			_pose_overrides[foot] = fp
	for bi in _pose_overrides: skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_place_racket(_dt)
	_ground_final_pose(true)

func _contact_descendant(bi: int, parent: int) -> bool:
	while bi >= 0 and bi != parent: bi = skel.get_bone_parent(bi)
	return bi == parent

func _contact_set_branch(bone: int, target: Transform3D) -> void:
	var delta: Transform3D = target * _current_global_pose(bone).affine_inverse()
	var updated: Dictionary = {}
	for bi in skel.get_bone_count():
		if _contact_descendant(bi,bone): updated[bi] = delta * _current_global_pose(bi)
	_pose_overrides.merge(updated, true)

func _contact_shift_branch(bone: int, shift: Vector3) -> void:
	for bi in skel.get_bone_count():
		if _contact_descendant(bi,bone):
			var p: Transform3D = _current_global_pose(bi)
			p.origin += shift
			_pose_overrides[bi] = p

func _contact_arm(side: String, goal: Vector3, pole: Vector3, weight: float) -> void:
	var shoulder: int = skel.find_bone(_bone_name(skel,"UpperArm."+side))
	var elbow: int = skel.find_bone(_bone_name(skel,"LowerArm."+side))
	var wrist: int = skel.find_bone(_bone_name(skel,"Wrist."+side))
	goal = _current_global_pose(wrist).origin.lerp(goal,weight)
	_contact_limb(shoulder,elbow,wrist,goal,pole)

func _contact_limb(upper: int, lower: int, end: int, goal: Vector3, pole: Vector3) -> void:
	var a: Transform3D = _current_global_pose(upper)
	var b: Transform3D = _current_global_pose(lower)
	var endpoint_link: Transform3D = _skin_bind[lower].affine_inverse() * _skin_bind[end]
	var c: Transform3D = b * endpoint_link
	var l1: float = _skin_bind[upper].origin.distance_to(_skin_bind[lower].origin)
	var l2: float = _skin_bind[lower].origin.distance_to(_skin_bind[end].origin)
	var reach: float = clampf(a.origin.distance_to(goal),absf(l1-l2)+0.005,l1+l2-0.008)
	var axis: Vector3 = (goal-a.origin).normalized()
	goal = a.origin + axis*reach
	var along: float = (l1*l1-l2*l2+reach*reach)/(2.0*reach)
	var bend: Vector3 = pole-a.origin
	bend = (bend-axis*axis.dot(bend)).normalized()
	var joint: Vector3 = a.origin+axis*along+bend*sqrt(maxf(0.0,l1*l1-along*along))
	var turn: Basis = Basis(Quaternion((b.origin-a.origin).normalized(),(joint-a.origin).normalized()))
	_contact_set_branch(upper,Transform3D(turn*a.basis,a.origin))
	b = _current_global_pose(lower);c = b * endpoint_link
	turn = Basis(Quaternion((c.origin-b.origin).normalized(),(goal-b.origin).normalized()))
	_contact_set_branch(lower,Transform3D(turn*b.basis,b.origin))
	if skel.get_bone_parent(end) != lower:
		var fp: Transform3D = _current_global_pose(lower) * endpoint_link
		fp.origin = goal
		_pose_overrides[end] = fp

# La recuperacion del saque no conserva la reverencia final de la toma.
# Limita la inclinacion del tronco sin separar brazos, cabeza o raqueta.
func _serve_spine_limit(e) -> void:
	if not (serve_toss >= 0.0 or (e.kind == "serve" and e.swing > 0.0) or serve_follow_t > 0.0):
		return
	var abdomen: int = skel.find_bone("Abdomen")
	var neck: int = skel.find_bone("Neck")
	var a: Transform3D = _current_global_pose(abdomen)
	var n: Transform3D = _current_global_pose(neck)
	var up: Vector3 = (n.origin-a.origin).normalized()
	var tilt: float = acos(clampf(up.dot(Vector3.UP),-1.0,1.0))
	var max_tilt: float = deg_to_rad(32.0)
	if serve_follow_t > 0.0:
		max_tilt = lerpf(deg_to_rad(13.0),max_tilt,serve_follow_t/0.30)
	if tilt <= max_tilt:
		return
	var flatten: Vector3 = Vector3(up.x,0.0,up.z).normalized()
	var desired: Vector3 = Vector3.UP*cos(max_tilt)+flatten*sin(max_tilt)
	var turn: Basis = Basis(Quaternion(up,desired))
	_contact_set_branch(abdomen, Transform3D(turn*a.basis,a.origin))
	for bi in _pose_overrides: skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_place_racket(0.0)

var _full_stroke_previous: float = 0.0
var _full_stroke_age: float = 9.0
var _full_stroke_back: bool = false
var approach_time: float = 9.0
var approach_active: bool = false
var approach_velocity: Vector3 = Vector3.ZERO
var approach_contact:Vector3=Vector3.ZERO
var _approach_blend: float = 0.0
var _prep_pose_age:float=0.0
var _prep_side_set:bool=false
var _prep_previous_target:Array[Transform3D]=[]
var _prep_switch_source:Array[Transform3D]=[]
var _prep_switch_age:float=9.0
var _prep_switch_duration:float=0.16
var _prep_candidate_age:float=0.0
var _prep_side_back:bool=false
var _prep_overhead:bool=false
var _prep_progress:float=0.0
var _prep_target:Vector3=Vector3.ZERO
var _prep_target_set:bool=false


func _articulated_ground(e, dt: float) -> void:
	tennis_contact_weight=0.0
	if _full_stroke_age<0.10:_twohand_wrist_prior=Vector3.ZERO
	if e.swing <= 0.0: has_visual_contact=false
	if (e.kind in ["serve","smash"] and e.swing > 0.0) or serve_ready or serve_toss >= 0.0 or celeb_t > 0.0 or e.dive_t > 0.0 or e.getup_t > 0.0:
		return
	var prep: float = float(e.get("prep_k")) if e.get("prep_k") != null else 0.0
	if e.swing>_full_stroke_previous:
		_full_stroke_age=0.0
		_full_stroke_back=e.hit_side=="back" if has_visual_contact else not ((look_target.x < e.x) == e.near)
	else:
		_full_stroke_age+=dt
	_full_stroke_previous=e.swing
	var stroke: bool = e.swing>0.0 or _full_stroke_age<0.65
	var approaching: float = 1.0-smoothstep(0.05,0.65,approach_time) if approach_active else 0.0
	# Horizontal arrival is not a hit opportunity while a lob is metres
	# above any reachable contact. Keep ready locomotion until it descends.
	approaching*=1.0-smoothstep(3.25,4.0,approach_contact.y)
	_approach_blend=move_toward(_approach_blend,approaching,dt*6.0)
	prep=maxf(prep,_approach_blend)
	if not approach_active:_prep_progress=0.0;_prep_target_set=false
	elif not stroke:
		_prep_progress=maxf(_prep_progress,prep);prep=_prep_progress
		if not _prep_target_set:_prep_target=approach_contact;_prep_target_set=true
		else:_prep_target=_prep_target.lerp(approach_contact,1.0-exp(-dt*14.0))
	var weight: float = smoothstep(0.1,0.7,prep) if not stroke else 1.0-smoothstep(0.40,0.65,_full_stroke_age)
	if weight <= 0.001: return
	tennis_contact_weight=weight
	var arrival_x:float=approach_contact.x
	var actor_x:float=e.x
	if not approach_active:_prep_side_set=false
	if approach_active and not _prep_side_set and prep>0.7:
		_prep_side_back=not ((arrival_x < actor_x) == e.near);_prep_overhead=approach_contact.y>2.15;_prep_side_set=true
	if approach_active and not stroke and _prep_side_set:
		var anticipated:bool=not ((arrival_x<actor_x)==e.near)
		if anticipated!=_prep_side_back:_prep_candidate_age+=dt
		else:_prep_candidate_age=0.0
		if _prep_candidate_age>=0.05:
			_prep_side_back=anticipated;_prep_candidate_age=0.0
			_prep_switch_source=_prep_previous_target.duplicate();_prep_switch_age=0.0;_prep_switch_duration=clampf(approach_time-0.02,0.10,0.16)
	var back: bool = _full_stroke_back if stroke else (_prep_side_back if _prep_side_set else not ((arrival_x < actor_x) == e.near))
	var overhead_preparing:bool=not stroke and approach_active and (_prep_overhead if _prep_side_set else approach_contact.y>2.15)
	if overhead_preparing:weight*=smoothstep(0.1,0.7,_approach_blend)
	if not stroke:
		if _prep_side_set:_prep_pose_age+=dt
		else:_prep_pose_age=0.0
		weight*=smoothstep(0.0,0.16,_prep_pose_age)
		tennis_contact_weight=weight
		if weight<=0.001:return
	var clip: String = "articulated/Servicio" if overhead_preparing else ("newback/Reves" if back else "newfore/Derecha")
	var elapsed: float = _full_stroke_age if stroke else 0.0
	var contact_tau: float = 0.77 if back else 0.84
	var tau: float = lerpf(0.10,contact_tau,clampf(prep,0.0,1.0)) if not stroke else contact_tau+elapsed*1.4
	if overhead_preparing:tau=lerpf(1.15,SERVE_TAU_CONTACT,clampf(prep,0.0,1.0))
	var anim: Animation = ap.get_animation(clip)
	var locals: Array[Transform3D] = []
	for bi in skel.get_bone_count(): locals.append(skel.get_bone_pose(bi))
	var target: Array[Transform3D] = locals.duplicate()
	for ti in anim.get_track_count():
		var path: NodePath = anim.track_get_path(ti)
		var bi: int = skel.find_bone(String(path.get_subname(0)))
		if bi < 0: continue
		if anim.track_get_type(ti) == Animation.TYPE_ROTATION_3D:
			target[bi].basis = Basis(anim.rotation_track_interpolate(ti,tau))
		elif anim.track_get_type(ti) == Animation.TYPE_POSITION_3D:
			target[bi].origin = anim.position_track_interpolate(ti,tau)
	if not _prep_switch_source.is_empty() and _prep_switch_source.size()==target.size():
		_prep_switch_age+=dt
		var transition:float=smoothstep(0.0,_prep_switch_duration,_prep_switch_age)
		for bi in target.size():target[bi]=_prep_switch_source[bi].interpolate_with(target[bi],transition)
		if transition>=1.0:_prep_switch_source.clear()
	_prep_previous_target=target.duplicate()
	_pose_overrides.clear()
	var plant:float=1.0
	if not stroke:
		var distance:float=Vector2(approach_contact.x-e.x,approach_contact.z-e.z).length()
		plant=1.0-smoothstep(1.7,2.5,distance)
	for bi in skel.get_bone_count():
		var p: int = skel.get_bone_parent(bi)
		var bn:String=skel.get_bone_name(bi)
		var lower:bool=bn.begins_with("UpperLeg") or bn.begins_with("LowerLeg") or bn.begins_with("Foot")
		var local: Transform3D = locals[bi].interpolate_with(target[bi],weight*(plant if lower else 1.0))
		_pose_overrides[bi] = local if p < 0 else _pose_overrides[p]*local
	# Keep the shoe attached to the shin while blending the different
	# target hierarchies. Target foot rotations remain available.
	for side in ["L","R"]:
		var knee: int = skel.find_bone(_bone_name(skel,"LowerLeg."+side))
		var foot: int = skel.find_bone(_bone_name(skel,"Foot."+side))
		var foot_pose: Transform3D = _pose_overrides[knee]*_skin_bind[knee].affine_inverse()*_skin_bind[foot]
		foot_pose.basis = _pose_overrides[foot].basis
		_pose_overrides[foot] = foot_pose
	for bi in _pose_overrides: skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_pose_air *= 1.0-weight
	_ground_final_pose(true)
	var source_wrist:Vector3=_current_global_pose(racket_hand_idx).origin
	var contact_preview: bool = not stroke and approach_active and approach_time < 0.25
	if (stroke and has_visual_contact) or contact_preview:
		var impact_weight: float = 1.0-smoothstep(0.04,0.16,elapsed) if stroke else (1.0-smoothstep(0.0,0.25,approach_time))*weight
		var contact_world: Vector3 = visual_contact if stroke else _prep_target
		var source_pose:Transform3D=_current_global_pose(racket_hand_idx)
		var source_head:Vector3=source_pose*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		var contact: Vector3 = source_head.lerp(skel.global_transform.affine_inverse()*contact_world,impact_weight)
		var shoulder: Vector3 = _current_global_pose(skel.find_bone(_bone_name(skel,"UpperArm.R"))).origin
		# Alcanzar con el tronco cuando brazo y raqueta no bastan. El arco
		# gira desde el abdomen y lleva consigo cabeza, hombros y brazos.
		var upper: int = skel.find_bone(_bone_name(skel,"UpperArm.R"))
		var elbow: int = skel.find_bone(_bone_name(skel,"LowerArm.R"))
		var max_reach: float = _skin_bind[upper].origin.distance_to(_skin_bind[elbow].origin)+_skin_bind[elbow].origin.distance_to(_skin_bind[racket_hand_idx].origin)+0.57/CHAR_SCALE
		if contact_preview:
			var preview_delta:Vector3=contact-shoulder
			if preview_delta.length()>max_reach-0.06:
				contact=shoulder+preview_delta.normalized()*(max_reach-0.06)
		var deficit: float = maxf(0.0,shoulder.distance_to(contact)-max_reach+0.012)
		var bend: Vector3 = contact-shoulder
		bend.y=0.0
		if deficit>0.001 and bend.length()>0.001:
			var abdomen: int = skel.find_bone("Abdomen")
			var apose: Transform3D = _current_global_pose(abdomen)
			var lean_axis: Vector3 = Vector3.UP.cross(bend.normalized())
			var lean: float = minf(0.36,deficit/maxf(0.15,shoulder.y-apose.origin.y))*impact_weight
			_contact_set_branch(abdomen,Transform3D(Basis(lean_axis,lean)*apose.basis,apose.origin))
			shoulder=_current_global_pose(upper).origin
		# Keep the source racket direction and elbow plane wherever reach allows.
		# Only turn the racket toward the ball by the minimum feasible angle.
		var axis: Vector3 = (contact-shoulder).normalized()
		var hand_basis: Basis = _current_global_pose(racket_hand_idx).basis.orthonormalized()
		var offset: Vector3 = hand_basis*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		var length: float = offset.length()
		var distance: float = shoulder.distance_to(contact)
		var arm_length: float = max_reach-0.57/CHAR_SCALE-0.028
		var minimum_dot: float = clampf((distance*distance+length*length-arm_length*arm_length)/(2.0*maxf(0.001,distance)*length),-1.0,1.0)
		var racket_axis: Vector3 = offset.normalized()
		if racket_axis.dot(axis)<minimum_dot:
			var side_axis: Vector3 = racket_axis-axis*racket_axis.dot(axis)
			if side_axis.length()<0.001: side_axis=Vector3.UP.cross(axis)
			var feasible: Vector3 = axis*minimum_dot+side_axis.normalized()*sqrt(maxf(0.0,1.0-minimum_dot*minimum_dot))
			hand_basis=Basis(Quaternion(racket_axis,feasible.normalized()))*hand_basis
		if not back and not overhead_preparing:
			hand_basis=_fit_onehand_clearance(contact,hand_basis,shoulder,arm_length)
		var wrist_goal: Vector3 = contact-hand_basis*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		var elbow_pole: Vector3 = _current_global_pose(elbow).origin
		_contact_arm("R",wrist_goal,elbow_pole,1.0)
		var hp: Transform3D = _current_global_pose(racket_hand_idx)
		_contact_set_branch(racket_hand_idx,Transform3D(hand_basis.orthonormalized(),hp.origin))
	if back and not overhead_preparing:
		var rp: Transform3D = _current_global_pose(racket_hand_idx)
		var current_head: Vector3=rp*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		var fit:Basis=_fit_twohand(current_head,rp.basis,source_wrist)
		if (stroke and has_visual_contact and elapsed<0.16) or contact_preview:
			var release:float=1.0-smoothstep(0.04,0.16,elapsed) if stroke else (1.0-smoothstep(0.0,0.25,approach_time))*weight
			var requested_world:Vector3=visual_contact if stroke else _prep_target
			var requested:Vector3=current_head.lerp(skel.global_transform.affine_inverse()*requested_world,release)
			fit=_fit_twohand(requested,rp.basis,source_wrist)
			var fit_goal:Vector3=requested-fit*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
			var rs:Vector3=_current_global_pose(skel.find_bone("UpperArm_R")).origin
			var arm_limit:float=_skin_bind[skel.find_bone("UpperArm_R")].origin.distance_to(_skin_bind[skel.find_bone("LowerArm_R")].origin)+_skin_bind[skel.find_bone("LowerArm_R")].origin.distance_to(_skin_bind[racket_hand_idx].origin)-0.012
			var feet:Dictionary={}
			for side in ["L","R"]:
				var foot:int=skel.find_bone("Foot_"+side);feet[side]=_current_global_pose(foot)
			var moved:float=0.0
			var reach_budget:float=0.20
			if contact_preview and not _prep_switch_source.is_empty():reach_budget*=smoothstep(0.0,_prep_switch_duration,_prep_switch_age)
			for _reach_pass in 3:
				rs=_current_global_pose(skel.find_bone("UpperArm_R")).origin
				fit_goal=requested-fit*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
				var deficit:float=maxf(0.0,rs.distance_to(fit_goal)-arm_limit)
				var shift_direction:Vector3=(fit_goal-rs).normalized()
				var shaft:Vector3=(fit*grip_basis.y).normalized()
				var left_center:Vector3=requested-shaft*0.475/CHAR_SCALE
				var left_goal:Vector3=left_center+_twohand_left_basis(shaft,left_center)*Vector3(0.065,0,-0.012)/CHAR_SCALE
				var left_shoulder:Vector3=_current_global_pose(skel.find_bone("UpperArm_L")).origin
				var left_deficit:float=maxf(0.0,left_shoulder.distance_to(left_goal)-arm_limit)
				if left_deficit>deficit:
					deficit=left_deficit;shift_direction=(left_goal-left_shoulder).normalized()
				var amount:float=minf(maxf(0.0,reach_budget-moved),deficit+0.004)*(1.0-smoothstep(0.04,0.16,elapsed))
				if deficit<=0.001 or amount<=0.0001:break
				moved+=amount
				var shift:Vector3=shift_direction*amount
				_contact_shift_branch(skel.find_bone("Body"),shift)
				for side in ["L","R"]:
					var hip:int=skel.find_bone("UpperLeg_"+side)
					var knee:int=skel.find_bone("LowerLeg_"+side)
					var foot:int=skel.find_bone("Foot_"+side)
					_contact_limb(hip,knee,foot,feet[side].origin,_current_global_pose(knee).origin)
					_pose_overrides[foot].basis=feet[side].basis
				current_head=requested
				fit=_fit_twohand(current_head,rp.basis,source_wrist)
		if stroke and elapsed>0.10:
			var wrist_fit:Basis=_fit_twohand_wrist(source_wrist,rp.basis)
			var release:float=smoothstep(0.10,0.20,elapsed)
			fit=fit.slerp(wrist_fit,release).orthonormalized()
			var from_wrist:Vector3=source_wrist+fit*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
			current_head=current_head.lerp(from_wrist,release)
			for _pass in 4:
				var correction:Vector3=_head_clearance_shift(current_head,fit)
				if correction.length()<0.0001:break
				current_head+=correction
		var right_goal:Vector3=current_head-fit*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		_contact_arm("R",right_goal,_current_global_pose(skel.find_bone("LowerArm_R")).origin,1.0)
		rp=_current_global_pose(racket_hand_idx)
		_contact_set_branch(racket_hand_idx,Transform3D(fit,rp.origin))
		rp=_current_global_pose(racket_hand_idx)
		var grip_center: Vector3 = rp*_fist_center_hand
		var shaft: Vector3 = (rp.basis*grip_basis.y).normalized()
		var left: int = skel.find_bone("Wrist_L")
		var center: Vector3 = grip_center+shaft*0.095/CHAR_SCALE
		var sh: Vector3 = _current_global_pose(skel.find_bone("UpperArm_L")).origin
		# Palm plane faces the wrist, keeping both fists on opposite sides.
		var toward: Vector3 = sh-center;toward-=shaft*shaft.dot(toward)
		if toward.length()<0.001:toward=Vector3.FORWARD
		var x:Vector3=toward.normalized()
		var z:Vector3=x.cross(shaft).normalized()
		_left_closed_basis=Basis(x,shaft,z)
		# Mirrored fist's wrist lies to the palm side of its centre.
		var wrist_offset:Vector3=_left_closed_basis*Vector3(0.065,0,-0.012)/CHAR_SCALE
		_contact_arm("L",center+wrist_offset,_current_global_pose(skel.find_bone("LowerArm_L")).origin,clampf(weight*2.0,0.0,1.0))
		var lp:Transform3D=_current_global_pose(left)
		var actual_center:Vector3=lp.origin-wrist_offset
		_closed_left.transform=Transform3D(_left_closed_basis.scaled(Vector3(-1,1,1)/CHAR_SCALE),actual_center)
		_closed_left.visible=actual_center.distance_to(center)*CHAR_SCALE<0.003
		_open_left.visible=not _closed_left.visible
		for lm in _left_open_meshes:lm.visible=false

	for bi in _pose_overrides: skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_place_racket(dt)

func _twohand_left_basis(shaft:Vector3,center:Vector3)->Basis:
	var sh:Vector3=_current_global_pose(skel.find_bone("UpperArm_L")).origin
	var toward:Vector3=sh-center;toward-=shaft*shaft.dot(toward)
	if toward.length()<0.001:toward=Vector3.FORWARD
	var x:Vector3=toward.normalized()
	return Basis(x,shaft,x.cross(shaft).normalized())

func _fit_twohand(head:Vector3,source:Basis,source_wrist:Vector3)->Basis:
	var rs:Vector3=_current_global_pose(skel.find_bone("UpperArm_R")).origin
	var ls:Vector3=_current_global_pose(skel.find_bone("UpperArm_L")).origin
	var limit:float=_skin_bind[skel.find_bone("UpperArm_L")].origin.distance_to(_skin_bind[skel.find_bone("LowerArm_L")].origin)+_skin_bind[skel.find_bone("LowerArm_L")].origin.distance_to(_skin_bind[skel.find_bone("Wrist_L")].origin)-0.012
	var src:Vector3=(source*grip_basis.y).normalized()
	var best:Basis=source
	var score:float=INF
	for y in 21:
		var yy:float=-0.95+y*0.095
		var rr:float=sqrt(1.0-yy*yy)
		for k in 48:
			var az:float=k*TAU/48.0
			var axis:Vector3=Vector3(rr*cos(az),yy,rr*sin(az))
			var hb:Basis=Basis(Quaternion(src,axis))*source
			var rw:Vector3=head-hb*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
			var lc:Vector3=head-axis*0.475/CHAR_SCALE
			var lb:Basis=_twohand_left_basis(axis,lc)
			var lw:Vector3=lc+lb*Vector3(0.065,0,-0.012)/CHAR_SCALE
			var er:float=maxf(0,rs.distance_to(rw)-limit)
			var el:float=maxf(0,ls.distance_to(lw)-limit)
			var cost:float=(er*er+el*el)*10000.0+rw.distance_squared_to(source_wrist)+(1.0-axis.dot(src))*0.0001
			if cost<score:score=cost;best=hb
	return best

# Reversible proportional experiment: move elbows/wrists with their skin,
# never stretch a solved limb separately from its rendered mesh.
func _rebalance_arms() -> void:
	var old:Dictionary=_skin_bind.duplicate(true)
	var segment_scale:Dictionary={}
	for side in ["L","R"]:
		var u:int=skel.find_bone("UpperArm_"+side)
		var l:int=skel.find_bone("LowerArm_"+side)
		var w:int=skel.find_bone("Wrist_"+side)
		var d1:Vector3=old[l].origin-old[u].origin
		var d2:Vector3=old[w].origin-old[l].origin
		var e1:Vector3=d1.normalized()*0.28-d1
		var e2:Vector3=d2.normalized()*0.25-d2
		segment_scale[u]=Basis(Quaternion(Vector3.RIGHT,d1.normalized()))*Basis.from_scale(Vector3(0.28/d1.length(),1,1))*Basis(Quaternion(Vector3.RIGHT,d1.normalized())).inverse()
		segment_scale[l]=Basis(Quaternion(Vector3.RIGHT,d2.normalized()))*Basis.from_scale(Vector3(0.25/d2.length(),1,1))*Basis(Quaternion(Vector3.RIGHT,d2.normalized())).inverse()
		for bi in skel.get_bone_count():
			if _contact_descendant(bi,l):_skin_bind[bi].origin+=e1
			if _contact_descendant(bi,w):_skin_bind[bi].origin+=e2
	for bi in skel.get_bone_count():
		var parent:int=skel.get_bone_parent(bi)
		var before:Transform3D=old[bi] if parent<0 else old[parent].affine_inverse()*old[bi]
		var after:Transform3D=_skin_bind[bi] if parent<0 else _skin_bind[parent].affine_inverse()*_skin_bind[bi]
		var shift:Vector3=after.origin-before.origin
		var rest:Transform3D=skel.get_bone_rest(bi);rest.origin+=shift
		skel.set_bone_rest(bi,rest)
		skel.set_bone_pose_position(bi,skel.get_bone_pose_position(bi)+shift)
	for mi in skel.find_children("*","MeshInstance3D",true,false):
		if mi.skin==null or not mi.mesh is ArrayMesh:continue
		var skin:Skin=mi.skin.duplicate()
		var ids:Array[int]=[]
		for i in skin.get_bind_count():
			var bi:int=skin.get_bind_bone(i)
			if bi<0:bi=skel.find_bone(skin.get_bind_name(i))
			ids.append(bi)
			if old.has(bi):skin.set_bind_pose(i,_skin_bind[bi].affine_inverse())
		var result:ArrayMesh=ArrayMesh.new()
		for si in mi.mesh.get_surface_count():
			var ar:Array=mi.mesh.surface_get_arrays(si).duplicate(true)
			var verts:PackedVector3Array=ar[Mesh.ARRAY_VERTEX]
			var normals:PackedVector3Array=ar[Mesh.ARRAY_NORMAL]
			var weights:PackedFloat32Array=ar[Mesh.ARRAY_WEIGHTS]
			var joints:PackedInt32Array=ar[Mesh.ARRAY_BONES]
			var per:int=joints.size()/verts.size()
			for vi in verts.size():
				var v:Vector3=Vector3.ZERO
				var n:Vector3=Vector3.ZERO
				for k in per:
					var bi:int=ids[joints[vi*per+k]]
					var weight:float=weights[vi*per+k]
					var stretch:Basis=segment_scale.get(bi,Basis.IDENTITY)
					v+=(_skin_bind[bi].origin+stretch*(verts[vi]-old[bi].origin))*weight
					n+=stretch.inverse().transposed()*normals[vi]*weight
				verts[vi]=v;normals[vi]=n.normalized()
			ar[Mesh.ARRAY_VERTEX]=verts;ar[Mesh.ARRAY_NORMAL]=normals
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,ar)
			result.surface_set_material(si,mi.mesh.surface_get_material(si))
		mi.mesh=result;mi.skin=skin
	# Imported animation translations use old lengths. Source retargeted
	# libraries are regenerated from this rig and already have new lengths.
	for libname in ap.get_animation_library_list():
		if libname in ["newfore","newback","articulated"]:continue
		var lib:AnimationLibrary=ap.get_animation_library(libname).duplicate(true)
		ap.remove_animation_library(libname);ap.add_animation_library(libname,lib)
		for an in lib.get_animation_list():
			var anim:Animation=lib.get_animation(an).duplicate(true)
			for ti in anim.get_track_count():
				if anim.track_get_type(ti)!=Animation.TYPE_POSITION_3D:continue
				var path:NodePath=anim.track_get_path(ti)
				if path.get_subname_count()==0:continue
				var bi:int=skel.find_bone(String(path.get_subname(0)))
				if bi<0:continue
				var parent:int=skel.get_bone_parent(bi)
				var before:Transform3D=old[bi] if parent<0 else old[parent].affine_inverse()*old[bi]
				var after:Transform3D=_skin_bind[bi] if parent<0 else _skin_bind[parent].affine_inverse()*_skin_bind[bi]
				var shift:Vector3=after.origin-before.origin
				for ki in anim.track_get_key_count(ti):anim.track_set_key_value(ti,ki,anim.track_get_key_value(ti,ki)+shift)
			lib.remove_animation(an);lib.add_animation(an,anim)

func _update_left_bridge()->void:
	var wrist:Vector3=_current_global_pose(skel.find_bone("Wrist_L")).origin
	var elbow:Vector3=_current_global_pose(skel.find_bone("LowerArm_L")).origin
	var axis:Vector3=(wrist-elbow).normalized()
	_left_bridge.position=wrist-axis*0.02
	_left_bridge.quaternion=Quaternion(Vector3.UP,axis)
	_left_bridge.scale=Vector3(1,0.12,1)

# Short real-impact support, independent of simulation position and attempts.
var _support_pending:bool=false
var _preimpact_support_armed:bool=false
var _support_age:float=9.0
var _support_foot:int=-1
var _support_anchor:Transform3D
var _support_measured_error:float=0.0
func _ground_stroke_support(e,dt:float)->void:
	_support_measured_error=0.0
	if (e.kind in ["serve","smash"]) or e.dive_t>0.0 or e.getup_t>0.0:
		_support_pending=false;_support_age=9.0;return
	if not approach_active:_preimpact_support_armed=false
	if approach_active and approach_time<0.12 and not _preimpact_support_armed:
		_preimpact_support_armed=true;_support_pending=true
	if _support_pending and _support_age<0.14 and _support_foot>=0:_support_pending=false
	if _support_pending:
		_support_pending=false;_support_age=0.0
		var lowest:float=INF
		for side in ["L","R"]:
			var foot:int=skel.find_bone("Foot_"+side)
			var pose:Transform3D=skel.global_transform*_current_global_pose(foot)
			var low:float=INF
			for point in _foot_points.get(foot,[]):low=minf(low,(pose*point).y)
			if low<lowest:
				lowest=low;_support_foot=foot;_support_anchor=pose
	else:_support_age+=dt
	if _support_age>=0.24 or _support_foot<0:return
	var side:String="L" if _support_foot==skel.find_bone("Foot_L") else "R"
	var hip:int=skel.find_bone("UpperLeg_"+side)
	var knee:int=skel.find_bone("LowerLeg_"+side)
	var goal:Transform3D=skel.global_transform.affine_inverse()*_support_anchor
	var hp:Vector3=_current_global_pose(hip).origin
	var l1:float=_skin_bind[hip].origin.distance_to(_skin_bind[knee].origin)
	var l2:float=_skin_bind[knee].origin.distance_to(_skin_bind[_support_foot].origin)
	# Release rather than stretch a leg when the runner has moved too far.
	if hp.distance_to(goal.origin)>l1+l2-0.012:
		_support_age=9.0;return
	var weight:float=1.0-smoothstep(0.14,0.24,_support_age)
	var original:Transform3D=_current_global_pose(_support_foot)
	var target:Vector3=original.origin.lerp(goal.origin,weight)
	var pole:Vector3=_current_global_pose(knee).origin
	_contact_limb(hip,knee,_support_foot,target,pole)
	var fp:Transform3D=_current_global_pose(_support_foot)
	fp.basis=original.basis.orthonormalized().slerp(goal.basis.orthonormalized(),weight)
	# Preserve sole height after the knee solve and foot rotation, without
	# moving the root, ball or upper body.
	var low:float=INF
	for point in _foot_points.get(_support_foot,[]):low=minf(low,(skel.global_transform*fp*point).y)
	if is_finite(low):
		var correction:Vector3=skel.global_transform.basis.inverse()*Vector3(0,0.004-low,0)
		_contact_limb(hip,knee,_support_foot,fp.origin+correction,pole)
		var solved:Transform3D=_current_global_pose(_support_foot)
		solved.basis=fp.basis;fp=solved
	_pose_overrides[_support_foot]=fp
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_support_measured_error=(skel.global_transform*fp.origin).distance_to(_support_anchor.origin)

var _serve_contact:Vector3=Vector3.ZERO
var _serve_contact_age:float=9.0
func register_serve_contact(point:Vector3)->void:
	_serve_contact=point;_serve_contact_age=0.0
func _fit_serve_contact(e,dt:float)->void:
	var preparing:bool=serve_toss>=0.0 and e.swing<=0.0
	var overhead:bool=e.kind=="smash" and e.swing>0.0 and has_visual_contact
	if not preparing and not overhead and (_serve_contact_age>0.22 or e.kind!="serve"):return
	var contact_age:float=maxf(0.0,0.34-e.swing) if overhead else _serve_contact_age
	var r:Transform3D=_current_global_pose(racket_hand_idx)
	var head:Vector3=r*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
	var target:Vector3=skel.global_transform.affine_inverse()*(look_target if preparing else (visual_contact if overhead else _serve_contact))
	var shoulder:int=skel.find_bone("UpperArm_R")
	var elbow:int=skel.find_bone("LowerArm_R")
	var a:Transform3D=_current_global_pose(shoulder)
	var weight:float=smoothstep(0.38,0.72,serve_toss) if preparing else 1.0-smoothstep(0.04,0.18,contact_age)
	var axis:Vector3=(target-a.origin).normalized()
	var turn:Basis=Basis(Quaternion((head-a.origin).normalized(),axis))
	var desired_basis:Basis=turn*r.basis.orthonormalized()
	var offset:Vector3=desired_basis*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
	var goal:Vector3=target-offset
	_contact_arm("R",goal,_current_global_pose(elbow).origin,weight)
	var wrist:Transform3D=_current_global_pose(racket_hand_idx)
	_contact_set_branch(racket_hand_idx,Transform3D(wrist.basis.orthonormalized().slerp(desired_basis,weight),wrist.origin))
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms();_place_racket(dt)
	if not preparing:_serve_contact_age+=dt

var serve_contact_preview:Vector3=Vector3.ZERO
var _serve_reach_lift:float=0.0
func _prepare_serve_reach(e)->void:
	var preparing:bool=serve_toss>=0.0
	var hitting:bool=e.kind in ["serve","smash"] and e.swing>0.0
	if not preparing and not hitting:return
	var envelope:float=smoothstep(0.45,0.72,serve_toss) if preparing else 1.0-smoothstep(0.04,0.24,0.24-e.swing)
	if preparing:
		# Advance into the serve's already-existing 35cm step progressively.
		position.z+=0.35*(1.0 if e.near else -1.0)*envelope
	var shoulder:Vector3=skel.global_transform*_current_global_pose(skel.find_bone("UpperArm_R")).origin
	var r:Transform3D=_current_global_pose(racket_hand_idx)
	var reach:float=1.035*CHAR_SCALE
	var target:Vector3=serve_contact_preview if preparing else (visual_contact if e.kind=="smash" else _serve_contact)
	var low:float=INF
	for side in ["L","R"]:
		var foot:int=skel.find_bone("Foot_"+side)
		var pose:Transform3D=skel.global_transform*_current_global_pose(foot)
		for point in _foot_points.get(foot,[]):low=minf(low,(pose*point).y)
	if not is_finite(low):return
	shoulder.y+=0.004+_pose_air-low
	var horizontal:float=Vector2(target.x-shoulder.x,target.z-shoulder.z).length_squared()
	var needed:float=maxf(0.0,target.y-shoulder.y-sqrt(maxf(0.0,reach*reach-horizontal)))
	_serve_reach_lift=minf(0.24,needed)*envelope
	_pose_air+=_serve_reach_lift

# Replays store the final pose, not enough simulation fields to improvise it.
func capture_visual_pose()->Dictionary:
	var poses:Array[Transform3D]=[]
	for bi in skel.get_bone_count():poses.append(_current_global_pose(bi))
	return {"world":transform,"bones":poses,"left_closed":_closed_left.visible,"left_closed_t":_closed_left.transform,"left_open_t":_open_left.transform,"bridge_t":_left_bridge.transform,"racket_t":racket_node.transform,"racket_on":racket_node.visible,"held_on":_held_ball_mesh!=null and _held_ball_mesh.visible,"held_t":_held_ball_mesh.transform if _held_ball_mesh!=null else Transform3D.IDENTITY}
func restore_visual_pose(frame:Dictionary)->void:
	transform=frame.world
	_pose_overrides.clear()
	for bi in frame.bones.size():
		_pose_overrides[bi]=frame.bones[bi]
		skel.set_bone_global_pose_override(bi,frame.bones[bi],1.0,true)
	skel.force_update_all_bone_transforms()
	_closed_left.visible=frame.left_closed;_open_left.visible=not frame.left_closed
	_closed_left.transform=frame.left_closed_t;_open_left.transform=frame.left_open_t
	_left_bridge.transform=frame.bridge_t
	racket_node.transform=frame.racket_t;racket_node.visible=frame.racket_on
	if _held_ball_mesh!=null:_held_ball_mesh.visible=frame.held_on;_held_ball_mesh.transform=frame.held_t

var _reset_pose:Dictionary={}
var _reset_age:float=9.0
func register_serve_miss()->void:
	_reset_pose=capture_visual_pose();_reset_age=0.0
func _blend_serve_reset(dt:float)->void:
	if _reset_age>=0.30 or _reset_pose.is_empty():return
	_reset_age+=dt
	var weight:float=smoothstep(0.0,0.30,_reset_age)
	transform=_reset_pose.world.interpolate_with(transform,weight)
	var source:Array=_reset_pose.bones
	var target:Array[Transform3D]=[]
	for bi in skel.get_bone_count():target.append(_current_global_pose(bi))
	_pose_overrides.clear()
	for bi in skel.get_bone_count():
		var parent:int=skel.get_bone_parent(bi)
		if bi==skel.find_bone("Foot_L"):parent=skel.find_bone("LowerLeg_L")
		if bi==skel.find_bone("Foot_R"):parent=skel.find_bone("LowerLeg_R")
		var from:Transform3D=source[bi] if parent<0 else source[parent].affine_inverse()*source[bi]
		var to:Transform3D=target[bi] if parent<0 else target[parent].affine_inverse()*target[bi]
		var local:Transform3D=from.interpolate_with(to,weight)
		# Limb translations have equal length; normalize after rotating
		# their direction rather than shortening the chord in a blend.
		if parent>=0 and not skel.get_bone_name(bi) in ["Body","PT_L","PT_R"]:
			if from.origin.length()>0.001 and to.origin.length()>0.001:
				var turn:Quaternion=Quaternion(from.origin.normalized(),to.origin.normalized())
				local.origin=Quaternion.IDENTITY.slerp(turn,weight)*from.origin.normalized()*lerpf(from.origin.length(),to.origin.length(),weight)
		_pose_overrides[bi]=local if parent<0 else _pose_overrides[parent]*local
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms();_ground_final_pose(true);_place_racket(dt)

# Bounds come from this character's head skin, not a bone-origin radius.
var _head_clearance_box:AABB
var _racket_clearance_points:PackedVector3Array=[]
func _cache_head_clearance()->void:
	var hi:int=skel.find_bone("Head")
	var initialized:bool=false
	for mi in skel.find_children("*","MeshInstance3D",true,false):
		if mi.skin==null:continue
		var map:Array=[]
		for k in mi.skin.get_bind_count():
			var bone:int=mi.skin.get_bind_bone(k)
			if bone<0:bone=skel.find_bone(mi.skin.get_bind_name(k))
			map.append(bone)
		for si in mi.mesh.get_surface_count():
			var ar:Array=mi.mesh.surface_get_arrays(si)
			var vs:PackedVector3Array=ar[Mesh.ARRAY_VERTEX]
			var bs:PackedInt32Array=ar[Mesh.ARRAY_BONES]
			var ws:PackedFloat32Array=ar[Mesh.ARRAY_WEIGHTS]
			if bs.is_empty():continue
			var n:int=bs.size()/vs.size()
			for vi in vs.size():
				for k in n:
					if map[bs[vi*n+k]]==hi and ws[vi*n+k]>0.99:
						var point:Vector3=_skin_bind[hi].affine_inverse()*vs[vi]
						if not initialized:_head_clearance_box=AABB(point,Vector3.ZERO);initialized=true
						else:_head_clearance_box=_head_clearance_box.expand(point)
	for k in 30:_racket_clearance_points.append(Vector3(0,k*0.015,0))
	for x in range(-4,5):
		for y in range(-4,5):
			var xx:float=x/4.0;var yy:float=y/4.0
			if xx*xx+yy*yy<=1.0:_racket_clearance_points.append(Vector3(xx*0.17,0.6+yy*0.20,0))
func _head_clearance_shift(head:Vector3,hand_basis:Basis)->Vector3:
	var hp:Transform3D=_current_global_pose(skel.find_bone("Head"))
	var inv:Transform3D=hp.affine_inverse()
	var extent:Vector3=_head_clearance_box.size*0.5+Vector3.ONE*0.012/CHAR_SCALE
	var center:Vector3=_head_clearance_box.get_center()
	var correction:Vector3=Vector3.ZERO
	var deepest:float=0.0
	var rack:Basis=hand_basis*grip_basis
	for point in _racket_clearance_points:
		var local:Vector3=inv*(head+rack*(point-Vector3(0,0.6,0))/CHAR_SCALE)-center
		var scaled:Vector3=Vector3(local.x/extent.x,local.y/extent.y,local.z/extent.z)
		var ratio:float=scaled.length()
		if ratio>=1.0:continue
		var normal:Vector3=scaled.normalized() if ratio>0.01 else Vector3.UP
		var surface:Vector3=center+normal*extent
		var shift:Vector3=hp.basis*(surface-(local+center))
		if shift.length()>deepest:deepest=shift.length();correction=shift
	return correction

# Keep the string centre on the ball. A rare near-head forehand changes the
# racket direction, not the contact position, bone lengths or simulation.
func _fit_onehand_clearance(contact:Vector3,source:Basis,shoulder:Vector3,arm_length:float)->Basis:
	if _head_clearance_shift(contact,source).length()<0.0001:return source
	var axis:Vector3=(source*grip_basis.y).normalized()
	var best:Basis=source
	var best_score:float=INF
	for y in 13:
		var yy:float=-0.96+y*0.16
		var rr:float=sqrt(1.0-yy*yy)
		for k in 24:
			var az:float=k*TAU/24.0
			var direction:Vector3=Vector3(rr*cos(az),yy,rr*sin(az))
			var basis:Basis=Basis(Quaternion(axis,direction))*source
			var wrist:Vector3=contact-basis*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
			var reach_error:float=maxf(0.0,shoulder.distance_to(wrist)-arm_length)
			var collision:float=_head_clearance_shift(contact,basis).length()
			var score:float=reach_error*1000.0+collision*2000.0+(1.0-axis.dot(direction))*0.05
			if score<best_score:best_score=score;best=basis
	return best

var _twohand_wrist_prior:Vector3=Vector3.ZERO
func _fit_twohand_wrist(wrist:Vector3,source:Basis)->Basis:
	var ls:Vector3=_current_global_pose(skel.find_bone("UpperArm_L")).origin
	var limit:float=_skin_bind[skel.find_bone("UpperArm_L")].origin.distance_to(_skin_bind[skel.find_bone("LowerArm_L")].origin)+_skin_bind[skel.find_bone("LowerArm_L")].origin.distance_to(_skin_bind[skel.find_bone("Wrist_L")].origin)-0.012
	var src:Vector3=(source*grip_basis.y).normalized()
	var best:Basis=source
	var best_score:float=INF
	for y in 15:
		var yy:float=-0.98+y*0.14
		var rr:float=sqrt(1.0-yy*yy)
		for k in 32:
			var az:float=k*TAU/32.0
			var axis:Vector3=Vector3(rr*cos(az),yy,rr*sin(az))
			var basis:Basis=Basis(Quaternion(src,axis))*source
			var grip:Vector3=wrist+basis*_fist_center_hand
			var lc:Vector3=grip+axis*0.095/CHAR_SCALE
			var lw:Vector3=lc+_twohand_left_basis(axis,lc)*Vector3(0.065,0,-0.012)/CHAR_SCALE
			var reach_error:float=maxf(0.0,ls.distance_to(lw)-limit)
			var head:Vector3=wrist+basis*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
			var cost:float=reach_error*reach_error*10000.0+(1.0-axis.dot(src))*0.05
			if _twohand_wrist_prior!=Vector3.ZERO:cost+=(1.0-axis.dot(_twohand_wrist_prior))*0.50
			if cost>=best_score:continue
			var shift:float=_head_clearance_shift(head,basis).length()
			var body_pen:float=_racket_body_penetration(head,basis)
			cost+=(shift*shift+body_pen*body_pen)*20000.0
			if cost<best_score:best_score=cost;best=basis
	_twohand_wrist_prior=(best*grip_basis.y).normalized()
	return best

func _racket_body_penetration(head:Vector3,basis:Basis)->float:
	var bottom:Vector3=_current_global_pose(skel.find_bone("Abdomen")).origin
	var top:Vector3=_current_global_pose(skel.find_bone("Neck")).origin
	var line:Vector3=top-bottom
	var length_sq:float=line.length_squared()
	var rack:Basis=basis*grip_basis
	var penetration:float=0.0
	for point in _racket_clearance_points:
		var pos:Vector3=head+rack*(point-Vector3(0,0.6,0))/CHAR_SCALE
		var t:float=clampf((pos-bottom).dot(line)/length_sq,0.0,1.0)
		var radius:float=lerpf(0.14,0.12,t)/CHAR_SCALE
		penetration=maxf(penetration,radius-pos.distance_to(bottom+line*t))
	return penetration

func _blend_ground_miss(dt:float)->void:
	if _ground_miss_age>=0.20 or _ground_miss_pose.is_empty():return
	_ground_miss_age+=dt
	var weight:float=smoothstep(0.0,0.20,_ground_miss_age)
	transform.basis=_ground_miss_pose.world.basis.slerp(transform.basis,weight).orthonormalized()
	_closed_left.visible=false;_open_left.visible=true
	var source:Array=_ground_miss_pose.bones
	var target:Array[Transform3D]=[]
	for bi in skel.get_bone_count():target.append(_current_global_pose(bi))
	_pose_overrides.clear()
	for bi in skel.get_bone_count():
		var parent:int=skel.get_bone_parent(bi)
		if bi==skel.find_bone("Foot_L"):parent=skel.find_bone("LowerLeg_L")
		if bi==skel.find_bone("Foot_R"):parent=skel.find_bone("LowerLeg_R")
		var from:Transform3D=source[bi] if parent<0 else source[parent].affine_inverse()*source[bi]
		var to:Transform3D=target[bi] if parent<0 else target[parent].affine_inverse()*target[bi]
		var local:Transform3D=from.interpolate_with(to,weight)
		# Limb translations have equal length; normalize after rotating
		# their direction rather than shortening the chord in a blend.
		if parent>=0 and not skel.get_bone_name(bi) in ["Body","PT_L","PT_R"]:
			if from.origin.length()>0.001 and to.origin.length()>0.001:
				var turn:Quaternion=Quaternion(from.origin.normalized(),to.origin.normalized())
				local.origin=Quaternion.IDENTITY.slerp(turn,weight)*from.origin.normalized()*lerpf(from.origin.length(),to.origin.length(),weight)
		_pose_overrides[bi]=local if parent<0 else _pose_overrides[parent]*local
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms();_ground_final_pose(true);_place_racket(dt)

func _guard_preparation_racket(e)->void:
	if (not approach_active and _ground_miss_age>=0.20) or e.swing>0.0 or _closed_left.visible:return
	for attempt in 4:
		var wrist:Transform3D=_current_global_pose(racket_hand_idx)
		var head:Vector3=wrist*(_fist_center_hand+grip_basis.y*0.57/CHAR_SCALE)
		var correction:Vector3=_head_clearance_shift(head,wrist.basis)
		if correction.length()<0.0001:break
		_contact_arm("R",wrist.origin+correction,_current_global_pose(skel.find_bone("LowerArm_R")).origin,1.0)
		var current:Transform3D=_current_global_pose(racket_hand_idx)
		_contact_set_branch(racket_hand_idx,Transform3D(wrist.basis,current.origin))
	for bi in _pose_overrides:skel.set_bone_global_pose_override(bi,_pose_overrides[bi],1.0,true)
	skel.force_update_all_bone_transforms();_place_racket(0.0)
