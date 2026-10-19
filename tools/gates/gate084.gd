extends SceneTree




var ok: = true
var Fig = load("res://scripts/player_fig.gd")
func _ent(spd: float, vx: float) -> Dictionary:
	return {"x": 0.0, "z": 0.0, "near": true, "speed": spd, "run": 0.0, "kind": "drive", 
		"swing": 0.0, "want_t": 0.25, "want": "drive", "vx": vx, "vz": 0.0, "prep_t": 0.0, 
		"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
		"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
		"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, 
		"plant_t": 0.0, "plant_dir": 0.0}
func _state(spd: float, vx: float) -> String:
	var f = Fig.new(0, true)
	root.add_child(f)
	f.update_from_sim(_ent(spd, vx), 1.0 / 60.0)
	var st: String = f.state
	f.queue_free()
	return st
func _init() -> void :
	call_deferred("_go")
func _go() -> void :
	var run_st: = _state(4.0, 4.0)
	var shuf_st: = _state(2.4, 2.4)
	var set_st: = _state(1.0, 0.5)
	var idle_st: = _state(0.0, 0.0)
	print("run=", run_st, " shuffle=", shuf_st, " llegando=", set_st, " parado=", idle_st)
	if run_st != "Run":
		print("FAIL: en carrera debe correr, no cargar pose: ", run_st);ok = false
	if shuf_st not in ["Run_Left", "Run_Right"]:
		print("FAIL: llegada lateral debe ser shuffle: ", shuf_st);ok = false
	if not set_st.begins_with("mocap/"):
		print("FAIL: al llegar debe cargar el backswing: ", set_st);ok = false
	if not idle_st.begins_with("mocap/"):
		print("FAIL: parado con bola debe cargar el backswing: ", idle_st);ok = false
	print("GATE084 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
