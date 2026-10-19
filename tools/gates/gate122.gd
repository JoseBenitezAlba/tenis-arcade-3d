extends SceneTree


const SoundKit = preload("res://scripts/sound_kit.gd")
const SimClass = preload("res://scripts/sim.gd")
func _init() -> void :
	var fail: = 0
	var sfx = SoundKit.new()
	root.add_child(sfx)
	await process_frame
	var st = sfx.streams.get("match_win")
	if st == null or not (st is AudioStreamWAV):
		print("FAIL: stream match_win ausente");fail += 1
	else:
		var dur: float = st.get_length()
		print("duracion match_win: ", dur)
		if dur < 0.9 or dur > 1.5:
			print("FAIL: duracion rara ", dur);fail += 1
	var HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var partido: = false
	for i in 900000:
		s.update(1.0 / 60.0)
		for e in s.events:
			if e.get("t") == "point" and e.get("txt") == "PARTIDO":
				if e.get("w") != 0 and e.get("w") != 1:
					print("FAIL: PARTIDO con w raro: ", e.get("w"));fail += 1
				partido = true
		s.events.clear()
		if partido: break
	if not partido:
		print("FAIL: el sim no emitio PARTIDO");fail += 1
	print("gate122 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
