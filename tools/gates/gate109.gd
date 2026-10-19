extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10909)

	if MV.winner_celebration_plan("PUNTO", 0) != []:
		print("FAIL A: punto suelto no debe celebrarse (v0.30)");ok = false
	if MV.winner_celebration_plan("PUNTO", 1) != []:
		print("FAIL A: deuce/oro no basta para celebrar");ok = false
	var saved: Array = MV.winner_celebration_plan("PUNTO", 2)
	var game: Array = MV.winner_celebration_plan("JUEGO", 0)
	var setp: Array = MV.winner_celebration_plan("SET", 0)
	var matchp: Array = MV.winner_celebration_plan("PARTIDO", 0)
	if saved.size() != 2 or saved[1] <= 0.0:
		print("FAIL A: salvar bola de set/partido debe celebrarse");ok = false
	if not (matchp.size() == 2 and matchp[1] > setp[1] and setp[1] > game[1] and game[1] > saved[1]):
		print("FAIL A: la celebracion debe crecer con la importancia");ok = false
	print("A saved=", saved, " juego=", game, " set=", setp, " partido=", matchp)

	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	var puntos: = 0
	var celebrados: = 0
	for m in 6:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		var hot: = 0
		for f in 60 * 60 * 8:
			s.update(1.0 / 60.0)
			if s.state == "serve":
				var M = s.M
				hot = 0
				if not M.tb:
					for i in 2:
						if M.pts[i] == 3 and M.games[i] == 3:
							hot = 3 if M.sets[i] >= M.sets_to_win - 1 else 2
					if M.pts[0] == 3 and M.pts[1] == 3:
						hot = maxi(hot, 1)
			for ev in s.events:
				if ev.get("t") == "point":
					puntos += 1
					if MV.winner_celebration_plan(ev.get("txt", "PUNTO"), hot) != []:
						celebrados += 1
			s.events.clear()
	var frac: = float(celebrados) / maxf(1.0, float(puntos))
	print("B puntos=", puntos, " celebrados=", celebrados, " frac=", snappedf(frac, 0.03))
	if frac < 0.05 or frac > 0.5:
		print("FAIL B: celebracion en cada punto o nunca");ok = false
	print("GATE109 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
