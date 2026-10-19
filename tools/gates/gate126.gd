extends SceneTree

func _init() -> void :
	var fail: = 0
	if MatchHUD.vignette_target(0) != 0.0 or MatchHUD.vignette_target(1) != 0.0:
		print("FAIL: vineta en punto normal");fail += 1
	var a: float = MatchHUD.vignette_target(2)
	var b: float = MatchHUD.vignette_target(3)
	print("set=", a, " partido=", b)
	if not (a > 0.0 and b > a and b < 0.4):
		print("FAIL: escala");fail += 1
	var h: = MatchHUD.new()
	root.add_child(h)
	await process_frame
	h.set_score_glow(3)
	if h.vignette == null:
		print("FAIL: no se crea");fail += 1
	else:
		if h.vignette.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			print("FAIL: bloquea el raton");fail += 1
		if h.get_child(0) != h.vignette:
			print("FAIL: no esta detras");fail += 1
		for i in 400:
			h._process(1.0 / 60.0)
		print("alpha tras 6.6s: ", h.vignette.modulate.a)
		if absf(h.vignette.modulate.a - b) > 0.01:
			print("FAIL: no llega al objetivo");fail += 1
		h.set_score_glow(0)
		for i in 400:
			h._process(1.0 / 60.0)
		if h.vignette.modulate.a > 0.001:
			print("FAIL: no se apaga");fail += 1
	print("gate126 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
