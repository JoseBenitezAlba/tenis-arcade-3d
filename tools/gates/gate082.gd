extends SceneTree






const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
var ok: = true
func _init() -> void :

	var c20: Vector2 = MV.contact_weight(20.0, "ok")
	var c22: Vector2 = MV.contact_weight(22.0, "ok")
	var c30: Vector2 = MV.contact_weight(30.0, "ok")
	var c38: Vector2 = MV.contact_weight(38.0, "ok")
	var c42: Vector2 = MV.contact_weight(42.0, "ok")
	var c50: Vector2 = MV.contact_weight(50.0, "ok")
	if c20 != Vector2.ZERO or c22 != Vector2.ZERO:
		print("FAIL A: debe ser 0 por debajo de 22 m/s: ", c20, " ", c22);ok = false
	if not (c30.x > 0.0 and c38.x > c30.x and c30.y > 0.0 and c38.y > c30.y):
		print("FAIL A: no crece con la velocidad: ", c30, " ", c38);ok = false
	if c42.distance_to(Vector2(0.05, 0.14)) > 0.001 or c50.distance_to(Vector2(0.05, 0.14)) > 0.001:
		print("FAIL A: techo mal: ", c42, " ", c50);ok = false
	if c42.x > 0.051 or c42.y > 0.161:
		print("FAIL A: pisa los picos de v0.36");ok = false

	var cl: Vector2 = MV.contact_weight(30.0, "late")
	var ce: Vector2 = MV.contact_weight(30.0, "early")
	if absf(cl.x - c30.x * 0.45) > 0.0005 or absf(ce.x - c30.x * 0.45) > 0.0005:
		print("FAIL B: timing justo debe pesar 45%: ", cl, " ", ce, " vs ", c30);ok = false

	var s: TennisSim = SimClass.new(true)
	var spds: = []
	var steps: = 0
	while steps < 60 * 120 and spds.size() < 40:
		s.update(1.0 / 60.0)
		steps += 1
		for ev in s.events:
			if ev.t == "hit":
				spds.append(ev.get("spd", 0.0))
		s.events.clear()
	var over22: = 0
	for v in spds:
		if v > 22.0:
			over22 += 1
	print("C golpes=", spds.size(), " sobre22=", over22)
	if spds.size() < 10 or over22 < int(spds.size() * 0.5):
		print("FAIL C: pocos golpes ordinarios activan el peso: ", over22, "/", spds.size());ok = false
	print("A bandas ok, B timing ok, C rally ok")
	print("GATE082 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
