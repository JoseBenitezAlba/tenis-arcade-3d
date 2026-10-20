extends SceneTree

func _init():
	var fail: = 0
	var T: Dictionary = TexGen.THEMES["hard"]
	var c: Color = T.court
	var o: Color = T.surround
	if not (c.b > c.r + 0.25 and c.b > c.g): print("FAIL: la pista dura no es azul");fail += 1
	if not (o.g > o.b and o.g > o.r + 0.1): print("FAIL: exterior no verde");fail += 1
	print("gate144 ", "PASS" if fail == 0 else "FAIL")
	quit()
