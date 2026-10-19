extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _mk() -> Object:
	return SimClass.new(false, HP, CP, "CPU", 1)
func _hit_with_speed(spd: float, n: int) -> Dictionary:


	var vxs: Array = []
	var vzs: Array = []
	for i in range(n):
		var s = _mk()
		s.state = "play";s.ball.in_play = true;s.ball.serving = false
		s.serve_unreturned = false
		s.pl[0].x = 0.0;s.pl[0].z = 0.5
		s.pl[0].speed = spd
		s.ball.x = 0.0;s.ball.y = 1.1;s.ball.z = 1.5
		s.ball.vx = 0.0;s.ball.vy = 0.0;s.ball.vz = -6.0
		s.ball.last = 1;s.ball.bounces = 1
		s.inp.x = 0.0;s.inp.y = 0.0
		s.do_hit(s.pl[0], "drive", false)
		vxs.append(s.ball.vx)
		vzs.append(absf(s.ball.vz))
	return {"vx": vxs, "vz": vzs}
func _sd(a: Array) -> float:
	var m: = 0.0
	for v in a: m += v
	m /= a.size()
	var q: = 0.0
	for v in a: q += (v - m) * (v - m)
	return sqrt(q / a.size())
func _mean(a: Array) -> float:
	var m: = 0.0
	for v in a: m += v
	return m / a.size()
func _init():
	randomize()
	var ok: = true
	var plant: = _hit_with_speed(0.0, 300)
	var walk: = _hit_with_speed(2.0, 300)
	var sprint: = _hit_with_speed(6.5, 300)
	var sd_plant: = _sd(plant.vx); var sd_walk: = _sd(walk.vx); var sd_sprint: = _sd(sprint.vx)
	var v_plant: = _mean(plant.vz); var v_sprint: = _mean(sprint.vz)
	print("C1 sd_plant=", snappedf(sd_plant, 0.01), " sd_walk=", snappedf(sd_walk, 0.01), " sd_sprint=", snappedf(sd_sprint, 0.01))
	print("C1 v_plant=", snappedf(v_plant, 0.1), " v_sprint=", snappedf(v_sprint, 0.1))
	if sd_sprint < sd_walk * 1.2: ok = false;print("FAIL sprint no penaliza precision")
	if sd_plant > sd_walk * 0.95: ok = false;print("FAIL plantado no mejora precision")
	if v_sprint > v_plant * 1.02: ok = false;print("FAIL sprint no quita ritmo")
	print("GATE063 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
