extends Node3D

var skel: Skeleton3D
var arm_l: int = -1
var arm_r: int = -1
var call_t: float = 0.0
var call_side: float = 1.0

func _ready() -> void :
	skel = find_child("Skeleton3D", true, false) as Skeleton3D
	if skel != null:
		arm_l = skel.find_bone("UpperArm.L")
		arm_r = skel.find_bone("UpperArm.R")
		if arm_l < 0:
			arm_l = skel.find_bone("UpperArm_L")
		if arm_r < 0:
			arm_r = skel.find_bone("UpperArm_R")
	set_process(false)

func call_out(side_x: float) -> void :
	call_side = 1.0 if side_x >= 0.0 else -1.0
	call_t = 1.0
	set_process(true)

func _process(dt: float) -> void :
	if skel == null:
		set_process(false)
		return
	call_t = maxf(0.0, call_t - dt)
	var a: float = 1.2 * (1.0 if call_t > 0.25 else call_t / 0.25)
	var bi: int = arm_r if call_side > 0.0 else arm_l
	if bi >= 0:
		var g: = skel.get_bone_global_pose(bi)
		var rot: = Basis(Vector3.BACK, a * call_side)
		skel.set_bone_global_pose_override(bi, Transform3D(rot * g.basis, g.origin), 1.0, true)
	if call_t <= 0.0:
		skel.clear_bones_global_pose_override()
		set_process(false)
