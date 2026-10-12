extends SceneTree
# v0.19: predict_bounce devuelve el punto y tiempo del primer bote (anillo de bote)
func _initialize() -> void:
	var ok_n := 0
	var err := 0.0
	var tmax := 0.0
	for i in 60:
		var sim := TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
		sim.state = "play"
		sim.ball.in_play = true
		sim.ball.x = randf_range(-3.5, 3.5)
		sim.ball.z = randf_range(1.0, 22.0)
		sim.ball.y = randf_range(0.6, 4.5)
		sim.ball.vx = randf_range(-4.0, 4.0)
		sim.ball.vy = randf_range(-2.0, 6.0)
		sim.ball.vz = randf_range(-14.0, 14.0)
		var pb: Dictionary = sim.predict_bounce()
		if not pb.ok:
			continue
		ok_n += 1
		tmax = maxf(tmax, pb.t)
		var bx: float = sim.ball.x
		var by: float = sim.ball.y
		var bz: float = sim.ball.z
		var bvx: float = sim.ball.vx
		var bvy: float = sim.ball.vy
		var bvz: float = sim.ball.vz
		var dt := 0.02
		for j in 220:
			bvy -= sim.G * dt
			bx += bvx * dt
			by += bvy * dt
			bz += bvz * dt
			if by <= sim.BR and bvy < 0:
				err += absf(bx - pb.x) + absf(bz - pb.z)
				break
	print("RING ok=%d/60 err_medio=%.4f t_max=%.2f" % [ok_n, err / maxf(1.0, ok_n), tmax])
	assert(ok_n >= 55, "casi todas las bolas en juego tienen bote previsto")
	assert(err / ok_n < 0.02, "el bote previsto coincide con la simulacion")
	assert(tmax <= 4.5, "tiempos de bote razonables")
	print("RING TEST PASS")
	quit()
