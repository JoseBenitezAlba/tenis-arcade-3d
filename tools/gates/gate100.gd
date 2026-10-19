extends SceneTree



const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :

	var v1: float = MV.ambience_vol(0.5, false, false)
	var v2: float = MV.ambience_vol(0.9, true, false)
	var v3: float = MV.ambience_vol(0.9, false, true)
	print("A rally0.5=", snappedf(v1, 0.01), " saque=", v2, " muted=", v3)
	if absf(v1 - 0.19) > 0.005 or absf(v2 - 0.03) > 0.001 or v3 != 0.0:
		print("FAIL A: mapeo de ambiente incorrecto");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("ambience"):
		print("FAIL B: falta stream ambience");ok = false
	else:
		var st: AudioStreamWAV = k.streams["ambience"]
		print("B loop_mode=", st.loop_mode, " bytes=", st.data.size())
		if st.loop_mode != AudioStreamWAV.LOOP_FORWARD or st.data.size() == 0:
			print("FAIL B: ambience no es un bucle con datos");ok = false
	k.queue_free()
	print("GATE100 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
