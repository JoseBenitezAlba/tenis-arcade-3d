class_name CourtBuilder
extends RefCounted

const L := 23.77
const NZ := L / 2.0

static func _mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    return m

static func _box(sx: float, sy: float, sz: float, mat: Material) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = Vector3(sx, sy, sz)
    bm.material = mat
    mi.mesh = bm
    return mi


# Figura real (Quaternius CC0) con animación en bucle para oficiales.
static func _fbx_figure(model: String, shirt: Color, pants: Color, skin: Color, anim: String, hair := Color("#3a2a18"), head_scale := 1.0) -> Node3D:
    var inst: Node3D = (load(model) as PackedScene).instantiate()
    inst.scale = Vector3.ONE * 0.806
    var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
    if ResourceLoader.exists("res://models/tennis_anims.tres"):
        ap.add_animation_library("tennis", load("res://models/tennis_anims.tres"))
    var stack := [inst]
    while stack.size() > 0:
        var n = stack.pop_back()
        for c in n.get_children(): stack.append(c)
        if n is MeshInstance3D and n.mesh:
            for i in n.mesh.get_surface_count():
                var m = n.mesh.surface_get_material(i)
                var nm: String = (m.resource_name if m else "").to_lower()
                var col := Color.WHITE
                if "skin" in nm or "face" in nm: col = skin
                elif "shirt" in nm: col = shirt
                elif "pants" in nm or "belt" in nm: col = pants
                elif "hair" in nm: col = hair
                else: continue
                var mm := StandardMaterial3D.new()
                mm.albedo_color = col
                mm.roughness = 0.8
                n.set_surface_override_material(i, mm)
    ap.play(anim, 0.0)
    # desincronizar fases entre copias
    ap.seek(randf() * 2.0, true)
    if head_scale != 1.0:
        var sk := inst.find_child("Skeleton3D", true, false) as Skeleton3D
        if sk:
            var hb := sk.find_bone("Head")
            if hb >= 0:
                sk.set_bone_pose_scale(hb, Vector3.ONE * head_scale)
    return inst

static func _figure(shirt_c: Color, skin_c: Color, shorts_c: Color, pose: String) -> Node3D:
    var root := Node3D.new()
    var shirt := _mat(shirt_c)
    var skin := _mat(skin_c)
    var shorts := _mat(shorts_c)
    var mk := func(r: float, h: float, mat: Material) -> MeshInstance3D:
        var mi := MeshInstance3D.new()
        var cm := CapsuleMesh.new()
        cm.radius = r
        cm.height = h
        cm.material = mat
        mi.mesh = cm
        return mi
    var hip_y := 0.94
    if pose == "seated":
        hip_y = 0.0
    elif pose == "kneel":
        hip_y = 0.55
    var pelvis := MeshInstance3D.new()
    var pb := BoxMesh.new()
    pb.size = Vector3(0.26, 0.14, 0.17)
    pb.material = shorts
    pelvis.mesh = pb
    pelvis.position = Vector3(0, hip_y, 0)
    root.add_child(pelvis)
    var torso : MeshInstance3D = mk.call(0.14, 0.46, shirt)
    torso.position = Vector3(0, hip_y + 0.24, 0)
    torso.scale = Vector3(1.1, 1.0, 0.75)
    root.add_child(torso)
    var head := MeshInstance3D.new()
    var hs := SphereMesh.new()
    hs.radius = 0.09
    hs.height = 0.19
    hs.material = skin
    head.mesh = hs
    head.position = Vector3(0, hip_y + 0.56, 0.01)
    root.add_child(head)
    for s in [-1, 1]:
        var arm : MeshInstance3D = mk.call(0.05, 0.55, skin)
        arm.position = Vector3(s * 0.19, hip_y + 0.22, 0.02)
        arm.rotation.z = s * 0.15
        root.add_child(arm)
        var hip := Node3D.new()
        hip.position = Vector3(s * 0.09, hip_y - 0.02, 0)
        root.add_child(hip)
        var thigh : MeshInstance3D = mk.call(0.07, 0.4, shorts if pose != "standing" else skin)
        thigh.position = Vector3(0, -0.19, 0)
        hip.add_child(thigh)
        var knee := Node3D.new()
        knee.position = Vector3(0, -0.4, 0)
        hip.add_child(knee)
        var shin : MeshInstance3D = mk.call(0.055, 0.4, skin)
        shin.position = Vector3(0, -0.19, 0)
        knee.add_child(shin)
        match pose:
            "seated":
                hip.rotation.x = -PI / 2.0 + 0.15
                knee.rotation.x = PI / 2.0 - 0.15
            "kneel":
                hip.rotation.x = 0.9 if s < 0 else -1.2
                knee.rotation.x = 1.5 if s < 0 else 0.1
            _:
                pass
    return root

static func build(surface: String, day: bool = false) -> Node3D:
    var root := Node3D.new()
    root.name = "Court"

    # suelo exterior
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_texture = TexGen.ground_texture(surface)
    ground_mat.uv1_scale = Vector3(4, 4, 4)
    ground_mat.roughness = 0.95
    var ground := MeshInstance3D.new()
    var gp := PlaneMesh.new()
    gp.size = Vector2(56, 56)
    gp.material = ground_mat
    ground.mesh = gp
    ground.position = Vector3(0, 0, L / 2.0)
    root.add_child(ground)

    # pista
    var court_len := L + 7.6
    var court_mat := StandardMaterial3D.new()
    court_mat.albedo_texture = TexGen.court_texture(surface)
    court_mat.roughness = 0.9
    var court := MeshInstance3D.new()
    var cb := PlaneMesh.new()
    cb.size = Vector2(14.4, court_len)
    cb.material = court_mat
    court.mesh = cb
    court.position = Vector3(0, 0.06, (L + 3.6 - 4.0) / 2.0)
    root.add_child(court)

    # red reglamentaria: postes a 0.914m de la linea de dobles (+-6.40m),
    # 1.07m en los postes, 0.914m en el centro (caida parabolica), correa central
    var post_mat := _mat(Color("#202634"))
    for xp in [-6.4, 6.4]:
        var post := MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.top_radius = 0.075
        cyl.bottom_radius = 0.075
        cyl.height = 1.07
        cyl.material = post_mat
        post.mesh = cyl
        post.position = Vector3(xp, 0.535, NZ)
        root.add_child(post)
        var cap := MeshInstance3D.new()
        var capm := CylinderMesh.new()
        capm.top_radius = 0.085
        capm.bottom_radius = 0.085
        capm.height = 0.03
        capm.material = _mat(Color("#e8e8e8"))
        cap.mesh = capm
        cap.position = Vector3(xp, 1.085, NZ)
        root.add_child(cap)
    var net_mat := StandardMaterial3D.new()
    net_mat.albedo_texture = TexGen.net_texture()
    net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    net_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segs := 48
    for i in segs:
        var x0 := -6.4 + 12.8 * float(i) / segs
        var x1 := -6.4 + 12.8 * float(i + 1) / segs
        # caida: 1.067 en postes, 0.914 en el centro
        var yt0 := 0.914 + 0.153 * pow(x0 / 6.4, 2.0)
        var yt1 := 0.914 + 0.153 * pow(x1 / 6.4, 2.0)
        var u0 := float(i) / segs
        var u1 := float(i + 1) / segs
        st.set_uv(Vector2(u0, 1.0)); st.add_vertex(Vector3(x0, 0.0, NZ))
        st.set_uv(Vector2(u1, 1.0)); st.add_vertex(Vector3(x1, 0.0, NZ))
        st.set_uv(Vector2(u0, 0.0)); st.add_vertex(Vector3(x0, yt0, NZ))
        st.set_uv(Vector2(u0, 0.0)); st.add_vertex(Vector3(x0, yt0, NZ))
        st.set_uv(Vector2(u1, 1.0)); st.add_vertex(Vector3(x1, 0.0, NZ))
        st.set_uv(Vector2(u1, 0.0)); st.add_vertex(Vector3(x1, yt1, NZ))
    st.set_material(net_mat)
    var net := MeshInstance3D.new()
    net.mesh = st.commit()
    root.add_child(net)
    # correa central blanca (5cm) hasta el suelo
    var strap := _box(0.05, 0.92, 0.02, _mat(Color("#f2f2f2")))
    strap.position = Vector3(0, 0.46, NZ)
    root.add_child(strap)

    # muros publicitarios
    var ad_names := ["TENIS ARCADE", "PRO TOUR", "SAQUE", "ACE", "SMASH", "MATCH POINT", "GOLDEN POINT", "TOP SPIN"]
    var ad_cols := [Color("#143a8a"), Color("#a11d33"), Color("#0f6b52"), Color("#6a2a9a"), Color("#b36a00"), Color("#0b5d8f"), Color("#a11d33"), Color("#143a8a")]
    var wall_z := L + 5.2
    var back_wall := _box(40, 3.0, 0.4, _mat(Color("#0d1530")))
    back_wall.position = Vector3(0, 1.5, wall_z + 0.2)
    root.add_child(back_wall)
    var i := 0
    var x := -17.6
    while x < 18:
        var board := _box(4.2, 1.0, 0.12, _mat(ad_cols[i % ad_cols.size()]))
        board.position = Vector3(x + 2.1, 0.5, wall_z)
        root.add_child(board)
        var lbl := Label3D.new()
        lbl.text = ad_names[i % ad_names.size()]
        lbl.font_size = 64
        lbl.modulate = Color.WHITE
        lbl.outline_size = 6
        lbl.outline_modulate = Color(0, 0, 0, 0.6)
        lbl.position = Vector3(x + 2.1, 0.5, wall_z - 0.09)
        lbl.rotation_degrees.y = 180
        root.add_child(lbl)
        x += 4.4
        i += 1

    # muro cercano (detras de camara, solo para rebotes visuales de lejos) omitido

    # gradas laterales y de fondo con textura de publico
    var crowd_mat := StandardMaterial3D.new()
    crowd_mat.albedo_texture = TexGen.tier_texture()
    crowd_mat.uv1_scale = Vector3(8, 3, 1)
    crowd_mat.roughness = 1.0
    var stands_far := _box(40, 7.0, 6.0, crowd_mat)
    stands_far.position = Vector3(0, 6.0, wall_z + 3.4)
    root.add_child(stands_far)
    var stands_near := _box(40, 7.0, 6.0, crowd_mat)
    stands_near.position = Vector3(0, 6.0, -12.0)
    root.add_child(stands_near)
    for sx in [-17.5, 17.5]:
        var stands_side := _box(6.0, 7.0, 34.0, crowd_mat)
        stands_side.position = Vector3(sx, 6.0, L / 2.0)
        root.add_child(stands_side)

    # torres de luz
    var tower_mat := _mat(Color("#1a2030"))
    var lamp_mat := StandardMaterial3D.new()
    lamp_mat.albedo_color = Color("#fff6d8")
    lamp_mat.emission_enabled = true
    lamp_mat.emission = Color("#fff6d8")
    lamp_mat.emission_energy_multiplier = 3.0
    for tx in [-12.0, 12.0]:
        for tz in [-4.0, L + 4.0]:
            var tower := _box(0.4, 9.0, 0.4, tower_mat)
            tower.position = Vector3(tx, 4.5, tz)
            root.add_child(tower)
            var lamp := _box(1.6, 0.8, 0.3, lamp_mat)
            lamp.position = Vector3(tx, 9.2, tz)
            root.add_child(lamp)

    # entorno: cielo nocturno + luces
    var env := WorldEnvironment.new()
    var e := Environment.new()
    var sky := Sky.new()
    var skym := ProceduralSkyMaterial.new()
    if day:
        var pano := PanoramaSkyMaterial.new()
        pano.panorama = TexGen.sky_panorama()
        sky.sky_material = pano
    else:
        skym.sky_top_color = Color("#05070f")
        skym.sky_horizon_color = Color("#1b2347")
        skym.ground_bottom_color = Color("#05070f")
        skym.ground_horizon_color = Color("#10162e")
        sky.sky_material = skym
    e.sky = sky
    e.background_mode = Environment.BG_SKY
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = 0.7 if day else 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    root.add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, 168, 0)
    sun.light_energy = 1.15 if day else 1.1
    sun.light_color = Color("#fff4e0") if day else Color("#e8eeff")
    sun.shadow_enabled = true
    root.add_child(sun)

    for sx in ([-7.0, 7.0] if not day else []):
        var spot := SpotLight3D.new()
        spot.position = Vector3(sx, 9.0, NZ)
        spot.rotation_degrees = Vector3(-90, 0, 0)
        spot.spot_range = 26.0
        spot.spot_angle = 42.0
        spot.light_energy = 3.0
        spot.light_color = Color("#fff2d0")
        root.add_child(spot)

    # --- props: silla arbitro, jueces de linea, recogepelotas, banquillos ---
    var green := _mat(Color("#1a5c3a"))
    var white := _mat(Color("#e8e8e8"))
    # silla del arbitro (al lado del poste de la red)
    var chair := Node3D.new()
    chair.position = Vector3(-7.0, 0, NZ)
    chair.rotation.y = 0.0
    root.add_child(chair)
    for lx in [-0.35, 0.35]:
        for lz in [-0.3, 0.3]:
            var leg := MeshInstance3D.new()
            var lc := CylinderMesh.new()
            lc.top_radius = 0.035
            lc.bottom_radius = 0.035
            lc.height = 2.3
            lc.material = green
            leg.mesh = lc
            leg.position = Vector3(lx, 1.15, lz)
            leg.rotation.z = lx * 0.12
            leg.rotation.x = -lz * 0.12
            chair.add_child(leg)
    var plat := _box(0.9, 0.06, 0.8, white)
    plat.position = Vector3(0, 2.0, 0)
    chair.add_child(plat)
    var seat := _box(0.6, 0.08, 0.55, green)
    seat.position = Vector3(0, 2.1, 0)
    chair.add_child(seat)
    var sback := _box(0.6, 0.5, 0.08, green)
    sback.position = Vector3(-0.28, 2.4, 0)
    chair.add_child(sback)
    var step1 := _box(0.5, 0.04, 0.15, white)
    step1.position = Vector3(0.45, 1.0, 0)
    chair.add_child(step1)
    var umpire := _fbx_figure("res://models/OldClassy_Male.fbx", Color("#2a3a6a"), Color("#f0f0f0"), Color("#d9a37a"), "tennis/Sitting_Idle", Color("#8a8078"), 0.72)
    umpire.position = Vector3(0, 2.02, 0)
    umpire.rotation.y = PI / 2.0  # modelo mira +Z: girar para que mire a la pista (+X)
    chair.add_child(umpire)
    var _watchers := []
    _watchers.append({"fig": umpire, "yaw": PI / 2.0})
    # jueces de linea sentados en las esquinas
    var judge_cols := [Color("#274070"), Color("#274070"), Color("#274070"), Color("#274070")]
    var jpos := [Vector3(-8.0, 0, -2.9), Vector3(8.0, 0, -2.9), Vector3(-5.6, 0, L + 2.9), Vector3(5.6, 0, L + 2.9)]
    for ji in 4:
        var jchair := Node3D.new()
        jchair.position = jpos[ji]
        jchair.rotation.y = 0.0 if jpos[ji].z < NZ else PI
        root.add_child(jchair)
        var jseat := _box(0.5, 0.06, 0.45, green)
        jseat.position = Vector3(0, 0.42, 0)
        jchair.add_child(jseat)
        var jback := _box(0.5, 0.4, 0.06, green)
        jback.position = Vector3(0, 0.62, -0.22)
        jchair.add_child(jback)
        var judge := _fbx_figure("res://models/Suit_Male.fbx", judge_cols[ji], Color("#222a40"), Color("#c98d62"), "tennis/Sitting_Idle", Color("#3a3230"), 0.72)
        judge.position = Vector3(0, 0.34, 0.02)
        jchair.add_child(judge)
        _watchers.append({"fig": judge, "yaw": jchair.rotation.y})
    # banquillos laterales
    for s in [-1, 1]:
        var bench := Node3D.new()
        bench.position = Vector3(s * 9.6, 0, NZ)
        bench.rotation.y = -s * PI / 2.0
        root.add_child(bench)
        var bseat := _box(2.2, 0.07, 0.55, white)
        bseat.position = Vector3(0, 0.45, 0)
        bench.add_child(bseat)
        var bback := _box(2.2, 0.35, 0.06, white)
        bback.position = Vector3(0, 0.65, -0.26)
        bench.add_child(bback)
        for bx in [-0.9, 0.9]:
            var bleg := _box(0.08, 0.45, 0.4, green)
            bleg.position = Vector3(bx, 0.22, 0)
            bench.add_child(bleg)
        var bag := _box(0.55, 0.3, 0.25, _mat(Color("#8a2a2a") if s < 0 else Color("#2a4a8a")))
        bag.position = Vector3(0.6, 0.62, 0)
        bench.add_child(bag)
    # cabezas que siguen la bola (ultimo hijo: procesa tras los AnimationPlayer)
    var bw: Node3D = load("res://scripts/ball_watcher.gd").new()
    bw.name = "BallWatcher"
    for wr in _watchers:
        bw.add_watcher(wr.fig, wr.yaw)
    root.add_child(bw)
    return root
