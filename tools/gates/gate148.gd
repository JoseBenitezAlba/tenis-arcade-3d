extends SceneTree
# gate148: v0.148 - aro de impacto mas duradero y algo mayor
func _init():
	var fail := 0
	var MV = load("res://scripts/match_view.gd")
	if MV.RING_LIFE < 0.25: print("FAIL: aro corto"); fail += 1
	var lo: Vector2 = MV.ring_params(0.0)
	var hi: Vector2 = MV.ring_params(60.0)
	if lo.x < 0.55 or hi.x < 1.5 or hi.y > 1.0 or lo.y < 0.7: print("FAIL: aro parametros"); fail += 1
	if hi.x <= lo.x: print("FAIL: no escala con la velocidad"); fail += 1
	print("gate148 ", "PASS" if fail == 0 else "FAIL")
	quit()
