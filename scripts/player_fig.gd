class_name PlayerFig
extends Node3D





const MODELS: = [
	"res://models/Casual_2.glb", 
]



const SHORTS_MODEL: = "res://models/Casual_Hoodie.glb"
const LOOKS: = [
	{"shirt": "#2b7cd3", "shorts": "#1c2833", "skin": "#b07850", "hair": "#3a2a18"}, 
	{"shirt": "#f2f2f2", "shorts": "#3d5a80", "skin": "#a06b42", "hair": "#141414"}, 
	{"shirt": "#39b54a", "shorts": "#f2f2f2", "skin": "#8d5524", "hair": "#0d0d0d"}, 
	{"shirt": "#f2a13c", "shorts": "#22303c", "skin": "#c98d62", "hair": "#7a4a1e"}, 
]
const P0: = {"shirt": "#e23b3b", "shorts": "#f2f2f2", "skin": "#b07850", "hair": "#3a2a18"}
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

func _init(look: int, is_player0: bool) -> void :
	var pal: Dictionary = P0 if is_player0 else LOOKS[look % LOOKS.size()]
	inst = (load(MODELS[0]) as PackedScene).instantiate()
	inst.scale = Vector3.ONE * CHAR_SCALE
	add_child(inst)
	skel = inst.find_child("Skeleton3D", true, false)
	ap = inst.find_child("AnimationPlayer", true, false)


	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


	if ResourceLoader.exists("res://models/mocap_anims_mm.tres"):
		ap.add_animation_library("mocap", load("res://models/mocap_anims_mm.tres"))
	_transplant_shorts()
	_apply_look(pal)
	_build_racket()
	_build_accessories()

var ankle_bones: Array = []

func _build_ankles(_skin_col: Color) -> void :
	# v0.140: el hueso LowerLeg de los clips no apunta al pie (IK sin retarget): la espinilla colgaba lejos de la zapatilla
	for side in ["L", "R"]:
		var kb: int = skel.find_bone("LowerLeg." + side)
		var fb: int = skel.find_bone("Foot." + side)
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
	legs.skeleton = NodePath("..")  # v0.140: sin esto la malla de piernas no se deformaba con el esqueleto (espinillas/tobillos desconectados de la zapatilla)
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

	for bone in ["Wrist.L", "Wrist.R"]:
		var ba: = BoneAttachment3D.new()
		ba.bone_name = bone
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
	var ba: = BoneAttachment3D.new()
	ba.bone_name = "Wrist.R"
	skel.add_child(ba)
	var rk: = Node3D.new()


	rk.scale = Vector3.ONE * (1.0 / CHAR_SCALE) * 1.15


	rk.rotation = Vector3(PI, 0.0, 0.0)
	rk.position = Vector3.ZERO
	ba.add_child(rk)
	racket_node = rk

	var handle: = MeshInstance3D.new()
	var hc: = CylinderMesh.new()
	hc.top_radius = 0.015
	hc.bottom_radius = 0.017
	hc.height = 0.26
	hc.radial_segments = 8
	hc.material = _mat(Color("#26221e"))
	handle.mesh = hc
	handle.position = Vector3(0, -0.095, 0)
	rk.add_child(handle)
	var butt: = MeshInstance3D.new()
	var bc: = CylinderMesh.new()
	bc.top_radius = 0.021
	bc.bottom_radius = 0.022
	bc.height = 0.025
	bc.radial_segments = 8
	bc.material = _mat(Color("#141210"))
	butt.mesh = bc
	butt.position = Vector3(0, 0.05, 0)
	rk.add_child(butt)

	var graphite: = _mat(Color("#191b20"))
	var frame_red: = _mat(Color("#d43a2c"))
	var throat_light: = _mat(Color("#cfd2d8"))
	for sx in [-1.0, 1.0]:
		var a: = Vector3(0, -0.225, 0)
		var b: = Vector3(sx * 0.085, -0.32, 0)
		var seg: = b - a
		var arm: = MeshInstance3D.new()
		var ac: = CylinderMesh.new()
		ac.top_radius = 0.009
		ac.bottom_radius = 0.012
		ac.height = seg.length()
		ac.material = throat_light
		arm.mesh = ac
		arm.position = (a + b) * 0.5
		arm.basis = _basis_along_y(seg.normalized())
		rk.add_child(arm)
	var frame: = MeshInstance3D.new()
	var tm: = TorusMesh.new()
	tm.inner_radius = 0.216
	tm.outer_radius = 0.247
	tm.ring_segments = 10
	tm.rings = 40
	tm.material = frame_red
	frame.mesh = tm


	frame.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	frame.scale = Vector3(1.0, 1.0, 1.18)
	frame.position = Vector3(0, -0.575, 0)
	rk.add_child(frame)
	var trim: = MeshInstance3D.new()
	var tt: = TorusMesh.new()
	tt.inner_radius = 0.209
	tt.outer_radius = 0.22
	tt.ring_segments = 8
	tt.rings = 40
	tt.material = throat_light
	trim.mesh = tt
	trim.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	trim.scale = Vector3(1.0, 1.0, 1.18)
	trim.position = Vector3(0, -0.575, 0)
	rk.add_child(trim)
	var strings: = MeshInstance3D.new()
	var qm: = QuadMesh.new()
	qm.size = Vector2(0.43, 0.51)
	var sm: = StandardMaterial3D.new()
	sm.albedo_texture = TexGen.string_texture()
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = sm
	strings.mesh = qm
	strings.position = Vector3(0, -0.575, 0)
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

	if state == name and signf(spd) == signf(last_spd): return
	state = name
	last_spd = spd
	ap.play(name, blend, spd)

func _play_seek(name: String, tau: float) -> void :
	if state != name:
		state = name
		ap.play(name, 0.05)
	ap.seek(tau, true)


const LOB_ARM: = -1.1
const FOOT_LIFT: = 0.05
const RK_OPEN: = 0.9
const TOSS_ARM: = -2.0  # v1.37
const SERVE_ARM: = -0.8  # v1.37


func _raise_arm(ang: float, bone: String = "UpperArm.R") -> void :
	var bi: = skel.find_bone(bone)
	if bi < 0:
		return
	var g: = skel.get_bone_global_pose(bi)
	skel.set_bone_global_pose_override(bi, Transform3D(Basis(Vector3.RIGHT, ang) * g.basis, g.origin), 1.0, true)

func _bend_torso(k: float) -> void :
	for bn in ["Abdomen", "Torso"]:
		var bi: = skel.find_bone(bn)
		if bi >= 0:
			var q: = skel.get_bone_global_pose(bi).basis.get_rotation_quaternion()
			skel.set_bone_global_pose_override(bi, Transform3D(Basis(q * Quaternion(Vector3.RIGHT, 0.45 * k)), skel.get_bone_global_pose(bi).origin), 1.0, true)

var celeb_t: = 0.0
var celeb_name: = ""
var had_windup: = false



const WINDUP: = 0.3
const CONTACT_K: = 0.47

static func _swing_clip(kind: String, hit_side: String) -> Array:


	match kind:
		"drop": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.38]

		"volley": return ["mocap/Reves" if hit_side == "back" else "mocap/Derecha", 1.0, 1.45]




		"smash": return ["mocap/Servicio", 0.95, 1.45]
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

func update_from_sim(e, dt: float) -> void :
	ap.advance(dt)
	if racket_node != null:
		racket_node.rotation = Vector3(PI, 0.0, 0.0)
	swing_now = e.swing
	var _fatk: float = e.get("fat") if e.get("fat") != null else 0.0



	skel.clear_bones_global_pose_override()
	skel.force_update_all_bone_transforms()
	if e.swing <= 0.0 and e.want_t <= 0.0:
		had_windup = false
	position = Vector3(e.x, FOOT_LIFT, e.z)  # v0.138: la pista esta a y=0.06 (court_builder); con los pies a 0 las suelas quedaban 6 cm bajo la superficie



	var target_y: = FOOT_LIFT
	if e.wait_serve and e.swing <= 0.0 and e.want_t <= 0.0 and e.speed < 0.5:
		target_y = FOOT_LIFT + absf(sin(float(Time.get_ticks_msec() % 1400) / 1400.0 * TAU * 2.6)) * 0.055
	position.y = lerpf(position.y, target_y, minf(1.0, dt * 14.0))

	if e.get("split_t") != null and e.split_t > 0.0 and e.swing <= 0.0 and e.get("dive_t") <= 0.0 and (e.get("getup_t") == null or e.getup_t <= 0.0):
		var sph: float = 1.0 - e.split_t / 0.32
		position.y = FOOT_LIFT + sin(sph * PI) * 0.09

	if hop_age < HOP_DUR:
		hop_age += dt
		position.y += hop_y(hop_age, hop_h)
		if hop_age >= HOP_DUR:
			hop_landed = true

	# v0.140: las suelas nunca por debajo de la pista (clips con pie bajo el suelo al celebrar / levantarse)
	if foot_bones.is_empty():
		for fbn in ["Foot.L", "Foot.R"]:
			var fbi: = skel.find_bone(fbn)
			if fbi >= 0:
				foot_bones.append(fbi)
	var fmin: = 99.0
	for fbi2 in foot_bones:
		var fy: float = (global_transform * skel.global_transform * skel.get_bone_global_pose(fbi2)).origin.y
		fmin = minf(fmin, fy)
	var fneed: float = 0.06 + 0.026 - fmin
	if fmin < 90.0 and fneed > 0.0:
		position.y += minf(fneed, 0.25)



	var facing: = 0.0 if e.near else PI
	if e.speed > 3.5 and absf(e.vx) > absf(e.vz):
		facing = atan2(e.vx, e.vz)

	var _sw: bool = e.swing > 0.0
	if not _sw:
		rotation.y = lerp_angle(rotation.y, facing, minf(1.0, dt * 9.0))

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
	rotation.x = lerpf(rotation.x, pitch, minf(1.0, dt * 10.0))
	rotation.z = lerpf(rotation.z, lean, minf(1.0, dt * 8.0))
	var sp: float = clampf(e.speed / 6.0, 0.0, 1.0)
	var swing_dur: float = 0.4 if e.kind == "serve" else 0.34
	var k: float = 1.0 - e.swing / swing_dur if e.swing > 0.0 else -1.0



	var elapsed: float = swing_dur - e.swing if e.swing > 0.0 else 99.0
	var hold_swing: bool = e.swing > 0.0 and (elapsed < 0.15 or e.speed <= 0.4)

	if e.get("dive_t") != null and e.dive_t > 0.0:




		var dp: float = clampf(1.0 - e.dive_t / 0.55, 0.0, 1.0)
		var roll_len: float = ap.get_animation("Roll").length if ap.has_animation("Roll") else 1.0
		_play_seek("Roll", minf(dp * 0.55, 0.07) * roll_len)
		return




	if e.get("getup_t") != null and e.getup_t > 0.0 and e.swing <= 0.0:
		if e.getup_t > 0.4:
			var roll_len2: float = ap.get_animation("Roll").length if ap.has_animation("Roll") else 1.0
			_play_seek("Roll", 0.07 * roll_len2)
		else:
			if state != "getup":
				state = "getup"
				ap.play("Idle_Sword", 0.34)
			ap.seek(0.0, true)
		return
	if serve_toss >= 0.0 and e.swing <= 0.0:

		_play_seek("mocap/Servicio", lerpf(0.1, 0.55, clampf(serve_toss, 0.0, 1.0)))
		_raise_arm(TOSS_ARM * _ease_out_cubic(clampf(serve_toss / 0.55, 0.0, 1.0)), "UpperArm.L")  # v1.37: el brazo del lanzamiento sube
		return
	if hold_swing and e.kind == "serve":

		_play_seek("mocap/Servicio", lerpf(0.55, 1.3, clampf(k, 0.0, 1.0)))
		# v1.37: brazo del lanzamiento arriba hasta el contacto y luego cae; brazo de golpe extendido arriba en el contacto
		_raise_arm(TOSS_ARM * (1.0 - _ease_in_cubic(clampf((k - 0.2) / 0.5, 0.0, 1.0))), "UpperArm.L")
		_raise_arm(SERVE_ARM * clampf(1.0 - absf(k - 0.55) / 0.3, 0.0, 1.0))
	elif hold_swing:
		var hs: String = e.hit_side if "hit_side" in e else "fore"
		var sc: = _swing_clip(e.kind, hs)
		var kk: = clampf(k, 0.0, 1.0)
		var tau: float
		if had_windup:



			tau = sc[1] + _ease_out_cubic(kk) * (sc[2] - sc[1])
		elif kk < 0.3:


			tau = _ease_in_cubic(kk / 0.3) * sc[1]
		else:
			tau = sc[1] + _ease_out_cubic((kk - 0.3) / 0.7) * (sc[2] - sc[1])
		_play_seek(sc[0], tau)



		var by: float = e.get("ball_y") if e.get("ball_y") != null else 1.0
		var low_k: float = clampf((0.95 - by) / 0.55, 0.0, 1.0)
		if low_k > 0.0:
			var env: float = clampf(1.0 - absf(kk - 0.47) / 0.53, 0.0, 1.0)
			_bend_torso(low_k * env)
		if e.kind == "lob" or e.kind == "toplob" or e.kind == "drop":


			var env2: float = clampf(1.0 - absf(kk - 0.5) / 0.5, 0.0, 1.0)
			if racket_node != null:

				racket_node.rotation = Vector3(PI, RK_OPEN * env2 * (1.0 if e.kind == "drop" else 0.0), 0.0)
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
		_play_seek(scw[0], wk * scw[1])
		had_windup = true


		var its: float = e.get("intent_side") if e.get("intent_side") != null else 0.0
		if its != 0.0:
			rotation.y += its * 0.22 * wk * (1.0 if e.near else -1.0)
	elif celeb_t > 0.0:
		celeb_t -= dt
		_play(celeb_name)
	elif e.want_t > 0.0 and e.speed <= 2.2:
		_play("Idle_Sword")
	elif e.speed > 0.9 and absf(e.vx) > absf(e.vz) * 1.15:
		# El shuffle lateral debe tener prioridad sobre el ciclo de carrera frontal;
		# de lo contrario el modelo corre de frente mientras se desplaza de costado.
		_play("Run_Left" if e.vx > 0.0 else "Run_Right", clampf(e.speed / 3.2, 0.65, 1.65))
	elif e.speed > 1.6 and ((e.vz < 0.0) if e.near else (e.vz > 0.0)) and absf(e.vz) > absf(e.vx) * 0.7:

		_play("Run_Back", clampf(e.speed / 5.0, 0.7, 1.4))
	elif e.speed > 6.5:
		_play("Run", clampf(e.speed / 4.0, 1.0, 1.6) * (1.0 - 0.18 * _fatk))
	elif e.speed > 2.8:
		_play("Run", clampf(e.speed / 5.0, 0.6, 1.2) * (1.0 - 0.18 * _fatk))
	elif e.speed > 0.4:

		_play("Walk", clampf(e.speed / 2.2, 0.8, 1.6))
	else:
		_play("Idle_Sword")

	if _fatk > 0.55:
		_bend_torso(0.5 * clampf((_fatk - 0.55) / 0.45, 0.0, 1.0))
	_apply_gaze()
