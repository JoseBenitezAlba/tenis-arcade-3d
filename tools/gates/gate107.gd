extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10707)

	print("A rut_y(0)=", snappedf(TennisSim.rut_y(0.0), 0.01), " rut_y(0.275)=", snappedf(TennisSim.rut_y(0.275), 0.01), 
		" rut_y(0.55)=", snappedf(TennisSim.rut_y(0.55), 0.01), " rut_y(2.0)=", snappedf(TennisSim.rut_y(2.0), 0.01))
	if absf(TennisSim.rut_y(0.0) - 0.95) > 0.01 or absf(TennisSim.rut_y(0.275) - 0.06) > 0.02 or absf(TennisSim.rut_y(0.55) - 0.95) > 0.01 or TennisSim.rut_y(2.0) != 0.95:
		print("FAIL A: perfil de bote incorrecto");ok = false

	var ruts: = 0
	var tosses: = 0
	var pts: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 2:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 4:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "rut_bounce":
					ruts += 1
				elif ev.get("t") == "toss":
					tosses += 1
				elif ev.get("t") == "point":
					pts += 1
			s.events.clear()
	var rpt: = float(ruts) / maxf(1.0, float(tosses))
	print("B rut_bounces=", ruts, " saques=", tosses, " botes/saque=", snappedf(rpt, 0.01), " puntos=", pts)
	if rpt < 2.4 or rpt > 3.6 or pts < 30:
		print("FAIL B: la rutina no suena ~3 veces por saque o el partido se rompio");ok = false
	print("GATE107 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
