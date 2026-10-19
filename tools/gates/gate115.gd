extends SceneTree





const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	print("A b0=", MV.hot_trail_boost(0), " b1=", MV.hot_trail_boost(1), " b2=", MV.hot_trail_boost(2), " b3=", MV.hot_trail_boost(3))
	if MV.hot_trail_boost(0) != 0.0 or absf(MV.hot_trail_boost(1) - 0.34) > 0.001 or absf(MV.hot_trail_boost(2) - 0.68) > 0.001 or absf(MV.hot_trail_boost(3) - 1.0) > 0.001:
		print("FAIL A: mapeo de brillo incorrecto");ok = false

	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var mv = MV.new()
	mv.sim = s
	s.M.pts = [3, 3]
	var hl_oro: int = mv._hot_level()
	s.M.pts = [3, 2]
	s.M.games = [3, 0]
	s.M.sets_to_win = 2
	s.M.sets = [0, 0]
	var hl_set: int = mv._hot_level()
	s.M.sets = [1, 0]
	var hl_mp: int = mv._hot_level()
	print("B oro=", hl_oro, " set=", hl_set, " partido=", hl_mp)
	if hl_oro != 1 or hl_set != 2 or hl_mp != 3:
		print("FAIL B: niveles calientes incorrectos");ok = false
	mv.free()
	print("GATE115 PASS" if ok else "GATE115 FAIL")
	quit(0 if ok else 1)
