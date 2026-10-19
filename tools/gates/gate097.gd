extends SceneTree





const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(97097)

	print("A t3=", MV.match_point_tension(3), " t2=", MV.match_point_tension(2), " t1=", MV.match_point_tension(1))
	if absf(MV.match_point_tension(3) - 0.7) > 0.001 or MV.match_point_tension(2) != 0.0 or MV.match_point_tension(1) != 0.0:
		print("FAIL A: mapeo de tension incorrecto");ok = false


	var pts_total: = 0
	var pts_mp: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 6:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		for f in 60 * 60 * 8:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "point":
					var M = s.M
					if not M.tb and M.pts[0] == 3 and M.pts[1] == 3:
						for i in 2:
							if M.games[i] == 3 and M.sets[i] >= M.sets_to_win - 1:
								pts_mp += 1
			s.events.clear()
		pts_total += maxi(1, s.M.games[0] + s.M.games[1])
	print("B puntos_mp(aprox_sets)=", pts_mp, " sobre ", pts_total, " juegos (cota)")
	if pts_mp < 1:
		print("FAIL B: la bola de partido nunca se da en demo");ok = false

	var k: = SoundKit.new()
	root.add_child(k)
	await process_frame
	if not k.streams.has("drum"):
		print("FAIL C: falta stream drum");ok = false
	else:
		k.play("drum", 1.0)
		if int(k.play_counts.get("drum", 0)) != 1:
			print("FAIL C: play() no contabiliza drum");ok = false
	k.queue_free()
	print("GATE097 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
