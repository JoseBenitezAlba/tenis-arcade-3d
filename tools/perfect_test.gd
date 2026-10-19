extends SceneTree

func _shot(sweet: bool, n: int) -> Dictionary:
	var Ts: = 0.0
	var spread: = 0.0
	var perf_count: = 0
	for i in n:
		var sim: = TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
		var e = sim.pl[0]
		sim.state = "play"

		e.x = 0.0
		e.z = 2.0
		sim.ball.x = 0.2 if sweet else 1.6
		sim.ball.z = 2.7 if sweet else 3.6
		sim.ball.y = 1.1
		sim.ball.vx = 0.0
		sim.ball.vy = -1.0
		sim.ball.vz = -8.0
		sim.ball.last = 1
		sim.ball.in_play = true
		var bz0: float = sim.ball.z
		sim.do_hit(e, "drive", false)
		var perf: = false
		for ev in sim.events:
			if ev.get("t") == "hit":
				perf = ev.get("perfect", false)
		if perf:
			perf_count += 1

		Ts += (sim.ball.vz)
		spread += absf(sim.ball.vx)
		sim.events.clear()
	return {"vz": - Ts / n, "vx_abs": spread / n, "perfect": perf_count}

func _initialize() -> void :
	var a: = _shot(true, 40)
	var b: = _shot(false, 40)
	print("SWEET  vz=%.1f vx|.|=%.2f perfect=%d/40" % [a.vz, a.vx_abs, a.perfect])
	print("OFF    vz=%.1f vx|.|=%.2f perfect=%d/40" % [b.vz, b.vx_abs, b.perfect])
	assert (a.perfect == 40, "todos los sweet son perfect")
	assert (b.perfect == 0, "ninguno fuera del punto dulce es perfect")
	assert (absf(a.vz) > absf(b.vz) * 1.1, "el perfect sale mas rapido")
	assert (a.vx_abs < b.vx_abs, "el perfect desvia menos")
	print("PERFECT TEST PASS")
	quit(0)
