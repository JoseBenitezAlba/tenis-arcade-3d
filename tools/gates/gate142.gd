extends SceneTree
# gate142: v0.142 - el ganador se queda quieto en la celebracion, velocimetro acotado, pelota oculta en la transicion a saque, paso lateral
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
func _init():
	var fail := 0
	seed(142)
	var wmoved := 0.0
	var maxk := 0.0
	var npts := 0
	for m in 2:
		var s: TennisSim = SimClass.new(m == 0, CP, HP, "CPU", 1)
		var prev := ""
		var wx0 := 0.0
		var wz0 := 0.0
		var lw := -1
		for f in 60 * 60 * 3:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.t == "serve": maxk = maxf(maxk, ev.spd * 8.4)
				
			s.events.clear()
			if s.state == "point" and prev != "point":
				lw = s.last_winner
				wx0 = s.pl[lw].x
				wz0 = s.pl[lw].z
				npts += 1
			if s.state == "point" and lw >= 0 and s.state_t < 2.5:
				wmoved = maxf(wmoved, Vector2(s.pl[lw].x - wx0, s.pl[lw].z - wz0).length())
			prev = s.state
	print("gate142 points=", npts, " winner moved=", snappedf(wmoved, 0.01), " max kmh=", snappedf(maxk, 1.0))
	if npts < 5: print("FAIL: pocos puntos"); fail += 1
	if wmoved > 1.6: print("FAIL: el ganador sigue corriendo en la celebracion"); fail += 1
	if maxk > 260.0: print("FAIL: velocidad fuera de rango"); fail += 1
	var mv: String = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var hd: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	var pf: String = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if not mv.contains("_serve_blank") or not mv.contains("hud.hide_speed()"): print("FAIL: transicion de saque"); fail += 1
	if not hd.contains("clampi(kmh, 0, 245)"): print("FAIL: velocimetro"); fail += 1
	if not pf.contains("e.speed <= 5.5 and absf(e.vx)"): print("FAIL: paso lateral"); fail += 1
	print("gate142 ", "PASS" if fail == 0 else "FAIL")
	quit()
