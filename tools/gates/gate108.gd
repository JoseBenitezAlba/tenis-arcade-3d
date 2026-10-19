extends SceneTree






const SimClass: = preload("res://scripts/sim.gd")
const MV: = preload("res://scripts/match_view.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
var ok: = true
func _init() -> void :
	seed(10808)

	var b_sli: = MV.spin_dust_bias(-0.75, 5.0)
	var b_top: = MV.spin_dust_bias(0.85, 5.0)
	print("A slice=", b_sli, " liftado=", b_top, " neutro_n=", MV.spin_dust_count(0.0), " slice_n=", MV.spin_dust_count(-0.75), " top_n=", MV.spin_dust_count(0.85))
	if b_sli.z <= 0.0 or b_sli.y >= 0.0 or MV.spin_dust_bias(-0.75, -5.0).z >= 0.0:
		print("FAIL A: el cortado no levanta estela rasante hacia adelante");ok = false
	if b_top.y <= 1.0 or b_top.z != 0.0:
		print("FAIL A: el liftado no levanta la nube hacia arriba");ok = false
	if MV.spin_dust_count(0.0) != 0 or MV.spin_dust_count(-0.75) != 4 or MV.spin_dust_count(0.85) != 4:
		print("FAIL A: conteo de polvo por efecto incorrecto");ok = false

	var bounces: = 0
	var strong: = 0
	var CP: = {"speed": 7.0, "T": 1.0, "err": 0.5, "miss": 0.1, "risk": 0.5}
	for m in 4:
		var s: TennisSim = SimClass.new(true, CP, HP, "CPU", 1)
		s.surface = "clay"
		for f in 60 * 60 * 6:
			s.update(1.0 / 60.0)
			for ev in s.events:
				if ev.get("t") == "bounce":
					bounces += 1
					if absf(ev.get("sp", 0.0)) >= 0.7:
						strong += 1
			s.events.clear()
	var frac: = float(strong) / maxf(1.0, float(bounces))
	print("B botes=", bounces, " con_efecto=", strong, " frac=", snappedf(frac, 0.03))
	if frac < 0.15 or frac > 0.8:
		print("FAIL B: el polvo de efecto saldria sin parar o nunca");ok = false
	print("GATE108 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
