extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const DIFFS: = [
	{"speed": 4.3, "react": 0.45, "err": 0.9, "miss": 0.3, "risk": 0.35}, 
	{"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}, 
	{"speed": 6.8, "react": 0.14, "err": 0.28, "miss": 0.06, "risk": 0.7}, 
]
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var pf: = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if not sm.contains("con la bola lanzada el sacador no se mueve"): print("FAIL: lock saque");fail += 1
	if not sm.contains("0.89 if AIP.speed < 6.2"): print("FAIL: banda NORMAL");fail += 1
	if not pf.contains("CELEB_ANIMS") or not pf.contains("rk_show_delay"): print("FAIL: raqueta celebracion");fail += 1
	if not mv.contains("_pb_fark"): print("FAIL: escala bola post-punto");fail += 1
	if not mv.contains("_pb_vel *= 11.0 / _pb_sp"): print("FAIL: cap rollout");fail += 1

	var s = SimClass.new(false, {"speed": 7.0, "T": 1.0, "err": 1.0}, DIFFS[1], "CPU", 1)
	var dt: = 1.0 / 60.0
	for i in 60 * 30:
		s.update(dt);s.events.clear()
		if s.state == "serve" and s.M.server == 0 and s.serve_stage == "ready":
			break
	s.inp.hit = true
	s.update(dt);s.events.clear()
	s.inp.x = 1.0;s.inp.y = -1.0
	var x0: float = s.pl[0].x
	var z0: float = s.pl[0].z
	var struck: = false
	for i in 40:
		s.update(dt);s.events.clear()
		if s.serve_stage == "hit": struck = true
	if not struck: print("FAIL: saque auto no sale");fail += 1

	var s2b: TennisSim = SimClass.new(false, {"speed": 7.0, "T": 1.0, "err": 1.0}, DIFFS[1], "CPU", 1)
	for i in 60 * 30:
		s2b.update(dt);s2b.events.clear()
		if s2b.state == "serve" and s2b.M.server == 0 and s2b.serve_stage == "ready":
			break
	s2b.inp.hit = true
	s2b.update(dt);s2b.events.clear()
	s2b.inp.x = 1.0;s2b.inp.y = -1.0
	var x1: float = s2b.pl[0].x
	var z1: float = s2b.pl[0].z
	var moved: = 0.0
	for i in 40:
		s2b.update(dt);s2b.events.clear()
		if s2b.serve_stage == "toss":
			moved = maxf(moved, maxf(absf(s2b.pl[0].x - x1), absf(s2b.pl[0].z - z1)))
	if moved > 0.05:
		print("FAIL: sacador se mueve con bola lanzada d=", moved);fail += 1

	seed(777)
	var mx: = 0.0
	var HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
	for m in 2:
		var s2: TennisSim = SimClass.new(true, DIFFS[1], HP, "CPU", 1)
		for f in 60 * 60 * 4:
			s2.update(1.0 / 60.0)
			for ev in s2.events:
				if ev.get("t") == "serve" and ev.get("id") == 0 and s2.serve_fault == 0:
					mx = maxf(mx, ev.spd * 8.4)
			s2.events.clear()
	print("NORMAL max serve kmh=", snapped(mx, 1))
	if mx > 215.0:
		print("FAIL: NORMAL saca demasiado fuerte");fail += 1
	print("gate168 ", "PASS" if fail == 0 else "FAIL")
	quit(0 if fail == 0 else 1)
