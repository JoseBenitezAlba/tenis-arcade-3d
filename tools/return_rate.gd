extends SceneTree

func _serve_once(aim: float) -> String:
	var sim: = TennisSim.new(false, {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}, {"speed": 6.2, "T": 1.0, "err": 1.0}, "CPU", 1)
	sim.inp.x = aim
	sim.inp.y = 1.0
	sim.inp.hit = true
	var tossed: = false
	var served: = false
	for i in 900:
		if tossed and not served and sim.ball.toss_t >= 0.5:
			sim.inp.hit = true
			served = true
		elif tossed and not served:
			sim.inp.hit = false
		sim.update(1.0 / 60.0)
		if not tossed:
			tossed = true
		for ev in sim.events:
			if ev.get("t") == "fault":
				return "FALTA"
			if ev.get("t") == "hit" and ev.get("id") == 1:
				return "RESTO"
			if ev.get("t") == "point":
				return "ACE" if int(ev.get("w")) == 0 else "???"
		sim.events.clear()
	return "timeout"

func _initialize() -> void :
	for aim in [0.2, 0.5, 0.8, 1.0]:
		var counts: = {"RESTO": 0, "ACE": 0, "FALTA": 0, "???": 0, "timeout": 0}
		for i in 20:
			counts[_serve_once(aim)] += 1
		print("aim=%.1f -> restos %d/20 aces %d faltas %d" % [aim, counts["RESTO"], counts["ACE"], counts["FALTA"]])
	quit(0)
