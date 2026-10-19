extends SceneTree





const Career: = preload("res://scripts/career.gd")
var ok: = true
func _init() -> void :

	if Career.pers_of("Taylor Fritzz") != "sv": print("FAIL A: Fritzz debe ser sv");ok = false
	if Career.pers_of("Alex de Minaurr") != "counter": print("FAIL A: de Minaurr debe ser counter");ok = false
	if Career.pers_of("Novak Djokovitz") != "counter": print("FAIL A: Djokovitz debe ser counter");ok = false
	var n1: String = Career.pers_of("Janiel Sinnar")
	if n1 != Career.pers_of("Janiel Sinnar"): print("FAIL A: pers_of no determinista");ok = false

	var base: Dictionary = Career.params_for(0.8, 1)
	var sv: Dictionary = Career.params_for(0.8, 1, "sv")
	var ctr: Dictionary = Career.params_for(0.8, 1, "counter")
	if base.has("style"): print("FAIL B: legacy no debe llevar style");ok = false
	if sv.get("style", "") != "sv" or sv.risk <= base.risk: print("FAIL B: sv mal aplicado");ok = false
	if ctr.get("style", "") != "counter" or ctr.speed <= base.speed or ctr.err >= base.err or ctr.miss >= base.miss:
		print("FAIL B: counter mal aplicado");ok = false

	var nsv: = 0; var nct: = 0
	for p in Career.POOL0:
		var pp: String = Career.pers_of(p[0])
		if pp == "sv": nsv += 1
		if pp == "counter": nct += 1
	print("C pool sv=", nsv, " counter=", nct, " base=", Career.POOL0.size() - nsv - nct)
	if nsv < 2 or nct < 2: print("FAIL C: el pool no ofrece variedad");ok = false
	print("A/B ok, legacy sin style: ", not base.has("style"))
	print("GATE079 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
