extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _init():
	var ok: = true

	var s = SimClass.new(false, HP, CP, "CPU", 1)
	s.state = "serve";s.M.server = 1
	var dt = 1.0 / 60.0
	var p = s.pl[0]
	s.state = "play"

	p.tvx = 6.3;p.tvz = 0.0
	var v_fresco: = 0.0
	var t: = 0.0


	while t < 1.5:
		p.tvx = 6.3
		s.update_player(p, dt)
		if p.x > 5.5: p.x = -5.5
		t += dt
	v_fresco = p.speed
	while t < 7.0:
		p.tvx = 6.3
		s.update_player(p, dt)
		if p.x > 5.5: p.x = -5.5
		t += dt
	var v_fundido: float = p.speed
	print("C1 v_fresco=", snappedf(v_fresco, 0.1), " v_tras_5s_sprint=", snappedf(v_fundido, 0.1), " fat=", snappedf(p.fat, 0.01))
	if v_fresco < 5.0: ok = false;print("FAIL sprint ni siquiera arranca")
	if v_fundido > v_fresco * 0.95: ok = false;print("FAIL no hay fatiga")

	t = 0.0
	while t < 4.0:
		p.tvx = 1.2
		s.update_player(p, dt)
		if p.x > 5.5: p.x = -5.5
		t += dt
	print("C2 fat_tras_descanso=", snappedf(p.fat, 0.01))
	if p.fat > 0.15: ok = false;print("FAIL no se recupera")
	t = 0.0
	while t < 1.2:
		p.tvx = 6.3
		s.update_player(p, dt)
		if p.x > 5.5: p.x = -5.5
		t += dt
	print("C2 v_recuperada=", snappedf(p.speed, 0.1))
	if p.speed < v_fresco * 0.95: ok = false;print("FAIL velocidad no vuelve")

	var s2 = SimClass.new(true, HP, CP, "CPU", 1)
	var t2: = 0.0
	var fat_max: = 0.0
	while t2 < 240.0:
		s2.update(dt);t2 += dt
		fat_max = maxf(fat_max, maxf(s2.pl[0].fat, s2.pl[1].fat))
	print("C3 fat_max en 4min demo=", snappedf(fat_max, 0.01))
	if fat_max < 0.3: ok = false;print("FAIL CPU no fatiga en rally")
	print("GATE061 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
