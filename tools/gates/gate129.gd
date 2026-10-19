extends SceneTree

var frames: = 0
var main
func _init() -> void :
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
func _process(_dt: float) -> bool:
	frames += 1
	if frames == 5:
		main._start_match({"surface": "clay", "AIP": {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, "PS": {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}, "demo": true, "career": false, "cpu_name": "CPU", "cpu_label": "CPU", "cpu_look": 1, "sets_to_win": 1, "tod": 0})
	if frames == 15:
		var fail: = 0
		var MV = main.match_view
		var lo: Vector2 = MV.ring_params(10.0)
		var hi: Vector2 = MV.ring_params(40.0)
		if not (hi.x > lo.x and hi.y > lo.y and lo.y > 0.5): print("FAIL: escalado");fail += 1
		if MV.ring_pool.size() != 6: print("FAIL: pool");fail += 1
		MV.spawn_ring(Vector3(0, 1, 0), 30.0)
		var vis: = 0
		for r in MV.ring_pool:
			if r.m.visible: vis += 1
		if vis != 1: print("FAIL: no aparece");fail += 1
		MV._tick_rings(0.1)
		if not MV.ring_pool[0].m.visible: print("FAIL: muere pronto");fail += 1
		MV._tick_rings(0.2)
		if MV.ring_pool[0].m.visible: print("FAIL: no se apaga");fail += 1
		print("gate129 ", "PASS" if fail == 0 else "FAIL")
		return true
	return false
