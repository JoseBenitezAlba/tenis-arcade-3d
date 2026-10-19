extends SceneTree

const PF = preload("res://scripts/player_fig.gd")
func _init() -> void :
	var fail: = 0
	if PF.whoosh_vol(8.0) != 0.0: print("FAIL: suave suena");fail += 1
	if not (PF.whoosh_vol(30.0) > PF.whoosh_vol(16.0) and PF.whoosh_vol(16.0) > 0.0): print("FAIL: monotona");fail += 1
	if PF.whoosh_vol(99.0) > 1.0: print("FAIL: tope");fail += 1
	var sk = SoundKit.new()
	root.add_child(sk)
	await process_frame
	if not sk.streams.has("whoosh"): print("FAIL: sin stream");fail += 1
	var fig = PF.new(0, true)
	root.add_child(fig)
	await process_frame
	fig.swing_now = 1.0
	var n: = 0
	for i in 20:
		fig.position = Vector3(i * 0.3, 0, 0)
		fig._trail_step(1.0 / 60.0)
		if fig.whoosh_pending > 0.0:
			n += 1
			fig.whoosh_pending = 0.0
	print("peticiones: ", n)
	if n != 1: print("FAIL: cooldown/peticion");fail += 1
	print("gate130 ", "PASS" if fail == 0 else "FAIL")
	quit()
