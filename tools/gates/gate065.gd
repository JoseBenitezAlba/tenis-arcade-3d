extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _mk(demo: = false) -> Object:
	return SimClass.new(demo, CP, HP, "CPU", 1)

func _cut_stumble(pid: int, spd: float) -> bool:
	var s = _mk()
	s.state = "play";s.ball.in_play = true
	var e = s.pl[pid]
	var dt = 1.0 / 60.0
	for i in range(42):
		e.tvx = spd;e.tvz = 0.0
		s.update_player(e, dt)
	for i in range(12):
		e.tvx = - spd;e.tvz = 0.0
		s.update_player(e, dt)
		if e.stumble_t > 0.0:
			return true
	return false

func _yank_rate(pid: int, spd: float, n: int) -> int:
	var k: = 0
	for i in range(n):
		if _cut_stumble(pid, spd): k += 1
	return k
func _init():
	randomize()
	var ok: = true
	var c1: = _yank_rate(0, 6.0, 6)
	print("C1 humano 6 yanks desesperados: stumbles=", c1)
	if c1 < 1: ok = false;print("FAIL humano no tropieza en yank desesperado")
	if c1 > 5: ok = false;print("FAIL humano tropieza siempre (sin azar)")
	var s2 = _mk()
	s2.state = "play";s2.ball.in_play = true
	s2.pl[0].vx = 4.5;s2.pl[0].tvx = -4.5
	s2.update_player(s2.pl[0], 1.0 / 60.0)
	print("C2 humano media carrera: stumble_t=", s2.pl[0].stumble_t)
	if s2.pl[0].stumble_t > 0.0: ok = false;print("FAIL humano tropieza sin ir a tope")
	var c3: = _yank_rate(1, 7.6, 6)
	print("C3 CPU 6 yanks desesperados: stumbles=", c3)
	if c3 < 1: ok = false;print("FAIL CPU no tropieza en yank desesperado")
	var s4 = _mk(true)
	var t: = 0.0; var dt = 1.0 / 60.0; var st0: = 0; var st1: = 0
	while t < 480.0:
		s4.update(dt);t += dt
		for ev in s4.events:
			if ev.get("t") == "stumble":
				if ev.get("id") == 0: st0 += 1
				else: st1 += 1
		s4.events.clear()
	print("C4 8min demo: id0=", st0, " id1(CPU)=", st1)
	if st1 > 6: ok = false;print("FAIL la CPU sigue tropezando como tic")
	if st0 + st1 < 1: ok = false;print("FAIL ya no tropieza nadie")
	print("GATE065 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
