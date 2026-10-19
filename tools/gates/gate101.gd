extends SceneTree



const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :

	print("A clay=", MV.mark_alpha("clay"), " grass=", MV.mark_alpha("grass"), " hard=", MV.mark_alpha("hard"))
	if absf(MV.mark_alpha("clay") - 0.4) > 0.001 or absf(MV.mark_alpha("grass") - 0.15) > 0.001 or MV.mark_alpha("hard") != 0.0:
		print("FAIL A: mapeo de marca incorrecto");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("catch"):
		print("FAIL B: falta stream catch");ok = false
	else:
		k.play("catch", 1.0)
		if int(k.play_counts.get("catch", 0)) != 1:
			print("FAIL B: play() no contabiliza catch");ok = false
	k.queue_free()
	print("GATE101 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
