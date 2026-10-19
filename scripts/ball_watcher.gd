


extends Node3D

var ball: Node3D = null
var watchers: = []

func add_watcher(fig: Node3D, base_yaw: float, body_clamp: = 0.0) -> void :
	var skel: = fig.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		return
	var bone: = skel.find_bone("Head")
	if bone < 0:
		return
	watchers.append({
		"skel": skel, 
		"bone": bone, 
		"rest": skel.get_bone_pose_rotation(bone), 
		"base_yaw": base_yaw, 
		"fig": fig, 
		"body_clamp": body_clamp, 
		"fig_base": fig.rotation.y, 
		"body_yaw": 0.0, 
	})

func _process(dt: float) -> void :
	if ball == null or watchers.is_empty():
		return
	var bp: = ball.global_position
	for w in watchers:
		var skel: Skeleton3D = w.skel
		var bone: int = w.bone
		var head_world: Vector3 = (skel.global_transform * skel.get_bone_global_pose(bone)).origin
		var to: Vector3 = bp - head_world
		var horiz: = Vector2(to.x, to.z).length()
		if horiz < 0.001:
			continue
		var delta: = wrapf(atan2(to.x, to.z) - float(w.base_yaw), - PI, PI)
		delta = clampf(delta, -1.05, 1.05)


		var body_delta: = 0.0
		if float(w.body_clamp) > 0.0:
			var target: = clampf(delta, - float(w.body_clamp), float(w.body_clamp))
			w.body_yaw = lerpf(float(w.body_yaw), target, minf(1.0, dt * 4.0))
			w.fig.rotation.y = float(w.fig_base) + float(w.body_yaw)
			body_delta = float(w.body_yaw)
		delta = clampf(delta - body_delta, -0.6, 0.6)
		var pitch: = clampf(atan2(to.y, horiz), -0.45, 0.45)

		var rest_g: Basis = (skel.global_transform * skel.get_bone_global_rest(bone)).basis
		var inv: = rest_g.inverse()
		var ay: Vector3 = (inv * Vector3.UP).normalized()
		var ax: Vector3 = (inv * Vector3.RIGHT).normalized()
		var q: = Quaternion(ay, - delta) * Quaternion(ax, pitch)
		skel.set_bone_pose_rotation(bone, (w.rest as Quaternion) * q)
