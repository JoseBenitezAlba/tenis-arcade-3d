class_name CourtBuilder
extends RefCounted

const L: = 23.77
const NZ: = L / 2.0

static func _mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

static func _box(sx: float, sy: float, sz: float, mat: Material) -> MeshInstance3D:
	var mi: = MeshInstance3D.new()
	var bm: = BoxMesh.new()
	bm.size = Vector3(sx, sy, sz)
	bm.material = mat
	mi.mesh = bm
	return mi



static func _fbx_figure(model: String, shirt: Color, pants: Color, skin: Color, anim: String, hair: = Color("#3a2a18"), head_scale: = 1.0) -> Node3D:
	var ps: PackedScene = null
	if ResourceLoader.exists(model):
		ps = load(model) as PackedScene
	if ps == null and model != "res://models/Casual_Hoodie.glb":
		return _fbx_figure("res://models/Casual_Hoodie.glb", shirt, pants, skin, anim, hair, head_scale)
	if ps == null:
		return Node3D.new()
	var inst: Node3D = ps.instantiate()
	inst.scale = Vector3.ONE * 0.806
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if ResourceLoader.exists("res://models/tennis_anims.tres"):
		var tl: AnimationLibrary = load("res://models/tennis_anims.tres")

		var fixed: = AnimationLibrary.new()
		var sk0: = inst.find_child("Skeleton3D", true, false) as Skeleton3D
		for an in tl.get_animation_list():
			var an_res: Animation = tl.get_animation(an).duplicate()
			if sk0 != null:
				var skp: String = str(ap.get_node(ap.root_node).get_path_to(sk0))
				for ti in an_res.get_track_count():
					var tp: = str(an_res.track_get_path(ti))
					var bone: String = tp.get_slice(":", 1) if ":" in tp else ""
					if bone != "" and sk0.find_bone(bone) < 0:
						var alt: String = bone.replace(".", "_")
						if alt.begins_with("Fist"):
							alt = "Wrist" + alt.trim_prefix("Fist")
						if bone == "Body" and sk0.find_bone("Body_2") >= 0:
							alt = "Body_2"
						if sk0.find_bone(alt) >= 0:
							bone = alt
					if bone != "":
						an_res.track_set_path(ti, NodePath(skp + ":" + bone))
			fixed.add_animation(an, an_res)
		ap.add_animation_library("tennis", fixed)
	var stack: = [inst]
	while stack.size() > 0:
		var n = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is MeshInstance3D and n.mesh:
			for i in n.mesh.get_surface_count():
				var m = n.mesh.surface_get_material(i)
				var nm: String = (m.resource_name if m else "").to_lower()
				var col: = Color.WHITE
				if "skin" in nm or "face" in nm: col = skin
				elif "shirt" in nm: col = shirt
				elif "pants" in nm or "belt" in nm: col = pants
				elif "hair" in nm: col = hair
				else: continue
				var mm: = StandardMaterial3D.new()
				mm.albedo_color = col
				mm.roughness = 0.8
				n.set_surface_override_material(i, mm)
	ap.play(anim, 0.0)

	ap.seek(randf() * 2.0, true)
	if head_scale != 1.0:
		var sk: = inst.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk:
			var hb: = sk.find_bone("Head")
			if hb >= 0:
				sk.set_bone_pose_scale(hb, Vector3.ONE * head_scale)
	return inst

static func _figure(shirt_c: Color, skin_c: Color, shorts_c: Color, pose: String) -> Node3D:
	var root: = Node3D.new()
	var shirt: = _mat(shirt_c)
	var skin: = _mat(skin_c)
	var shorts: = _mat(shorts_c)
	var mk: = func(r: float, h: float, mat: Material) -> MeshInstance3D:
		var mi: = MeshInstance3D.new()
		var cm: = CapsuleMesh.new()
		cm.radius = r
		cm.height = h
		cm.material = mat
		mi.mesh = cm
		return mi
	var hip_y: = 0.94
	if pose == "seated":
		hip_y = 0.0
	elif pose == "kneel":
		hip_y = 0.55
	var pelvis: = MeshInstance3D.new()
	var pb: = BoxMesh.new()
	pb.size = Vector3(0.26, 0.14, 0.17)
	pb.material = shorts
	pelvis.mesh = pb
	pelvis.position = Vector3(0, hip_y, 0)
	root.add_child(pelvis)
	var torso: MeshInstance3D = mk.call(0.14, 0.46, shirt)
	torso.position = Vector3(0, hip_y + 0.24, 0)
	torso.scale = Vector3(1.1, 1.0, 0.75)
	root.add_child(torso)
	var head: = MeshInstance3D.new()
	var hs: = SphereMesh.new()
	hs.radius = 0.09
	hs.height = 0.19
	hs.material = skin
	head.mesh = hs
	head.position = Vector3(0, hip_y + 0.56, 0.01)
	root.add_child(head)
	for s in [-1, 1]:
		var arm: MeshInstance3D = mk.call(0.05, 0.55, skin)
		arm.position = Vector3(s * 0.19, hip_y + 0.22, 0.02)
		arm.rotation.z = s * 0.15
		root.add_child(arm)
		var hip: = Node3D.new()
		hip.position = Vector3(s * 0.09, hip_y - 0.02, 0)
		root.add_child(hip)
		var thigh: MeshInstance3D = mk.call(0.07, 0.4, shorts if pose != "standing" else skin)
		thigh.position = Vector3(0, -0.19, 0)
		hip.add_child(thigh)
		var knee: = Node3D.new()
		knee.position = Vector3(0, -0.4, 0)
		hip.add_child(knee)
		var shin: MeshInstance3D = mk.call(0.055, 0.4, skin)
		shin.position = Vector3(0, -0.19, 0)
		knee.add_child(shin)
		match pose:
			"seated":
				hip.rotation.x = - PI / 2.0 + 0.15
				knee.rotation.x = PI / 2.0 - 0.15
			"kneel":
				hip.rotation.x = 0.9 if s < 0 else -1.2
				knee.rotation.x = 1.5 if s < 0 else 0.1
			_:
				pass
	return root

static func build(surface: String, day_v = false) -> Node3D:

	var tod: int = (0 if day_v else 1) if day_v is bool else int(day_v)
	var root: = Node3D.new()
	root.name = "Court"


	var ground_mat: = StandardMaterial3D.new()
	ground_mat.albedo_texture = TexGen.ground_texture(surface, tod == 1)
	ground_mat.uv1_scale = Vector3(4, 4, 4)
	ground_mat.roughness = 0.95
	var ground: = MeshInstance3D.new()
	var gp: = PlaneMesh.new()
	gp.size = Vector2(56, 56)
	gp.material = ground_mat
	ground.mesh = gp
	ground.position = Vector3(0, 0, L / 2.0)
	root.add_child(ground)


	var court_len: = L + 7.6
	var court_mat: = StandardMaterial3D.new()
	court_mat.albedo_texture = TexGen.court_texture(surface, tod == 1)
	court_mat.roughness = 0.62
	court_mat.metallic_specular = 0.1
	var court: = MeshInstance3D.new()
	var cb: = PlaneMesh.new()
	cb.size = Vector2(14.4, court_len)
	court_mat.roughness = 0.62
	cb.material = court_mat
	court.mesh = cb
	court.position = Vector3(0, 0.06, (L + 3.6 - 4.0) / 2.0)
	root.add_child(court)




	var post_mat: = _mat(Color("#202634"))
	for xp in [-6.4, 6.4]:

		var post: = MeshInstance3D.new()
		var cyl: = CylinderMesh.new()
		cyl.top_radius = 0.075
		cyl.bottom_radius = 0.075
		cyl.height = 1.07
		cyl.material = post_mat
		post.mesh = cyl
		post.position = Vector3(xp, 0.535, NZ)
		root.add_child(post)
		var cap: = MeshInstance3D.new()
		var capm: = CylinderMesh.new()
		capm.top_radius = 0.085
		capm.bottom_radius = 0.085
		capm.height = 0.03
		capm.material = _mat(Color("#e8e8e8"))
		cap.mesh = capm
		cap.position = Vector3(xp, 1.085, NZ)
		root.add_child(cap)
	var net_mat: = StandardMaterial3D.new()
	net_mat.albedo_texture = TexGen.net_texture()
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st: = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: = 48
	for i in segs:
		var x0: = -6.4 + 12.8 * float(i) / segs
		var x1: = -6.4 + 12.8 * float(i + 1) / segs

		var yt0: = 0.914 + 0.153 * pow(x0 / 6.4, 2.0)
		var yt1: = 0.914 + 0.153 * pow(x1 / 6.4, 2.0)
		var u0: = float(i) / segs
		var u1: = float(i + 1) / segs
		st.set_uv(Vector2(u0, 1.0));st.add_vertex(Vector3(x0, 0.0, NZ))
		st.set_uv(Vector2(u1, 1.0));st.add_vertex(Vector3(x1, 0.0, NZ))
		st.set_uv(Vector2(u0, 0.0));st.add_vertex(Vector3(x0, yt0, NZ))
		st.set_uv(Vector2(u0, 0.0));st.add_vertex(Vector3(x0, yt0, NZ))
		st.set_uv(Vector2(u1, 1.0));st.add_vertex(Vector3(x1, 0.0, NZ))
		st.set_uv(Vector2(u1, 0.0));st.add_vertex(Vector3(x1, yt1, NZ))
	st.set_material(net_mat)
	var net: = MeshInstance3D.new()
	net.mesh = st.commit()
	net.name = "NetMesh"
	root.add_child(net)

	var strap_mat: = _mat(Color("#ffffff"))
	strap_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var strap: = _box(0.075, 0.92, 0.04, strap_mat)
	strap.position = Vector3(0, 0.46, NZ)
	root.add_child(strap)



	var base_mat: = _mat(Color("#262c3a"))
	for xp in [-6.4, 6.4]:
		var pb: = MeshInstance3D.new()
		var pbm: = CylinderMesh.new()
		pbm.top_radius = 0.14
		pbm.bottom_radius = 0.19
		pbm.height = 0.07
		pbm.material = base_mat
		pb.mesh = pbm
		pb.position = Vector3(xp, 0.095, NZ)
		root.add_child(pb)
	var cable_mat: = _mat(Color("#f6f6f6"))
	var cn: = 24
	for ci in cn:
		var x0: = -6.4 + 12.8 * float(ci) / cn
		var x1: = -6.4 + 12.8 * float(ci + 1) / cn
		var y0: = 0.914 + 0.153 * pow(x0 / 6.4, 2.0) + 0.012
		var y1: = 0.914 + 0.153 * pow(x1 / 6.4, 2.0) + 0.012
		var seg: = _box(x1 - x0 + 0.02, 0.045, 0.05, cable_mat)
		seg.position = Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, NZ)
		seg.rotation.z = atan2(y1 - y0, x1 - x0)
		root.add_child(seg)


	var ad_names: = ["DEUCE", "COURT CLUB", "COURT", "TENNIS", "DEUCE", "COURT CLUB", "TENNIS", "COURT"]
	var ad_cols: = [Color("#0c3a72"), Color("#11457f"), Color("#0a3568"), Color("#124a86"), Color("#0d3f78"), Color("#0b5d8f"), Color("#10406f"), Color("#0c3a72")]
	var wall_z: = L + 5.2
	var back_wall: = _box(40, 2.0, 0.4, _mat(Color("#0a2550")))
	back_wall.position = Vector3(0, 1.0, wall_z + 0.2)
	root.add_child(back_wall)
	var wall_trim: = _box(40, 0.08, 0.5, _mat(Color("#dbe8ff")))
	wall_trim.position = Vector3(0, 2.02, wall_z + 0.02)
	root.add_child(wall_trim)
	for bx in [-2.1, 2.1]:
		var brand: = Label3D.new()
		brand.text = "COURT" if bx > 0.0 else "CLUB"
		brand.font_size = 100
		brand.modulate = Color("#f4f8ff")
		brand.outline_size = 12
		brand.outline_modulate = Color(0.01, 0.05, 0.16, 0.9)
		brand.position = Vector3(bx, 1.55, wall_z - 0.13)
		brand.rotation_degrees.y = 180
		root.add_child(brand)
	var emblem_ring: = MeshInstance3D.new()
	var et: = TorusMesh.new()
	et.inner_radius = 0.3
	et.outer_radius = 0.4
	et.ring_segments = 10
	et.rings = 24
	et.material = _mat(Color("#f4f8ff"))
	emblem_ring.mesh = et
	emblem_ring.position = Vector3(0, 1.55, wall_z - 0.18)
	emblem_ring.rotation_degrees.x = 90.0
	root.add_child(emblem_ring)
	var emblem_ball: = MeshInstance3D.new()
	var eb: = SphereMesh.new()
	eb.radius = 0.17
	eb.height = 0.34
	eb.radial_segments = 20
	eb.rings = 10
	var ebm: = StandardMaterial3D.new()
	ebm.albedo_color = Color("#d8f040")
	ebm.emission_enabled = true
	ebm.emission = Color("#d8f040")
	ebm.emission_energy_multiplier = 0.5
	eb.material = ebm
	emblem_ball.mesh = eb
	emblem_ball.position = Vector3(0, 1.55, wall_z - 0.14)
	root.add_child(emblem_ball)
	for bx in [-12.6, 12.6]:
		var wall_side: = Label3D.new()
		wall_side.text = "DEUCE" if bx < 0 else "PRO TOUR"
		wall_side.font_size = 78
		wall_side.modulate = Color("#dfe9ff")
		wall_side.outline_size = 9
		wall_side.outline_modulate = Color(0.01, 0.05, 0.16, 0.9)
		wall_side.position = Vector3(bx, 1.52, wall_z - 0.13)
		wall_side.rotation_degrees.y = 180
		root.add_child(wall_side)
	var i: = 0
	var x: = -18.3
	while x < 18.4:
		var board: = _box(6.0, 1.05, 0.12, _mat(ad_cols[i % ad_cols.size()]))
		board.position = Vector3(x + 3.0, 0.525, wall_z)
		root.add_child(board)
		var lbl: = Label3D.new()
		lbl.text = ad_names[i % ad_names.size()]
		lbl.font_size = 78
		lbl.modulate = Color.WHITE
		lbl.outline_size = 7
		lbl.outline_modulate = Color(0, 0, 0, 0.6)
		lbl.position = Vector3(x + 3.0, 0.525, wall_z - 0.09)
		lbl.rotation_degrees.y = 180
		root.add_child(lbl)
		x += 6.2
		i += 1




	var stand_dark: = _mat(Color("#070c17"))
	var crowd_mat: = StandardMaterial3D.new()
	crowd_mat.albedo_texture = TexGen.tier_texture()
	crowd_mat.albedo_color = Color(0.6, 0.61, 0.66)
	crowd_mat.uv1_scale = Vector3(1, 1, 1)
	crowd_mat.roughness = 1.0
	crowd_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crowd_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var stands_far: = _box(44, 8.5, 6.0, stand_dark)
	stands_far.position = Vector3(0, 6.25, wall_z + 11.0)
	root.add_child(stands_far)
	var far_face: = MeshInstance3D.new()
	var fq: = QuadMesh.new()
	fq.size = Vector2(44, 8.5)
	fq.material = crowd_mat
	far_face.mesh = fq
	far_face.position = Vector3(0, 6.25, wall_z + 7.3)
	far_face.rotation.y = PI
	root.add_child(far_face)
	for ti in 4:
		var ty: float = 2.3 + ti * 2.0
		var ledge: = _box(44, 0.22, 0.75, stand_dark)
		ledge.position = Vector3(0, ty, wall_z + 7.0)
		root.add_child(ledge)
		var rail: = _box(44, 0.05, 0.05, _mat(Color("#6f7d92")))
		rail.position = Vector3(0, ty + 0.58, wall_z + 6.68)
		root.add_child(rail)
	var far_roof: = _box(46, 0.4, 7.0, stand_dark)
	far_roof.position = Vector3(0, 10.6, wall_z + 12.0)
	root.add_child(far_roof)
	var ribbon_mat: = StandardMaterial3D.new()
	ribbon_mat.albedo_color = Color("#cfe6ff")
	ribbon_mat.emission_enabled = tod == 1
	ribbon_mat.emission = Color("#cfe6ff")
	ribbon_mat.emission_energy_multiplier = 1.35
	var walkway_mat: = _mat(Color("#1a2030"))
	var mid_walk: = _box(43.5, 0.7, 2.0, walkway_mat)
	mid_walk.position = Vector3(0, 6.25, wall_z + 6.6)
	root.add_child(mid_walk)
	var mid_rail: = _box(43.5, 0.05, 0.05, _mat(Color("#6f7d92")))
	mid_rail.position = Vector3(0, 6.7, wall_z + 5.55)
	root.add_child(mid_rail)
	var mid_ribbon: = _box(43.5, 0.06, 0.07, ribbon_mat)
	mid_ribbon.position = Vector3(0, 5.9, wall_z + 5.58)
	root.add_child(mid_ribbon)
	var roof_fascia: = _box(45.0, 0.6, 0.9, walkway_mat)
	roof_fascia.position = Vector3(0, 10.25, wall_z + 7.05)
	root.add_child(roof_fascia)
	var roof_strip: = _box(45.0, 0.06, 0.08, ribbon_mat)
	roof_strip.position = Vector3(0, 10.0, wall_z + 6.55)
	root.add_child(roof_strip)
	var roof_light: = StandardMaterial3D.new()
	roof_light.albedo_color = Color("#fff2d0")
	roof_light.emission_enabled = true
	roof_light.emission = Color("#fff2d0")
	roof_light.emission_energy_multiplier = 2.4
	for lx in [-16.0, -5.0, 6.0, 17.0]:
		var strip: = _box(2.4, 0.06, 0.18, roof_light)
		strip.position = Vector3(lx, 10.37, wall_z + 9.4)
		root.add_child(strip)
	# Near end is a courtside advertising barrier with open stepped seating behind it.
	for ni in 8:
		var nx: float = -15.4 + ni * 4.4
		var near_board: = _box(4.2, 1.0, 0.12, _mat(ad_cols[ni]))
		near_board.position = Vector3(nx, 0.5, -8.8)
		root.add_child(near_board)
		var near_label: = Label3D.new()
		near_label.text = ad_names[ni]
		near_label.font_size = 64
		near_label.modulate = Color.WHITE
		near_label.outline_size = 6
		near_label.position = Vector3(nx, 0.5, -8.71)
		root.add_child(near_label)
	var side_wall_mat: = _mat(Color("#123f7a"))
	var side_trim_mat: = _mat(Color("#dbe8ff"))
	for sx in [-12.0, 12.0]:
		var side_wall: = _box(0.16, 0.9, 30.0, side_wall_mat)
		side_wall.position = Vector3(sx, 0.45, 13.0)
		root.add_child(side_wall)
		var side_trim: = _box(0.2, 0.06, 30.0, side_trim_mat)
		side_trim.position = Vector3(sx, 0.92, 13.0)
		root.add_child(side_trim)
		var outer: = _box(12.0, 0.02, 30.0, _mat(Color("#1d3a1e")))
		outer.position = Vector3(signf(sx) * 18.0, 0.02, 13.0)
		root.add_child(outer)
		var si: = 0
		var sz: = -1.0
		while sz < L + 8.0:
			var slbl: = Label3D.new()
			slbl.text = ["DEUCE", "COURT CLUB", "COURT", "TENNIS"][si % 4]
			slbl.font_size = 44
			slbl.modulate = Color("#f2f6ff")
			slbl.outline_size = 6
			slbl.outline_modulate = Color(0, 0.02, 0.08, 0.85)
			slbl.position = Vector3(sx - signf(sx) * 0.1, 0.42, sz)
			slbl.rotation_degrees.y = - signf(sx) * 90.0
			root.add_child(slbl)
			sz += 5.2
			si += 1

	var plinth_mat: = _mat(Color("#16252c"))
	for pz in [-12.0, wall_z + 11.0]:
		var plinth: = _box(40, 2.5, 6.0, plinth_mat)
		plinth.position = Vector3(0, 1.25, pz)
		root.add_child(plinth)
	for sx in [-24.0, 24.0]:
		var stands_side: = _box(6.0, 8.5, 34.0, stand_dark)
		stands_side.position = Vector3(sx, 6.25, L / 2.0)
		root.add_child(stands_side)
		var side_face: = MeshInstance3D.new()
		var sq: = QuadMesh.new()
		sq.size = Vector2(34, 8.5)
		sq.material = crowd_mat
		side_face.mesh = sq
		side_face.position = Vector3(sx - signf(sx) * 3.55, 6.25, L / 2.0)
		side_face.rotation.y = - signf(sx) * PI / 2.0
		root.add_child(side_face)
		for ti in 4:
			var ty: float = 2.3 + ti * 2.0
			var ledge: = _box(0.75, 0.22, 34.0, stand_dark)
			ledge.position = Vector3(sx - signf(sx) * 3.85, ty, L / 2.0)
			root.add_child(ledge)
			var rail: = _box(0.05, 0.05, 34.0, _mat(Color("#6f7d92")))
			rail.position = Vector3(sx - signf(sx) * 4.1, ty + 0.58, L / 2.0)
			root.add_child(rail)
		var side_roof: = _box(7.0, 0.4, 36.0, stand_dark)
		side_roof.position = Vector3(sx, 10.6, L / 2.0)
		root.add_child(side_roof)
		var side_plinth: = _box(6.0, 2.5, 34.0, plinth_mat)
		side_plinth.position = Vector3(sx, 1.25, L / 2.0)
		root.add_child(side_plinth)


	var tower_mat: = _mat(Color("#1a2030"))
	var lamp_mat: = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color("#fff6d8")
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color("#fff6d8")
	if tod == 0:
		lamp_mat.albedo_color = Color("#3a4149")
		lamp_mat.emission_enabled = false
	elif tod == 2:
		lamp_mat.albedo_color = Color("#3a4149")
		lamp_mat.emission_energy_multiplier = 0.35
	else:
		lamp_mat.albedo_color = Color("#131822")
		lamp_mat.emission_enabled = false
	for tx in [-12.0, 12.0]:
		for tz in [-4.0, L + 4.0]:
			var tower: = _box(0.45, 11.2, 0.45, tower_mat)
			tower.position = Vector3(tx, 5.6, tz)
			root.add_child(tower)
			var lamp: = _box(3.6, 2.3, 0.32, lamp_mat)
			lamp.position = Vector3(tx, 11.0, tz)
			root.add_child(lamp)



	if tod == 1:
		var cell_mat: = StandardMaterial3D.new()
		cell_mat.albedo_color = Color("#fffbe8")
		cell_mat.emission_enabled = true
		cell_mat.emission = Color("#fffbe8")
		cell_mat.emission_energy_multiplier = 1.5
		var cone_mat: = StandardMaterial3D.new()
		cone_mat.albedo_color = Color(1.0, 0.97, 0.85, 0.012)
		cone_mat.emission_enabled = true
		cone_mat.emission = Color(1.0, 0.97, 0.85)
		cone_mat.emission_energy_multiplier = 0.02
		cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cone_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var glow_tex: = TexGen.glow_texture()
		for tx in [-12.0, 12.0]:
			for tz in [-4.0, L + 4.0]:
				var zface: float = 0.17 if tz < NZ else -0.17
				for gx in 5:
					for gy in 4:
						var cell: = _box(0.56, 0.4, 0.07, cell_mat)
						cell.set_meta("flood", "cell")
						cell.position = Vector3(tx + (gx - 2) * 0.68, 11.0 + (gy - 1.5) * 0.52, tz + zface)
						root.add_child(cell)
				var from: = Vector3(tx, 10.7, tz)
				var to: = Vector3(tx * 0.35, 0.06, NZ)
				var cone: = MeshInstance3D.new()
				cone.set_meta("flood", "cone")
				var cm: = CylinderMesh.new()
				cm.top_radius = 0.7
				cm.bottom_radius = 4.4
				cm.height = from.distance_to(to)
				cm.material = cone_mat
				cone.mesh = cm
				cone.position = (from + to) * 0.5
				cone.look_at_from_position((from + to) * 0.5, to, Vector3.UP)
				cone.rotate_object_local(Vector3.RIGHT, PI / 2.0)
				root.add_child(cone)
				var halo: = Sprite3D.new()
				halo.texture = glow_tex
				halo.pixel_size = 0.06
				halo.position = Vector3(tx, 11.0, tz)
				halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				halo.no_depth_test = true
				halo.modulate = Color(1.0, 0.97, 0.86, 0.4)
				halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(halo)


	var env: = WorldEnvironment.new()
	var e: = Environment.new()
	var sky: = Sky.new()
	var skym: = ProceduralSkyMaterial.new()
	if tod == 0:
		var pano: = PanoramaSkyMaterial.new()
		pano.panorama = TexGen.sky_panorama()
		sky.sky_material = pano
	elif tod == 2:
		skym.sky_top_color = Color("#5a6ab0")
		skym.sky_horizon_color = Color("#ffc08a")
		skym.ground_bottom_color = Color("#241d33")
		skym.ground_horizon_color = Color("#c96a4a")
		sky.sky_material = skym
	else:
		var pano_n: = PanoramaSkyMaterial.new()
		pano_n.panorama = TexGen.night_sky_panorama()
		sky.sky_material = pano_n
	e.sky = sky
	e.background_mode = Environment.BG_SKY
	if tod == 1:
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color("#b9c7e6")
		e.ambient_light_energy = 1.25
	else:
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = 0.46 if tod == 0 else 1.15
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0 if tod == 0 else (1.04 if tod == 2 else 1.02)
	if tod == 1:
		e.glow_enabled = true
		e.glow_intensity = 0.5
		e.glow_bloom = 0.03
		e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
		e.glow_hdr_threshold = 0.9
		e.adjustment_enabled = true
		e.adjustment_brightness = 1.03
		e.adjustment_contrast = 1.07
		e.adjustment_saturation = 1.1
		e.fog_enabled = true
		e.fog_light_color = Color("#0a1530")
		e.fog_light_energy = 0.45
		e.fog_density = 0.0022
		e.fog_sky_affect = 0.0
	env.environment = e
	root.add_child(env)

	var sun: = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 168, 0) if tod != 2 else Vector3(-24, 148, 0)
	sun.light_energy = 0.82 if tod == 0 else (1.25 if tod == 2 else 0.55)
	sun.light_color = Color("#fff4e0") if tod == 0 else (Color("#ffc98a") if tod == 2 else Color("#c9d8ff"))
	sun.shadow_enabled = tod != 1
	sun.directional_shadow_max_distance = 65.0
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 1.2
	root.add_child(sun)



	if tod == 1:
		for sx in [-7.0, 7.0]:
			for sz in [NZ - 5.5, NZ + 5.5]:
				var spot: = SpotLight3D.new()
				spot.position = Vector3(sx, 11.0, sz)
				spot.rotation_degrees = Vector3(-90, 0, 0)
				spot.spot_range = 56.0
				spot.spot_angle = 86.0
				spot.spot_attenuation = 0.55
				spot.light_energy = 0.72
				spot.light_color = Color("#fff2d0")
				root.add_child(spot)


	var staff_frame: = _mat(Color("#cfd5dd"))
	var white: = _mat(Color("#e8e8e8"))

	var chair: = Node3D.new()
	chair.position = Vector3(-7.0, 0, NZ)
	chair.rotation.y = 0.0
	root.add_child(chair)
	for lx in [-0.35, 0.35]:
		for lz in [-0.3, 0.3]:
			var leg: = MeshInstance3D.new()
			var lc: = CylinderMesh.new()
			lc.top_radius = 0.035
			lc.bottom_radius = 0.035
			lc.height = 2.3
			lc.material = staff_frame
			leg.mesh = lc
			leg.position = Vector3(lx, 1.15, lz)
			leg.rotation.z = lx * 0.12
			leg.rotation.x = - lz * 0.12
			chair.add_child(leg)
	for ry in [0.45, 1.25, 1.95]:
		for rz in [-0.3, 0.3]:
			var xrail: = _box(0.76, 0.035, 0.035, staff_frame)
			xrail.position = Vector3(0, ry, rz)
			chair.add_child(xrail)
		for rx in [-0.35, 0.35]:
			var zrail: = _box(0.035, 0.035, 0.64, staff_frame)
			zrail.position = Vector3(rx, ry, 0)
			chair.add_child(zrail)
	var plat: = _box(0.9, 0.06, 0.8, white)
	plat.position = Vector3(0, 2.0, 0)
	chair.add_child(plat)
	var seat: = _box(0.6, 0.08, 0.55, staff_frame)
	seat.position = Vector3(0, 2.1, 0)
	chair.add_child(seat)
	var sback: = _box(0.6, 0.5, 0.08, staff_frame)
	sback.position = Vector3(-0.28, 2.4, 0)
	chair.add_child(sback)
	var desk: = _box(0.6, 0.05, 0.35, staff_frame)
	desk.position = Vector3(0.42, 2.35, 0.0)
	chair.add_child(desk)
	var canopy: = MeshInstance3D.new()
	var cm: = CylinderMesh.new()
	cm.top_radius = 0.85
	cm.bottom_radius = 0.85
	cm.height = 0.05
	cm.radial_segments = 20
	cm.material = white
	canopy.mesh = cm
	canopy.position = Vector3(0, 3.4, 0)
	chair.add_child(canopy)
	var pole: = _box(0.04, 1.1, 0.04, staff_frame)
	pole.position = Vector3(0, 2.85, 0)
	chair.add_child(pole)
	var step1: = _box(0.5, 0.04, 0.15, white)
	step1.position = Vector3(0.45, 1.0, 0)
	chair.add_child(step1)
	var umpire_model: String = "res://models/OldClassy_Male.fbx"
	if not ResourceLoader.exists(umpire_model):
		umpire_model = "res://models/Casual_Hoodie.glb"
	var umpire: = _fbx_figure(umpire_model, Color("#1c2430"), Color("#151a22"), Color("#d9a37a"), "tennis/Sitting_Idle", Color("#2a2018"), 1.0)
	umpire.scale = Vector3.ONE * 1.28
	umpire.position = Vector3(0, 2.08, 0)
	umpire.rotation.y = PI / 2.0
	chair.add_child(umpire)
	var _watchers: = []
	_watchers.append({"fig": umpire, "yaw": PI / 2.0, "body": 0.45})

	var judge_cols: = [Color("#2f6fb5"), Color("#2f6fb5"), Color("#2f6fb5"), Color("#2f6fb5")]
	var jpos: = [Vector3(-8.4, 0, NZ - 2.0), Vector3(8.4, 0, NZ + 2.0), Vector3(-6.7, 0, L + 3.45), Vector3(6.7, 0, L + 3.45)]
	for ji in 4:
		var jchair: = Node3D.new()
		jchair.position = jpos[ji]
		jchair.rotation.y = - signf(jpos[ji].x) * PI / 2.0
		root.add_child(jchair)
		for jlx in [-0.22, 0.22]:
			for jlz in [-0.19, 0.19]:
				var jleg: = _box(0.04, 0.4, 0.04, white)
				jleg.position = Vector3(jlx, 0.2, jlz)
				jchair.add_child(jleg)
		var jseat: = _box(0.5, 0.06, 0.45, white)
		jseat.position = Vector3(0, 0.42, 0)
		jchair.add_child(jseat)
		var jback: = _box(0.5, 0.4, 0.06, _mat(Color("#8e2f2f")))
		jback.position = Vector3(0, 0.62, -0.22)
		jchair.add_child(jback)
		var judge: = _fbx_figure("res://models/Suit_Male.fbx", judge_cols[ji], Color("#151518"), Color("#c98d62"), "tennis/Sitting_Idle", Color("#2a2018"), 0.85)
		judge.set_script(load("res://scripts/line_judge.gd"))
		judge.add_to_group("line_judges")
		judge.scale = Vector3.ONE * 0.9
		judge.position = Vector3(0, 0.39, 0.02)
		jchair.add_child(judge)
		_watchers.append({"fig": judge, "yaw": jchair.rotation.y, "body": 0.35})


	var kid_pos: = [Vector3(-5.9, 0, -2.95), Vector3(5.9, 0, -2.95), Vector3(-8.4, 0, L + 1.5), Vector3(8.4, 0, L + 1.5)]
	for ki in 4:
		var kid: = _fbx_figure("res://models/Casual_Hoodie.glb", Color("#2f6fb5"), Color("#f2f2f2"), Color("#d9a37a"), "Idle_Sword", Color("#2a2018"), 0.42)
		kid.scale = Vector3.ONE * 0.55
		kid.position = kid_pos[ki]
		kid.rotation.y = 0.0 if kid_pos[ki].z < NZ else PI
		root.add_child(kid)
		_watchers.append({"fig": kid, "yaw": kid.rotation.y, "body": 0.25})

	for kx in [-5.8, 5.8]:
		var kpost: = _fbx_figure("res://models/Casual_Hoodie.glb", Color("#2f6fb5"), Color("#f2f2f2"), Color("#d9a37a"), "Idle_Sword", Color("#2a2018"), 0.42)
		kpost.scale = Vector3.ONE * 0.72
		kpost.position = Vector3(signf(kx) * 8.1, 0, NZ + 0.35)
		kpost.rotation.y = - signf(kx) * PI / 2.0
		root.add_child(kpost)
		_watchers.append({"fig": kpost, "yaw": kpost.rotation.y, "body": 0.25})
	var kmid: = _fbx_figure("res://models/Casual_Hoodie.glb", Color("#2f6fb5"), Color("#f2f2f2"), Color("#d9a37a"), "Idle_Sword", Color("#2a2018"), 0.42)
	kmid.scale = Vector3.ONE * 0.72
	kmid.position = Vector3(0, 0, NZ + 0.55)
	kmid.rotation.y = PI
	root.add_child(kmid)
	_watchers.append({"fig": kmid, "yaw": kmid.rotation.y, "body": 0.25})

	for s in [-1, 1]:
		var bench: = Node3D.new()
		bench.position = Vector3(s * 10.8, 0, NZ)
		bench.rotation.y = - s * PI / 2.0
		root.add_child(bench)
		var bseat: = _box(2.2, 0.07, 0.55, white)
		bseat.position = Vector3(0, 0.45, 0)
		bench.add_child(bseat)
		var bback: = _box(2.2, 0.35, 0.06, white)
		bback.position = Vector3(0, 0.65, -0.26)
		bench.add_child(bback)
		for bx in [-0.9, 0.9]:
			var bleg: = _box(0.08, 0.45, 0.4, staff_frame)
			bleg.position = Vector3(bx, 0.22, 0)
			bench.add_child(bleg)
		var bcanopy: = _box(2.3, 0.05, 1.0, _mat(Color("#e9eef4")))
		bcanopy.position = Vector3(0, 1.95, 0.05)
		bench.add_child(bcanopy)
		for px in [-1.02, 1.02]:
			for pz in [-0.38, 0.42]:
				var bpost: = _box(0.05, 1.5, 0.05, _mat(Color("#b9c4d0")))
				bpost.position = Vector3(px, 1.2, pz)
				bench.add_child(bpost)
		var bag: = MeshInstance3D.new()
		var bag_mesh: = CapsuleMesh.new()
		bag_mesh.radius = 0.14
		bag_mesh.height = 0.65
		bag_mesh.material = _mat(Color("#7c2430") if s < 0 else Color("#244568"))
		bag.mesh = bag_mesh
		bag.rotation.z = PI / 2.0
		bag.position = Vector3(0.55, 0.63, 0)
		bench.add_child(bag)
		for strap_x in [0.35, 0.75]:
			var bag_strap: = _box(0.035, 0.025, 0.29, _mat(Color("#15202b")))
			bag_strap.position = Vector3(strap_x, 0.765, 0)
			bench.add_child(bag_strap)
		for slat_y in [0.51, 0.61, 0.71, 0.81]:
			var slat_gap: = _box(2.16, 0.012, 0.065, _mat(Color("#839699")))
			slat_gap.position = Vector3(0, slat_y, -0.26)
			bench.add_child(slat_gap)

		var towel: = _box(0.55, 0.3, 0.05, _mat(Color("#ffd86b")))
		towel.position = Vector3(-0.45, 0.7, -0.24)
		towel.name = "BenchTowel"
		bench.add_child(towel)
		var towel_hang: = _box(0.55, 0.22, 0.04, _mat(Color("#f0b94a")))
		towel_hang.position = Vector3(-0.45, 0.58, -0.3)
		towel_hang.name = "BenchTowelHang"
		bench.add_child(towel_hang)
		var bottle: = MeshInstance3D.new()
		var bottle_mesh: = CylinderMesh.new()
		bottle_mesh.top_radius = 0.035
		bottle_mesh.bottom_radius = 0.045
		bottle_mesh.height = 0.26
		bottle_mesh.material = _mat(Color("#37c6e8"))
		bottle.mesh = bottle_mesh
		bottle.position = Vector3(-0.1, 0.61, 0.05)
		bottle.name = "BenchBottle"
		bench.add_child(bottle)
		var cooler: = _box(0.5, 0.52, 0.38, _mat(Color("#f0c23a")))
		cooler.position = Vector3(1.25, 0.27, 0.12)
		bench.add_child(cooler)
		var cooler_top: = _box(0.5, 0.06, 0.38, _mat(Color("#d9a52a")))
		cooler_top.position = Vector3(1.25, 0.56, 0.12)
		bench.add_child(cooler_top)


	var bw: Node3D = load("res://scripts/ball_watcher.gd").new()
	bw.name = "BallWatcher"
	for wr in _watchers:
		bw.add_watcher(wr.fig, wr.yaw, wr.get("body", 0.0))
	root.add_child(bw)
	return root



static func flood_cells(tod: int) -> int:
	return 48 if tod == 1 else 0

static func flood_cones(tod: int) -> int:
	return 4 if tod == 1 else 0
