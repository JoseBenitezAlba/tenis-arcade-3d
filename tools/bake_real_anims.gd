extends SceneTree

const OLD2NEW: = {
	"Hips": "pelvis", "Body": "spine_01", "Chest": "spine_03", "Neck": "neck_01", "Head": "head",
	"Shoulder_L": "clavicle_l", "UpperArm_L": "upperarm_l", "LowerArm_L": "lowerarm_l", "Wrist_L": "hand_l",
	"Shoulder_R": "clavicle_r", "UpperArm_R": "upperarm_r", "LowerArm_R": "lowerarm_r", "Wrist_R": "hand_r",
	"UpperLeg_L": "thigh_l", "LowerLeg_L": "calf_l", "Foot_L": "foot_l", "PT_L": "ball_l",
	"UpperLeg_R": "thigh_r", "LowerLeg_R": "calf_r", "Foot_R": "foot_r", "PT_R": "ball_r",
}
const FPS: = 30.0
var old_skel: Skeleton3D
var old_ap: AnimationPlayer
var new_skel: Skeleton3D
var new_rest: Dictionary = {}
var old_rest: Dictionary = {}

func _initialize() -> void :
	call_deferred("run")

func run() -> void :
	var old = (load("res://models/Casual_2.glb") as PackedScene).instantiate()
	root.add_child(old)
	old_skel = old.find_child("Skeleton3D", true, false) as Skeleton3D
	old_ap = old.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for o in OLD2NEW:
		var oi: int = old_skel.find_bone(o)
		if oi >= 0:
			old_rest[o] = old_skel.get_bone_global_rest(oi).basis
	var mh = (load("res://models/mh_3244.glb") as PackedScene).instantiate()
	root.add_child(mh)
	new_skel = mh.find_child("Skeleton3D", true, false) as Skeleton3D
	for i in new_skel.get_bone_count():
		new_rest[new_skel.get_bone_name(i)] = new_skel.get_bone_global_rest(i).basis

	var base_lib: AnimationLibrary = old_ap.get_animation_library(old_ap.get_animation_library_list()[0])
	var base_out: = AnimationLibrary.new()
	for clip in base_lib.get_animation_list():
		var a: Animation = base_lib.get_animation(clip)
		base_out.add_animation(clip, _bake(clip, a.length))
	_save(base_out, "res://models/real/base.tres")
	print("BASE DONE ", base_out.get_animation_list().size())

	old_ap.add_animation_library("f", load("res://models/actual_Derecha.tres"))
	old_ap.add_animation_library("b", load("res://models/actual_Reves.tres"))
	old_ap.add_animation_library("vf", load("res://models/actual_VDerecha.tres"))
	old_ap.add_animation_library("vb", load("res://models/actual_VReves.tres"))
	old_ap.add_animation_library("s", load("res://models/serve_actual_experiment.tres"))
	old_ap.add_animation_library("m", load("res://models/mocap_anims_mm.tres"))

	_make_single("f/Derecha", "Derecha", "res://models/real/fore.tres")
	_make_single("b/Reves", "Reves", "res://models/real/back.tres")
	_make_single("vf/VDerecha", "VDerecha", "res://models/real/volf.tres")
	_make_single("vb/VReves", "VReves", "res://models/real/volb.tres")
	_make_single("s/Servicio", "Servicio", "res://models/real/serve.tres")
	_make_single("m/Smash", "Smash", "res://models/real/smash.tres")
	print("ALL DONE")
	quit()

func _make_single(src: String, clip: String, out_path: String) -> void :
	var lib_name: String = src.get_slice("/", 0)
	var lib: AnimationLibrary = old_ap.get_animation_library(lib_name)
	var a: Animation = lib.get_animation(clip)
	var out: = AnimationLibrary.new()
	out.add_animation(clip, _bake(src, a.length))
	_save(out, out_path)
	print("WROTE ", out_path, " len=", a.length)

func _bake(src: String, length: float) -> Animation :
	var count: int = int(ceil(length * FPS)) + 1
	var keys: Dictionary = {}
	for o in OLD2NEW:
		keys[o] = []
	old_ap.play(src, 0.0)
	for f in count:
		var t: float = minf(float(f) / FPS, length)
		old_ap.seek(t, true)
		old_skel.force_update_all_bone_transforms()
		var deltas: Dictionary = {}
		for o in OLD2NEW:
			var oi: int = old_skel.find_bone(o)
			if oi >= 0:
				deltas[o] = old_rest[o].inverse() * old_skel.get_bone_global_pose(oi).basis
		var desired: Dictionary = {}
		for i in new_skel.get_bone_count():
			var n: String = new_skel.get_bone_name(i)
			var found: String = ""
			for o in OLD2NEW:
				if OLD2NEW[o] == n:
					found = o
					break
			desired[n] = new_rest[n] * (deltas[found] if found != "" else Basis())
		for o in OLD2NEW:
			var n: String = OLD2NEW[o]
			var p: int = new_skel.get_bone_parent(new_skel.find_bone(n))
			var pg: Basis = desired[new_skel.get_bone_name(p)] if p >= 0 else Basis()
			var local: Basis = pg.inverse() * desired[n]
			keys[o].append([t, local.get_rotation_quaternion()])
	var anim: = Animation.new()
	anim.length = length
	for o in OLD2NEW:
		if new_skel.find_bone(OLD2NEW[o]) < 0 or old_skel.find_bone(o) < 0:
			continue
		var ti: int = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(ti, NodePath("Skeleton3D:" + o))
		anim.track_set_interpolation_type(ti, Animation.INTERPOLATION_LINEAR)
		for k in keys[o]:
			anim.track_insert_key(ti, k[0], k[1])
	return anim

func _save(lib: AnimationLibrary, path: String) -> void :
	var err: int = ResourceSaver.save(lib, path)
	if err != OK:
		print("SAVE FAIL ", path, " err=", err)
