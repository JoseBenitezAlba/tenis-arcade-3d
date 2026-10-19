extends SceneTree



const HUD: = preload("res://scripts/hud.gd")
const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	var a0: float = HUD.glow_alpha(0, 1.0)
	var a1: float = HUD.glow_alpha(1, 1.0)
	var mn: = 1.0
	var mx: = 0.0
	for i in 40:
		var a: float = HUD.glow_alpha(3, float(i) * 0.05)
		mn = minf(mn, a)
		mx = maxf(mx, a)
	print("A a0=", a0, " a1=", a1, " pulso3=[", snappedf(mn, 0.01), ",", snappedf(mx, 0.01), "]")
	if a0 != 0.0 or a1 != 0.0 or mn < 0.19 or mx > 0.91 or mx - mn < 0.3:
		print("FAIL A: pulso dorado incorrecto");ok = false

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
	print("B oro=", hl_oro, " set=", hl_set, " partido=", hl_mp, " glow(set)=", snappedf(HUD.glow_alpha(hl_set, 0.35), 0.01), " glow(oro)=", HUD.glow_alpha(hl_oro, 0.35))
	if hl_oro != 1 or hl_set != 2 or hl_mp != 3 or HUD.glow_alpha(hl_oro, 0.35) != 0.0 or HUD.glow_alpha(hl_set, 0.35) <= 0.0:
		print("FAIL B: el brillo no sigue al marcador");ok = false
	mv.free()
	print("GATE119 PASS" if ok else "GATE119 FAIL")
	quit(0 if ok else 1)
