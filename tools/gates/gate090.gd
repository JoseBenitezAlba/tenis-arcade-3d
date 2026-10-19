extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _mk(srv: bool, vy: float) -> Dictionary:
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	s.state = "play"
	s.serve_unreturned = srv
	s.inp.x = 0.0;s.inp.y = 0.0
	s.ball.vy = vy
	s.ball.y = 1.05
	s.ball.x = s.pl[0].x
	return s._player_aim(s.pl[0], "drive", 0.0)
func _init() -> void :
	seed(90090)

	var tmin: = 99.0
	var tmax: = 0.0
	for i in 40:
		tmin = minf(tmin, _mk(true, 2.0).T)
		tmax = maxf(tmax, _mk(false, 2.0).T)
	print("A resto_al_bote Tmax=", snappedf(tmin, 0.001), " rally_al_bote Tmin=", snappedf(tmax, 0.001))
	if tmin >= tmax:
		print("FAIL A: el resto al bote no sale mas rapido");ok = false

	var tr: = 99.0
	var tw: = 0.0
	for i in 40:
		tr = minf(tr, _mk(false, 2.0).T)
		tw = maxf(tw, _mk(false, -2.0).T)
	print("B rally al bote T=", snappedf(tr, 0.001), " esperando T=", snappedf(tw, 0.001))
	if tr >= tw:
		print("FAIL B: al bote en rally ya no premia");ok = false

	if not _mk(true, 2.0).rise or not _mk(false, 2.0).rise:
		print("FAIL C: rise perdido");ok = false
	print("GATE090 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
