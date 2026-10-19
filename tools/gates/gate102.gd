extends SceneTree




const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10202)

	print("A r9='", MV.rally_count_txt(9), "' r10='", MV.rally_count_txt(10), "' r23='", MV.rally_count_txt(23), "'")
	if MV.rally_count_txt(9) != "" or MV.rally_count_txt(10) != "RALLY 10" or MV.rally_count_txt(23) != "RALLY 23":
		print("FAIL A: formato de contador incorrecto");ok = false

	var rallies: = 0
	var long10: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 6:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		var last_rh: = 0
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "hit":
					last_rh = s.rally_hits
				elif ev.get("t") == "point" or ev.get("t") == "fault":
					rallies += 1
					if last_rh >= 10:
						long10 += 1
					last_rh = 0
			s.events.clear()
	var frac: = float(long10) / maxf(1.0, float(rallies))
	print("B rallies=", rallies, " con_contador=", long10, " frac=", snappedf(frac, 0.03))
	if frac < 0.05 or frac > 0.35:
		print("FAIL B: el contador saldria sin parar o nunca");ok = false
	print("GATE102 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
