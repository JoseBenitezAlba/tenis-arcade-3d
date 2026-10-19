extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :

	if MV.cam_push(1, "serve") != 1.0: print("FAIL A: caliente+saque");ok = false
	if MV.cam_push(2, "serve") != 1.0: print("FAIL A: set point");ok = false
	if MV.cam_push(1, "play") != 0.0: print("FAIL A: en juego no empuja");ok = false
	if MV.cam_push(0, "serve") != 0.0: print("FAIL A: punto normal no empuja");ok = false

	var cam_pos: = Vector3(0, 4.8, -9.8)
	var goal: = Vector3(1.0, cam_pos.y, cam_pos.z)
	var fov: = 41.0
	var push: float = MV.cam_push(1, "serve")
	var nz: = 23.77 / 2.0
	var goal2: Vector3 = goal.lerp(Vector3(goal.x, goal.y - 0.18, nz), 0.06 * push)
	var dz: float = absf(goal2.z - goal.z)
	var dy: float = goal.y - goal2.y
	var dfov: float = 2.5 * push
	print("B dz=", snappedf(dz, 0.01), " dy=", snappedf(dy, 0.01), " dfov=", dfov)
	if dz < 0.5 or dz > 2.0: print("FAIL B: dz fuera de banda: ", dz);ok = false
	if dy < 0.005 or dy > 0.05: print("FAIL B: dy fuera de banda: ", dy);ok = false
	if dfov < 1.0 or dfov > 3.5: print("FAIL B: dfov fuera de banda");ok = false
	print("A mapeo ok, B bandas ok")
	print("GATE091 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
