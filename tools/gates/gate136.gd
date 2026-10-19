extends SceneTree

var fig
func ent(kind: String, sw: float) -> Dictionary:
	return {"x": 0.0, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": kind, 
		"swing": sw, "want_t": 0.3 if sw > 0.0 else 0.0, "want": kind, "vx": 0.0, "vz": 0.0, "prep_t": 0.0, 
		"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
		"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
		"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, "plant_t": 0.0, "plant_dir": 0.0, "charge": 1.0}
func ry(kind: String) -> float:
	var best: = 0.0
	for i in 24:
		fig.update_from_sim(ent(kind, 0.34 - 0.34 * float(i) / 24.0), 1.0 / 60.0)
		best = maxf(best, absf(fig.racket_node.rotation.y))
	return best
func _init() -> void :
	fig = load("res://scripts/player_fig.gd").new(0, true)
	root.add_child(fig)
	await process_frame
	var fail: = 0
	var d: = ry("drop")
	var f: = ry("drive")
	print("drop ", d, " drive ", f)
	if d < 0.5: print("FAIL: dejada sin giro");fail += 1
	if f > 0.001: print("FAIL: drive gira");fail += 1
	fig.update_from_sim(ent("drive", 0.0), 1.0 / 60.0)
	if absf(fig.racket_node.rotation.y) > 0.001: print("FAIL: no resetea");fail += 1
	print("gate136 ", "PASS" if fail == 0 else "FAIL")
	quit()
