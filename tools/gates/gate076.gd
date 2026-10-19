extends SceneTree





const CB: = preload("res://scripts/court_builder.gd")
var ok: = true
func _init() -> void :
	var d: = CB.build("hard", 0)
	var t: = CB.build("hard", 2)
	var n: = CB.build("hard", 1)
	var sun_d: = _sun(d); var sun_t: = _sun(t)
	print("A dia solx=", sun_d.rotation_degrees.x, " tarde solx=", sun_t.rotation_degrees.x, 
		" focos dia/tarde/noche=", _spots(d), "/", _spots(t), "/", _spots(n), 
		" color tarde=", sun_t.light_color)
	if absf(sun_t.rotation_degrees.x) > 25.0: print("FAIL A: sol de tarde demasiado alto");ok = false
	if absf(sun_t.rotation_degrees.x) >= absf(sun_d.rotation_degrees.x) * 0.5: print("FAIL A: sol de tarde no claramente mas bajo");ok = false
	if _spots(t) != 0 or _spots(d) != 0 or _spots(n) != 2: print("FAIL A: focos mal por sesion");ok = false
	if sun_t.light_color.r <= sun_t.light_color.b: print("FAIL A: luz de tarde no calida");ok = false
	print("GATE076 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _sun(node: Node) -> DirectionalLight3D:
	for ch in node.get_children():
		if ch is DirectionalLight3D: return ch
	return null
func _spots(node: Node) -> int:
	var c: = 0
	for ch in node.get_children():
		if ch is SpotLight3D: c += 1
	return c
func _process(_dt: float) -> bool:
	return true
