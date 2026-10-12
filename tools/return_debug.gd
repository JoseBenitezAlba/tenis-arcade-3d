extends SceneTree
# Por que la CPU no devuelve saques planos abiertos
func _initialize() -> void:
	var sim := TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
	# saque humano flat, q=1.0, apuntando abierto (como el usuario)
	sim.inp.x = 0.9
	sim.inp.y = 1.0  # flat
	sim.inp.hit = true  # toss
	var tossed := false
	var served := false
	var printed := 0
	var cpu = sim.pl[1]
	var last_t := -1.0
	for i in 600:
		if tossed and not served and sim.ball.toss_t >= 0.50:
			sim.inp.hit = true
			served = true
		elif tossed and not served:
			sim.inp.hit = false
		sim.update(1.0 / 60.0)
		if not tossed:
			tossed = true
		if served and sim.serve_unreturned and sim.time - last_t > 0.04:
			last_t = sim.time
			var b = sim.ball
			print("t=%.2f ball(%.2f,%.2f,%.2f) vz=%.1f vx=%.1f bounces=%d | cpu.x=%.2f z=%.2f react=%.2f tx=%.2f | dx=%.2f dz=%.2f" % [sim.time, b.x, b.y, b.z, b.vz, b.vx, b.bounces, cpu.x, cpu.z, cpu.react, cpu.tx, absf(b.x - cpu.x), absf(b.z - cpu.z)])
			printed += 1
		for ev in sim.events:
			if ev.get("t") == "hit" and ev.get("id") == 1:
				print(">>> CPU DEVUELVE kind=%s" % ev.get("kind"))
			if ev.get("t") == "point":
				print(">>> PUNTO w=%s txt=%s rally=%d" % [str(ev.get("w")), str(ev.get("txt")), sim.rally_hits])
				quit(0)
		sim.events.clear()
		if printed > 30:
			break
	print("sin punto en 10s?")
	quit(1)
