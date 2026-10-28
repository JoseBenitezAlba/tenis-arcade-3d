extends SceneTree
const S = preload("res://scripts/sim.gd")
func _init():
	var fail = 0
	for side in [0, 1]:
		var s = S.new(true, {"style": "sv"});s.M.server = side;s.prep_serve();s.serve_stage = "hit";s.state = "serve";s.ball.held = false;s.ball.toss = false;s.ball.in_play = true;s.ball.last = side;s.ball.z = s.pl[side].z;s.ball.y = 2;s.ball.vz = 20 if side == 0 else -20
		var e = s.pl[side];e.appr_t = 2.6
		var z0 = e.z
		for t in 30: s.ai_control(e, 1.0 / 60);s.update_player(e, 1.0 / 60)
		if absf(e.z - z0) < 1.0: print("FAIL S/V follow serve side=", side);fail += 1
		s.serve_stage = "toss";e.vx = 0;e.vz = 0;s.ai_control(e, 1.0 / 60);s.update_player(e, 1.0 / 60)
		if absf(e.vx) + absf(e.vz) > 0.001: print("FAIL toss lock");fail += 1
	for hitter in [0, 1]:
		var s = S.new(false);s.state = "play";s.serve_unreturned = false
		var b = s.ball;b.held = false;b.toss = false;b.in_play = true;b.last = hitter;b.bounces = 1;b.x = 3;b.z = 4 if hitter == 1 else 20;b.y = 0.18;b.vy = -2;b.vz = -2 if hitter == 1 else 2;b.vx = 0
		s.step_ball(0.016)
		if s.last_winner != hitter: print("FAIL winner");fail += 1
	print("GATE179 PASS" if fail == 0 else "GATE179 FAIL")
	quit(fail)
