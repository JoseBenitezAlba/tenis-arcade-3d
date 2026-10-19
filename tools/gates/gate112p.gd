extends SceneTree







const SimClass: = preload("res://scripts/sim.gd")


const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(11212)
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}

	var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
	for marcador in [[0, 0, 0], [2, 1, 0], [3, 3, 1], [1, 3, 1], [0, 3, 0]]:
		s.M.pts = [marcador[0], marcador[1]]
		s.M.server = marcador[2]
		var esp0: Vector2 = s.break_pos(s.pl[0])
		var esp1: Vector2 = s.break_pos(s.pl[1])
		s.prep_serve()
		var d0: = Vector2(s.pl[0].x - esp0.x, s.pl[0].z - esp0.y).length()
		var d1: = Vector2(s.pl[1].x - esp1.x, s.pl[1].z - esp1.y).length()
		if d0 > 0.001 or d1 > 0.001:
			print("FAIL A: break_pos no replica prep_serve en ", marcador, " d=", d0, ",", d1);ok = false
	print("A break_pos == prep_serve en 5 marcadores")

	s = SimClass.new(true, CP, HP, "CPU", 1)
	s.v112_walk = true
	s.surface = "clay"
	var puntos: = 0
	var mejorados: = 0
	var d_ini: = [0.0, 0.0]
	var d_fin: = [0.0, 0.0]
	var en_p: = false
	for f in 60 * 60 * 6:
		s.update(1.0 / 60.0)
		if s.state == "point":
			if not en_p:
				en_p = true
				for i in 2:
					var bp: Vector2 = s.break_pos(s.pl[i])
					d_ini[i] = Vector2(s.pl[i].x - bp.x, s.pl[i].z - bp.y).length()
			for i in 2:
				var bp: Vector2 = s.break_pos(s.pl[i])
				d_fin[i] = Vector2(s.pl[i].x - bp.x, s.pl[i].z - bp.y).length()
		elif en_p:
			en_p = false
			puntos += 1
			var mej: float = (d_ini[0] - d_fin[0]) + (d_ini[1] - d_fin[1])
			if mej > 0.5 or (d_fin[0] < 0.6 and d_fin[1] < 0.6):
				mejorados += 1
		s.events.clear()
	var frac: = float(mejorados) / maxf(1.0, float(puntos))
	print("B puntos=", puntos, " con acercamiento=", mejorados, " frac=", snappedf(frac, 0.02))
	if frac < 0.75:
		print("FAIL B: la caminata no acerca a las marcas");ok = false
	print("GATE112 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
