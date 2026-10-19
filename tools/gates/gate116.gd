extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	print("A g0=", MV.flash_gap(0), " g1=", MV.flash_gap(1), " g2=", MV.flash_gap(2), " g3=", MV.flash_gap(3))
	if MV.flash_gap(0) != 0.0 or absf(MV.flash_gap(1) - 0.4) > 0.001 or absf(MV.flash_gap(2) - 0.3) > 0.001 or absf(MV.flash_gap(3) - 0.2) > 0.001:
		print("FAIL A: mapeo de flashes incorrecto");ok = false

	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var mv = MV.new()
	mv.sim = s
	var hl_norm: int = mv._hot_level()
	s.M.pts = [3, 3]
	var hl_oro: int = mv._hot_level()
	s.M.pts = [3, 2]
	s.M.games = [3, 0]
	s.M.sets_to_win = 2
	s.M.sets = [1, 0]
	var hl_mp: int = mv._hot_level()
	print("B normal=", hl_norm, " oro=", hl_oro, " partido=", hl_mp, " gap(oro)=", MV.flash_gap(hl_oro))
	if hl_norm != 0 or hl_oro != 1 or hl_mp != 3 or MV.flash_gap(hl_oro) <= 0.0 or MV.flash_gap(hl_norm) != 0.0:
		print("FAIL B: el gatillo de flashes no sigue al marcador");ok = false
	mv.free()
	print("GATE116 PASS" if ok else "GATE116 FAIL")
	quit(0 if ok else 1)
