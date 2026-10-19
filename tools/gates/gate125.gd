extends SceneTree

const MV = preload("res://scripts/match_view.gd")
const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	var s: = 0.0
	var prev: = 0.0
	for i in 400:
		s = MV.sweat_next(s, 12)
		if s < prev: fail += 1
		prev = s
	if s != 1.0:
		print("FAIL: no llega al tope ", s);fail += 1
	if MV.sweat_next(0.0, 0) != 0.0:
		print("FAIL: rally 0 suda");fail += 1
	var one: float = MV.sweat_next(0.0, 20)
	print("rally de 20: ", one)
	if absf(one - 0.1) > 0.001:
		print("FAIL: formula");fail += 1
	var base: = Color("#e23b3b")
	var c0: Color = PF.sweat_color(base, 0.0)
	var c1: Color = PF.sweat_color(base, 1.0)
	if c0 != base: print("FAIL: base alterada");fail += 1
	if c1.r >= base.r or c1.r < base.r * 0.7: print("FAIL: oscurecido fuera de rango ", c1);fail += 1

	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	fig.set_sweat(1.0)
	print("shirt_mats=", fig.shirt_mats.size())
	if fig.shirt_mats.size() > 0:
		var m = fig.shirt_mats[0].m
		if m.albedo_color == fig.shirt_mats[0].base: print("FAIL: albedo no cambio");fail += 1
	print("gate125 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
