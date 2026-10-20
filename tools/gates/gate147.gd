extends SceneTree
# gate147: v0.147 - la sombra de la bola es mas legible en el suelo y sigue visible en el aire
func _init():
	var fail := 0
	var MV = load("res://scripts/match_view.gd")
	if MV.ball_shadow_alpha(0.0) < 0.8: print("FAIL: sombra en el suelo debil"); fail += 1
	if MV.ball_shadow_alpha(6.0) < 0.5: print("FAIL: sombra a 6 m se pierde"); fail += 1
	if MV.ball_shadow_alpha(30.0) < 0.3: print("FAIL: sombra minima"); fail += 1
	if MV.ball_shadow_alpha(3.0) >= MV.ball_shadow_alpha(0.0): print("FAIL: no decrece"); fail += 1
	print("gate147 ", "PASS" if fail == 0 else "FAIL")
	quit()
