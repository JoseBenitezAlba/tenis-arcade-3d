extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var pf: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var mn: = FileAccess.get_file_as_string("res://scripts/menus.gd")
	if not mn.contains("const VERSION: = \"v0.179\""): print("FAIL: VERSION");fail += 1
	if not sm.contains("serve_stage in [\"ready\", \"toss\"]"): print("FAIL: lock ready+toss ausente");fail += 1
	if not sm.contains("\"t\": \"let\""): print("FAIL: evento let ausente");fail += 1
	if not sm.contains("ball.serve_net = true"): print("FAIL: flag serve_net ausente");fail += 1
	if not pf.contains("CELEB_ANIMS"): print("FAIL: CELEB_ANIMS ausente");fail += 1
	if not pf.contains("rk_show_delay"): print("FAIL: rk_show_delay ausente");fail += 1
	if not mv.contains("func skid_color"): print("FAIL: skid_color ausente");fail += 1
	if not mv.contains("\"let\":"): print("FAIL: popup LET ausente");fail += 1
	if not mv.contains("return 0.42 if surf == \"clay\" else 0.0"): print("FAIL: skid_alpha 0.42 ausente");fail += 1

	seed(171171)
	var HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
	var CPU: = {"speed": 7.0, "T": 1.0, "err": 1.0}
	var s: TennisSim = SimClass.new(false, CPU, HP, "CPU", 1)
	s.state = "serve";s.M.server = 1;s.prep_serve();s.cpu_serve_at = s.time + 0.1
	for f in 60 * 6:
		s.update(1.0 / 60.0)
		s.events.clear()
	s.state = "serve";s.M.server = 1;s.M.pts = [0, 0];s.prep_serve()
	s.ball.in_play = true;s.ball.serving = true;s.ball.serve_net = true
	s.ball.x = - signf(s.pl[1].x) * 1.0;s.ball.z = s.NZ - 3.0;s.ball.last = 1
	var f0: = s.serve_fault
	s.judge_landing()
	var let_ev: = false
	for e in s.events:
		if e.get("t") == "let": let_ev = true
	if not let_ev: print("FAIL: no LET en bola tocada de red dentro del cuadro");fail += 1
	if s.serve_fault != f0: print("FAIL: LET altero serve_fault");fail += 1
	if s.serve_stage != "ready": print("FAIL: LET no rearma el saque");fail += 1

	s.state = "serve";s.M.server = 1;s.M.pts = [0, 0];s.prep_serve()
	s.serve_stage = "rally"
	var v0: = 18.0
	s.ball.held = false;s.ball.toss = false
	s.ball.in_play = true;s.ball.serving = true;s.ball.serve_net = false
	s.ball.x = 0.5;s.ball.z = s.NZ + 0.1;s.ball.y = s.NET_H + 0.04
	s.ball.vx = 0.0;s.ball.vy = 0.5;s.ball.vz = - v0;s.ball.last = 1
	s.update(1.0 / 60.0)
	if not s.ball.serve_net: print("FAIL: roce de red en saque no marca serve_net");fail += 1
	if absf(s.ball.vz) >= v0 * 0.9: print("FAIL: roce de red en saque no frena la bola");fail += 1

	s.state = "serve";s.M.server = 1;s.M.pts = [0, 0];s.prep_serve()
	var lock_ok: = true
	for f in 60:
		s.pl[1].tvx = 4.0;s.pl[1].tvz = -4.0
		s.update(1.0 / 60.0)
		s.events.clear()
		if s.serve_stage in ["ready", "toss"] and (absf(s.pl[1].vx) > 0.01 or absf(s.pl[1].vz) > 0.01):
			lock_ok = false
	if not lock_ok: print("FAIL: sacador se mueve con la barra de saque activa");fail += 1
	print("gate171 ", "PASS" if fail == 0 else "FAIL")
	quit(0 if fail == 0 else 1)
