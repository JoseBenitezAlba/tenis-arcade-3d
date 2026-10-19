extends SceneTree



const MV: = preload("res://scripts/match_view.gd")
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
var ok: = true
func _init() -> void :

	print("A s1.0=", MV.leg_dust_shake(1.0), " s0.9=", MV.leg_dust_shake(0.9), " s0.3=", MV.leg_dust_shake(0.3), " s0.2=", MV.leg_dust_shake(0.2))
	if absf(MV.leg_dust_shake(1.0) - 0.7) > 0.001 or absf(MV.leg_dust_shake(0.9) - 0.6) > 0.001 or MV.leg_dust_shake(0.3) != 0.0 or MV.leg_dust_shake(0.2) != 0.0:
		print("FAIL A: mapeo de sacudida incorrecto");ok = false

	seed(117)
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var juegos: = 0
	for i in 60 * 60 * 12:
		s.update(1.0 / 60.0)
		for ev in s.events:
			if ev.get("t") == "point" and ev.get("txt") == "JUEGO":
				juegos += 1
		s.events.clear()
		if juegos >= 1:
			break
	print("B juegos_vistos=", juegos)
	if juegos < 1:
		print("FAIL B: el sim no cierra juegos");ok = false
	print("GATE117 PASS" if ok else "GATE117 FAIL")
	quit(0 if ok else 1)
