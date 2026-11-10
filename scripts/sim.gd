class_name TennisSim
extends RefCounted


const L: = 23.77
const NZ: = L / 2.0
const G: = 23.0
const SOFT_V: = 46.0
const STROKE_VCAP: = 52.0
const SMASH_VCAP: = 56.0
const MAGNUS_K: = 4.0
const MAGNUS: = false
const MAG_DRAG: = 0.07
const MAG_LIFT: = 0.22


static func g_eff(spin: float) -> float:
	return clampf(G + MAGNUS_K * spin, 16.0, 30.0)
const BR: = 0.17
const NET_H: = 0.95

static func randn() -> float:
	return (randf() + randf() + randf() - 1.5) / 0.75

class Player extends RefCounted:
	var id: = 0
	var near: = false
	var x: = 0.0
	var z: = 0.0
	var vx: = 0.0
	var vz: = 0.0
	var tvx: = 0.0
	var tvz: = 0.0
	var swing: = 0.0
	var kind: = "drive"
	var cool: = 0.0
	var run: = 0.0
	var side: = 1.0
	var react: = 0.0
	var pred_for: = -1
	var tx: = 0.0
	var tz: = 0.0
	var flash: = 0.0
	var speed: = 0.0
	var want: = "drive"
	var want_t: = 0.0
	var kind_roll: = 0.5

	var plan: = ""
	var plan_left: = 0
	var plan_side: = 1.0


	var intent_side: = 0.0

	var dodge_for: = -1
	var dodge_t: = 0.0
	var letgo_for: = -1

	var plant_t: = 0.0
	var plant_dir: = 0.0

	var dive_t: = 0.0
	var dive_cool: = 0.0
	var dive_for: = -1
	var sprint_t: = 0.0
	var yank_armed: = false

	var chase: = 1.0
	var appr_t: = 0.0

	var wait_serve: = false
	var prep_t: = 0.0
	var prep_k: = 0.0

	var charge: = 0.0
	var charging: = false
	var charge_pow: = 1.0
	var aim_lx: = 0.0  # latch de dirección de golpe (29-oct): última dir. no nula desde carga/disparo hasta contacto
	var buffered_hit_t: = 0.0

	var hit_side: = "fore"


	var split_t: = 0.0
	var split_boost: = 0.0


	var recov: = 0.0


	var getup_t: = 0.0
	var contact_recovery: bool = false


	var recov_bonus: = 0.0

	var recov_lean: = 0.0


	var fat: = 0.0


	var stumble_t: = 0.0
	var stumble_cool: = 0.0
	var stumble_dir: = 0.0
	var idle_t: = 0.0
	var burst: = 0.0
	var _prev_swing: = 0.0

class Ball extends RefCounted:
	var serve_net: bool = false
	var serve_token: int = -1
	var dead_roll: bool = false
	var departing_hitter: int = -1
	var x: = 0.0
	var y: = 1.0
	var z: = 0.0
	var vx: = 0.0
	var vy: = 0.0
	var vz: = 0.0
	var bounces: = 0
	var last: = -1
	var held: = true
	var toss: = false
	var toss_t: = 0.0
	var in_play: = false
	var serving: = true
	var hit_id: = 0
	var trail: Array = []
	var hot: = 0.0
	var spin: = 0.0
	var curve: = 0.0
	var serve_jam: = false
	var kind: = "drive"
	var px: = 0.0
	var py: = 0.0
	var pz: = 0.0




class AIParams extends RefCounted:
	var speed: = 5.6
	var react: = 0.27
	var err: = 0.5
	var miss: = 0.15

	var risk: = 0.5
	var attack: = 0.0
	var serve_lo: = 47.2
	var serve_hi: = 51.0

	var style: = ""
	static func from_dict(d: Dictionary) -> AIParams:
		var p: = AIParams.new()
		for k in ["speed", "react", "err", "miss", "risk", "attack", "serve_lo", "serve_hi"]:
			if d.has(k):
				p.set(k, float(d[k]))
		if d.has("style"):
			p.style = String(d["style"])
		return p

class PlayerStats extends RefCounted:
	var speed: = 7.0
	var T: = 1.0
	var err: = 1.0
	static func from_dict(d: Dictionary) -> PlayerStats:
		var p: = PlayerStats.new()
		for k in ["speed", "T", "err"]:
			if d.has(k):
				p.set(k, float(d[k]))
		return p

class MatchState extends RefCounted:
	var pts: Array = [0, 0]
	var games: Array = [0, 0]
	var sets: Array = [0, 0]
	var server: = 0
	var sets_to_win: = 1

	var tb: = false
	var tb_pts: Array = [0, 0]
	var tb_total: = 0
	var tb_first_server: = 0

var demo: = true
var AIP: = AIParams.new()
var last_serve_tx: = 0.0
var last_serve_place: = ""
var PS: = PlayerStats.new()
var cpu_name: = "CPU"

var ball: = Ball.new()
var pl: Array = []
var M: = MatchState.new()
var state: = "serve"
var state_t: = 0.0
var serve_fault: = 0
var serve_fault_armed: = false
var serve_token: = 0
var last_fault_token: = -1
var serve_stage: = "ready"
var cpu_serve_at: = 0.0
var rut_t: = 0.0
var rut_b: = 0


static func rut_y(t: float) -> float:
	if t >= 1.65:
		return 0.95
	var b: float = (t / 0.55) - floor(t / 0.55)
	return 0.3 + 0.65 * (cos(b * TAU) * 0.5 + 0.5)
var time: = 0.0
var rally_hits: = 0
var rally_start_hit: = 0
var last_rally_hitter: = -1
var serve_unreturned: = false
var match_over: = false
var last_winner: = -1

static func _st() -> Dictionary:
	return {"aces": 0, "winners": 0, "errors": 0, "df": 0, "first_in": 0, "first_total": 0, "max_serve": 0, "points": 0}
var stats: = []
var rally_max: = 0
var let_until: = -1.0
var v112_walk: = false
var over_sent: = false
var _physics_dt: float = 0.0
var inp: = {"x": 0.0, "y": 0.0, "hit": false, "lob": false, "hit_rel": false, "drop": false}
var events: Array = []

func _init(p_demo: bool = true, p_aip: Dictionary = {}, p_ps: Dictionary = {}, p_cpu_name: String = "CPU", sets_to_win: int = 1) -> void :
	stats = [_st(), _st()]
	demo = p_demo
	if not p_aip.is_empty():
		AIP = AIParams.from_dict(p_aip)
	if not p_ps.is_empty():
		PS = PlayerStats.from_dict(p_ps)
	cpu_name = p_cpu_name
	var p0: = Player.new()
	p0.id = 0
	p0.near = true
	p0.z = -0.8
	var p1: = Player.new()
	p1.id = 1
	p1.near = false
	p1.z = L + 0.8
	pl = [p0, p1]
	M.sets_to_win = sets_to_win
	reset_match()
	start_point()

func reset_match() -> void :
	M.pts = [0, 0]
	M.games = [0, 0]
	M.sets = [0, 0]
	M.server = 0
	match_over = false
	over_sent = false

func start_point() -> void :
	state = "serve"
	state_t = 0.0
	serve_fault = 0
	prep_serve()


func prep_serve() -> void :
	ball.dead_roll = false
	ball.departing_hitter = -1
	var srv = pl[M.server]
	var rec = pl[1 - M.server]
	var sgn: = 1.0 if ((M.tb_total if M.tb else M.pts[0] + M.pts[1]) % 2) == 0 else -1.0
	var near: bool = srv.near
	srv.x = 1.4 * sgn if near else -1.4 * sgn
	srv.z = -0.9 if near else L + 0.9
	srv.vx = 0.0
	srv.vz = 0.0
	srv.swing = 0.0
	rec.x = - srv.x * 1.07
	rec.z = L + 0.6 if near else -0.6
	rec.vx = 0.0
	rec.vz = 0.0
	rec.swing = 0.0
	rec.pred_for = -1
	ball.serve_net = false
	ball.serve_token = -1
	reset_serve_ball()
	rally_hits = 0
	rally_start_hit = ball.hit_id
	last_rally_hitter = -1
	serve_unreturned = false
	for p in pl:
		p.plan = ""
		p.plan_left = 0
		p.intent_side = 0.0
	for _pl in pl:
		_pl.aim_lx = 0.0



func break_pos(e) -> Vector2:
	var sgn: = 1.0 if ((M.tb_total if M.tb else M.pts[0] + M.pts[1]) % 2) == 0 else -1.0
	var snear: bool = pl[M.server].near
	var sx: float = 1.4 * sgn if snear else -1.4 * sgn
	if M.server == e.id:
		return Vector2(sx, -0.9 if snear else L + 0.9)
	return Vector2(- sx * 1.07, L + 0.6 if snear else -0.6)


static func break_vel(d: float) -> float:
	return clampf(d * 3.0, 0.0, 2.6)

func reset_serve_ball() -> void :
	var srv = pl[M.server]
	ball.held = true
	ball.toss = false
	ball.toss_t = 0.0
	ball.in_play = false
	ball.serving = true
	ball.bounces = 0
	ball.last = -1
	ball.serve_token = -1
	serve_fault_armed = false
	ball.vx = 0.0
	ball.vy = 0.0
	ball.vz = 0.0
	ball.trail = []
	serve_stage = "ready"
	rut_t = 0.0
	rut_b = 0

	cpu_serve_at = time + 1.85 + randf_range(0.0, 0.7) if (srv.id == 1 or demo) else 0.0

func award_point(w: int, why: String, sub: String) -> void :
	if time < let_until:
		return
	if state == "point" or state == "over":
		return

	var srv: int = M.server
	stats[w].points += 1
	rally_max = maxi(rally_max, rally_hits)
	match why:
		"PUNTO":
			if rally_hits <= 1:
				stats[srv].aces += 1
			else:
				stats[w].winners += 1
		"FUERA", "RED":
			stats[1 - w].errors += 1
		"DOBLE FALTA":
			pass
	state = "point"
	state_t = 0.0
	last_winner = w
	for _pl in pl:
		_pl.aim_lx = 0.0
	ball.in_play = false
	if not ball.held:
		ball.dead_roll = true
		if Vector2(ball.vx, ball.vz).length() < 0.35:
			ball.vx = clampf(ball.x * 0.2, -1.2, 1.2)
			ball.vz = (1.0 if ball.z > NZ else -1.0) * 2.0
	var txt: = why
	var sb: = sub
	var brk: = false
	if M.tb:

		M.tb_pts[w] += 1
		M.tb_total += 1

		var k: = M.tb_total
		if k == 1:
			M.server = 1 - M.tb_first_server
		elif k >= 2 and (k - 1) % 2 == 0:
			M.server = 1 - M.server
		if M.tb_pts[w] >= 7 and M.tb_pts[w] - M.tb_pts[1 - w] >= 2:
			M.sets[w] += 1
			M.games = [0, 0]
			M.games[w] = 4
			M.games[1 - w] = 3
			M.tb = false
			M.tb_pts = [0, 0]
			txt = "SET"
			sb = "Para ti" if w == 0 else "Para " + cpu_name
			M.server = 1 - M.tb_first_server
			if M.sets[w] >= M.sets_to_win:
				match_over = true
				txt = "PARTIDO"
				sb = ""
		events.append({"t": "point", "w": w, "txt": txt, "sub": sb})
		serve_fault = 0
		return
	M.pts[w] += 1
	if M.pts[w] >= 4:
		M.games[w] += 1
		M.pts = [0, 0]
		brk = M.server != w
		M.server = 1 - M.server
		if M.games[w] >= 4 and M.games[1 - w] <= 2:
			M.sets[w] += 1
			M.games = [0, 0]
			txt = "SET"
			sb = "Para ti" if w == 0 else "Para " + cpu_name
			if M.sets[w] >= M.sets_to_win:
				match_over = true
				txt = "PARTIDO"
				sb = ""
		elif M.games[0] == 3 and M.games[1] == 3:

			M.tb = true
			M.tb_pts = [0, 0]
			M.tb_total = 0
			M.tb_first_server = M.server
			txt = "JUEGO"
			sb = "TIE-BREAK"
		else:
			txt = "JUEGO"
			sb = "Para ti" if w == 0 else "Para " + cpu_name
	elif M.pts[0] == 3 and M.pts[1] == 3:
		sb = "40-40 · punto de oro"
	events.append({"t": "point", "w": w, "txt": txt, "sub": sb, "brk": brk})
	serve_fault = 0


func fault(why: String) -> void :
	if ball.serving and state != "serve":
		state = "serve"
		state_t = 0.0
	if state != "serve" or not serve_fault_armed:
		return
	if (why == "Saque no golpeado" or why == "SIN CONTACTO") and serve_stage != "toss":
		return
	if ball.serve_token < 0 or ball.serve_token == last_fault_token:
		return
	serve_fault_armed = false
	last_fault_token = ball.serve_token
	if serve_fault == 0:
		stats[M.server].first_total += 1
	serve_fault += 1
	if serve_fault >= 2:
		stats[M.server].df += 1
		award_point(1 - M.server, "DOBLE FALTA", "")
		return
	events.append({"t": "fault", "why": why})
	ball.in_play = false
	for _p in pl:
		_p.charging = false
		_p.charge = 0.0
		_p.buffered_hit_t = 0.0
		_p.want_t = 0.0

	prep_serve()

func _sim_flight(x0: float, y0: float, z0: float, vx0: float, vy0: float, vz0: float, tmax: float) -> Dictionary:
	var r: = {"bounce_t": 99.0, "bounce_x": 0.0, "bounce_z": 0.0, "net_y": -1.0}
	if not is_finite(tmax) or tmax <= 0.0:
		return r
	tmax = minf(tmax, 3.0)
	var bx: = x0
	var by: = y0
	var bz: = z0
	var bvx: = vx0
	var bvy: = vy0
	var bvz: = vz0
	var dt: = 0.008
	var t: = 0.0
	while t < tmax:
		bvy -= g_eff(ball.spin) * dt
		if MAGNUS and ball.spin > 0.3:
			var hsp: = Vector2(bvx, bvz).length()
			bvy += minf(MAG_LIFT * ball.spin * hsp, 0.45 * G) * dt
			bvx *= 1.0 - MAG_DRAG * dt
			bvz *= 1.0 - MAG_DRAG * dt
		var pz: = bz
		bx += bvx * dt
		by += bvy * dt
		bz += bvz * dt
		t += dt
		if r.net_y < 0.0 and (pz - NZ) * (bz - NZ) < 0.0:
			r.net_y = by
		if by <= BR and bvy < 0.0:
			r.bounce_t = t
			r.bounce_x = bx
			r.bounce_z = bz
			return r
	return r


func launch_magnus(tx: float, tz: float, T0: float, y0: float, clear: float = 1.3, vcap: float = 0.0) -> void :
	var T: float = T0 * clampf(1.0 - 0.06 * ball.spin, 0.88, 1.12)
	var dx: = tx - ball.x
	var dz: = tz - ball.z
	var n: = 0
	var ncap: = 0
	while n < 14:
		var vx: = dx / T
		var vz: = dz / T
		var vy: = 6.0
		var r: = {}
		var want: = Vector2(dx, dz).length()
		for _pass in 3:
			var lo: = 0.2
			var hi: = 14.0
			for i in 20:
				vy = (lo + hi) * 0.5
				r = _sim_flight(ball.x, y0, ball.z, vx, vy, vz, T * 1.6)
				if r.bounce_t < T:
					lo = vy
				else:
					hi = vy
			if r.get("bounce_t", 99.0) > 90.0:
				break
			var got: = Vector2(r.bounce_x - ball.x, r.bounce_z - ball.z).length()
			if got > 0.5 and absf(got - want) > 0.05:
				var f: = want / got
				vx *= f
				vz *= f
			else:
				break
		var sp0: = Vector3(vx, vy, vz).length()
		if vcap > 0.0 and ncap < 30 and sp0 > SOFT_V:
			var tgt: = minf(vcap, SOFT_V + (sp0 - SOFT_V) * 0.25)
			if sp0 > tgt * 1.01:
				T *= minf(sp0 / tgt, 1.06)
				ncap += 1
				continue
		if (r.get("net_y", -1.0) >= clear and r.get("bounce_t", 99.0) < 90.0) or n >= 13:
			ball.vx = vx
			ball.vy = vy
			ball.vz = vz
			break
		T *= 1.07
		n += 1
	ball.y = max(y0, 0.35)
	ball.curve = 0.0
	ball.serve_jam = false


func launch(tx: float, tz: float, T: float, y0: float, clear: float = 1.3, vcap: float = 0.0) -> void :


	T *= clampf(1.0 - 0.06 * ball.spin, 0.88, 1.12)
	var n: = 0
	var ncap: = 0
	while true:
		var vx: = (tx - ball.x) / T
		var vz: = (tz - ball.z) / T
		var vy: = (0.5 * g_eff(ball.spin) * T * T - y0) / T
		var tn: = (NZ - ball.z) / vz
		var yn: = 9.0
		if tn > 0.0 and tn < T:
			yn = y0 + vy * tn - 0.5 * g_eff(ball.spin) * tn * tn

		if vcap > 0.0 and ncap < 30:
			var sp0: float = Vector3(vx, vy, vz).length()
			if sp0 > SOFT_V:
				var tgt: float = minf(vcap, SOFT_V + (sp0 - SOFT_V) * 0.25)
				if sp0 > tgt * 1.01:
					T *= minf(sp0 / tgt, 1.06)
					ncap += 1
					continue
		if yn >= clear or n >= 14:
			ball.vx = vx
			ball.vy = vy
			ball.vz = vz
			break
		T *= 1.07
		n += 1
	ball.y = max(y0, 0.35)
	ball.curve = 0.0
	ball.serve_jam = false


func _launch_any(tx: float, tz: float, T: float, y0: float, clear: float, vcap: float) -> void :
	if MAGNUS:
		launch_magnus(tx, tz, T, y0, clear, vcap)
	else:
		launch(tx, tz, T, y0, clear, vcap)


func _clamp_launch_speed(tx: float, tz: float, T: float, y0: float, clear: float, vcap: float, lo: float, hi: float, tmin: float, tmax: float) -> float :
	var t: float = clampf(T, tmin, tmax)
	_launch_any(tx, tz, t, y0, clear, vcap)
	var sp: float = Vector3(ball.vx, ball.vy, ball.vz).length()
	for _i in 20:
		if sp >= lo - 0.05 and sp <= hi + 0.05:
			break
		var target: float = lo if sp < lo else hi
		t = clampf(t * sp / maxf(target, 0.01), tmin, tmax)
		_launch_any(tx, tz, t, y0, clear, vcap)
		var nsp: float = Vector3(ball.vx, ball.vy, ball.vz).length()
		if absf(nsp - sp) < 0.05:
			sp = nsp
			break
		sp = nsp
	# A low contact that has to clear the net can end up below the floor with
	# the flat trajectory. Try the lofted branch as well and keep the faster one.
	if sp < lo - 0.05:
		var t2: float = clampf(t * 1.08, tmin, tmax)
		for _j in 6:
			_launch_any(tx, tz, t2, y0, clear, vcap)
			var sp2: float = Vector3(ball.vx, ball.vy, ball.vz).length()
			if sp2 > sp:
				sp = sp2
				t = t2
			if sp >= lo - 0.05 or t2 >= tmax - 0.0001:
				break
			t2 = clampf(t2 * 1.08, tmin, tmax)
		_launch_any(tx, tz, t, y0, clear, vcap)
		sp = Vector3(ball.vx, ball.vy, ball.vz).length()
	return sp


func do_hit(e: Player, kind: String, ai: bool) -> void :
	var opp = pl[1 - e.id]
	var dir: = 1.0 if e.near else -1.0
	var dx: = absf(ball.x - e.x)
	var dz: = absf(ball.z - e.z)
	var was_dive: bool = e.dive_t > 0.0

	if e.id == M.server and state == "serve" and serve_stage != "rally":
		if serve_stage == "toss" and ball.toss:
			var sq: float = 1.0 - clampf(absf(ball.toss_t - 0.5) / 0.45, 0.0, 1.0)
			if sq <= 0.02 or ball.y < 1.25:
				fault("SIN CONTACTO")
			else:
				do_serve(e, maxf(sq, 0.4), "")
		return
	var srv_ret_hit: bool = serve_unreturned and M.server != e.id
	if srv_ret_hit and ball.bounces == 0 and state == "serve":
		if ball.serve_net:
			events.append({"t": "let"})
			let_until = time + 1.2
			ball.in_play = false
			prep_serve()
			return
		var s_pb: = predict_bounce()
		if s_pb.get("ok", false):
			var sv = pl[M.server]
			var sdir: = 1.0 if sv.near else -1.0
			var sbox: = - signf(sv.x)
			var sz: float = s_pb.z
			var sx: float = s_pb.x
			var s_in_z: bool = (sz > NZ and sz <= NZ + 6.4 + BR) if sdir > 0 else (sz < NZ and sz >= NZ - 6.4 - BR)
			var s_in_x: bool = absf(sx) <= 4.11 + BR and sx * sbox >= - BR
			if not (s_in_z and s_in_x):
				fault("Fuera del cuadro")
				return
	if srv_ret_hit and state == "serve":
		state = "play"
		state_t = 0.0
		ball.serving = false
		serve_stage = "rally"
	var in_spd: = Vector3(ball.vx, ball.vy, ball.vz).length()
	var stretch: = maxf(0.0, dx - 0.8) + maxf(0.0, dz - 0.8)


	if ball.y > 2.15 and kind != "lob" and kind != "toplob" and not serve_unreturned:
		kind = "smash"



	if ball.bounces == 0 and not serve_unreturned and absf(e.z - NZ) < 6.2 and ball.y > 0.8 and kind != "lob" and kind != "toplob" and kind != "drop":
		kind = "volley"
	if not ai and e.id == 0 and e.dive_t > 0.0 and (kind == "lob" or kind == "toplob"):
		kind = "drive"


	if ai and AIP.style == "counter" and kind == "drive" and stretch > 0.0 and ball.y > 0.6 and (e.kind_roll < 0.45) and ( not (srv_ret_hit and (stretch < 1.2))):
		kind = "lob"




	var move_q: = 1.0
	if e.speed > 2.5:
		move_q = 1.0 + 0.5 * clampf((e.speed - 2.5) / 4.5, 0.0, 1.0)
	elif e.speed < 1.2 and stretch < 0.4:
		move_q = 0.85
	var aim: Dictionary
	if ai:
		aim = _ai_aim(e, opp, kind, stretch, move_q)
	else:
		aim = _player_aim(e, kind, stretch, move_q)
	if ai and srv_ret_hit and (aim.T as float) > 0.0:
		aim.T *= 1.12
	if move_q > 1.0:
		aim.T *= 1.0 + 0.12 * (move_q - 1.0)
	elif move_q < 1.0:
		aim.T *= 0.92
	if not ai and kind == "drive" and move_q > 1.2 and stretch < 0.8:
		aim.T *= 0.95
	var on_rise: bool = aim.get("rise", false)
	var perfect: bool = aim.get("perfect", false)
	var tq: String = aim.get("tq", "ok")
	var tx: float = aim.tx
	var d: float = clampf(aim.d, 0.02, 1.04)
	var T: float = aim.T
	var launch_y: float = maxf(ball.y, 0.5)
	if not ai and e.id == 0 and kind in ["drive", "slice", "volley"]:
		launch_y = maxf(launch_y, 1.0)
		if ball.y < 0.85:
			d = maxf(d, 0.78)

	if ai and kind == "drive" and stretch > 0.6:
		T *= 1.12 + 0.15 * clampf(stretch - 0.6, 0.0, 1.5)
	var run_pen: float = clampf((e.speed - 3.0) / 4.0, 0.0, 1.0)
	if run_pen > 0.0 and kind != "lob":
		var rp_err: float = AIP.err if ai else PS.err
		tx += randn() * 0.3 * run_pen * rp_err
		d += randn() * 0.05 * run_pen * rp_err


	var shot_charge: float = e.charge_pow
	if not ai and (kind == "drive" or kind == "smash") and e.charge_pow > 1.0:
		T /= e.charge_pow
		d = minf(d + 0.1 * (e.charge_pow - 1.0) / 0.6, 1.04)


		if not perfect:
			var rk: float = (e.charge_pow - 1.0) / 0.6
			tx += randn() * 0.2 * rk * PS.err
			d += randn() * 0.05 * rk * PS.err
	e.charge_pow = 1.0
	if ai:
		e.intent_side = 0.0
	if ai and e.plan_left > 0:
		e.plan_left -= 1
		if e.plan == "abierto":
			e.plan_side = - e.plan_side
		if e.plan_left <= 0:
			e.plan = ""

	ball.spin = {"drop": -1.0, "lob": 0.25, "smash": 0.5, "slice": -0.75, "volley": 0.3, "toplob": 1.1}.get(kind, 0.85)
	ball.kind = kind
	var tz: = NZ + dir * (2.2 + d * (L / 2.0 - 2.2))
	if not ai and e.id == 0 and kind not in ["drop", "lob", "toplob"]:
		var tx_margin: float = 0.15 if absf(e.aim_lx) > 0.82 else 0.45
		tx = clampf(tx, -4.115 + tx_margin, 4.115 - tx_margin)
		var extreme: bool = absf(e.aim_lx) > 0.82
		var margin: float = 0.35 if extreme else (1.0 if kind == "volley" else 1.2)
		if e.near:
			var zmax: float = L - margin
			var zmin: float = maxf(ball.z + 1.6, NZ + 1.4)
			tz = zmax if zmin > zmax else clampf(tz, zmin, zmax)
		else:
			var zmin2: float = margin
			var zmax2: float = minf(ball.z - 1.6, NZ - 1.4)
			tz = zmin2 if zmax2 < zmin2 else clampf(tz, zmin2, zmax2)
	if kind == "slice":
		T *= 0.88
	if kind == "drive" or kind == "slice":
		# Ritmo constante por distancia: T escala con la distancia real al objetivo
		# (18.1m = drive de fondo a bola profunda). Sin esto, un drive a media pista
		# sale con el mismo T que uno de fondo -> globo lento (65-70 HUD) regalado.
		T *= clampf(absf(tz - ball.z) / 17.0, 0.55, 1.0)  # cap 1.0 (decisión 29-oct): media pista más rápida, fondo como 0.191
	if srv_ret_hit:

		e.recov_bonus = clampf((in_spd - 14.0) / 2.0, 0.0, 1.0) * 0.25

		if ball.serve_jam:
			e.recov_bonus += 0.15
			tx += randn() * 0.35 * (AIP.err if ai else PS.err)
			d += randn() * 0.06 * (AIP.err if ai else PS.err)




	if e.dive_t <= 0.0:
		e.recov_bonus += clampf(stretch, 0.0, 2.0) * (0.22 if ( not demo and e.id == 0) else 0.18)




		if stretch > 0.6:
			var ldir: float = signf(ball.x - e.x)
			if ldir == 0.0:
				ldir = signf(e.vx)
			e.recov_lean = clampf(stretch, 0.0, 2.0) * 0.14 * ldir
		else:
			e.recov_lean = 0.0















	var nc_floor: = 1.1
	if kind == "drive":
		nc_floor = 1.02
	elif kind == "slice":
		nc_floor = 1.07
	elif kind == "drop" or kind == "volley":
		nc_floor = 1.0
	elif kind == "smash":
		nc_floor = 1.1
	elif kind == "lob" or kind == "toplob":
		nc_floor = 1.3
	var _vcap: = (SMASH_VCAP if kind == "smash" else (STROKE_VCAP if kind in ["drive", "slice", "volley"] else 0.0))
	if MAGNUS:
		var dirz2: float = signf(tz - NZ)
		if dirz2 != 0.0:
			tz = NZ + dirz2 * minf(absf(tz - NZ), L / 2.0 - 0.25)
		tx = clampf(tx, -3.7, 3.7)
		launch_magnus(tx, tz, T, launch_y, nc_floor, _vcap)
	else:
		launch(tx, tz, T, launch_y, nc_floor, _vcap)
	var before_skim: Vector3 = Vector3(ball.vx, ball.vy, ball.vz)
	var explicit_skim_risk: bool = false
	var nc_skim: = 0.0
	if kind == "drive" and (stretch > 0.35 or move_q > 1.05 or ball.y < 0.8):
		nc_skim = 1.11
	elif kind == "volley":
		nc_skim = 1.13
	elif kind == "drop":
		nc_skim = 1.11
	elif kind == "smash":
		nc_skim = 1.18
	if nc_skim > 0.0 and ball.vz != 0.0:
		var nc_sig: = (0.03 + 0.02 * stretch + 0.025 * maxf(move_q - 1.0, 0.0)) * (AIP.err if ai else PS.err)
		if perfect:
			nc_sig *= 0.5
		nc_skim += randn() * nc_sig


		if stretch > 0.35 and randf() < 0.035 * (AIP.err if ai else PS.err):
			nc_skim -= 0.1 + randf() * 0.08
			explicit_skim_risk = true






		var nc_forced: = false
		if stretch > 0.35 and randf() < 0.035 * (AIP.err if ai else PS.err):
			nc_skim -= 0.1 + randf() * 0.08
			explicit_skim_risk = true
			nc_forced = true
		var dzs: float = tz - ball.z
		if dzs != 0.0 and ball.vz != 0.0:
			var yn0: float = launch_y
			var r: float = (NZ - ball.z) / dzs
			var tn0: float = (NZ - ball.z) / ball.vz
			if MAGNUS and absf(tz - NZ) > 4.0:
				var rr0: = _sim_flight(ball.x, yn0, ball.z, ball.vx, ball.vy, ball.vz, tn0 * 3.0 + 0.5)
				if rr0.get("net_y", -1.0) > nc_skim:
					var dirz: float = signf(tz - NZ)
					if dirz == 0.0:
						dirz = 1.0
					var tz2: float = NZ + dirz * minf(absf(tz - NZ), L / 2.0 - 0.25)
					var tx2: float = clampf(tx, -3.7, 3.7)
					launch_magnus(tx2, tz2, absf(dzs) / absf(ball.vz), yn0, 0.0, 0.0)
			else:
				var yn_cur: float = yn0 + ball.vy * tn0 - 0.5 * g_eff(ball.spin) * tn0 * tn0
				if yn_cur > nc_skim:
					var applied: = false
					if r > 0.0 and r < 1.0:
						var t2: float = (nc_skim - yn0 * (1.0 - r)) / (0.5 * g_eff(ball.spin) * r * (1.0 - r))
						if t2 > 0.04:
							var Tn: float = sqrt(t2)
							if absf(dzs) / Tn <= absf(ball.vz) * 1.18:
								ball.vy = (0.5 * g_eff(ball.spin) * t2 - yn0) / Tn
								ball.vz = dzs / Tn
								ball.vx = (tx - ball.x) / Tn
								applied = true
					if not applied and nc_forced:
						ball.vy -= (yn_cur - nc_skim) / tn0
	# Do not turn a safe launch into a netcord through analytic skim rounding.
	# Explicit shot risks and their random draws remain unchanged.
	if not ai and not demo and e.id == 0 and kind == "drive" and not explicit_skim_risk and nc_skim >= NET_H + 0.08 and not MAGNUS and ball.curve == 0.0 and absf(_physics_dt - 1.0 / 60.0) < 0.0000001:
		var before_cross: float = _skim_cross_height(before_skim)
		var after_cross: float = _skim_cross_height(Vector3(ball.vx, ball.vy, ball.vz))
		if before_cross >= NET_H + 0.08 and after_cross > 0.0 and after_cross < NET_H + 0.08:
			ball.vx = before_skim.x
			ball.vy = before_skim.y
			ball.vz = before_skim.z
	if not ai and not demo and e.id == 0 and e.dive_t > 0.0:
		e.dive_t = 0.0
		e.getup_t = 0.55
		e.contact_recovery = true
	ball.last = e.id
	ball.departing_hitter = e.id
	ball.bounces = 0
	ball.serving = false
	ball.in_play = true
	ball.hit_id += 1
	if last_rally_hitter != e.id:
		rally_hits += 1
	last_rally_hitter = e.id
	serve_unreturned = false
	e.swing = 0.34

	if e.speed > 2.5 and kind in ["drive", "slice", "toplob", "volley"]:
		e.plant_t = 0.35
		e.plant_dir = signf(e.vx) if absf(e.vx) > 1.0 else 0.0



		if e.plant_dir != 0.0:
			var rl: float = e.plant_dir * (0.08 + clampf((e.speed - 2.5) / 4.5, 0.0, 1.0) * 0.1)
			e.recov_lean = clampf(e.recov_lean + rl, -0.26, 0.26)
	e.kind = kind


	e.hit_side = "fore" if ((ball.x < e.x) == e.near) else "back"
	e.cool = 0.4
	e.flash = 0.22 if aim.get("tper", false) else 0.12
	e.want_t = 0.0
	if ai and kind == "drive":
		var _hkmh: float = Vector3(ball.vx, ball.vy, ball.vz).length() * 4.0
		var _ic: = 0
		while _hkmh > 164.0 and _ic < 4:
			T = minf(T * _hkmh / 162.0, 1.7)
			if MAGNUS:
				launch_magnus(tx, tz, T, max(ball.y, 0.5), nc_floor, STROKE_VCAP)
			else:
				launch(tx, tz, T, max(ball.y, 0.5), nc_floor, STROKE_VCAP)
			_hkmh = Vector3(ball.vx, ball.vy, ball.vz).length() * 4.0
			_ic += 1
	if not ai and not demo and e.id == 0 and kind in ["drive", "slice", "volley"]:
		var _forced: bool = dx > 1.15 or move_q > 1.05 or ball.y <= 0.85 or on_rise or tq in ["late", "early", "rise"]
		var _lo: float = 31.94 if _forced else 37.5
		var _hi: float = 33.3 if _forced else 43.1
		var _tmin: float = 0.08 if _forced else 0.12
		if was_dive:
			_lo = 34.7
			_hi = 40.0
			_tmin = 0.12
		_clamp_launch_speed(tx, tz, T, launch_y, nc_floor, _vcap, _lo, _hi, _tmin, 2.2)
	if not ai and e.id == 0 and kind == "drop":
		_clamp_launch_speed(tx, tz, T, launch_y, nc_floor, _vcap, 29.17, 34.0, 0.08, 2.2)
	if kind == "slice":
		_clamp_launch_speed(tx, tz, T, launch_y, nc_floor, _vcap, 30.0, 34.5, 0.12, 2.2)
	if kind in ["drive", "slice", "volley", "smash"]:
		var _floor_sp: float = Vector3(ball.vx, ball.vy, ball.vz).length()
		var _floor_min: float = 33.3 if ai else 31.94
		if _floor_sp < _floor_min:
			var _ff: float = _floor_min / maxf(_floor_sp, 0.01)
			ball.vx *= _ff
			ball.vy *= _ff
			ball.vz *= _ff
	var spd: = Vector3(ball.vx, ball.vy, ball.vz).length()
	ball.hot = clampf((spd - 24.0) / 20.0, 0.0, 1.0)
	events.append({"t": "hit", "id": e.id, "kind": kind, "x": ball.x, "y": ball.y, "z": ball.z, "rise": on_rise, "perfect": perfect, "tper": aim.get("tper", false), "spd": spd, "charge": shot_charge, "tq": tq, "jam": srv_ret_hit and ball.serve_jam, "stretch": snappedf(stretch, 0.01)})

	if ai and AIP.style == "sv" and kind in ["drive", "slice", "volley"] and rally_hits <= 6:
		e.appr_t = maxf(e.appr_t, 1.6)
	var other = pl[1 - e.id]
	if other.swing <= 0.0 and other.dive_t <= 0.0 and other.charging == false:
		other.split_t = 0.32



func _ai_aim(e: Player, opp: Player, kind: String, stretch: float, move_q: float = 1.0) -> Dictionary:
	var D = AIP
	var tx: = 0.0
	var d: = 0.0
	var T: = 1.0


	var base_side: float = e.intent_side if e.intent_side != 0.0 else (-1.0 if opp.x > 0 else 1.0)
	if e.intent_side == 0.0 and D.err < 0.4 and absf(opp.vx) > 1.6 and absf(opp.x) < 3.4:
		base_side = -signf(opp.vx)
	tx = base_side * randf_range(1.8, 3.9)
	if stretch > 1.2 and (kind == "lob" or kind == "slice"):
		tx = clampf(tx * 0.3, -1.2, 1.2)
	if randf() < 0.14:
		tx = randf_range(-0.8, 0.8)
	if kind == "toplob":

		d = 0.82
		T = 1.15
	elif kind == "lob":
		d = 0.9
		T = 1.5
	elif kind == "drop":
		d = 0.12
		T = 1.0
	elif kind == "slice":

		d = 0.55
		T = 1.05
	elif kind == "volley":

		d = 0.55
		T = 0.4
		if absf(opp.x) > 0.8:
			tx = clampf( - signf(opp.x) * randf_range(1.6, 3.4), -3.9, 3.9)

		if ball.y < 1.05:
			d = 0.4
			T *= 1.25
			tx += randn() * D.err * 0.4
		else:
			T *= 0.92
	elif kind == "smash":
		d = 0.55
		T = 0.52
	else:
		d = 0.62 + randf() * 0.36
		T = 0.64 + (1.0 - d) * 0.14
		if D.style == "power":
			d = maxf(d, 0.78)
			T *= 0.95
	if absf(opp.x) > 3.0 and kind != "drop":
		tx = clampf( - signf(opp.x) * randf_range(2.6, 3.8), -3.9, 3.9)
		d = minf(d + 0.15, 1.0)
		T *= 0.95


	var reversing: bool = absf(opp.vx) > 2.5
	var opp_net: bool = absf(opp.z - NZ) < 4.2
	var clear_chance: bool = absf(opp.x) > 2.4 or reversing or opp_net



	var aggro: float = clampf(0.15 + rally_hits * 0.12 + D.attack * 0.65, 0.15, 0.85)
	if kind != "drop" and kind != "lob" and clear_chance and randf() < aggro:
		if reversing:
			tx = clampf( - signf(opp.vx) * randf_range(2.8, 3.9), -3.9, 3.9)
		else:
			var _lo: float = 2.8 + 0.4 * D.attack
			tx = clampf(signf(tx) * randf_range(_lo, 3.9), -3.9, 3.9)
		T *= 0.85 - 0.12 * D.risk
		d = minf(d + 0.12, 1.0)
		tx += randn() * D.err * 0.5
	elif opp_net and kind == "drive" and not stretch:
		T *= 0.94
		d = maxf(d, 0.78)


	if e.plan_left > 0 and (kind == "drive" or kind == "slice"):
		if e.plan == "pina" or e.plan == "abierto":
			tx = clampf(e.plan_side * randf_range(2.4, 3.6), -3.9, 3.9)
			d = maxf(d, 0.75)
		elif e.plan == "dejada" and e.plan_left > 1:
			tx = clampf(tx, -2.0, 2.0)
			d = maxf(d, 0.8)
	tx += randn() * D.err * (0.5 + stretch * 0.7) * move_q
	d += randn() * 0.08 * D.err * move_q
	return {"tx": tx, "d": d, "T": T}




func _player_aim(e: Player, kind: String, stretch: float, move_q: float = 1.0) -> Dictionary:
	var on_rise: = false
	var perfect: = false
	var es_late_swing: = false
	var late_contact: = false
	var tx: = 0.0
	var d: = 0.0
	var T: = 1.0

	var tx_lim: = 4.05 if e.charge_pow >= 1.25 else 3.9
	# Acoplamiento diana-contacto atenuado por intención: con dirección plena el
	# offset pesa 0.35 (antes 1.4 fijo), así el cruzado estirado sale cruzado.
	# La penalización defensiva se conserva vía dispersión (ruido ∝ stretch) y
	# menor ritmo; sin dirección (inp.x=0) el comportamiento es el de 0.191.
	# Sustento: capture-route/aim_matrix.gd (antes/después en LEEME).
	var ax: float = e.aim_lx
	var aim_coup: = 1.4 * (1.0 - 0.75 * absf(ax))
	var chg: float = clampf((e.charge_pow - 1.0) / 0.6, 0.0, 1.0)
	var aim_span: float = 3.0 + 0.9 * chg
	tx = clamp(ax * aim_span + (ball.x - e.x) * aim_coup, - tx_lim, tx_lim)
	var up: bool = inp.y > 0.4
	var opp_net: bool = absf(pl[1 - e.id].z - NZ) < 4.2
	if kind == "toplob":


		d = 0.8
		T = 1.15 * PS.T
	elif kind == "lob":
		d = 0.88
		T = 1.55
	elif kind == "drop":
		d = 0.1
		T = 1.0
	elif kind == "slice":

		d = 0.55
		T = 1.05 * PS.T
	elif kind == "volley":

		d = 0.72 if up else 0.55
		T = 0.4 * PS.T


		if ball.y < 1.05:
			T *= 1.25
			d = minf(d, 0.4)
		else:
			T *= 0.92
	elif kind == "smash":
		d = 0.5 + (0.3 if up else 0.0)
		T = 0.52 * PS.T
		if absf(ax) < 0.3:
			var ox: float = pl[1 - e.id].x
			var side: float = -signf(ox)
			if side == 0.0:
				side = signf(tx) if absf(tx) > 0.2 else 1.0
			tx = clampf(side * 2.8, -3.6, 3.6)
	else:
		d = 0.95 if up else 0.62

		T = (0.66 if up else 0.72) * PS.T


		if ball.vy > 1.0:
			on_rise = true
			T *= 0.88
			d = minf(d + 0.06, 1.0)



			if serve_unreturned:
				T *= 0.94


		if ball.vy < -0.5 and ball.y < 0.62:
			late_contact = true
			T *= 1.08

	if kind == "drive" and opp_net and absf(ax) > 0.3:
		T *= 0.94
		d = minf(d + 0.05, 1.0)

	if kind == "drive" or kind == "smash":
		var pdx: = absf(ball.x - e.x)
		var pdz: = absf(ball.z - e.z)
		perfect = pdx < 0.75 and pdz > 0.25 and pdz < 1.05 and ball.y > 0.85 and ball.y < 1.45
	if perfect:
		T *= 0.78
		d = minf(d + 0.12, 1.0)




	var swing_el: float = clampf(0.3 - e.swing, 0.0, 0.3)
	var tper: = false
	if (kind == "drive" or kind == "smash" or kind == "slice") and e.dive_t <= 0.0:
		if swing_el >= 0.2:
			T *= 1.1
			d *= 0.94
			es_late_swing = true
		elif swing_el <= (0.14 if e.speed < 1.2 else 0.1) and perfect:
			tper = true
	var es: float = 0.25 if perfect else 1.0
	if tper:
		es *= 0.6
		T *= 0.95
	if es_late_swing:
		es *= 1.35
	if late_contact:
		es *= 1.4
	if kind == "toplob":
		es *= 1.35
	elif kind == "slice":
		es *= 0.6
	elif kind == "volley":
		es *= 0.7
		if ball.y < 1.05:
			es *= 1.5
	var hq: float = clampf(1.0 - absf(ball.y - 1.05) / 1.6, 0.35, 1.0)
	var qf: float = 2.0 - hq
	es *= move_q
	tx += randn() * (0.12 + stretch * 0.55) * PS.err * qf * es
	d += randn() * (0.03 + stretch * 0.07) * PS.err * qf * es
	if on_rise:
		tx += randn() * 0.18 * PS.err * es
		d += randn() * 0.05 * PS.err * es
	d *= 0.85 + 0.15 * hq

	var tq: = "ok"
	if tper:
		tq = "perfect+"
	elif es_late_swing:
		tq = "early"
	elif perfect:
		tq = "perfect"
	elif late_contact:
		tq = "late"
	elif on_rise:
		tq = "rise"
	return {"tx": tx, "d": d, "T": T, "rise": on_rise, "perfect": perfect, "tq": tq, "tper": tper}

func do_serve(e: Player, q: float, stype: String = "") -> void :
	var serve_spin: = 0.6
	var serve_curve: = 0.0
	serve_unreturned = true
	var dir: = 1.0 if e.near else -1.0
	var box_sign: = - signf(e.x)
	var tx: = 0.0
	var tzr: = 0.0
	var err: = 0.0
	var serve_T: = 1.0
	if e.id == 0 and not demo:
		tx = box_sign * clamp(2.0 + inp.x * box_sign * 1.6, 0.7, 3.4)





		var flat: bool = inp.y > 0.4 and stype == ""
		var safe: bool = stype == "slice"
		var kick: bool = stype == "kick"
		tzr = 6.0 if flat else (4.3 if safe else (4.6 if kick else 4.9))
		err = ((1.0 - q) * 0.9 + 0.08) * PS.err
		err *= 1.0 + 1.7 * clampf((absf(tx) - 1.5) / 2.3, 0.0, 1.0)
		if safe or kick:
			err *= 0.75
		serve_T = 0.74 * 0.9 * (lerpf(1.06, 0.8, q) if flat else (lerpf(1.25, 1.0, q) if safe else (lerpf(1.3, 1.05, q) if kick else lerpf(1.12, 0.84, q))))
		if safe:
			serve_spin = 0.55
			serve_curve = box_sign * 1.8
		elif kick:
			serve_spin = 0.95
	else:

		var rec = pl[1 - e.id]
		if serve_fault > 0:

			tx = box_sign * randf_range(0.9, 3.3)
			tzr = randf_range(4.2, 5.3)
			err = 0.08 + 0.28 * AIP.err
			serve_T = 1.05
			serve_spin = randf_range(0.75, 1.0)


			if AIP.risk > 0.6 and randf() < 0.15:
				tx = box_sign * randf_range(3.0, 3.7)
				tzr = randf_range(5.2, 5.9)
				err = (AIP.err * 0.7 + 0.1) * 1.15
				serve_T = 0.95
				serve_spin = 0.5
			var df_p: float = 0.004 + 0.02 * AIP.err
			if randf() < df_p:
				if randf() < 0.5:
					tzr = 7.05 + randf_range(0.0, 0.4)
				else:
					tx = box_sign * randf_range(4.35, 4.75)
		else:


			var rec_pos: float = clampf(rec.x * box_sign, 0.0, 4.0)



			var wide_p: = 0.45
			var t_p: = 0.25
			if rec_pos > 2.2:
				wide_p = 0.2;t_p = 0.45
			elif rec_pos < 1.0:
				wide_p = 0.58;t_p = 0.15
			var gamble: = randf()
			if gamble < wide_p:
				tx = box_sign * randf_range(3.9, 4.05)
				last_serve_place = "wide"
			elif gamble < wide_p + t_p:
				tx = box_sign * randf_range(0.8, 1.2)
				last_serve_place = "T"
			elif gamble < 0.9:
				tx = box_sign * clampf(rec_pos + randf_range(-0.3, 0.3), 0.7, 3.4)
				last_serve_place = "body"
			else:
				tx = box_sign * randf_range(1.0, 3.5)
				last_serve_place = "rand"
			tzr = randf_range(5.6, 6.1) if AIP.attack >= 0.2 else randf_range(5.4, 6.2)
			err = 0.55 + 0.30 * AIP.err
			var base_T: float = 0.9 if AIP.speed < 5.0 else (0.89 if AIP.speed < 6.2 else 0.76)



			var pace: = randf()
			var bomb_p: float = 0.1 + 0.2 * AIP.risk


			var p_s: int = M.pts[e.id]
			var p_r: int = M.pts[1 - e.id]
			if p_r >= 3 and p_r > p_s:
				bomb_p += 0.14
			elif p_s >= 3 and p_r <= 1:
				bomb_p *= 0.45


			if AIP.style == "sv":
				bomb_p += 0.1
				base_T *= 0.97
			elif AIP.style == "counter":
				bomb_p *= 0.6
				base_T *= 1.05
				err *= 0.85
			elif AIP.style == "power":
				bomb_p += 0.18
				base_T *= 0.94
				err *= 1.12
			var kick_p: float = bomb_p + 0.22
			var slice_p: float = kick_p + 0.16
			if pace < bomb_p:
				serve_T = base_T * 0.92
				serve_spin = 0.45
			elif pace < kick_p:
				serve_T = base_T * 1.16
				serve_spin = 0.95
			elif pace < slice_p:

				serve_T = base_T * 1.04
				serve_spin = 0.6
				serve_curve = box_sign * randf_range(1.3, 1.9)
			else:
				serve_T = base_T * randf_range(0.97, 1.06)

			if serve_fault == 0 and randf() < 0.2:
				tx = box_sign * clampf(absf(pl[0].x), 0.5, 3.6)
				last_serve_place = "body"

	var sv_chance: float = 0.92 if AIP.style == "sv" else (0.05 if AIP.style == "counter" else (0.08 if AIP.style == "power" else 0.15))
	var surf_sv: float = 1.25 if surface == "grass" else (0.8 if surface == "clay" else 1.0)
	if (e.id == 1 or demo) and serve_fault == 0 and randf() < sv_chance * surf_sv:
		e.appr_t = 2.8
	tx += randn() * err
	tzr += randn() * err * (0.9 if (e.id == 0 and not demo and inp.y > 0.4) else 0.8)
	last_serve_tx = tx
	if e.id == 0:
		ball.spin = serve_spin
	launch(tx, NZ + dir * tzr, serve_T, max(ball.y, 2.0), 1.06)



	var sspd: = Vector3(ball.vx, ball.vy, ball.vz).length()
	if e.id == 1:
		var _slo: float = randf_range(AIP.serve_lo, AIP.serve_hi) if serve_fault == 0 else randf_range(37.5, 40.0)
		var _shi: float = AIP.serve_hi + 3.2 if serve_fault == 0 else 43.1
		sspd = _clamp_launch_speed(tx, NZ + dir * tzr, serve_T, max(ball.y, 2.0), 1.14, 0.0, _slo, _shi, 0.18, 1.6)
		if AIP.attack >= 0.35 and sspd < AIP.serve_lo:
			var _sf: float = AIP.serve_lo / maxf(sspd, 0.01)
			ball.vx *= _sf
			ball.vy *= _sf
			ball.vz *= _sf
			sspd = Vector3(ball.vx, ball.vy, ball.vz).length()
	elif not demo and e.id == 0:
		var _first: bool = serve_fault == 0
		var _kick: bool = stype == "slice" or stype == "kick"
		var _slo: float = (36.1 if _first else 34.7) if _kick else (45.0 if _first else 37.5)
		var _shi: float = (38.9 if _first else 36.1) if _kick else (48.6 if _first else 40.3)
		sspd = _clamp_launch_speed(tx, NZ + dir * tzr, serve_T, max(ball.y, 2.0), 1.14, 0.0, _slo, _shi, 0.18, 1.0)
	ball.spin = serve_spin
	ball.curve = serve_curve
	ball.hot = clampf((sspd - 24.0) / 20.0, 0.0, 1.0)
	ball.last = e.id
	ball.bounces = 0
	ball.in_play = true
	ball.held = false
	ball.toss = false
	ball.serving = true
	ball.hit_id += 1
	e.swing = 0.24 if e.id == 0 else 0.24
	e.kind = "serve"
	ball.kind = "serve"
	if serve_fault == 0:
		stats[e.id].first_in += 1
		stats[e.id].first_total += 1
	stats[e.id].max_serve = maxi(stats[e.id].max_serve, int(round(sspd * 3.6)))
	events.append({"t": "serve", "id": e.id, "q": q, "spd": sspd, "x": ball.x, "y": ball.y, "z": ball.z})
	if e.near:
		e.z += 0.35
	else:
		e.z -= 0.35



	var sr_other = pl[1 - e.id]

	if sr_other.swing <= 0.0 and sr_other.dive_t <= 0.0:

		sr_other.split_t = 0.32
	serve_stage = "hit"
	rally_hits = 1
	rally_start_hit = ball.hit_id
	last_rally_hitter = e.id

func toss_ball() -> void :
	serve_token += 1
	ball.serve_token = serve_token
	serve_fault_armed = true
	ball.held = false
	ball.toss = true
	ball.toss_t = 0.0
	ball.vy = 10.5
	ball.vx = 0.0
	ball.vz = 0.0
	serve_stage = "toss"
	events.append({"t": "toss"})




var surface: = "hard"

func _surface_mv() -> float:
	if surface == "clay":
		return 0.94
	if surface == "grass":
		return 1.04
	return 1.0

func _bounce_factors(s: float) -> Array:


	var vy_f: = 0.74
	var damp: = 0.79
	if s > 0.2:
		vy_f = 0.72 + 0.05 * s
		damp = 0.79 + 0.16 * s
	elif s < -0.2:
		vy_f = 0.72 + 0.06 * s
		damp = 0.79 + 0.12 * s



		if s <= -0.9:
			vy_f *= 0.85
			damp *= 0.75



	if surface == "clay":
		vy_f *= 1.1
		damp *= 0.9
		if s > 0.2:
			vy_f *= 1.0 + 0.06 * s
	elif surface == "grass":
		vy_f *= 0.88
		damp *= 1.06
		if s > 0.2:
			vy_f *= 1.0 - 0.06 * s
	else:
		vy_f *= 0.96
		damp *= 1.03
	return [vy_f, minf(damp, 1.05)]



func _intercept(e: Player) -> Array:
	var bx: = ball.x
	var by: = ball.y
	var bz: = ball.z
	var bvx: = ball.vx
	var bvy: = ball.vy
	var bvz: = ball.vz
	var bf: = _bounce_factors(ball.spin)
	var zc: float = e.z + 0.55
	var dt: = 0.02
	var t: = 0.0
	while t < 1.0:
		bvy -= g_eff(ball.spin) * dt
		if MAGNUS and ball.spin > 0.3 and not ball.serving:
			var _hsp: float = Vector2(bvx, bvz).length()
			bvy += minf(MAG_LIFT * ball.spin * _hsp, 0.45 * G) * dt
			bvx *= 1.0 - MAG_DRAG * dt
			bvz *= 1.0 - MAG_DRAG * dt
		bx += bvx * dt
		by += bvy * dt
		bz += bvz * dt
		t += dt
		if by <= BR and bvy < 0.0:
			by = BR
			bvy = - bvy * bf[0]
			bvx *= bf[1]
			bvz *= bf[1]
		if bz <= zc:
			return [bx, bz, t]
		if by > 3.4:
			break
	return [0.0, 0.0, -1.0]



func _assist(e: Player) -> void :
	var est: = _intercept(e)
	if est[2] < 0.0:
		return
	var tx: float = est[0] - 0.28 * e.side


	var tz: float = est[1] + (-0.55 if e.near else 0.55)
	var ddx: float = tx - e.x
	var ddz: float = tz - e.z
	var dist: = Vector2(ddx, ddz).length()
	if dist > 2.9 or dist < 0.12:
		return
	var base_sp: float = PS.speed if ( not demo and e.id == 0) else AIP.speed
	var sp: = minf(base_sp * 1.35 * _surface_mv(), dist / 0.22)
	e.tvx = ddx / dist * sp
	e.tvz = ddz / dist * sp

func step_ball(dt: float) -> void :


	if ball.dead_roll and not ball.held and not ball.in_play and state == "point":
		ball.vy -= G * dt
		ball.x += ball.vx * dt
		ball.z += ball.vz * dt
		ball.y += ball.vy * dt
		if ball.y <= BR:
			ball.y = BR
			ball.vy = - ball.vy * 0.2 if ball.vy < -0.8 else 0.0
			ball.vx *= maxf(0.0, 1.0 - 2.8 * dt)
			ball.vz *= maxf(0.0, 1.0 - 2.8 * dt)
		return
	var sv = pl[M.server]
	var sdir: = 1.0 if sv.near else -1.0
	if ball.held:


		rut_t += dt
		ball.x = sv.x + 0.28
		ball.z = sv.z + 0.3 * sdir
		var ny: float = rut_y(rut_t)
		if rut_b < int(rut_t / 0.55) and rut_t < 1.66:
			rut_b = int(rut_t / 0.55)
			events.append({"t": "rut_bounce"})
		ball.y = ny
		ball.vx = 0.0
		ball.vy = 0.0
		ball.vz = 0.0
		return
	if ball.toss:
		ball.toss_t += dt
		ball.vy -= g_eff(ball.spin) * dt
		ball.y += ball.vy * dt
		ball.x = sv.x + 0.28
		ball.z = sv.z + 0.3 * sdir
		if ball.vy < 0.0 and ball.y <= 0.25:
			ball.toss = false
			ball.vy = 0.0
			ball.held = true
			ball.y = 0.25
			fault("Saque no golpeado")
		return
	if not ball.in_play and state != "point":
		return
	var pz: = ball.z
	ball.px = ball.x
	ball.py = ball.y
	ball.pz = ball.z
	ball.trail.append(Vector3(ball.x, ball.y, ball.z))
	if ball.trail.size() > 9:
		ball.trail.pop_front()
	ball.vy -= g_eff(ball.spin) * dt
	if MAGNUS and ball.spin > 0.3 and ball.in_play and not ball.serving:
		var _hsp: = Vector2(ball.vx, ball.vz).length()
		ball.vy += minf(MAG_LIFT * ball.spin * _hsp, 0.45 * G) * dt
		ball.vx *= 1.0 - MAG_DRAG * dt
		ball.vz *= 1.0 - MAG_DRAG * dt

	if ball.curve != 0.0 and ball.bounces == 0:
		ball.vx += ball.curve * dt
	ball.x += ball.vx * dt
	ball.y += ball.vy * dt
	ball.z += ball.vz * dt
	if ball.in_play and (pz - NZ) * (ball.z - NZ) < 0 and ball.y < NET_H + (0.03 if state == "serve" else 0.08):


		if ball.y >= NET_H and state == "play" and randf() < 0.55:
			events.append({"t": "netcord"})
			ball.vx *= 0.35
			ball.vz *= randf_range(0.05, 0.3)
			if randf() < 0.35:
				ball.vz = - absf(ball.vz) * 0.18
			ball.vy = minf(ball.vy, 0.4)
			ball.spin = 0.0
			return
		if ball.y >= NET_H:
			if state == "serve":
				events.append({"t": "netcord"})
				ball.vx *= 0.3
				ball.vz *= randf_range(0.05, 0.25)
				ball.vy = minf(ball.vy, 0.3)
				ball.spin = 0.0
				ball.serve_net = true
			return
		events.append({"t": "net"})
		ball.vx *= 0.22
		ball.vz = (-1.0 if pz < NZ else 1.0) * clampf(absf(ball.vz) * 0.08, 0.25, 1.3)
		ball.dead_roll = state == "play"
		ball.vy = minf(ball.vy, 0.4)
		ball.z = NZ + (0.06 if pz > NZ else -0.06)
		ball.in_play = false
		if state == "serve":
			fault("Red")
		else:
			award_point(1 - ball.last, "RED", "")
		return


	if ball.in_play and (state == "play" or state == "serve"):
		for i in 2:
			var bp = pl[i]
			var bdx: float = ball.x - bp.x
			var bdz: float = ball.z - bp.z
			# A legal shot can start behind its hitter. Let it leave the
			# hitter's body once, without suppressing later body contacts.
			if ball.departing_hitter == i:
				var outward: float = bdx * ball.vx + bdz * ball.vz
				if (bdx * bdx + bdz * bdz >= 0.36 and outward >= 0.0) or ball.y >= 1.8 or ball.vz * (1.0 if bp.near else -1.0) <= 0.0:
					ball.departing_hitter = -1
				else:
					continue
			if bdx * bdx + bdz * bdz < 0.2 and ball.y > 0.12 and ball.y < 1.62:
				var toward: float = (bp.x - ball.x) * ball.vx + (bp.z - ball.z) * ball.vz
				if toward > 0.0 and bp.want_t <= 0.0 and bp.swing <= 0.0:
					ball.in_play = false
					events.append({"t": "body", "who": i, "x": ball.x, "y": ball.y, "z": ball.z})
					if state == "serve" and ball.serve_net:
						# ITF 22a: saque roza la red y luego toca al restador antes de botar -> let.
						events.append({"t": "let"})
						let_until = time + 1.2
						prep_serve()
					else:
						# ITF 24 caso 7: saque limpio que toca al restador antes de botar -> punto del SACADOR.
						award_point(1 - i, "PUNTO", "Bola al cuerpo")
					return
	if ball.in_play and ball.bounces >= 1 and (ball.z < -2.3 or ball.z > L + 2.3 or absf(ball.x) > 6.5) and state == "play" and not ball.serving:
		ball.in_play = false
		award_point(ball.last, "PUNTO", "")
		return
	if ball.y <= BR and ball.vy < 0:
		ball.y = BR
		var sp: = absf(ball.vy)
		var bf: = _bounce_factors(ball.spin)
		if ball.kind == "slice" and ball.bounces == 0:
			bf[0] *= 0.62
			bf[1] *= 1.15




		if serve_unreturned and ball.bounces == 0:
			bf[0] = 0.63 + 0.04 * ball.spin
			bf[1] = 0.78
		ball.vy = - ball.vy * bf[0]
		ball.vx *= bf[1]
		ball.vz *= bf[1]
		if absf(ball.vy) < 1.2:
			ball.vy = 0.0

		if ball.in_play:
			events.append({"t": "bounce", "v": clamp(sp / 10.0, 0.2, 1.0), "x": ball.x, "z": ball.z, "sp": ball.spin, "vz": ball.vz})
			ball.bounces += 1
			if ball.bounces == 1:


				if serve_unreturned and absf(ball.x - pl[1 - M.server].x) < 0.5:
					ball.serve_jam = true
				judge_landing()
			elif ball.bounces >= 2:
				ball.in_play = false
				if state == "play":
					award_point(ball.last, "PUNTO", "Dos botes")



			if ball.in_play and ball.vy == 0.0 and ball.bounces >= 1 and state == "play":
				ball.in_play = false
				award_point(ball.last, "PUNTO", "Dos botes")



	if ball.in_play and state == "play" and ball.bounces >= 1 and ball.y <= BR + 0.02 and absf(ball.vy) < 0.05:
		ball.in_play = false
		award_point(ball.last, "PUNTO", "Dos botes")

func judge_landing() -> void :
	var hitter = pl[ball.last]
	var dir: = 1.0 if hitter.near else -1.0
	var x: = ball.x
	var z: = ball.z



	var eps: = BR
	var on_opp: bool = z > NZ if dir > 0 else z < NZ
	if ball.serving:
		var box_sign: = - signf(hitter.x)
		var in_z: bool
		if dir > 0:
			in_z = z > NZ and z <= NZ + 6.4 + eps
		else:
			in_z = z < NZ and z >= NZ - 6.4 - eps
		var in_x: bool = absf(x) <= 4.11 + eps and x * box_sign >= - eps
		if in_z and in_x:
			serve_fault_armed = false
			if ball.serve_net:
				events.append({"t": "let"})
				let_until = time + 1.2
				ball.in_play = false
				prep_serve()
				return
			state = "play"
			state_t = 0.0
			ball.serving = false
			serve_stage = "rally"
			return
		ball.in_play = false
		fault("Fuera del cuadro" if on_opp else "Red")
		return


	var inside: bool = absf(x) <= 4.115 + eps and z >= - eps and z <= L + eps
	if on_opp and inside:
		return
	ball.in_play = false
	award_point(1 - ball.last, "FUERA", "" if on_opp else "Bola corta")

func predict(e: Player) -> Vector3:
	var bx: = ball.x
	var by: = ball.y
	var bz: = ball.z
	var bvx: = ball.vx
	var bvy: = ball.vy
	var bvz: = ball.vz
	var bn: = ball.bounces
	var dt: = 0.02
	var lob_intercept: bool = ball.kind in ["lob", "toplob"] and ball.bounces == 0
	for i in 220:
		bvy -= g_eff(ball.spin) * dt
		if MAGNUS and ball.spin > 0.3 and not ball.serving:
			var _hsp: float = Vector2(bvx, bvz).length()
			bvy += minf(MAG_LIFT * ball.spin * _hsp, 0.45 * G) * dt
			bvx *= 1.0 - MAG_DRAG * dt
			bvz *= 1.0 - MAG_DRAG * dt
		bx += bvx * dt
		by += bvy * dt
		bz += bvz * dt
		# Meet a reachable lob while it descends into overhead height,
		# instead of always chasing its high rebound beyond the baseline.
		if lob_intercept and bn == 0 and bvy < 0.0 and by > 2.2 and by < 2.65 and (bz < NZ - 1.0 if e.near else bz > NZ + 1.0):
			var elapsed: float = (i + 1) * dt
			var reach: float = AIP.speed * 1.3 * maxf(elapsed - e.react - 0.2, 0.0)
			if Vector2(bx - e.x, bz - e.z).length() < reach:
				return Vector3(bx, by, bz)
		if by <= BR and bvy < 0:
			by = BR
			var bf: = _bounce_factors(ball.spin)
			if ball.kind == "slice" and bn == 0:
				bf[0] *= 0.62
				bf[1] *= 1.15
			bvy *= - bf[0]
			bvx *= bf[1]
			bvz *= bf[1]
			bn += 1
		var past: bool = bz < -1.6 if e.near else bz > L + 1.6
		if (bn >= 1 and by < 1.5 and bvy < 0 and (bz < 4.5 if e.near else bz > L - 4.5)) or past:
			break
	return Vector3(bx, by, bz)


func predict_bounce() -> Dictionary:
	var r: = {"ok": false, "x": 0.0, "z": 0.0, "t": 0.0}
	if not ball.in_play:
		return r
	var bx: = ball.x
	var by: = ball.y
	var bz: = ball.z
	var bvx: = ball.vx
	var bvy: = ball.vy
	var bvz: = ball.vz
	var dt: = 0.02
	var t: = 0.0
	for i in 220:
		bvy -= g_eff(ball.spin) * dt
		if MAGNUS and ball.spin > 0.3 and not ball.serving:
			var _hsp: float = Vector2(bvx, bvz).length()
			bvy += minf(MAG_LIFT * ball.spin * _hsp, 0.45 * G) * dt
			bvx *= 1.0 - MAG_DRAG * dt
			bvz *= 1.0 - MAG_DRAG * dt
		bx += bvx * dt
		by += bvy * dt
		bz += bvz * dt
		t += dt
		if by <= BR and bvy < 0:
			r.ok = true
			r.x = bx
			r.z = bz
			r.t = t
			return r
	return r

func ai_control(e: Player, dt: float) -> void :
	var D = AIP
	var dir: = 1.0 if e.near else -1.0
	var opp = pl[1 - e.id]
	if state == "point" and e.id == last_winner:

		e.wait_serve = false
		e.tvx = 0.0
		e.tvz = 0.0
		return
	if state == "point" and v112_walk:


		e.wait_serve = false
		if e.id == last_winner and state_t < 1.1:
			e.tvx = 0.0
			e.tvz = 0.0
			return
		var bp: = break_pos(e)
		var bx: = bp.x - e.x
		var bz: = bp.y - e.z
		var bd: = Vector2(bx, bz).length()
		if bd > 0.12:
			var bv: float = break_vel(bd)
			e.tvx = bx / bd * bv
			e.tvz = bz / bd * bv
		else:
			e.tvx = 0.0
			e.tvz = 0.0
		return
	if state == "serve" and M.server == e.id and not (serve_stage == "hit" and AIP.style == "sv" and e.appr_t > 0.0):
		e.tvx = 0.0
		e.tvz = 0.0
		return
	var coming: bool = ball.in_play and ball.last != e.id and ball.vz * dir < 0 and (state == "play" or state == "serve")
	var tx: = clampf(ball.x * 0.3, -2.0, 2.0)
	var tz: = -1.0 if e.near else L + 1.0
	e.wait_serve = state == "serve" and M.server != e.id
	if e.wait_serve:


		var srv = pl[M.server]
		tx = - signf(srv.x) * 2.2
		tz = -0.6 if e.near else L + 0.6
	var mv: float = D.speed * 0.7
	e.dodge_t = maxf(0.0, e.dodge_t - dt)
	e.appr_t = maxf(0.0, e.appr_t - dt)
	e.want_t = maxf(0.0, e.want_t - dt)
	if not coming and e.appr_t > 0.0 and (state == "play" or (state == "serve" and serve_stage == "hit" and AIP.style == "sv" and M.server == e.id)):


		tx = clampf(ball.x * 0.5, -1.6, 1.6)
		tz = (NZ - 1.35) if e.near else (NZ + 1.35)
		mv = D.speed * 1.28
	if coming:
		if e.pred_for != ball.hit_id and e.dodge_t <= 0.0 and e.letgo_for != ball.hit_id:
			e.pred_for = ball.hit_id
			var srv_ret: bool = serve_unreturned and M.server != e.id


			var alerta: bool = srv_ret or rally_hits <= 4


			e.react = (D.react * (0.55 if srv_ret else 0.4) + randf_range(0.0, 0.04)) if alerta else (D.react * 0.5 + randf_range(0.0, 0.06))


			e.chase = 1.0
			if ball.kind == "drop" and not srv_ret:
				e.react *= 0.35
				e.chase = 1.3
			var p: = predict(e)
			e.tx = p.x + randn() * D.err * (0.35 if srv_ret else 0.6)
			e.tz = p.z + (-0.2 if e.near else 0.2) + randn() * D.err * 0.3
			if ball.bounces == 0 and not srv_ret and ball.kind != "lob" and ball.kind != "toplob":
				var short_pb: = predict_bounce()
				if short_pb.ok and absf(short_pb.x) <= 4.115 and short_pb.z >= 0.0 and short_pb.z <= L:
					var short_land: bool = (short_pb.z > 5.9) if e.near else (short_pb.z < L - 5.9)
					if short_land:
						e.tz = short_pb.z + (-0.35 if e.near else 0.35)



			if e.appr_t > 0.0 and ball.kind != "lob":




				e.tz = maxf(e.tz, NZ - 3.2) if e.near else minf(e.tz, NZ + 3.2)
			e.kind_roll = randf()


			if e.dive_t <= 0.0 and e.dive_cool <= 0.0 and e.swing <= 0.0 and e.letgo_for != ball.hit_id:
				var dpd: = Vector2(e.tx - e.x, e.tz - e.z).length()
				var t_est: float = (e.z - ball.z) / ball.vz if absf(ball.vz) > 2.0 else 99.0
				var pbd: = predict_bounce()
				var alive_d: bool = ball.bounces >= 1 or (pbd.ok and absf(pbd.x) <= 4.115 and pbd.z >= 0.0 and pbd.z <= L)
				var gap: float = dpd - D.speed * 1.48 * maxf(t_est - 0.12, 0.0)
				var _spd_in: float = Vector3(ball.vx, ball.vy, ball.vz).length()
				var _show_dive: bool = gap > 1.8 and dpd < 5.2 and _spd_in > 36.0 and ball.kind in ["drive", "volley"] and e.kind_roll < 0.2
				if alive_d and t_est > 0.12 and t_est < 0.75 and absf(ball.x - e.x) > 3.6 and ((gap > 2.0 and dpd < 5.2) or _show_dive):
					e.dive_t = 0.55
					e.dive_cool = 3.2
					e.dive_for = ball.hit_id
					e.react = 0.0
					var dl: = maxf(dpd, 0.1)
					e.vx = (e.tx - e.x) / dl * 10.5
					e.vz = (e.tz - e.z) / dl * 10.5
					events.append({"t": "dive", "id": e.id, "hid": ball.hit_id})




		if e.dodge_for != ball.hit_id and e.dodge_t <= 0.0 and absf(ball.vz) > 8.0:
			var t_arr: float = (e.z - ball.z) / ball.vz
			if t_arr > 0.02 and t_arr < 1.2:
				var xa: float = ball.x + ball.vx * t_arr
				var ya: float = ball.y + ball.vy * t_arr - 0.5 * g_eff(ball.spin) * t_arr * t_arr
				if absf(xa - e.x) < 0.5 and ya > 0.25 and ya < 1.65:
					var locked: bool = e.swing > 0.05 or e.cool > 0.05
					var pb: = predict_bounce()




					var playable: bool = ball.bounces >= 1 or (pb.ok and absf(pb.x) <= 4.115 and pb.z >= 0.0 and pb.z <= L)

					var clear_out: bool = pb.ok and (absf(pb.x) > 4.115 + 0.85 or pb.z < -0.85 or pb.z > L + 0.85)
					if not playable and not clear_out:
						playable = true









					var no_time: bool = playable and ball.bounces == 0 and t_arr < 0.32 and absf(ball.vz) > 24.0
					if locked or not playable or no_time:
						e.dodge_for = ball.hit_id
						if not playable:
							e.letgo_for = ball.hit_id


						var chance: float = (1.0 if ball.kind == "smash" else 0.45) if no_time else clampf(1.05 - D.err, 0.45, 0.97)
						if randf() < chance:
							var side_d: float = signf(e.x - xa)
							if side_d == 0.0:
								side_d = 1.0 if e.x >= 0.0 else -1.0
							e.tx = clampf(e.x + side_d * randf_range(1.2, 1.7), -5.4, 5.4)
							e.tz = e.z
							e.react = 0.0
							e.dodge_t = 0.35
							if playable:


								e.pred_for = -1
								e.dodge_t = 0.26


							e.vx = side_d * 7.5
							e.vz = 0.0
							events.append({"t": "dodge", "id": e.id, "hid": ball.hit_id})
		e.react -= dt
		if e.react <= 0.0:
			tx = e.tx
			tz = e.tz


			mv = D.speed * (1.48 if (serve_unreturned and M.server != e.id) else maxf(e.chase, 1.3))
	mv *= _surface_mv()
	var ex: = tx - e.x
	var ez: = tz - e.z
	var d: = Vector2(ex, ez).length()
	if d > 0.08:
		var m: float = min(mv, d * 8.0)
		e.tvx = ex / d * m
		e.tvz = ez / d * m
	else:
		e.tvx = 0.0
		e.tvz = 0.0
	if coming and e.cool <= 0.0 and e.swing <= 0.0 and e.getup_t <= 0.0:
		var dx: = absf(ball.x - e.x)
		var dz: = absf(ball.z - e.z)
		var srv_ret2: bool = serve_unreturned and M.server != e.id




		var gx: = 1.6 if srv_ret2 else 1.35
		var gz: = 1.5 if srv_ret2 else 1.25



		if e.appr_t > 0.0 and ball.bounces == 0:
			gx *= 1.45
			gz *= 1.35
		if e.dive_t > 0.0:
			gx *= 1.8
			gz *= 1.8



		if e.want_t <= 0.0 and e.letgo_for != ball.hit_id and ball.y < 3.4:
			var dist: = Vector2(ball.x - e.x, ball.z - e.z).length()
			var to_p: = Vector2(e.x - ball.x, e.z - ball.z)
			var closing: = (ball.vx * to_p.x + ball.vz * to_p.y) / maxf(dist, 0.05)
			var tta: = dist / maxf(closing, 5.0)
			if tta < 0.55:

				e.want = "drive"
				e.want_t = 0.3

				if e.intent_side == 0.0:

					e.intent_side = e.plan_side if e.plan_left > 0 else (-1.0 if opp.x > 0.0 else 1.0)



		if e.want_t > 0.0 and e.swing <= 0.0 and e.dive_t <= 0.0 and ball.last != e.id and ball.vz * (1.0 if e.near else -1.0) < 0.0:
			_assist(e)





		var volley_zone: = absf(ball.z - NZ) < 3.2
		var ymax: = 2.35 if volley_zone else 1.8
		if ball.y > 2.15 and not (serve_unreturned and M.server != e.id):
			ymax = 2.7
		if dx < gx and dz < gz and ball.y < ymax and ball.y > 0.15 and e.letgo_for != ball.hit_id and (state != "serve" or ball.bounces >= 1):
			var stretch: = dx > 1.0 or dz > 1.0

			var miss_p: float = D.miss * (0.35 if srv_ret2 else 1.0)
			if not (stretch and randf() < miss_p):
				var kind: = "drive"
				var r: float = e.kind_roll



				if absf(opp.x) > 2.4 or absf(opp.vx) > 2.5:




					var appr_k: float = 0.9 if D.style == "sv" else (0.2 if D.style == "counter" else 0.55)
					if ((e.z > -1.6) if e.near else (e.z < L + 1.6)) and randf() < D.risk * appr_k:
						e.appr_t = 2.8


				var opp_deep: bool = (opp.z < 0.3) if opp.near else (opp.z > L - 0.3)
				var opp_net: bool = (opp.z > 5.5) if opp.near else (opp.z < L - 5.5)
				var opp_wide: bool = absf(opp.x) > 2.8
				var self_inside: bool = (e.z > -1.6) if e.near else (e.z < L + 1.6)



				if e.plan_left <= 0 and rally_hits <= 2 and not stretch and randf() < 0.3 + 0.25 * D.risk:
					var pr: = randf()
					if absf(opp.x) > 0.5:
						e.plan_side = - signf(opp.x)
					else:
						e.plan_side = 1.0 if randf() < 0.5 else -1.0
					e.intent_side = e.plan_side
					if pr < 0.4:
						e.plan = "pina"
					elif pr < 0.7:
						e.plan = "abierto"
					else:
						e.plan = "dejada"
					e.plan_left = 3


				if (opp_net or (opp.appr_t > 0.5)) and not srv_ret2:
					if r < 0.26 and not stretch:
						kind = "toplob"
					elif r < 0.44:
						kind = "lob"
					elif r < 0.56 and ball.y < 1.5:




						kind = "drop"
				elif opp_deep and self_inside and D.err < 0.8:


					var drop_p: float = 0.1 + 0.1 * D.risk + (0.16 if opp_wide else 0.0)
					if r > 1.0 - drop_p:
						kind = "drop"
				if e.plan == "dejada" and e.plan_left == 1 and self_inside and kind == "drive":



					kind = "drop"
				if kind == "drive" and stretch and ( not (srv_ret2 and (dx < 1.6) and (dz < 1.6))):


					var _smag: float = maxf(0.0, dx - 1.0) + maxf(0.0, dz - 1.0)
					var def_lob_p: float = 0.05 + (0.9 - D.err) * 0.06 + (1.0 - D.risk) * 0.08 + minf(_smag * 0.05, 0.1)
					if ball.kind == "smash":
						def_lob_p += 0.25
					elif ball.kind == "drop":
						def_lob_p += 0.15
					if r < def_lob_p:
						kind = "lob"
					elif r < def_lob_p + 0.18 + minf(_smag * 0.12, 0.22):
						kind = "slice"
				do_hit(e, kind, true)
				if e.appr_t <= 0.0 and not stretch and (kind == "drive" or kind == "slice"):
					var short_contact: bool = (ball.z > 3.0) if e.near else (ball.z < L - 3.0)
					var chip_charge: bool = srv_ret2 and D.style == "sv"
					var attack_pos: bool = short_contact or chip_charge or ((opp_deep or opp_wide) and d > 0.7)
					var appr_p: float = 0.45 if D.style == "sv" else (0.04 if D.style == "counter" else (0.12 if D.style == "power" else 0.18))
					if chip_charge:
						appr_p += 0.2
					var surf_appr: float = 1.25 if surface == "grass" else (0.8 if surface == "clay" else 1.0)
					if attack_pos and randf() < appr_p * (0.7 + 0.6 * D.risk) * surf_appr:
						e.appr_t = 2.4
			else:
				e.cool = 0.3
				e.swing = 0.3
				e.kind = "drive"


func _in_hit_win(e: Player, bx: float, by: float, bz: float, gx: float, gz: float, ymax: float) -> bool:

	var behind: float = 0.55
	if not demo and e.id == 0:
		behind = 2.4 if e.dive_t <= 0.0 else 2.5
	var h_behind: bool = (bz < e.z - behind) if e.near else (bz > e.z + behind)
	var lat: float = gx
	var bh_side: float = 1.0 if e.near else -1.0
	if (bx - e.x) * bh_side > 0.0:
		lat += 0.45
	return absf(bx - e.x) < lat and absf(bz - e.z) < gz and by < ymax and not h_behind

func human_control(e: Player, dt: float) -> void :
	if state != "play":
		e.buffered_hit_t = 0.0
	var smv: float = _surface_mv()
	e.tvx = inp.x * PS.speed * smv
	e.tvz = inp.y * PS.speed * smv
	if state == "point":
		if e.id == last_winner:
			e.tvx = 0.0
			e.tvz = 0.0
			return

		if Vector2(inp.x, inp.y).length() < 0.25:
			var bp: = break_pos(e)
			var bx: = bp.x - e.x
			var bz: = bp.y - e.z
			var bd: = Vector2(bx, bz).length()
			if bd > 0.12:
				var bv: float = break_vel(bd)
				e.tvx = bx / bd * bv
				e.tvz = bz / bd * bv
			else:
				e.tvx = 0.0
				e.tvz = 0.0
		elif Vector2(inp.x, inp.y).length() < 0.25:
			e.tvx = 0.0
			e.tvz = 0.0
	e.wait_serve = state == "serve" and M.server != e.id
	var strike_ok: bool = state == "play" or (state == "serve" and serve_unreturned and M.server != e.id)
	if state == "play" and ball.last == e.id and not e.charging and e.swing <= 0.0 and e.want_t <= 0.0 and e.getup_t <= 0.0 and e.dive_t <= 0.0 and Vector2(inp.x, inp.y).length() < 0.25:
		var rx: float = clampf(ball.x * 0.15, -0.8, 0.8)
		var rdx: float = rx - e.x
		if absf(rdx) > 0.12:
			e.tvx = signf(rdx) * minf(PS.speed * 0.55 * smv, absf(rdx) * 3.0)
		else:
			e.tvx = 0.0
		e.tvz = 0.0


	if e.dive_t <= 0.0 and e.dive_cool <= 0.0 and e.swing <= 0.0 and state == "play" and ball.in_play and ball.last != e.id and ball.vz < 0.0 and e.speed > 5.0:
		var bdist: = Vector2(ball.x - e.x, ball.z - e.z).length()
		var bto: = Vector2(e.x - ball.x, e.z - ball.z)
		var bclose: = (ball.vx * bto.x + ball.vz * bto.y) / maxf(bdist, 0.05)
		var tta: = bdist / maxf(bclose, 5.0)
		var h_gap: float = bdist - PS.speed * maxf(tta - 0.12, 0.0)


		if tta < 0.5 and h_gap > 2.0 and bdist > 3.2 and bdist < 4.8 and absf(ball.x - e.x) > 3.6 and e.dive_for != ball.hit_id:
			e.dive_t = 0.55
			e.dive_cool = 3.2
			e.dive_for = ball.hit_id
			var bl: = maxf(bdist, 0.1)
			e.vx = (ball.x - e.x) / bl * 10.5
			e.vz = (ball.z - e.z) / bl * 10.5
			if e.want_t <= 0.0:
				e.want = "drive"
				e.want_t = 0.3
			events.append({"t": "dive", "id": e.id, "hid": ball.hit_id})
	# Preserve a normal-shot press made just before recovery ends.
	# It cannot hit during getup and does not change the legal contact window.
	e.buffered_hit_t = maxf(0.0, e.buffered_hit_t - dt)
	if inp.lob or inp.drop:
		e.buffered_hit_t = 0.0
	if inp.hit and e.getup_t > 0.0 and e.getup_t <= 0.15 and state == "play":
		e.buffered_hit_t = 0.2
	var want_hit: bool = inp.hit
	if e.buffered_hit_t > 0.0 and e.getup_t <= 0.0 and state == "play":
		want_hit = true
		e.buffered_hit_t = 0.0
	var want_lob: bool = inp.lob
	var want_drop: bool = inp.drop
	var rel_hit: bool = inp.hit_rel
	inp.hit = false
	# Latch de dirección (opción b, 29-oct): captura la última dirección lateral
	# no nula entre carga/disparo y contacto; soltar el stick conserva la
	# intención y reorientar sigue funcionando. Se borra al terminar/cancelar el
	# swing (y en punto/resaque, abajo): sin arrastre entre golpes. Si no hay
	# dirección en toda la ventana, aim_lx=0 y la diana se comporta como 0.191.
	if e.swing <= 0.0 and not e.charging and e.dive_t <= 0.0 and e.want_t <= 0.0:
		e.aim_lx = 0.0
	elif absf(inp.x) > 0.05:
		e.aim_lx = inp.x
	inp.lob = false
	inp.hit_rel = false
	inp.drop = false
	if state == "serve" and M.server == 0:
		if want_hit or want_lob:
			if serve_stage == "ready":
				toss_ball()
			elif serve_stage == "toss":

				var _st: = "kick" if want_lob else ("slice" if inp.y < -0.4 else "")
				var _q: float = 1.0 - clamp(absf(ball.toss_t - 0.5) / 0.45, 0.0, 1.0)
				if _q <= 0.03 or ball.y < 1.25:
					# Intento de swing sin contacto o dejar caer el lanzamiento = falta.
					e.swing = 0.3
					events.append({"t": "swing_miss"})
					fault("SIN CONTACTO")
				else:
					do_serve(e, maxf(_q, 0.4), _st)

		return




	# Explicit shot selection cancels an armed drive before contact.
	if (want_lob or want_drop) and state == "play" and ball.in_play and e.getup_t <= 0.0:
		e.charging = false
		e.charge = 0.0
	if want_hit and not e.charging and e.getup_t <= 0.0 and ((state == "play" or state == "serve") and ball.in_play):
		e.charging = true
		e.charge = 0.0
		e.aim_lx = 0.0
	elif want_hit or want_lob or want_drop:

		if e.swing <= 0.0 and strike_ok and ball.in_play and e.getup_t <= 0.0:
			e.swing = 0.3
			e.aim_lx = inp.x
			var _dk1: = "drop" if absf(e.z - NZ) < 7.0 and e.speed < 2.0 else "slice"
			var _lb1: = "toplob" if inp.y > 0.4 else "lob"
			e.kind = _lb1 if want_lob else (_dk1 if want_drop else "drive")
			e.want = e.kind
			e.want_t = 0.6
	if e.charging and ((state != "play" and state != "serve") or not ball.in_play):
		e.charging = false
		e.charge = 0.0
	if e.charging:
		if e.speed < 2.5:
			e.charge = minf(1.0, e.charge + dt / 0.85)
		elif e.speed > 4.0:
			e.charge = maxf(0.0, e.charge - dt * 2.0)
		e.prep_t = 0.25
		if rel_hit and not (state == "serve" and ball.in_play):


			var _fire_now: = false
			if strike_ok and ball.in_play and e.swing <= 0.0 and e.getup_t <= 0.0 and ball.last != e.id and ball.vz < 0.0 and e.cool <= 0.0:
				var _rv: = absf(ball.z - NZ) < 3.2
				var _rm: = 2.35 if _rv else 2.2
				if ball.y > 2.15:
					_rm = 2.7

				_fire_now = _in_hit_win(e, ball.x, ball.y, ball.z, 2.9, 2.5, _rm) or _in_hit_win(e, (ball.x + ball.px) * 0.5, (ball.y + ball.py) * 0.5, (ball.z + ball.pz) * 0.5, 2.9, 2.5, _rm)
			if not _fire_now and strike_ok and ball.in_play and ball.last != e.id and ball.vz < 0.0:
				pass
			else:
				e.charging = false
			if _fire_now:

				var late: = false
				if e.charge >= 0.5 and ball.last != e.id and ball.vz < 0.0 and ball.y > 2.4:
					late = false
				if late and ball.last != e.id and ball.vz < 0.0:
					var pd2: = Vector2(ball.x - e.x, ball.z - e.z).length()
					var pt2: = Vector2(e.x - ball.x, e.z - ball.z)
					var pc2: = (ball.vx * pt2.x + ball.vz * pt2.y) / maxf(pd2, 0.05)
					late = pd2 / maxf(pc2, 5.0) < 0.18
				e.charge_pow = 1.0 if late else 1.0 + 0.6 * e.charge
				e.swing = 0.3
				var _lb2: = "toplob" if inp.y > 0.4 else "lob"
				e.kind = "lob" if late else (_lb2 if want_lob else "drive")
				e.want = e.kind
				e.want_t = 0.3
				events.append({"t": "charge_fire", "p": snappedf(e.charge_pow, 0.01), "late": late})


	if e.charging and strike_ok and ball.in_play and ball.last != e.id and ball.vz < 0.0 and e.cool <= 0.0 and e.getup_t <= 0.0 and e.dive_t <= 0.0:
		_assist(e)
		var a_volley: = absf(ball.z - NZ) < 3.2
		var amax: = 2.35 if a_volley else 2.2
		if ball.y > 2.15:
			amax = 2.7
		if _in_hit_win(e, ball.x, ball.y, ball.z, 2.9, 2.5, amax) or _in_hit_win(e, (ball.x + ball.px) * 0.5, (ball.y + ball.py) * 0.5, (ball.z + ball.pz) * 0.5, 2.9, 2.5, amax):
			e.charging = false
			e.charge_pow = 1.0 + 0.6 * e.charge
			e.swing = 0.3
			e.kind = "drive"
			e.want = e.kind
			e.want_t = 0.3
			events.append({"t": "charge_fire", "p": snappedf(e.charge_pow, 0.01), "late": false, "auto": true})
	if e.want_t > 0.0:
		e.want_t -= dt
		if ball.in_play and ball.last != e.id and ball.vz < 0 and e.cool <= 0.0 and strike_ok and e.getup_t <= 0.0:
			_assist(e)
			var hgx: = 2.9
			var hgz: = 2.5
			if e.dive_t > 0.0:
				hgx = 3.05
				hgz = 2.65


			var h_volley: = absf(ball.z - NZ) < 3.2
			var hmax: = 2.35 if h_volley else 2.2
			if ball.y > 2.15:
				hmax = 2.7

			if _in_hit_win(e, ball.x, ball.y, ball.z, hgx, hgz, hmax) or _in_hit_win(e, (ball.x + ball.px) * 0.5, (ball.y + ball.py) * 0.5, (ball.z + ball.pz) * 0.5, hgx, hgz, hmax):
				e.swing = 0.3
				do_hit(e, e.want, false)
				e.want_t = 0.0

func update_player(e: Player, dt: float) -> void :
	e.prep_t = maxf(0.0, e.prep_t - dt)
	var _pk_target: = 0.0
	var _pz_sign: = 1.0 if e.near else -1.0
	if e.swing <= 0.0 and e.want_t <= 0.0 and ball.in_play and ball.last != e.id and ball.vz * _pz_sign < 0.0 and state == "play":
		var pdist: = Vector2(ball.x - e.x, ball.z - e.z).length()
		var pto: = Vector2(e.x - ball.x, e.z - ball.z)
		var pclose: = (ball.vx * pto.x + ball.vz * pto.y) / maxf(pdist, 0.05)
		if pdist / maxf(pclose, 5.0) < 1.4:
			e.prep_t = 0.25
		var _ptn: float = pdist / maxf(pclose, 5.0)
		if _ptn < 1.4:
			_pk_target = clampf(1.0 - _ptn / 1.4, 0.0, 1.0)
	e.prep_k = lerpf(e.prep_k, _pk_target, minf(1.0, dt * (10.0 if _pk_target > e.prep_k else 6.0)))

	e.cool = max(0.0, e.cool - dt)
	e.swing = max(0.0, e.swing - dt)
	e.flash = max(0.0, e.flash - dt)

	var _prev_dive: float = e.dive_t
	e.dive_t = max(0.0, e.dive_t - dt)
	e.plant_t = maxf(0.0, e.plant_t - dt)
	if _prev_dive > 0.0 and e.dive_t <= 0.0:
		e.getup_t = 0.55
	e.getup_t = maxf(0.0, e.getup_t - dt)
	if e.getup_t <= 0.0:
		e.contact_recovery = false

	if e.split_t > 0.0:
		var prev_split: float = e.split_t
		e.split_t = maxf(0.0, e.split_t - dt)
		if prev_split > 0.14 and e.split_t <= 0.14:
			e.split_boost = 0.22
	e.split_boost = maxf(0.0, e.split_boost - dt)
	e.dive_cool = max(0.0, e.dive_cool - dt)



	if e.swing <= 0.0 and e._prev_swing > 0.0:



		var _rec_base: float = 0.05 if ( not demo and e.id == 0) else 0.1
		e.recov = (0.0 if e.getup_t > 0.0 else {"smash": 0.3, "serve": 0.13}.get(e.kind, _rec_base)) + e.recov_bonus

		if not demo and e.id == 0:
			e.recov = minf(e.recov, 0.08)
		elif e.speed > 3.5:
			e.recov = minf(e.recov, 0.45) * 0.7
		e.recov_bonus = 0.0
	e._prev_swing = e.swing
	e.recov = maxf(0.0, e.recov - dt)
	if e.recov > 0.0 and e.dive_t <= 0.0:
		var rf: float = clampf(1.0 - e.recov / 0.26, 0.78 if ( not demo and e.id == 0) else 0.4, 1.0)
		e.tvx *= rf
		e.tvz *= rf


	if e.getup_t > 0.0 and not e.contact_recovery:
		var gf: float = clampf(1.0 - e.getup_t / 0.55, 0.0, 1.0)
		e.tvx *= gf * gf
		e.tvz *= gf * gf


	var tv_len: = Vector2(e.tvx, e.tvz).length()
	if tv_len > 3.0:
		if e.idle_t > 0.16 and e.speed < 1.6 and e.burst <= 0.0 and e.recov <= 0.0 and e.dive_t <= 0.0 and e.getup_t <= 0.0 and e.stumble_t <= 0.0 and state != "point" and state != "over":
			e.burst = 0.16
			var iv: = Vector2(e.tvx, e.tvz).normalized()
			e.vx += iv.x * 1.6
			e.vz += iv.y * 1.6
		e.idle_t = 0.0
	else:
		e.idle_t += dt
	e.burst = maxf(0.0, e.burst - dt)



	e.stumble_cool = maxf(0.0, e.stumble_cool - dt)
	var _sp_now: = Vector2(e.vx, e.vz).length()
	var _tv_now: = Vector2(e.tvx, e.tvz).length()




	var _sth: float = PS.speed if e.id == 0 else AIP.speed



	if _sp_now > _sth:
		e.sprint_t += dt
	elif _sp_now < _sth * 0.9:
		e.sprint_t = 0.0


	var _dot: = 1.0
	if _sp_now > 0.5 and _tv_now > 3.0:
		_dot = (e.vx * e.tvx + e.vz * e.tvz) / (_sp_now * _tv_now)
	if _sp_now > _sth and _dot > -0.3:
		e.yank_armed = true
	if e.stumble_t <= 0.0 and e.stumble_cool <= 0.0 and e.dive_t <= 0.0 and e.getup_t <= 0.0 and e.sprint_t > 0.45 and _sp_now > _sth and e.yank_armed and _dot < -0.85:
		e.yank_armed = false
		if randf() < 0.5:
			e.stumble_t = 0.4
			e.stumble_cool = 12.0
			e.stumble_dir = signf(e.vx) if absf(e.vx) >= absf(e.vz) else 0.0
			events.append({"t": "stumble", "id": e.id})
	e.stumble_t = maxf(0.0, e.stumble_t - dt)
	if e.stumble_t > 0.0:
		e.tvx *= 0.25
		e.tvz *= 0.25


	if e.speed > 5.5:
		e.fat = minf(1.0, e.fat + dt / 4.0)
	elif e.speed < 4.0:
		e.fat = maxf(0.0, e.fat - dt / 3.0)
	if e.fat > 0.0:
		var fat_k: float = 1.0 - 0.1 * e.fat
		e.tvx *= fat_k
		e.tvz *= fat_k


	var kvx: = 11.0
	var kvz: = 11.0
	if e.dive_t > 0.0:
		kvx = 2.2
		kvz = 2.2
	if e.tvx == 0.0:
		kvx = 16.0 if (e.swing > 0.0 or e.want_t > 0.0) else 7.5
	elif signf(e.tvx) != signf(e.vx) and absf(e.vx) > 2.2:
		kvx = 5.5 if ( not demo and e.id == 0) else 4.2
	if e.tvz == 0.0:
		kvz = 16.0 if (e.swing > 0.0 or e.want_t > 0.0) else 7.5
	elif signf(e.tvz) != signf(e.vz) and absf(e.vz) > 2.2:
		kvz = 5.5 if ( not demo and e.id == 0) else 4.2
	if not demo and e.id == 0 and e.getup_t > 0.0 and e.contact_recovery:
		if e.vx * inp.x < 0.0:
			kvx = maxf(kvx, 11.0)
		if e.vz * inp.y < 0.0:
			kvz = maxf(kvz, 11.0)
	if e.split_boost > 0.0:
		kvx *= 1.6
		kvz *= 1.6
	if e.burst > 0.0:
		kvx *= 1.9
		kvz *= 1.9


	if state == "serve" and serve_stage in ["ready", "toss"] and M.server == e.id:

		e.tvx = 0.0
		e.tvz = 0.0
	if state == "point" or state == "over":

		var _wsp: = Vector2(e.tvx, e.tvz).length()
		if _wsp > 2.6:
			e.tvx *= 2.6 / _wsp
			e.tvz *= 2.6 / _wsp
		if e.x > 4.7:
			e.tvx = minf(e.tvx, 0.0)
		elif e.x < -4.7:
			e.tvx = maxf(e.tvx, 0.0)
		if e.near:
			if e.z > NZ - 4.2:
				e.tvz = minf(e.tvz, 0.0)
			elif e.z < -3.2:
				e.tvz = maxf(e.tvz, 0.0)
		else:
			if e.z < NZ + 4.2:
				e.tvz = maxf(e.tvz, 0.0)
			elif e.z > L + 3.2:
				e.tvz = minf(e.tvz, 0.0)
	e.vx += (e.tvx - e.vx) * minf(1.0, dt * kvx)
	e.vz += (e.tvz - e.vz) * minf(1.0, dt * kvz)
	if state == "point" or state == "over":
		var _vsp: = Vector2(e.vx, e.vz).length()
		if _vsp > 3.2:
			e.vx *= 3.2 / _vsp
			e.vz *= 3.2 / _vsp
	e.x += e.vx * dt
	e.z += e.vz * dt
	if state == "serve" and M.server == e.id and not (serve_stage == "hit" and AIP.style == "sv" and e.appr_t > 0.0 and (demo or e.id == 1)):


		var _sgn: = 1.0 if ((M.tb_total if M.tb else M.pts[0] + M.pts[1]) % 2) == 0 else -1.0
		var _sside: float = signf((1.4 * _sgn) if e.near else (-1.4 * _sgn))
		e.x = clampf(e.x, 0.25, 4.1) if _sside > 0.0 else clampf(e.x, -4.1, -0.25)
		e.z = clamp(e.z, -2.2, -0.3) if e.near else clamp(e.z, L + 0.3, L + 2.2)
	elif state == "serve" and M.server != e.id:

		e.x = clampf(e.x, -4.0, 4.0)
		e.z = clamp(e.z, -2.4, 0.9) if e.near else clamp(e.z, L - 0.9, L + 2.4)
	elif state == "point" or state == "over":

		e.x = clamp(e.x, -5.2, 5.2)
		e.z = clamp(e.z, -2.4, NZ - 2.2) if e.near else clamp(e.z, NZ + 2.2, L + 2.4)
	else:
		e.x = clamp(e.x, -5.2, 5.2)
		e.z = clamp(e.z, -2.4, NZ - 2.2) if e.near else clamp(e.z, NZ + 2.2, L + 2.4)
	var sp: = Vector2(e.vx, e.vz).length()
	e.run += sp * dt * 1.9
	e.speed = sp
	var target: = 1.0 if ball.x > e.x else -1.0
	e.side += (target - e.side) * minf(1.0, dt * 10.0)

func update(dt: float) -> void :
	_physics_dt = dt
	time += dt
	state_t += dt
	if state == "point" and not match_over and not demo and state_t > 0.8 and (inp.hit or inp.lob or inp.drop):
		inp.hit = false
		inp.lob = false
		inp.drop = false
		start_point()
	ball.hot = maxf(0.0, ball.hot - dt * 2.5)
	if demo:
		ai_control(pl[0], dt)
	else:
		human_control(pl[0], dt)
	ai_control(pl[1], dt)
	if state == "serve" and (demo or M.server == 1) and cpu_serve_at > 0.0 and time > cpu_serve_at:
		if serve_stage == "ready":
			toss_ball()
			cpu_serve_at = time + 0.72 + randf_range(0.0, 0.08)
		elif serve_stage == "toss":
			do_serve(pl[M.server], 0.75 + randf_range(0.0, 0.25))
			cpu_serve_at = 0.0
	update_player(pl[0], dt)
	update_player(pl[1], dt)
	var sub: = 2
	for i in sub:
		step_ball(dt / sub)
	var point_window: = 2.0 if demo else 2.2
	if state == "point" and state_t > point_window:
		if match_over and not demo:
			if not over_sent:
				over_sent = true
				events.append({"t": "over"})
		else:
			start_point()
	if demo and state == "play" and state_t > 40.0:
		start_point()

# Matches step_ball's two substeps under the supported fixed physics contract.
func _skim_cross_height(v: Vector3) -> float:
	var y: float = ball.y
	var z: float = ball.z
	var vy: float = v.y
	var dt: float = _physics_dt / 2.0
	for i in 360:
		var previous_z: float = z
		vy -= g_eff(ball.spin) * dt
		y += vy * dt
		z += v.z * dt
		if (previous_z - NZ) * (z - NZ) < 0.0:
			return y
		if y <= BR:
			return -1.0
	return -1.0
