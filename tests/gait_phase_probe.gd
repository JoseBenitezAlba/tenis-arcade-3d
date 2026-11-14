extends SceneTree

# Measure support phases of the locomotion clips: for each gait clip, sample
# both feet over the cycle and report, in clip-time fractions, where each foot
# is in stance (low and moving backward relative to the root).
func _initialize():
	call_deferred("run")

func run():
	var inst = (load("res://models/Casual_2.glb") as PackedScene).instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var fl = skel.find_bone("Foot_L")
	var fr = skel.find_bone("Foot_R")
	var ll = skel.find_bone("LowerLeg_L")
	var lr = skel.find_bone("LowerLeg_R")
	print("bones fl=", fl, " fr=", fr, " ll=", ll, " lr=", lr)
	if fl < 0:
		var names = []
		for i in skel.get_bone_count():
			names.append(skel.get_bone_name(i))
		print("BONES: ", names)
		quit()
		return
	for clip in ["Run", "Run_Left", "Run_Right", "Run_Back", "Walk"]:
		if not ap.has_animation(clip):
			print("MISSING CLIP ", clip)
			continue
		var anim: Animation = ap.get_animation(clip)
		var length: float = anim.length
		var N: int = 64
		var xs_l = []; var ys_l = []; var zs_l = []
		var xs_r = []; var ys_r = []; var zs_r = []
		ap.play(clip, 0.0)
		ap.seek(0.0, true)
		ap.advance(0.0)
		for i in N:
			var tau: float = length * float(i) / float(N)
			ap.seek(tau, true)
			ap.advance(0.0)
			skel.force_update_all_bone_transforms()
			var pl: Transform3D = skel.global_transform * skel.get_bone_global_pose(fl)
			var pr: Transform3D = skel.global_transform * skel.get_bone_global_pose(fr)
			xs_l.append(pl.origin.x); ys_l.append(pl.origin.y); zs_l.append(pl.origin.z)
			xs_r.append(pr.origin.x); ys_r.append(pr.origin.y); zs_r.append(pr.origin.z)
		# stance = foot low (y within 3cm of cycle min for that foot)
		var minl = INF; var minr = INF
		for i in N: minl = minf(minl, ys_l[i]); minr = minf(minr, ys_r[i])
		var stance_l = []; var stance_r = []
		for i in N:
			if ys_l[i] < minl + 0.03: stance_l.append(snappedf(float(i)/N, 0.001))
			if ys_r[i] < minr + 0.03: stance_r.append(snappedf(float(i)/N, 0.001))
		# backward-speed proxy during stance: dz or dx per sample along clip axis
		print("CLIP ", clip, " len=", snappedf(length, 0.001))
		print("  L stance fracs: ", stance_l)
		print("  R stance fracs: ", stance_r)
		print("  L x[0,1/4,1/2,3/4]=", snappedf(xs_l[0],0.01), ",", snappedf(xs_l[N/4],0.01), ",", snappedf(xs_l[N/2],0.01), ",", snappedf(xs_l[3*N/4],0.01),
			" z=", snappedf(zs_l[0],0.01), ",", snappedf(zs_l[N/4],0.01), ",", snappedf(zs_l[N/2],0.01), ",", snappedf(zs_l[3*N/4],0.01))
		print("  R x[0,1/4,1/2,3/4]=", snappedf(xs_r[0],0.01), ",", snappedf(xs_r[N/4],0.01), ",", snappedf(xs_r[N/2],0.01), ",", snappedf(xs_r[3*N/4],0.01),
			" z=", snappedf(zs_r[0],0.01), ",", snappedf(zs_r[N/4],0.01), ",", snappedf(zs_r[N/2],0.01), ",", snappedf(zs_r[3*N/4],0.01))
	inst.queue_free()
	quit()
