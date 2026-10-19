extends SceneTree




const SK: = preload("res://scripts/sound_kit.gd")
const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :
	var sk: SoundKit = SK.new()
	root.add_child(sk)
	sk._ready()

	for nm in ["step", "step_clay", "step_grass"]:
		if not sk.streams.has(nm):
			print("FAIL A: falta stream ", nm);ok = false
	if sk.streams.has("step_clay") and sk.streams["step_clay"].data == sk.streams["step"].data:
		print("FAIL A: step_clay identico al base");ok = false
	if sk.streams.has("step_grass") and sk.streams["step_grass"].data == sk.streams["step"].data:
		print("FAIL A: step_grass identico al base");ok = false

	if sk.surf_name("step", "clay") != "step_clay": print("FAIL B: clay");ok = false
	if sk.surf_name("step", "grass") != "step_grass": print("FAIL B: grass");ok = false
	if sk.surf_name("step", "hard") != "step": print("FAIL B: hard debe caer al base");ok = false

	var i3: float = MV.step_interval(3.0)
	var i5: float = MV.step_interval(5.0)
	var i8: float = MV.step_interval(8.0)
	var i0: float = MV.step_interval(0.5)
	print("C intervalos: 3m/s=", i3, " 5m/s=", i5, " 8m/s=", i8, " 0.5m/s=", i0)
	if not (i3 > i5 and i5 > i8):
		print("FAIL C: no decrece con la velocidad");ok = false
	if i8 < 0.19 or i0 > 0.46:
		print("FAIL C: fuera de banda");ok = false
	if i3 < 0.2 or i3 > 0.45:
		print("FAIL C: valor tipico fuera de banda: ", i3);ok = false
	print("A streams ok, B mapeo ok, C cadencia ok")
	print("GATE085 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
