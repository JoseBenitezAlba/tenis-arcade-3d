extends SceneTree
const SimClass: = preload("res://scripts/sim.gd")
func _initialize() -> void :
	var fail: = 0
	var sm: = FileAccess.get_file_as_string("res://scripts/sim.gd")
	var mv: = FileAccess.get_file_as_string("res://scripts/match_view.gd")
	var mn: = FileAccess.get_file_as_string("res://scripts/menus.gd")
	var ma: = FileAccess.get_file_as_string("res://scripts/main.gd")
	if not mn.contains("const VERSION: = \"v0.179\""): print("FAIL: VERSION");fail += 1
	if not ma.contains("func _tourney_resolve(win: bool, M)"): print("FAIL: tourney resolve sig");fail += 1
	if not mv.contains("_closeup_ok = ev.txt in [\"JUEGO\", \"SET\", \"PARTIDO\"]"): print("FAIL: closeup trigger");fail += 1
	if not mv.contains("lanzar la bola · sale solo"): print("FAIL: serve hint 1");fail += 1
	if not mv.contains("Otro toque en el ápice = más potencia · si no, sale solo"): print("FAIL: serve hint 2");fail += 1
	if not mv.contains("_meter_hold"): print("FAIL: meter hold");fail += 1
	if sm.contains("_hdist / 29.0"): print("FAIL: v0.176 speed floor debe estar revertido");fail += 1
	if not sm.contains("var target: float = 182.6 if (AIP.speed >= 5.0 and AIP.speed < 6.2) else 203.0"): print("FAIL: serve cap all-CPU");fail += 1
	if not sm.contains("while _hkmh > 164.0 and _ic < 4"): print("FAIL: rally clamp 165");fail += 1
	if not sm.contains("rally_hits <= 2"): print("FAIL: server alerta return");fail += 1
	if not sm.contains("absf(ball.x) > 6.5"): print("FAIL: wide out ruling");fail += 1
	if not sm.contains("ball.dead_roll = state == \"play\""): print("FAIL: net trickle v0.179 (bola de red rueda; pin actualizado del vz*=-0.3 estatico)");fail += 1
	if not sm.contains("and not srv_ret2:"): print("FAIL: srv_ret2 lob branch guard");fail += 1
	if not sm.contains("(not (srv_ret2 and (dx < 1.6) and (dz < 1.6)))"): print("FAIL: def_lob return guard");fail += 1
	if not sm.contains("(not (srv_ret_hit and (stretch < 1.2)))"): print("FAIL: counter lob return guard");fail += 1
	if not sm.contains("absf(pb.x) > 4.115 + 0.85"): print("FAIL: clear_out margin");fail += 1
	if not sm.contains("(1.0 if ball.kind == \"smash\" else 0.45) if no_time"): print("FAIL: no_time dodge chance");fail += 1


	if fail == 0: print("GATE172 OK")
	else: print("GATE172 FAILS=", fail)
	quit(fail)
