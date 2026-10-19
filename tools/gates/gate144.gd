extends SceneTree
# gate144: v0.144 - restador dentro de individuales, raqueta oculta al celebrar, diana con contraste y bola de saque acotada
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}

func _init():
	var fail := 0
	seed(144)

	var s: TennisSim = SimClass.new(false, CP, HP, "CPU", 1)
	s.M.server = 1
	s.prep_serve()
	if absf(s.pl[0].x) > 3.715:
		print("FAIL: restador inicial fuera de individuales x=", s.pl[0].x); fail += 1
	s.inp.x = 1.0
	for f in 60:
		s.update(1.0 / 60.0)
	if absf(s.pl[0].x) > 3.92:
		print("FAIL: restador entra en el pasillo de dobles x=", s.pl[0].x); fail += 1

	var MV = load("res://scripts/match_view.gd")
	if MV.held_ball_scale(false, true, 1.0) > 0.45:
		print("FAIL: bola de saque demasiado grande"); fail += 1
	if MV.held_ball_scale(true, false, 0.0) > 0.35:
		print("FAIL: bola en mano demasiado grande"); fail += 1

	var pf: String = FileAccess.get_file_as_string("res://scripts/player_fig.gd")
	if not (pf.contains('celeb_name == "Wave"') and pf.contains('celeb_name == "Punch_Right"')):
		print("FAIL: raqueta visible al celebrar"); fail += 1
	var tx: String = FileAccess.get_file_as_string("res://scripts/textures.gd")
	if not tx.contains("halo > ring"):
		print("FAIL: diana sin borde de contraste"); fail += 1

	print("gate144 ", "PASS" if fail == 0 else "FAIL")
	quit()
