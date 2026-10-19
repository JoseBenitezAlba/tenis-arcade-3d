class_name CrowdFX
extends Node3D




var mm_body: MultiMeshInstance3D
var mm_head: MultiMeshInstance3D
var base_pos: Array[Vector3] = []
var face_rot: Array[Basis] = []
var head_yaw: Array[float] = []
var ball_pos: = Vector3(0, 1.0, 11.885)
var phases: Array[float] = []
var jitters: Array[float] = []
var shirt_cols: Array[Color] = []
var skin_cols: Array[Color] = []
var empty: Array[bool] = []
var mm_cap: MultiMeshInstance3D
var cap_ok: Array[bool] = []
var cap_cols: Array[Color] = []
var stand_up: Array[bool] = []
var ova_t: = 0.0
var sil_t: = 0.0
var time: = 0.0
var exc: = 0.0
var force_ovation: = false
var n: = 0

const SHIRTS: = ["#d94f3d", "#e8b53a", "#3f7fd9", "#45a36b", "#e8e4da", "#c75ba8", "#7a5fd0", "#d97f3a", "#3fb8b8", "#b8c4d4", "#8a4f2e", "#4a5568"]

const MUTED: = ["#3a4250", "#4e5563", "#636b78", "#8b909b", "#a49f93", "#2f3644", "#756a5c", "#525a68"]
const SKINS: = ["#f2c79b", "#d9a06b", "#a06b3f", "#7a4a28", "#f5d7b5", "#8a5a35"]

func _mat() -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	return m

func build() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = 20261011

	var stands: Array = []

	stands.append([Vector3(-19.0, 3.05, 28.9), Vector3(1, 0, 0), Vector3(0, 0.78, -0.5), 39, 8, Basis(Vector3.UP, PI), Vector3(0, 0, 1), [13, 26]])

	stands.append([Vector3(14.3, 3.05, -2.0), Vector3(0, 0, 1), Vector3(-0.5, 0.78, 0), 29, 7, Basis(Vector3.UP, - PI * 0.5), Vector3(1, 0, 0), [14]])
	stands.append([Vector3(-14.3, 3.05, -2.0), Vector3(0, 0, 1), Vector3(0.5, 0.78, 0), 29, 7, Basis(Vector3.UP, PI * 0.5), Vector3(-1, 0, 0), [14]])
	var step_mat: = StandardMaterial3D.new()
	step_mat.albedo_color = Color("#39405a")
	step_mat.roughness = 1.0
	var aisle_mat: = StandardMaterial3D.new()
	aisle_mat.albedo_color = Color("#4a5270")
	aisle_mat.roughness = 1.0
	for st in stands:
		var org: Vector3 = st[0]
		var dc: Vector3 = st[1]
		var dr: Vector3 = st[2]
		var back: Vector3 = st[6]
		var aisles: Array = st[7]
		for r in st[4]:

			var rc: Vector3 = org + dc * (st[3] - 1) * 0.5 + dr * r
			var along: = dc.abs()
			var step_sz: Vector3 = Vector3.ONE * 0.95 + along * (float(st[3]) + 1.0 - 0.95)
			step_sz.y = 0.55
			var step: = MeshInstance3D.new()
			var sb: = BoxMesh.new()
			sb.size = step_sz
			sb.material = step_mat
			step.mesh = sb
			step.position = rc + Vector3(0, -0.295, 0) + back * 0.22
			step.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(step)

			for ax in aisles:
				var ac: Vector3 = org + dc * ax + dr * r
				var strip: = MeshInstance3D.new()
				var ab: = BoxMesh.new()
				ab.size = Vector3.ONE * 0.97 + along * 0.5 as Vector3
				ab.size.y = 0.58
				ab.material = aisle_mat
				strip.mesh = ab
				strip.position = ac + Vector3(0, -0.29, 0) + back * 0.22
				strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(strip)
			for c in st[3]:
				if c in aisles:
					continue
				var p: Vector3 = org + dc * c + dr * r
				p.x += rng.randf_range(-0.16, 0.16)
				p.z += rng.randf_range(-0.16, 0.16)
				base_pos.append(p)
				face_rot.append(st[5])
				head_yaw.append(atan2(p.x - ball_pos.x, p.z - ball_pos.z) + PI)
				phases.append(rng.randf_range(0.0, TAU))
				jitters.append(rng.randf_range(0.7, 1.3))



				var blk: = int(c / 7) + int(r / 2) * 8
				var brng: = RandomNumberGenerator.new()
				brng.seed = 991 + blk * 37 + int(org.x * 3.0) + int(org.z)
				var block_col: = Color(MUTED[brng.randi_range(0, MUTED.size() - 1)])
				if brng.randf() < 0.22:
					block_col = Color(SHIRTS[brng.randi_range(0, SHIRTS.size() - 1)])
				var prng: = RandomNumberGenerator.new()
				prng.seed = 5003 + blk * 131 + c * 17 + r * 7
				var col: = block_col
				if prng.randf() < 0.3:
					col = Color(MUTED[prng.randi_range(0, MUTED.size() - 1)])
				elif prng.randf() < 0.1:
					col = Color(SHIRTS[prng.randi_range(0, SHIRTS.size() - 1)])
				col = col.lerp(Color(0.22, 0.22, 0.27), prng.randf_range(0.1, 0.42))
				shirt_cols.append(col)
				skin_cols.append(Color(SKINS[prng.randi_range(0, SKINS.size() - 1)]))
				empty.append(prng.randf() < 0.07)

				var CAPS: = ["#e8e4da", "#d94f3d", "#3f7fd9", "#2f3644", "#e8b53a"]
				cap_ok.append(prng.randf() < 0.24 and not empty[empty.size() - 1])
				cap_cols.append(Color(CAPS[prng.randi_range(0, CAPS.size() - 1)]))
				stand_up.append(prng.randf() < 0.45)
	n = base_pos.size()


	for st in stands:
		var org2: Vector3 = st[0]
		var dc2: Vector3 = st[1]
		var dr2: Vector3 = st[2]
		var back2: Vector3 = st[6]
		var along2: = dc2.abs()
		var top: Vector3 = org2 + dc2 * (st[3] - 1) * 0.5 + dr2 * (st[4] - 1)
		var width2: float = float(st[3]) + 1.0

		var walk: = MeshInstance3D.new()
		var wb: = BoxMesh.new()
		var wsz: Vector3 = Vector3.ONE * 4.2 + along2 * (width2 - 4.2)
		wsz.y = 0.5
		wb.size = wsz
		wb.material = step_mat
		walk.mesh = wb
		walk.position = top + Vector3(0, -0.27, 0) + back2 * (0.22 + 2.1)
		walk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(walk)

		var rim: = MeshInstance3D.new()
		var rb: = BoxMesh.new()
		var rsz: Vector3 = Vector3.ONE * 0.35 + along2 * (width2 - 0.35)
		rsz.y = 1.15
		rb.size = rsz
		rb.material = step_mat
		rim.mesh = rb
		rim.position = top + Vector3(0, 0.52, 0) + back2 * 4.15
		rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rim)

		var skirt: = MeshInstance3D.new()
		var kb: = BoxMesh.new()
		var ksz: Vector3 = Vector3.ONE * 0.8 + along2 * (width2 - 0.8)
		ksz.y = 0.75
		kb.size = ksz
		kb.material = step_mat
		skirt.mesh = kb
		skirt.position = org2 + dc2 * (st[3] - 1) * 0.5 + Vector3(0, -0.42, 0) + back2 * 0.35
		skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(skirt)

	var body_mesh: = CapsuleMesh.new()
	body_mesh.radius = 0.16
	body_mesh.height = 0.72
	var head_mesh: = SphereMesh.new()
	head_mesh.radius = 0.125
	head_mesh.height = 0.25

	var mmb: = MultiMesh.new()
	mmb.transform_format = MultiMesh.TRANSFORM_3D
	mmb.use_colors = true
	mmb.mesh = body_mesh
	mmb.instance_count = n
	var mmh: = MultiMesh.new()
	mmh.transform_format = MultiMesh.TRANSFORM_3D
	mmh.use_colors = true
	mmh.mesh = head_mesh
	mmh.instance_count = n
	for i in n:
		mmb.set_instance_color(i, shirt_cols[i])
		mmh.set_instance_color(i, skin_cols[i])
	mm_body = MultiMeshInstance3D.new()
	mm_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mm_body.multimesh = mmb
	mm_body.material_override = _mat()
	add_child(mm_body)
	mm_head = MultiMeshInstance3D.new()
	mm_head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mm_head.multimesh = mmh
	mm_head.material_override = _mat()
	add_child(mm_head)

	var cap_mesh: = CylinderMesh.new()
	cap_mesh.top_radius = 0.128
	cap_mesh.bottom_radius = 0.13
	cap_mesh.height = 0.1
	cap_mesh.radial_segments = 10
	var mmc: = MultiMesh.new()
	mmc.transform_format = MultiMesh.TRANSFORM_3D
	mmc.use_colors = true
	mmc.mesh = cap_mesh
	mmc.instance_count = n
	for i in n:
		mmc.set_instance_color(i, cap_cols[i])
	mm_cap = MultiMeshInstance3D.new()
	mm_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mm_cap.multimesh = mmc
	mm_cap.material_override = _mat()
	add_child(mm_cap)

func react(is_error: bool) -> void :
	if is_error:
		sil_t = 2.2
	else:
		ova_t = 2.8


const FLASH_SITES: = 60
var flash_t: = 0.0
var flash_mm: MultiMeshInstance3D = null
var flash_seats: Array[int] = []


static func flash_pulse(t: float, phase: float, period: float) -> float:
	var x: float = fposmod(t + phase, period)
	return 1.0 if x < 0.11 else 0.0

func start_flashes(dur: float) -> void :
	if n == 0:
		return
	if flash_mm == null:
		var sm: = SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.6
		sm.radial_segments = 8
		sm.rings = 4
		var fmat: = StandardMaterial3D.new()
		fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fmat.albedo_color = Color(1.0, 1.0, 0.92)
		sm.material = fmat
		var mm: = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sm
		mm.instance_count = FLASH_SITES
		flash_mm = MultiMeshInstance3D.new()
		flash_mm.name = "CameraFlashes"
		flash_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flash_mm.multimesh = mm
		add_child(flash_mm)

		var far: Array[int] = []
		for i in n:
			if not empty[i] and base_pos[i].z > 20.0:
				far.append(i)
		var step: int = maxi(1, far.size() / FLASH_SITES)
		var i: = 0
		while flash_seats.size() < FLASH_SITES and i < far.size():
			flash_seats.append(far[i])
			i += step
		while flash_seats.size() < FLASH_SITES:
			flash_seats.append(0)
	flash_t = dur

func _update_flashes(dt: float) -> void :
	if flash_mm == null:
		return
	if flash_t > 0.0:
		flash_t -= dt
	for k in FLASH_SITES:
		var on: float = 0.0
		if flash_t > 0.0:
			on = flash_pulse(time, float(k) * 0.37, 0.9 + float(k % 5) * 0.13)
		var p: Vector3 = base_pos[flash_seats[k]] + Vector3(0, 1.0, 0)
		flash_mm.multimesh.set_instance_transform(k, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * on), p))

func update(dt: float, rally_exc: float) -> void :
	time += dt
	_update_flashes(dt)
	exc = lerpf(exc, rally_exc, clampf(dt * 4.0, 0.0, 1.0))
	if ova_t > 0.0:
		ova_t -= dt
	if sil_t > 0.0:
		sil_t -= dt
	var ova: = force_ovation or ova_t > 0.0
	var frozen: = sil_t > 0.0 and not ova
	for i in n:
		if empty[i]:

			var tz: = Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), base_pos[i])
			mm_body.multimesh.set_instance_transform(i, tz)
			mm_head.multimesh.set_instance_transform(i, tz)
			mm_cap.multimesh.set_instance_transform(i, tz)
			continue
		var p: Vector3 = base_pos[i] + Vector3(0, 0.13, 0)
		var ph: float = phases[i]
		var y: = 0.0
		if frozen:
			y = -0.05
		elif ova:


			var boost: = 2.0 if stand_up[i] else 1.0
			y = absf(sin(time * 7.5 * jitters[i] - (p.x + p.z) * 0.35 + ph)) * 0.22 * boost
		else:
			var amp: float = 0.03 + 0.11 * exc
			var frq: float = 1.3 + 4.5 * exc
			y = sin(time * frq * jitters[i] + ph) * amp

		var body_sy: = 0.92
		if ova and stand_up[i]:
			body_sy = 1.16
		var t: = Transform3D(face_rot[i].scaled(Vector3(1.32, body_sy, 1.32)), p + Vector3(0, y + 0.28, 0))
		mm_body.multimesh.set_instance_transform(i, t)

		var ty: float = atan2(p.x - ball_pos.x, p.z - ball_pos.z) + PI
		head_yaw[i] = lerp_angle(head_yaw[i], ty, minf(1.0, dt * 3.5))
		var sy: = 1.0
		var bt: float = fmod(time * 0.31 * jitters[i] + phases[i] * 3.0, 6.5)
		if bt < 0.1:
			sy = 0.35
		var head_base: = y + 0.82
		if ova and stand_up[i]:
			head_base += 0.19
		t = Transform3D(Basis(Vector3.UP, head_yaw[i]).scaled(Vector3(1.18, sy * 1.18, 1.18)), p + Vector3(0, head_base, 0))
		mm_head.multimesh.set_instance_transform(i, t)

		if cap_ok[i]:
			mm_cap.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(0, head_base + 0.155, 0)))
		else:
			mm_cap.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), p))
