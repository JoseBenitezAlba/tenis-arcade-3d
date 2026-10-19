extends SceneTree
# gate137: saque - el brazo izquierdo sube en el lanzamiento (mano por encima del hombro) y el golpe sale con el brazo derecho alto en el contacto
var fig
func ent(sw: float) -> Dictionary:
	return {"x": 0.0, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "serve",
		"swing": sw, "want_t": 0.3 if sw > 0.0 else 0.0, "want": "serve", "vx": 0.0, "vz": 0.0, "prep_t": 0.0,
		"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0,
		"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0,
		"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, "plant_t": 0.0, "plant_dir": 0.0, "charge": 1.0}
func hand_y(bone: String) -> float:
	var bi: int = fig.skel.find_bone(bone)
	return (fig.skel.global_transform * fig.skel.get_bone_global_pose(bi)).origin.y
func _init() -> void:
	fig = load("res://scripts/player_fig.gd").new(0, true)
	root.add_child(fig)
	await process_frame
	var fail := 0
	fig.serve_toss = 0.0
	fig.update_from_sim(ent(0.0), 1.0 / 60.0)
	var l0: float = hand_y("Wrist.L")
	fig.serve_toss = 0.9
	fig.update_from_sim(ent(0.0), 1.0 / 60.0)
	var l1: float = hand_y("Wrist.L")
	var sh: float = hand_y("UpperArm.L")
	print("muneca L inicio ", l0, " fin ", l1, " hombro ", sh)
	if l1 < sh - 0.05: print("FAIL: brazo del lanzamiento no sube"); fail += 1
	if l1 - l0 < 0.2: print("FAIL: sin recorrido"); fail += 1
	fig.serve_toss = -1.0
	fig.update_from_sim(ent(0.2), 1.0 / 60.0)
	print("gate137 ", "PASS" if fail == 0 else "FAIL")
	quit()
