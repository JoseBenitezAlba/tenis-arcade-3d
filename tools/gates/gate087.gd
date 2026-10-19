extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _mk(surf: String) -> TennisSim:
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	s.surface = surf
	return s
func _init() -> void :

	for surf in ["clay", "grass", "hard"]:
		var s: = _mk(surf)
		var bd: Array = s._bounce_factors(-1.0)
		var bs: Array = s._bounce_factors(-0.75)
		print("A ", surf, ": dejada vy=", snappedf(bd[0], 0.001), " damp=", snappedf(bd[1], 0.001), 
			" | slice vy=", snappedf(bs[0], 0.001), " damp=", snappedf(bs[1], 0.001))
		if not (bd[0] < bs[0] * 0.95 and bd[1] < bs[1] * 0.9):
			print("FAIL A: la dejada no muere mas que el slice en ", surf);ok = false

	var s2: = _mk("hard")
	s2.state = "play"
	s2.ball.in_play = true;s2.ball.serving = false
	s2.ball.held = false;s2.ball.toss = false
	s2.serve_unreturned = false
	s2.ball.x = 0.0;s2.ball.y = 0.4;s2.ball.z = TennisSim.NZ + 2.0
	s2.ball.vx = 0.0;s2.ball.vy = -4.0;s2.ball.vz = 6.0
	s2.ball.spin = -1.0
	s2.ball.last = 0;s2.ball.bounces = 0;s2.ball.kind = "drop"
	var pre: = absf(s2.ball.vz)
	var prev_b: = s2.ball.bounces
	var post: = -1.0
	for i in 240:
		s2.update(1.0 / 60.0)
		s2.events.clear()
		if s2.ball.bounces > prev_b:
			post = absf(s2.ball.vz)
			break
	print("B avance pre=", pre, " post=", snappedf(post, 0.01), " ratio=", snappedf(post / pre, 0.01) if post > 0.0 else -1.0)
	if post < 0.0 or post / pre > 0.55:
		print("FAIL B: la dejada no se muere al picar");ok = false
	print("GATE087 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
