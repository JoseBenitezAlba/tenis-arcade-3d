extends SceneTree
# gate138: (1) el tope de velocidad en el golpe - ningun drive/slice/volea supera STROKE_VCAP ni remate SMASH_VCAP (con margen de iteracion) en 12 min de CPU vs CPU; (2) la bola sostenida/botando se ve mas pequena; (3) los pies quedan sobre la pista (y>=0.05)
const SimClass: = preload("res://scripts/sim.gd")
const HP: = {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15, "risk": 0.5}
const CP: = {"speed": 7.0, "T": 1.0, "err": 1.0}
func _init():
	randomize()
	var fail := 0
	var s = SimClass.new(true, CP, HP, "CPU", 1)
	var t := 0.0
	var mx := 0.0; var smx := 0.0; var n := 0
	while t < 720.0:
		s.update(1.0 / 60.0); t += 1.0 / 60.0
		for ev in s.events:
			if ev.get("t") == "hit":
				n += 1
				var k: String = ev.get("kind", "")
				if k in ["drive", "slice", "volley"]: mx = maxf(mx, ev.spd)
				if k == "smash": smx = maxf(smx, ev.spd)
		s.events.clear()
	print("golpes=", n, " max_stroke=", snappedf(mx, 0.1), " max_smash=", snappedf(smx, 0.1))
	if mx > 62.0: print("FAIL: drive demasiado rapido ", mx); fail += 1
	if smx > 66.0: print("FAIL: remate demasiado rapido ", smx); fail += 1
	if n < 200: print("FAIL: pocos golpes"); fail += 1
	var MV = load("res://scripts/match_view.gd")
	if MV.held_ball_scale(true, false, 0.0) > 0.7: print("FAIL: bola en mano grande"); fail += 1
	if absf(MV.held_ball_scale(false, false, 0.0) - 1.0) > 0.001: print("FAIL: bola en juego no 1.0"); fail += 1
	var f = load("res://scripts/player_fig.gd").new(0, true)
	root.add_child(f)
	await process_frame
	var e := {"x": 0.0, "z": 0.0, "near": true, "speed": 0.0, "run": 0.0, "kind": "drive", "swing": 0.0, "want_t": 0.0, "want": "drive", "vx": 0.0, "vz": 0.0, "prep_t": 0.0, "wait_serve": false, "dive_t": 0.0, "getup_t": 0.0, "stumble_t": 0.0, "stumble_dir": 0.0, "hit_side": "fore", "ball_y": 1.0, "split_t": 0.0, "side": 0.0, "fat": 0.0, "recov": 0.0, "recov_lean": 0.0, "intent_side": 0.0, "plant_t": 0.0, "plant_dir": 0.0, "charge": 1.0}
	for i in 30: f.update_from_sim(e, 1.0 / 60.0)
	print("pies y=", f.position.y)
	if f.position.y < 0.045: print("FAIL: pies bajo la pista"); fail += 1
	print("gate138 ", "PASS" if fail == 0 else "FAIL")
	quit()
