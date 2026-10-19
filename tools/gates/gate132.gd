extends SceneTree

const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	if PF.hop_y(-1.0, 0.3) != 0.0 or PF.hop_y(0.6, 0.3) != 0.0: print("FAIL: fuera de ventana");fail += 1
	var pk: float = PF.hop_y(PF.HOP_DUR * 0.5, 0.3)
	if abs(pk - 0.3) > 0.001: print("FAIL: pico ", pk);fail += 1
	if not (PF.hop_y(0.1, 0.3) > 0.0 and PF.hop_y(0.1, 0.3) < pk): print("FAIL: subida");fail += 1
	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	fig.hop(0.3)
	if fig.hop_age != 0.0 or fig.hop_landed: print("FAIL: estado inicial");fail += 1
	fig.hop_age = PF.HOP_DUR - 0.01
	print("gate132 ", "PASS" if fail == 0 else "FAIL")
	quit()
