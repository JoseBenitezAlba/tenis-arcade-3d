extends SceneTree
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var pf: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")

	if not pf.contains("velocidad visual efectiva"): print("FAIL: marca eff_sp");fail += 1
	if not pf.contains("eff_sp = minf(e.speed, mvd / maxf(dt, 0.0001) * 1.15 + 0.35)"): print("FAIL: eff_sp calc");fail += 1
	if pf.contains("elif e.speed > 6.5:"): print("FAIL: cadena sin eff_sp");fail += 1

	if sm.contains("clavado contra el borde"): print("FAIL: damp sim residual");fail += 1

	if not pf.contains("if eff_sp > 5.6 and absf(e.vx) > absf(e.vz):"): print("FAIL: facing");fail += 1

	if pf.contains("e.speed / 3.2") or pf.contains("e.speed / 4.0, 1.0, 1.6"): print("FAIL: patinar");fail += 1

	var sim: = TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 7.0, "T": 1.0, "err": 1.0}, "CPU", 1)
	sim.state = "play"
	sim.ball.in_play = true;sim.ball.serving = false
	sim.ball.x = 3.0;sim.ball.y = 1.0;sim.ball.z = 20.0
	sim.ball.vx = 0.0;sim.ball.vy = 0.0;sim.ball.vz = 3.0
	sim.ball.last = 0;sim.ball.bounces = 1
	sim.pl[0].x = 5.1;sim.pl[0].z = -0.5
	sim.inp.x = 1.0;sim.inp.y = 0.0
	var dt: = 1.0 / 60.0
	for i in 40:
		sim.update(dt)
		sim.events.clear()
	if absf(sim.pl[0].x - 5.2) > 0.01: print("FAIL: posicion cambio x=", sim.pl[0].x);fail += 1
	if sim.pl[0].vx < 5.0: print("FAIL: sim tocada vx=", sim.pl[0].vx);fail += 1
	print("gate164 ", "PASS" if fail == 0 else "FAIL")
	quit()
