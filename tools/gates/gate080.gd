extends SceneTree



const SK: = preload("res://scripts/sound_kit.gd")
var ok: = true
func _init() -> void :
	var sk: SoundKit = SK.new()
	root.add_child(sk)
	sk._ready()

	for nm in ["bounce_clay", "bounce_grass", "skid_clay", "skid_grass"]:
		if not sk.streams.has(nm):
			print("FAIL A: falta stream ", nm);ok = false
	if sk.streams.has("bounce_clay") and sk.streams["bounce_clay"].data == sk.streams["bounce"].data:
		print("FAIL A: bounce_clay identico al base");ok = false
	if sk.streams.has("skid_clay") and sk.streams["skid_clay"].data == sk.streams["skid"].data:
		print("FAIL A: skid_clay identico al base");ok = false

	if sk.surf_name("bounce", "clay") != "bounce_clay": print("FAIL B: clay");ok = false
	if sk.surf_name("bounce", "grass") != "bounce_grass": print("FAIL B: grass");ok = false
	if sk.surf_name("bounce", "hard") != "bounce": print("FAIL B: hard debe caer al base");ok = false
	if sk.surf_name("skid", "clay") != "skid_clay": print("FAIL B: skid clay");ok = false
	print("A streams ok, B mapeo ok")
	print("GATE080 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
