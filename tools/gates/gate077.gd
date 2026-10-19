extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
var ok: = true
func _mk(style: String):
	var CP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
	if style != "": CP["style"] = style
	return SimClass.new(true, CP, HP, "CPU", 1)
func _serve(s, rec_x: float) -> void :
	s.pl[0].x = rec_x
	s.pl[0].z = -1.0
	s.state = "serve"
	s.M.server = 1
	s.serve_fault = 0
	s.pl[1].appr_t = 0.0
	s.pl[1].x = 2.0
	s.ball.held = false
	s.ball.toss = false
	s.ball.x = s.pl[1].x;s.ball.y = 2.6;s.ball.z = s.pl[1].z
	s.do_serve(s.pl[1], 1.0)
func _init() -> void :
	seed(77077)

	var up_sv: = 0; var up_base: = 0; var spd_sv: = 0.0; var spd_base: = 0.0; var n_sv: = 0; var n_base: = 0
	for i in range(200):
		var s1 = _mk("sv")
		_serve(s1, 0.0)
		if s1.serve_fault == 0 and s1.pl[1].appr_t > 0.0: up_sv += 1
		if s1.serve_fault == 0: spd_sv += Vector3(s1.ball.vx, s1.ball.vy, s1.ball.vz).length();n_sv += 1
		var s2 = _mk("")
		_serve(s2, 0.0)
		if s2.serve_fault == 0 and s2.pl[1].appr_t > 0.0: up_base += 1
		if s2.serve_fault == 0: spd_base += Vector3(s2.ball.vx, s2.ball.vy, s2.ball.vz).length();n_base += 1
	print("A subidas sv=", up_sv, " base=", up_base, " /200  spd1 sv=", snappedf(spd_sv / maxf(n_sv, 1), 0.1), " base=", snappedf(spd_base / maxf(n_base, 1), 0.1))
	if up_sv < 100: print("FAIL A: el sv no sube tras el saque");ok = false
	if up_base > 0: print("FAIL A: la base no debe subir tras el saque");ok = false
	if spd_sv / maxf(n_sv, 1) <= spd_base / maxf(n_base, 1): print("FAIL A: el saque del sv no es mas rapido");ok = false

	var spd_ctr: = 0.0; var n_ctr: = 0; var df_ctr: = 0; var df_base: = 0
	for i in range(200):
		var s1 = _mk("counter")
		_serve(s1, 0.0)
		if s1.serve_fault == 0: spd_ctr += Vector3(s1.ball.vx, s1.ball.vy, s1.ball.vz).length();n_ctr += 1
		else: df_ctr += 1
		var s2 = _mk("")
		_serve(s2, 0.0)
		if s2.serve_fault != 0: df_base += 1
	print("B spd1 ctr=", snappedf(spd_ctr / maxf(n_ctr, 1), 0.1), " faltas ctr=", df_ctr, " base=", df_base, " /200")
	if spd_ctr / maxf(n_ctr, 1) >= spd_base / maxf(n_base, 1): print("FAIL B: el saque del contragolpeador no es mas lento");ok = false

	var lob_ctr: = 0; var lob_base: = 0
	for i in range(120):
		for st in ["counter", ""]:
			var s = _mk(st)
			s.state = "play"
			s.ball.in_play = true;s.ball.serving = false
			s.ball.held = false;s.ball.toss = false
			s.serve_unreturned = false
			s.pl[0].x = 0.0;s.pl[0].z = 19.0
			s.ball.x = 2.0;s.ball.y = 1.2;s.ball.z = 18.0
			s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = 5.0
			s.ball.last = 0;s.ball.bounces = 1;s.ball.kind = "drive"
			s.pl[1].x = 0.2;s.pl[1].z = 18.8;s.pl[1].swing = 0.0;s.pl[1].speed = 0.0
			s.pl[1].kind_roll = 0.2
			s.pl[1].plan = "";s.pl[1].plan_left = 0

			s.do_hit(s.pl[1], "drive", true)
			if s.ball.kind == "lob":
				if st == "counter": lob_ctr += 1
				else: lob_base += 1
	print("B2 globo estirado ctr=", lob_ctr, " base=", lob_base, " /120")
	if lob_ctr < 30: print("FAIL B2: el contragolpeador no levanta el globo estirado");ok = false
	if lob_base > 0: print("FAIL B2: la base no debe globear por personalidad");ok = false

	var appr_sv: = _count_appr("sv")
	var appr_base: = _count_appr("")
	print("C cierres sv=", appr_sv, " base=", appr_base, " (900s demo)")
	if appr_sv < 35 or appr_sv < appr_base * 1.5: print("FAIL C: el sv no cierra mucho mas en rally");ok = false
	print("GATE077 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _count_appr(style: String) -> int:
	var s = _mk(style)
	var total: = 0
	var prev: float = 0.0
	for i in range(54000):
		s.update(1.0 / 60.0)
		if s.pl[1].appr_t > 0.0 and prev <= 0.0: total += 1
		prev = s.pl[1].appr_t
	return total
func _process(_dt: float) -> bool:
	return true
