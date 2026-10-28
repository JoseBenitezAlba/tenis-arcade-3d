extends SceneTree

var fig = null
var frames: = 0
var ex: = 0.0
var ez: = 5.0
func _init() -> void :
	var Fig = load("res://scripts/player_fig.gd")
	fig = Fig.new(0, true)
	root.add_child(fig)
func _process(_dt: float) -> bool:
	frames += 1
	ex += 0.5 / 60.0
	ez += -2.9 / 60.0
	var ent: = {"x": ex, "z": ez, "near": true, "speed": 3.0, "run": 0.0, "kind": "drive", 
		"swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 0.5, "vz": -2.9, "prep_t": 0.0, 
		"wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, 
		"hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, 
		"recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, "burst": 0.0, "charge": 0.0, "charging": false, "plant_dir": 1.0, "idle_t": 0.0}
	fig.update_from_sim(ent, 1.0 / 60.0)
	if frames == 40:
		print("anim=", fig.state, " roty=", snappedf(fig.rotation.y, 0.01))
		var fail: = 0
		if fig.state != "Run_Back": print("FAIL: no Run_Back");fail += 1
		if absf(fig.rotation.y) > 0.6: print("FAIL: de espaldas");fail += 1
		var tx: = FileAccess.get_file_as_string("res://scripts/textures.gd")
		if not tx.contains("0.85 if halo > ring"): print("FAIL: halo diana");fail += 1
		var pg: = FileAccess.get_file_as_string("res://project.godot")
		if not pg.contains("boot_splash/image"): print("FAIL: splash");fail += 1
		print("gate157 ", "PASS" if fail == 0 else "FAIL")
		quit()
	return false
