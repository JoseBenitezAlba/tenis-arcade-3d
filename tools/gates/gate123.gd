extends SceneTree

const MV = preload("res://scripts/match_view.gd")
func _init() -> void :
	var fail: = 0
	var mx: = 0.0
	var mn: = 0.0
	for i in 600:
		var v: float = MV.net_sway(i * 0.05, "point")
		mx = maxf(mx, v)
		mn = minf(mn, v)
		if MV.net_sway(i * 0.05, "play") != 0.0:
			print("FAIL: se mueve en juego");fail += 1;break
	print("rango entre puntos: ", mn, " .. ", mx)
	if mx > 0.006 or mn < -0.006:
		print("FAIL: amplitud excesiva");fail += 1
	if mx < 0.003:
		print("FAIL: imperceptible/inmovil");fail += 1
	if MV.net_shake_time("net") != 0.35 or MV.net_shake_time("netcord") != 0.18:
		print("FAIL: v0.99 tocada");fail += 1
	print("gate123 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
