extends SceneTree



const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(96096)

	var p14: = MV.crowd_point_plan("PUNTO", 14)
	var p13: = MV.crowd_point_plan("PUNTO", 13)
	var p5: = MV.crowd_point_plan("PUNTO", 5)
	var pj: = MV.crowd_point_plan("JUEGO", 20)
	var has_ov: = false
	for rx in p14:
		if rx[0] == "ovation" and absf(rx[1] - 0.9) < 0.001:
			has_ov = true
	print("A p14=", p14, " p13=", p13, " p5=", p5, " juego20=", pj)
	if not has_ov:
		print("FAIL A: 14+ no pone la grada de pie");ok = false
	for rx in p13:
		if rx[0] == "ovation":
			print("FAIL A: 13 golpes ya da ovacion");ok = false
	if p5.size() != 1 or p5[0][0] != "applause":
		print("FAIL A: cortesia de rally medio rota");ok = false
	if pj.size() != 1 or absf(pj[0][1] - 0.8) > 0.001:
		print("FAIL A: cierre de juego roto");ok = false

	var rallies: = 0
	var mar: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 8:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		var last_rh: = 0
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					last_rh = s.rally_hits
				elif ev.get("t") == "point" or ev.get("t") == "fault":
					rallies += 1
					if last_rh >= 14:
						mar += 1
					last_rh = 0
			s.events.clear()
	var frac: = float(mar) / maxf(1.0, float(rallies))
	print("B rallies=", rallies, " maratonianos=", mar, " frac=", snappedf(frac, 0.03))
	if frac < 0.01 or frac > 0.2:
		print("FAIL B: ovacion maratoniana constante o inexistente");ok = false
	print("GATE096 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
