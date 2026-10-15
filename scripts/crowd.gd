class_name CrowdFX
extends Node3D

# Publico 3D reactivo: figuras low-poly (capsula+esfera) en gradas, con
# vaiven de fondo, ovacion con ola en puntos largos/ganados y silencio en errores.

var mm_body: MultiMeshInstance3D
var mm_head: MultiMeshInstance3D
var base_pos: Array[Vector3] = []
var face_rot: Array[Basis] = []
var head_yaw: Array[float] = []  # v0.35: giro de cabeza siguiendo la bola
var ball_pos := Vector3(0, 1.0, 11.885)  # v0.35: lo escribe match_view cada frame
var phases: Array[float] = []
var jitters: Array[float] = []
var shirt_cols: Array[Color] = []
var skin_cols: Array[Color] = []
var empty: Array[bool] = []  # v0.36: asientos vacios (grada real, no mural)
var ova_t := 0.0
var sil_t := 0.0
var time := 0.0
var exc := 0.0
var force_ovation := false
var n := 0

const SHIRTS := ["#d94f3d", "#e8b53a", "#3f7fd9", "#45a36b", "#e8e4da", "#c75ba8", "#7a5fd0", "#d97f3a", "#3fb8b8", "#b8c4d4", "#8a4f2e", "#4a5568"]
# v0.36: grada creible - base de tonos apagados (ropa real), acentos por bloques
const MUTED := ["#3a4250", "#4e5563", "#636b78", "#8b909b", "#a49f93", "#2f3644", "#756a5c", "#525a68"]
const SKINS := ["#f2c79b", "#d9a06b", "#a06b3f", "#7a4a28", "#f5d7b5", "#8a5a35"]

func _mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	return m

func build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261011
	# definicion de graderias: [origen, dir_fila, dir_grada, columnas, filas, rot]
	var stands: Array = []
	# grada lejana (z+, mirando a -z); las filas suben hacia la camara para no enterrarse en la grada
	stands.append([Vector3(-19.0, 3.05, 28.9), Vector3(1, 0, 0), Vector3(0, 0.78, -0.5), 39, 8, Basis(Vector3.UP, PI)])
	# gradas laterales (mirando al centro); idem hacia la pista
	stands.append([Vector3(14.3, 3.05, -2.0), Vector3(0, 0, 1), Vector3(-0.5, 0.78, 0), 29, 7, Basis(Vector3.UP, -PI * 0.5)])
	stands.append([Vector3(-14.3, 3.05, -2.0), Vector3(0, 0, 1), Vector3(0.5, 0.78, 0), 29, 7, Basis(Vector3.UP, PI * 0.5)])
	for st in stands:
		var org: Vector3 = st[0]
		var dc: Vector3 = st[1]
		var dr: Vector3 = st[2]
		for r in st[4]:
			for c in st[3]:
				var p: Vector3 = org + dc * c + dr * r
				p.x += rng.randf_range(-0.16, 0.16)
				p.z += rng.randf_range(-0.16, 0.16)
				base_pos.append(p)
				face_rot.append(st[5])
				head_yaw.append(atan2(p.x - ball_pos.x, p.z - ball_pos.z) + PI)
				phases.append(rng.randf_range(0.0, TAU))
				jitters.append(rng.randf_range(0.7, 1.3))
				# v0.36: color por bloques - cada bloque de grada tira a un tono
				# (como las aficiones reales), con variacion individual y ~1/9
				# de asientos vacios para que no sea un muro uniforme de puntos
				var blk := int(c / 7) + int(r / 2) * 8
				var brng := RandomNumberGenerator.new()
				brng.seed = 991 + blk * 37 + int(org.x * 3.0) + int(org.z)
				var block_col := Color(MUTED[brng.randi_range(0, MUTED.size() - 1)])
				if brng.randf() < 0.22:
					block_col = Color(SHIRTS[brng.randi_range(0, SHIRTS.size() - 1)])
				var prng := RandomNumberGenerator.new()
				prng.seed = 5003 + blk * 131 + c * 17 + r * 7
				var col := block_col
				if prng.randf() < 0.30:
					col = Color(MUTED[prng.randi_range(0, MUTED.size() - 1)])
				elif prng.randf() < 0.10:
					col = Color(SHIRTS[prng.randi_range(0, SHIRTS.size() - 1)])
				col = col.lerp(Color(0.22, 0.22, 0.27), prng.randf_range(0.10, 0.42))
				shirt_cols.append(col)
				skin_cols.append(Color(SKINS[prng.randi_range(0, SKINS.size() - 1)]))
				empty.append(prng.randf() < 0.11)
	n = base_pos.size()

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.16
	body_mesh.height = 0.72
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.125
	head_mesh.height = 0.25

	var mmb := MultiMesh.new()
	mmb.transform_format = MultiMesh.TRANSFORM_3D
	mmb.use_colors = true
	mmb.mesh = body_mesh
	mmb.instance_count = n
	var mmh := MultiMesh.new()
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

func react(is_error: bool) -> void:
	if is_error:
		sil_t = 2.2
	else:
		ova_t = 2.8

func update(dt: float, rally_exc: float) -> void:
	time += dt
	exc = lerpf(exc, rally_exc, clampf(dt * 4.0, 0.0, 1.0))
	if ova_t > 0.0:
		ova_t -= dt
	if sil_t > 0.0:
		sil_t -= dt
	var ova := force_ovation or ova_t > 0.0
	var frozen := sil_t > 0.0 and not ova
	for i in n:
		if empty[i]:
			# v0.36: asiento vacio - escala cero (deja huecos en la grada)
			var tz := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), base_pos[i])
			mm_body.multimesh.set_instance_transform(i, tz)
			mm_head.multimesh.set_instance_transform(i, tz)
			continue
		var p: Vector3 = base_pos[i]
		var ph: float = phases[i]
		var y := 0.0
		if frozen:
			y = -0.05 # bajon de decepcion
		elif ova:
			# ola: la fase depende de la posicion x+z
			y = absf(sin(time * 7.5 * jitters[i] - (p.x + p.z) * 0.35 + ph)) * 0.22
		else:
			var amp: float = 0.03 + 0.11 * exc
			var frq: float = 1.3 + 4.5 * exc
			y = sin(time * frq * jitters[i] + ph) * amp
		# figura sentada: cuerpo achatado, cabeza redonda justo encima
		var t := Transform3D(face_rot[i].scaled(Vector3(1.12, 0.78, 1.12)), p + Vector3(0, y + 0.28, 0))
		mm_body.multimesh.set_instance_transform(i, t)
		# v0.35: las cabezas siguen la bola y parpadean (micro-guiño por squash)
		var ty: float = atan2(p.x - ball_pos.x, p.z - ball_pos.z) + PI
		head_yaw[i] = lerp_angle(head_yaw[i], ty, minf(1.0, dt * 3.5))
		var sy := 1.0
		var bt: float = fmod(time * 0.31 * jitters[i] + phases[i] * 3.0, 6.5)
		if bt < 0.10:
			sy = 0.35
		t = Transform3D(Basis(Vector3.UP, head_yaw[i]).scaled(Vector3(1.0, sy, 1.0)), p + Vector3(0, y + 0.70, 0))
		mm_head.multimesh.set_instance_transform(i, t)
