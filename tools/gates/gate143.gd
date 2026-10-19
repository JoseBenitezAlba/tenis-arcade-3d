extends SceneTree
# gate143: v0.143 - recuperacion tras golpe corriendo acotada, aro de bote blanco en tierra, bola de saque menor, raqueta oculta en HitRecieve, x acotada
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
func _init():
	var fail := 0
	seed(143)
	var xmax := 0.0
	for m in 2:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 3:
			s.update(1.0 / 60.0)
			s.events.clear()
			for i in 2:
				xmax = maxf(xmax, absf(s.pl[i].x))
	print("gate143 xmax=", snappedf(xmax, 0.01))
	if xmax > 5.25: print("FAIL: jugador fuera del callejon"); fail += 1
	var MV = load("res://scripts/match_view.gd")
	if MV.held_ball_scale(false, true, 0.5) > 0.65: print("FAIL: bola de saque grande"); fail += 1
	var mv: String = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var pf: String = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	var sm: String = FileAccess.get_file_as_string("res://scripts/sim.gd")
	if not mv.contains("Color(1.0, 1.0, 1.0, lerpf(1.0, 0.85, k))"): print("FAIL: aro tierra"); fail += 1
	if not pf.contains('celeb_name == "HitRecieve"'): print("FAIL: raqueta HitRecieve"); fail += 1
	if not sm.contains("minf(e.recov, 0.45) * 0.7"): print("FAIL: recuperacion corriendo"); fail += 1
	print("gate143 ", "PASS" if fail == 0 else "FAIL")
	quit()
