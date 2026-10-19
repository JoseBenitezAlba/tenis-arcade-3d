extends SceneTree









const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func flight(spin: float) -> Dictionary:
	var s: TennisSim = SimClass.new(true, {}, HP, "CPU", 1)
	s.ball.x = 0.0
	s.ball.z = 19.0
	s.ball.spin = spin
	s.launch(0.5, 4.0, 0.85, 1.0, 0.0)
	var apex: = 0.0
	var t: = 0.0
	var land_z: = 0.0
	var dt: = 1.0 / 240.0
	for i in 240 * 3:
		s.ball.vy -= TennisSim.g_eff(s.ball.spin) * dt
		s.ball.x += s.ball.vx * dt
		s.ball.y += s.ball.vy * dt
		s.ball.z += s.ball.vz * dt
		t += dt
		apex = maxf(apex, s.ball.y)
		if s.ball.y <= 0.0:
			land_z = s.ball.z
			break
	return {"apex": apex, "t": t, "land_z": land_z, "vy_i": s.ball.vy}
func _init() -> void :
	seed(10606)

	print("A g_eff(0.85)=", TennisSim.g_eff(0.85), " g_eff(0)=", TennisSim.g_eff(0.0), " g_eff(-0.75)=", TennisSim.g_eff(-0.75))
	if TennisSim.g_eff(0.85) <= TennisSim.G or TennisSim.g_eff(-0.75) >= TennisSim.G or TennisSim.g_eff(0.0) != TennisSim.G:
		print("FAIL A: mapeo Magnus incorrecto");ok = false

	var top: = flight(0.85)
	var sli: = flight(-0.75)
	print("B liftado apex=", snappedf(top.apex, 0.01), " t=", snappedf(top.t, 0.02), " vy_imp=", snappedf(top.vy_i, 0.01), " land_z=", snappedf(top.land_z, 0.02), 
		" | cortado apex=", snappedf(sli.apex, 0.01), " t=", snappedf(sli.t, 0.02), " vy_imp=", snappedf(sli.vy_i, 0.01), " land_z=", snappedf(sli.land_z, 0.02))
	if top.t >= sli.t - 0.03 or top.vy_i >= sli.vy_i - 0.5:
		print("FAIL B: el liftado no llega antes y mas picado que el cortado");ok = false
	if absf(top.land_z - 4.0) > 0.35 or absf(sli.land_z - 4.0) > 0.35:
		print("FAIL B: launch ya no compensa el aterrizaje");ok = false

	var pts: = 0
	var hits: = 0
	var fuera: = 0
	var red: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 6:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		for f in 60 * 60 * 8:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					hits += 1
				elif ev.get("t") == "point":
					pts += 1
					if str(ev.get("txt", "")) == "FUERA": fuera += 1
					if str(ev.get("txt", "")) == "RED": red += 1
			s.events.clear()
	var hpp: = float(hits) / maxf(1.0, float(pts))
	print("C puntos=", pts, " fuera=", fuera, " red=", red, " hits/punto=", snappedf(hpp, 0.01))
	if float(fuera) > 0.06 * pts or float(red) > 0.06 * pts or hpp < 3.0 or hpp > 7.6:
		print("FAIL C: el vuelo con efecto rompio el ritmo o la punteria");ok = false
	print("GATE106 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
