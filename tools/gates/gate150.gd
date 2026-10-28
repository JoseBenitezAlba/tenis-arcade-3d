extends SceneTree

func _init():
	var fail: = 0
	var T = load("res://scripts/textures.gd")
	if T.LINE_W_BASE < 0.14 or T.LINE_W_BASE > 0.2: print("FAIL: linea de fondo");fail += 1
	if T.LINE_W_SIDE < 0.09 or T.LINE_W_SIDE > 0.14: print("FAIL: linea lateral");fail += 1
	if T.LINE_W_BASE <= T.LINE_W_SIDE: print("FAIL: fondo no mas ancha");fail += 1
	print("gate150 ", "PASS" if fail == 0 else "FAIL")
	quit()
