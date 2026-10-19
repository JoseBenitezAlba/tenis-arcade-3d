class_name StaticShadows
extends RefCounted




static func spec(nz: float) -> Array:
	return [
		[Vector3(0.0, 0.055, nz + 0.3), Vector2(13.4, 0.9), 0.16], 
		[Vector3(-7.0, 0.055, nz), Vector2(1.5, 1.4), 0.3], 
		[Vector3(9.6, 0.055, nz), Vector2(2.4, 1.2), 0.26], 
		[Vector3(-9.6, 0.055, nz), Vector2(2.4, 1.2), 0.26], 
		[Vector3(-6.4, 0.055, nz), Vector2(0.5, 0.5), 0.3], 
		[Vector3(6.4, 0.055, nz), Vector2(0.5, 0.5), 0.3], 
	]

static func add_to(parent: Node3D, tex: Texture2D, nz: float) -> int:
	var n: = 0
	for it in spec(nz):
		var m: = StandardMaterial3D.new()
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color.a = it[2]
		var q: = MeshInstance3D.new()
		var qm: = QuadMesh.new()
		qm.size = it[1]
		qm.material = m
		q.mesh = qm
		q.rotation_degrees.x = -90
		q.position = it[0]
		parent.add_child(q)
		n += 1
	return n
