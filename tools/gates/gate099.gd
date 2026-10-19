extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
const CB: = preload("res://scripts/court_builder.gd")
var ok: = true
func _init() -> void :

	print("A net=", MV.net_shake_time("net"), " netcord=", MV.net_shake_time("netcord"), " bounce=", MV.net_shake_time("bounce"))
	if absf(MV.net_shake_time("net") - 0.35) > 0.001 or absf(MV.net_shake_time("netcord") - 0.18) > 0.001 or MV.net_shake_time("bounce") != 0.0:
		print("FAIL A: mapeo de temblor incorrecto");ok = false

	var court: Node3D = CB.build("clay", 1)
	root.add_child(court)
	var nn = court.get_node_or_null("NetMesh")
	print("B NetMesh=", nn != null)
	if nn == null:
		print("FAIL B: la pista no expone NetMesh");ok = false
	court.queue_free()
	print("GATE099 ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
