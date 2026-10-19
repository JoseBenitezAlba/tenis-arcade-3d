extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _init():
	randomize()
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var dt = 1.0 / 60.0
	var t: = 0.0
	var appr_frames0: = 0; var appr_frames1: = 0
	var volleys: = 0; var lobs_vs_net: = 0; var hits: = 0
	var prev_appr1: = 0.0; var appr_starts: = 0
	while t < 960.0:
		s.update(dt);t += dt
		if s.pl[0].appr_t > 0.0: appr_frames0 += 1
		if s.pl[1].appr_t > 0.0: appr_frames1 += 1
		if s.pl[1].appr_t > 0.0 and prev_appr1 <= 0.0: appr_starts += 1
		prev_appr1 = s.pl[1].appr_t
		for ev in s.events:
			if ev.get("t") == "hit":
				hits += 1
				if ev.get("kind") == "volley": volleys += 1
				if ev.get("kind") == "lob": lobs_vs_net += 1
		s.events.clear()
	print("appr_s id0=", snappedf(appr_frames0 / 60.0, 0.1), " id1=", snappedf(appr_frames1 / 60.0, 0.1), " subidas id1=", appr_starts)
	print("hits=", hits, " voleas=", volleys, " globos=", lobs_vs_net)
	var ok: = true




	if appr_starts < 3: ok = false;print("FAIL ya no hay subidas")
	if lobs_vs_net > 58: ok = false;print("FAIL festival de globos")
	var conv: = 0
	for rep in range(20):
		var s2 = SimClass.new(true)
		s2.state = "play"
		s2.ball.in_play = true;s2.ball.serving = false
		s2.ball.held = false;s2.ball.toss = false
		s2.serve_unreturned = false
		s2.pl[1].x = 0.3;s2.pl[1].z = s2.NZ + 3.2;s2.pl[1].appr_t = 2.6
		s2.pl[0].x = 0.0;s2.pl[0].z = s2.NZ - 7.0;s2.pl[0].speed = 0.0
		s2.ball.x = 0.0;s2.ball.y = 1.1;s2.ball.z = s2.NZ - 6.8
		s2.ball.vx = 0.0;s2.ball.vy = 0.0;s2.ball.vz = -6.0
		s2.ball.last = 1;s2.ball.bounces = 1
		s2.inp.x = 0.0;s2.inp.y = 0.0
		s2.do_hit(s2.pl[0], "drive", false)
		var t2: = 0.0; var dt2 = 1.0 / 60.0
		while t2 < 2.5:
			s2.update(dt2);t2 += dt2
			var done: = false
			for ev in s2.events:
				if ev.get("t") == "hit" and int(ev.get("id")) == 1:
					if str(ev.get("kind")) == "volley": conv += 1
					done = true
				elif ev.get("t") == "point" or ev.get("t") == "net":
					done = true
			s2.events.clear()
			if done: break
	print("C4 conversion forzada: voleas=", conv, "/20")
	if conv < 6: ok = false;print("FAIL la subida no convierte (<30%)")
	print("GATE066 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
