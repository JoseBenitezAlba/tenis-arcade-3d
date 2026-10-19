extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	print("A late=", MV.mishit_shake("late"), " early=", MV.mishit_shake("early"), " ok=", MV.mishit_shake("ok"), " perfect=", MV.mishit_shake("perfect"))
	if absf(MV.mishit_shake("late") - 0.1) > 0.001 or absf(MV.mishit_shake("early") - 0.1) > 0.001 or MV.mishit_shake("ok") != 0.0 or MV.mishit_shake("perfect") != 0.0 or MV.mishit_shake("perfect+") != 0.0:
		print("FAIL A: mapeo de sacudida incorrecto");ok = false


	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var e = s.pl[0]
	e.swing = 0.2
	s.ball.vy = -1.0
	s.ball.y = 0.5
	s.ball.x = e.x
	s.ball.z = e.z - 0.6
	var a1: Dictionary = s._player_aim(e, "drive", 0.0)
	print("B late tq=", a1.get("tq"))
	if a1.get("tq") != "late":
		print("FAIL B: la bola baja no marca late");ok = false
	e.swing = 0.05
	s.ball.vy = 2.0
	s.ball.y = 1.2
	s.ball.x = e.x + 2.0
	var a2: Dictionary = s._player_aim(e, "drive", 0.0)
	print("B early tq=", a2.get("tq"))
	if a2.get("tq") != "early":
		print("FAIL B: el swing agotado no marca early");ok = false
	print("GATE114 PASS" if ok else "GATE114 FAIL")
	quit(0 if ok else 1)
