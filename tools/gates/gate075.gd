extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
func _mk(risk: float, pts0: int, pts1: int, fault: int) -> RefCounted:
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": risk, "react": 0.2}
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	s.M.server = 1
	s.M.pts = [pts0, pts1]
	s.serve_fault = fault
	s.state = "serve"
	s.pl[1].x = -1.4;s.pl[1].z = s.L + 0.9
	return s
func _serve(s, rec_x: float) -> Dictionary:
	s.pl[0].x = rec_x;s.pl[0].z = -0.6
	s.ball.x = s.pl[1].x;s.ball.y = 2.6;s.ball.z = s.pl[1].z
	s.do_serve(s.pl[1], 1.0)
	return {"vx": s.ball.vx, "spd": Vector3(s.ball.vx, s.ball.vy, s.ball.vz).length(), "tx": s.last_serve_tx}
func _init():
	seed(75075)
	var ok: = true


	var t_camp: = 0; var t_cent: = 0; var w_camp: = 0; var w_cent: = 0
	for i in range(200):
		var s1 = _mk(0.5, 0, 0, 0)
		_serve(s1, 3.0)
		if s1.last_serve_place == "T": t_camp += 1
		if s1.last_serve_place == "wide": w_camp += 1
		var s2 = _mk(0.5, 0, 0, 0)
		_serve(s2, 0.5)
		if s2.last_serve_place == "T": t_cent += 1
		if s2.last_serve_place == "wide": w_cent += 1
	print("A acampando T=", t_camp, " abierto=", w_camp, " | centrado T=", t_cent, " abierto=", w_cent, " (/200)")
	if t_camp <= t_cent * 1.5:
		print("FAIL A: el acampante no recibe mucha mas T");ok = false
	if w_cent <= w_camp:
		print("FAIL A: el centrado no recibe mas abiertos");ok = false

	var spd_down: = 0.0; var spd_easy: = 0.0
	for i in range(200):
		var s3 = _mk(0.5, 3, 0, 0)
		spd_down += _serve(s3, 1.5).spd
		var s4 = _mk(0.5, 0, 3, 0)
		spd_easy += _serve(s4, 1.5).spd
	spd_down /= 200.0;spd_easy /= 200.0
	print("B spd rotura-en-contra=", snappedf(spd_down, 0.01), " 40-0=", snappedf(spd_easy, 0.01))
	if spd_down <= spd_easy:
		print("FAIL B: la presion no aprieta el saque");ok = false

	var spd_ag: = 0.0; var spd_co: = 0.0
	for i in range(400):
		var s5 = _mk(0.8, 0, 0, 1)
		spd_ag += _serve(s5, 1.5).spd
		var s6 = _mk(0.2, 0, 0, 1)
		spd_co += _serve(s6, 1.5).spd
	spd_ag /= 400.0;spd_co /= 400.0
	print("C 2o saque spd agresivo=", snappedf(spd_ag, 0.01), " conservador=", snappedf(spd_co, 0.01))
	if spd_ag <= spd_co:
		print("FAIL C: el agresivo no tira segundos con veneno");ok = false
	print("GATE075 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
