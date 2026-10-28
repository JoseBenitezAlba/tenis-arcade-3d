extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const DIFFS: = [
	{"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3, "risk": 0.35}, 
	{"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, 
	{"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06, "risk": 0.7}, 
]
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not sm.contains("var target: float = 182.6 if (AIP.speed >= 5.0 and AIP.speed < 6.2) else 203.0"): print("FAIL: tope 184 ausente");fail += 1
	if not sm.contains("v0.170: la CPU en NORMAL ya no saca por encima del maximo humano"): print("FAIL: comentario tope");fail += 1
	if not sm.contains("if kmh < 162.0:"): print("FAIL: suelo 162 ausente");fail += 1

	seed(170170)
	var HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
	var mx: = 0.0
	for m in 3:
		var s2: TennisSim = SimClass.new(true, DIFFS[1], HP, "CPU", 1)
		for f in 60 * 60 * 4:
			s2.update(1.0 / 60.0)
			for ev in s2.events:
				if ev.get("t") == "serve" and ev.get("id") == 1 and s2.serve_fault == 0:
					mx = maxf(mx, ev.spd * 8.4)
			s2.events.clear()
	print("NORMAL max serve kmh=", snapped(mx, 1))
	if mx > 185.0:
		print("FAIL: NORMAL supera el tope 184");fail += 1
	if mx < 162.0:
		print("FAIL: NORMAL perdio potencia (suelo 162)");fail += 1

	var mx3: = 0.0
	for m in 2:
		var s3: TennisSim = SimClass.new(true, DIFFS[2], HP, "CPU", 1)
		for f in 60 * 60 * 4:
			s3.update(1.0 / 60.0)
			for ev in s3.events:
				if ev.get("t") == "serve" and ev.get("id") == 1 and s3.serve_fault == 0:
					mx3 = maxf(mx3, ev.spd * 8.4)
			s3.events.clear()
	print("DIFICIL max serve kmh=", snapped(mx3, 1))
	if mx3 < 190.0:
		print("FAIL: DIFICIL perdio las bombas");fail += 1
	print("gate170 ", "PASS" if fail == 0 else "FAIL")
	quit(0 if fail == 0 else 1)
