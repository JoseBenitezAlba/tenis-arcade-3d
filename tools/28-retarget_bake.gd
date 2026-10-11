extends SceneTree
# Retarget UAL (DEF-*) animations onto UACP skeleton. World-space delta method.
const SRC := "res://models/AnimationLibrary_Godot_Standard.gltf"
const TGT := "res://models/Casual_Male.fbx"
const OUT := "res://models/tennis_anims.tres"
const FPS := 30.0
const ANIMS := ["Idle","Walk","Jog_Fwd","Sprint","Sword_Idle","Sword_Attack","Punch_Cross","Spell_Simple_Enter","Spell_Simple_Shoot","Jump","Dance","Hit_Chest","Roll","PickUp_Table","Sitting_Idle","Idle_Talking","Walk_Formal","Crouch_Idle","Hit_Head"]
const MAP := {
    "DEF-hips": "Body", "DEF-spine.001": "Hips", "DEF-spine.002": "Abdomen", "DEF-spine.003": "Torso",
    "DEF-neck": "Neck", "DEF-head": "Head",
    "DEF-shoulder.L": "Shoulder.L", "DEF-upper_arm.L": "UpperArm.L", "DEF-forearm.L": "LowerArm.L", "DEF-hand.L": "Fist.L",
    "DEF-shoulder.R": "Shoulder.R", "DEF-upper_arm.R": "UpperArm.R", "DEF-forearm.R": "LowerArm.R", "DEF-hand.R": "Fist.R",
    "DEF-thigh.L": "UpperLeg.L", "DEF-shin.L": "LowerLeg.L", "DEF-foot.L": "Foot.L",
    "DEF-thigh.R": "UpperLeg.R", "DEF-shin.R": "LowerLeg.R", "DEF-foot.R": "Foot.R",
}
var sks: Skeleton3D
var skt: Skeleton3D
var src_parents := {}
var tgt_parents := {}
var src_rest_local := {}
var tgt_rest_local := {}
var src_bone_idx := {}
var tgt_bone_idx := {}
var S_w := Transform3D.IDENTITY
var T_w := Transform3D.IDENTITY
var src_rest_w := {}   # world (rot-only Basis per bone)
var tgt_rest_w := {}   # world Basis per bone
var tgt_rest_w_full := {}  # full world Transform3D (for positions)

func _chain(inst: Node, sk: Node) -> Transform3D:
    var t := Transform3D.IDENTITY
    var path := []
    var n = sk
    while n != inst and n != null:
        path.push_front(n)
        n = n.get_parent()
    for p in path:
        t = t * (p as Node3D).transform
    return t

func _fk(bone: String, locals: Dictionary, parents: Dictionary, rests: Dictionary, cache: Dictionary) -> Transform3D:
    if cache.has(bone): return cache[bone]
    var local: Transform3D = locals.get(bone, rests.get(bone, Transform3D.IDENTITY))
    var p: String = parents.get(bone, "")
    var g: Transform3D
    if p == "":
        g = local
    else:
        g = _fk(p, locals, parents, rests, cache) * local
    cache[bone] = g
    return g

func _rot(t: Transform3D) -> Basis:
    return t.basis.orthonormalized()

func _init():
    var src_inst = load(SRC).instantiate()
    sks = src_inst.find_child("Skeleton3D", true, false)
    var tgt_inst = load(TGT).instantiate()
    skt = tgt_inst.find_child("Skeleton3D", true, false)
    S_w = _chain(src_inst, sks)
    T_w = _chain(tgt_inst, skt)
    print("S_w scale=", S_w.basis.get_scale(), " T_w scale=", T_w.basis.get_scale())

    for i in sks.get_bone_count():
        var n = sks.get_bone_name(i)
        src_bone_idx[n] = i
        src_parents[n] = sks.get_bone_name(sks.get_bone_parent(i)) if sks.get_bone_parent(i) >= 0 else ""
        src_rest_local[n] = sks.get_bone_rest(i)
    for i in skt.get_bone_count():
        var n = skt.get_bone_name(i)
        tgt_bone_idx[n] = i
        tgt_parents[n] = skt.get_bone_name(skt.get_bone_parent(i)) if skt.get_bone_parent(i) >= 0 else ""
        tgt_rest_local[n] = skt.get_bone_rest(i)

    var src_rest_fk := {}
    for n in src_bone_idx: _fk(n, {}, src_parents, src_rest_local, src_rest_fk)
    var tgt_rest_fk := {}
    for n in tgt_bone_idx: _fk(n, {}, tgt_parents, tgt_rest_local, tgt_rest_fk)
    for n in src_bone_idx: src_rest_w[n] = _rot(S_w * src_rest_fk[n])
    for n in tgt_bone_idx:
        tgt_rest_w[n] = _rot(T_w * tgt_rest_fk[n])
        tgt_rest_w_full[n] = T_w * tgt_rest_fk[n]

    # world height ratio (head)
    var ratio: float = tgt_rest_w_full["Head"].origin.y / max(0.001, (S_w * src_rest_fk["DEF-head"]).origin.y)
    print("world ratio=", ratio, " tgt_head_y=", tgt_rest_w_full["Head"].origin.y, " src_head_y=", (S_w * src_rest_fk["DEF-head"]).origin.y)

    var ap: AnimationPlayer = src_inst.find_child("AnimationPlayer", true, false)
    var lib := AnimationLibrary.new()
    var s_w_rot: Basis = _rot(S_w)
    var t_w_rot: Basis = _rot(T_w)

    for anim_name in ANIMS:
        if not ap.has_animation(anim_name):
            print("MISSING ANIM: ", anim_name)
            continue
        var a: Animation = ap.get_animation(anim_name)
        var len := a.get_length()
        var rot_tracks := {}
        var pos_tracks := {}
        for ti in a.get_track_count():
            var bone := String(a.track_get_path(ti).get_concatenated_subnames()).split(":")[0]
            if a.track_get_type(ti) == Animation.TYPE_ROTATION_3D: rot_tracks[bone] = ti
            elif a.track_get_type(ti) == Animation.TYPE_POSITION_3D: pos_tracks[bone] = ti

        var out := Animation.new()
        out.set_length(len)
        const LOOPS := ["Idle","Walk","Jog_Fwd","Sprint","Sword_Idle","Sitting_Idle","Crouch_Idle","Dance","Walk_Formal","Idle_Talking"]
        if anim_name in LOOPS:
            out.set_loop_mode(Animation.LOOP_LINEAR)
        var out_rot := {}
        var t2s := {}
        for s in MAP: t2s[MAP[s]] = s
        for s in MAP:
            var t: String = MAP[s]
            if tgt_bone_idx.has(t):
                var idx := out.add_track(Animation.TYPE_ROTATION_3D)
                out.track_set_path(idx, NodePath("CharacterArmature/Skeleton3D:" + t))
                out_rot[t] = idx
        var pos_idx := out.add_track(Animation.TYPE_POSITION_3D)
        out.track_set_path(pos_idx, NodePath("CharacterArmature/Skeleton3D:Body"))

        var steps := int(ceil(len * FPS)) + 1
        for k in steps:
            var tau = min(k / FPS, len - 0.0001)
            var locals := {}
            for bone in src_bone_idx:
                var tr: Transform3D = src_rest_local[bone]
                if rot_tracks.has(bone): tr.basis = Basis(a.rotation_track_interpolate(rot_tracks[bone], tau))
                if pos_tracks.has(bone): tr.origin = a.position_track_interpolate(pos_tracks[bone], tau)
                locals[bone] = tr
            var src_fk := {}
            for n in src_bone_idx: _fk(n, locals, src_parents, src_rest_local, src_fk)

            # target world-rot FK
            var wrot := {}
            for t in tgt_bone_idx:
                var p: String = tgt_parents[t]
                var parent_w: Basis = wrot.get(p, t_w_rot)
                var s: String = t2s.get(t, "")
                if s != "" and src_fk.has(s):
                    var delta: Basis = _rot(S_w * src_fk[s]) * src_rest_w[s].inverse()
                    var desired: Basis = delta * tgt_rest_w[t]
                    wrot[t] = desired
                    out.rotation_track_insert_key(out_rot[t], tau, Quaternion(parent_w.inverse() * desired))
                else:
                    wrot[t] = parent_w * _rot(tgt_rest_local[t])
            # Body world position
            var sd: Vector3 = (S_w * src_fk["DEF-hips"]).origin - (S_w * src_rest_fk["DEF-hips"]).origin
            var p_w: Vector3 = tgt_rest_w_full["Body"].origin + sd * ratio
            var parent_body_w: Transform3D = T_w * tgt_rest_fk["Bone"]
            out.position_track_insert_key(pos_idx, tau, parent_body_w.affine_inverse() * p_w)

        lib.add_animation(anim_name, out)
        print("baked ", anim_name)
    var err := ResourceSaver.save(lib, OUT)
    print("SAVE err=", err)
    quit()
