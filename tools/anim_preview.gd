extends SceneTree
# Usage: godot --path . --script tools/anim_preview.gd -- <model.fbx> <anim> <time> <out.png> [lib.tres]
func _init():
    var args := OS.get_cmdline_user_args()
    var model: String = args[0] if args.size() > 0 else "res://models/Casual_Male.fbx"
    var anim: String = args[1] if args.size() > 1 else "Sword_Attack"
    var t: float = float(args[2]) if args.size() > 2 else 0.5
    var out: String = args[3] if args.size() > 3 else "/home/sandbox/godot/shots/animtest.png"
    var lib_path: String = args[4] if args.size() > 4 else "res://models/tennis_anims.tres"

    var root := Node3D.new()
    get_root().add_child(root)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, 30, 0)
    sun.shadow_enabled = false
    root.add_child(sun)
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.7, 0.75, 0.8)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(1, 1, 1)
    e.ambient_light_energy = 0.7
    env.environment = e
    root.add_child(env)

    var inst: Node3D = load(model).instantiate()
    root.add_child(inst)
    var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
    if ResourceLoader.exists(lib_path):
        var lib: AnimationLibrary = load(lib_path)
        ap.add_animation_library("tennis", lib)
    var full := anim if ap.has_animation(anim) else "tennis/" + anim
    if not ap.has_animation(full):
        print("NO ANIM ", full, " available: ", ap.get_animation_list())
        quit(1)
        return
    ap.play(full)
    ap.advance(t)

    # frame the character
    var aabb := AABB()
    var first := true
    var stack := [inst]
    while stack.size() > 0:
        var n = stack.pop_back()
        for c in n.get_children(): stack.append(c)
        if n is MeshInstance3D and n.mesh:
            var m: AABB = n.get_aabb()
            var gt: AABB = n.global_transform * m
            if first: aabb = gt; first = false
            else: aabb = aabb.merge(gt)
    print("AABB: ", aabb)
    # frame using skeleton head height in world space (fallback 1.7m)
    var h := 1.7
    var sk = inst.find_child("Skeleton3D", true, false)
    if sk:
        var hi := -1
        for i in sk.get_bone_count():
            if sk.get_bone_name(i) == "Head": hi = i
        if hi >= 0:
            var wy: float = (sk.global_transform * sk.get_bone_global_rest(hi)).origin.length()
            if wy > 0.05: h = wy * 1.15
    var cam := Camera3D.new()
    root.add_child(cam)
    var center := Vector3(0, h * 0.5, 0)
    var az: float = float(args[5]) if args.size() > 5 else 45.0
    var r := deg_to_rad(az)
    cam.position = center + Vector3(sin(r) * h * 2.0, h * 0.1, cos(r) * h * 2.0)
    cam.look_at(center, Vector3.UP)
    cam.current = true

    await process_frame
    await process_frame
    await process_frame
    var img := get_root().get_texture().get_image()
    img.save_png(out)
    print("SAVED ", out)
    quit()
