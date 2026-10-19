extends SceneTree

const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	if PF.punch_scale(-1.0, 1.0) != Vector3.ONE: print("FAIL: antes");fail += 1
	if PF.punch_scale(0.2, 1.0) != Vector3.ONE: print("FAIL: despues");fail += 1
	var mid: Vector3 = PF.punch_scale(PF.PUNCH_DUR * 0.5, 1.0)
	if not (mid.y > 1.03 and mid.x < 1.0): print("FAIL: pico ", mid);fail += 1
	if not (PF.punch_scale(PF.PUNCH_DUR * 0.5, 1.0).y > PF.punch_scale(PF.PUNCH_DUR * 0.5, 0.4).y): print("FAIL: escala con fuerza");fail += 1
	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	fig.punch(40.0)
	fig._process(0.08)
	if fig.scale.y <= 1.02: print("FAIL: figura no se estira ", fig.scale);fail += 1
	for i in 20: fig._process(0.02)
	if fig.scale != Vector3.ONE: print("FAIL: no vuelve ", fig.scale);fail += 1
	print("gate131 ", "PASS" if fail == 0 else "FAIL")
	quit()
