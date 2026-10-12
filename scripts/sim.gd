class_name TennisSim
extends RefCounted

# Port del simulador de la versión web tenis-arcade (mecánicas validadas).
const L := 23.77
const NZ := L / 2.0
const G := 19.0
const BR := 0.17
const NET_H := 0.95

static func randn() -> float:
    return (randf() + randf() + randf() - 1.5) / 0.75

class Player extends RefCounted:
    var id := 0
    var near := false
    var x := 0.0
    var z := 0.0
    var vx := 0.0
    var vz := 0.0
    var tvx := 0.0
    var tvz := 0.0
    var swing := 0.0
    var kind := "drive"
    var cool := 0.0
    var run := 0.0
    var side := 1.0
    var react := 0.0
    var pred_for := -1
    var tx := 0.0
    var tz := 0.0
    var flash := 0.0
    var speed := 0.0
    var want := "drive"
    var want_t := 0.0
    var kind_roll := 0.5

class Ball extends RefCounted:
    var x := 0.0
    var y := 1.0
    var z := 0.0
    var vx := 0.0
    var vy := 0.0
    var vz := 0.0
    var bounces := 0
    var last := -1
    var held := true
    var toss := false
    var toss_t := 0.0
    var in_play := false
    var serving := true
    var hit_id := 0
    var trail: Array = []

var demo := true
var AIP := {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}
var PS := {"speed": 7.0, "T": 1.0, "err": 1.0}
var cpu_name := "CPU"

var ball := Ball.new()
var pl: Array = []
var M := {"pts": [0, 0], "games": [0, 0], "sets": [0, 0], "server": 0, "sets_to_win": 1}
var state := "serve"
var state_t := 0.0
var serve_fault := 0
var serve_stage := "ready"
var cpu_serve_at := 0.0
var time := 0.0
var rally_hits := 0
var serve_unreturned := false
var match_over := false
var over_sent := false
var inp := {"x": 0.0, "y": 0.0, "hit": false, "lob": false}
var events: Array = []

func _init(p_demo: bool = true, p_aip: Dictionary = {}, p_ps: Dictionary = {}, p_cpu_name: String = "CPU", sets_to_win: int = 1) -> void:
    demo = p_demo
    if not p_aip.is_empty():
        AIP = p_aip
    if not p_ps.is_empty():
        PS = p_ps
    cpu_name = p_cpu_name
    var p0 := Player.new()
    p0.id = 0
    p0.near = true
    p0.z = -0.8
    var p1 := Player.new()
    p1.id = 1
    p1.near = false
    p1.z = L + 0.8
    pl = [p0, p1]
    M.sets_to_win = sets_to_win
    reset_match()
    start_point()

func reset_match() -> void:
    M.pts = [0, 0]
    M.games = [0, 0]
    M.sets = [0, 0]
    M.server = 0
    match_over = false
    over_sent = false

func start_point() -> void:
    state = "serve"
    state_t = 0.0
    serve_fault = 0
    prep_serve()

func prep_serve() -> void:
    var srv = pl[M.server]
    var rec = pl[1 - M.server]
    var sgn := 1.0 if ((M.pts[0] + M.pts[1]) % 2) == 0 else -1.0
    var near: bool = srv.near
    srv.x = 1.4 * sgn if near else -1.4 * sgn
    srv.z = -0.9 if near else L + 0.9
    srv.vx = 0.0
    srv.vz = 0.0
    srv.swing = 0.0
    rec.x = -2.5 * sgn if near else 2.5 * sgn
    rec.z = L + 0.6 if near else -0.6
    rec.vx = 0.0
    rec.vz = 0.0
    rec.swing = 0.0
    rec.pred_for = -1
    reset_serve_ball()
    rally_hits = 0
    serve_unreturned = false

func reset_serve_ball() -> void:
    var srv = pl[M.server]
    ball.held = true
    ball.toss = false
    ball.toss_t = 0.0
    ball.in_play = false
    ball.serving = true
    ball.bounces = 0
    ball.last = -1
    ball.vx = 0.0
    ball.vy = 0.0
    ball.vz = 0.0
    ball.trail = []
    serve_stage = "ready"
    cpu_serve_at = time + 1.1 + randf_range(0.0, 0.6) if (srv.id == 1 or demo) else 0.0

func award_point(w: int, why: String, sub: String) -> void:
    if state == "point" or state == "over":
        return
    state = "point"
    state_t = 0.0
    ball.in_play = false
    M.pts[w] += 1
    var txt := why
    var sb := sub
    events.append({"t": "sfx_point", "w": w})
    if M.pts[w] >= 4:
        M.games[w] += 1
        M.pts = [0, 0]
        M.server = 1 - M.server
        if M.games[w] >= 4:
            M.sets[w] += 1
            M.games = [0, 0]
            txt = "SET"
            sb = "Para ti" if w == 0 else "Para " + cpu_name
            if M.sets[w] >= M.sets_to_win:
                match_over = true
                sb = ""
        else:
            txt = "JUEGO"
            sb = "Para ti" if w == 0 else "Para " + cpu_name
    elif M.pts[0] == 3 and M.pts[1] == 3:
        sb = "40-40 · punto de oro"
    events.append({"t": "point", "w": w, "txt": txt, "sub": sb})
    serve_fault = 0

func fault(why: String) -> void:
    if state != "serve":
        return
    serve_fault += 1
    if serve_fault >= 2:
        award_point(1 - M.server, "DOBLE FALTA", "")
        return
    events.append({"t": "fault", "why": why})
    ball.in_play = false
    reset_serve_ball()

func launch(tx: float, tz: float, T: float, y0: float) -> void:
    var n := 0
    while true:
        var vx := (tx - ball.x) / T
        var vz := (tz - ball.z) / T
        var vy := (0.5 * G * T * T - y0) / T
        var tn := (NZ - ball.z) / vz
        var yn := 9.0
        if tn > 0.0 and tn < T:
            yn = y0 + vy * tn - 0.5 * G * tn * tn
        if yn >= 1.3 or n >= 14:
            ball.vx = vx
            ball.vy = vy
            ball.vz = vz
            break
        T *= 1.07
        n += 1
    ball.y = max(y0, 0.35)

func do_hit(e: Player, kind: String, ai: bool) -> void:
    var opp = pl[1 - e.id]
    var dir := 1.0 if e.near else -1.0
    var dx := absf(ball.x - e.x)
    var dz := absf(ball.z - e.z)
    var stretch := maxf(0.0, dx - 0.8) + maxf(0.0, dz - 0.8)
    var tx := 0.0
    var d := 0.0
    var T := 1.0
    var on_rise := false
    var perfect := false
    if ball.y > 2.15 and kind != "lob":
        kind = "smash"
    if ai:
        var D = AIP
        tx = (-1.0 if opp.x > 0 else 1.0) * randf_range(1.0, 3.5)
        if randf() < 0.22:
            tx = randf_range(-1.0, 1.0)
        if kind == "lob":
            d = 0.9
            T = 1.65
        elif kind == "drop":
            d = 0.12
            T = 1.15
        elif kind == "smash":
            d = 0.55
            T = 0.6
        else:
            d = 0.55 + randf() * 0.4
            T = 0.98 + (1.0 - d) * 0.2
        if absf(opp.x) > 3.0 and kind != "drop":
            tx = clampf(-signf(opp.x) * randf_range(2.6, 3.8), -3.9, 3.9)
            d = minf(d + 0.15, 1.0)
            T *= 0.95
        # v0.14: buscar el winner - a la esquina y mas rapido cuando el rival
        # esta lejos del punto de caida o lleva inercia al lado contrario
        var reversing: bool = absf(opp.vx) > 2.5
        var clear_chance: bool = absf(opp.x) > 2.4 or reversing
        if kind != "drop" and kind != "lob" and clear_chance and randf() < 0.75:
            if reversing:
                tx = clampf(-signf(opp.vx) * randf_range(2.8, 3.8), -3.9, 3.9)
            else:
                tx = clampf(signf(tx) * randf_range(2.8, 3.8), -3.9, 3.9)
            T *= 0.7
            d = minf(d + 0.12, 1.0)
            tx += randn() * D.err * 0.5
        tx += randn() * D.err * (0.5 + stretch * 0.7)
        d += randn() * 0.08 * D.err
    else:
        tx = clamp(inp.x * 3.1 + (ball.x - e.x) * 1.4, -3.9, 3.9)
        var up: bool = inp.y > 0.4
        if kind == "lob":
            d = 0.88
            T = 1.7
        elif kind == "drop":
            d = 0.1
            T = 1.15
        elif kind == "smash":
            d = 0.5 + (0.3 if up else 0.0)
            T = 0.58 * PS.T
        else:
            d = 0.95 if up else 0.62
            T = (0.92 if up else 1.02) * PS.T
            # v0.16: golpear al bote (bola subiendo) quita tiempo al rival
            # pero pide mas precision que esperar a que la bola baje
            if ball.vy > 1.0:
                on_rise = true
                T *= 0.88
                d = minf(d + 0.06, 1.0)
        # v0.18: raquetazo perfecto - contacto en el punto dulce (bola delante
        # del cuerpo y a la cintura): sale mas rapida, mas profunda y casi sin error
        if kind == "drive" or kind == "smash":
            var pdx := absf(ball.x - e.x)
            var pdz := absf(ball.z - e.z)
            perfect = pdx < 0.75 and pdz > 0.25 and pdz < 1.05 and ball.y > 0.85 and ball.y < 1.45
        if perfect:
            T *= 0.82
            d = minf(d + 0.08, 1.0)
        var es: float = 0.35 if perfect else 1.0
        var hq: float = clampf(1.0 - absf(ball.y - 1.05) / 1.6, 0.35, 1.0)
        var qf: float = 2.0 - hq
        tx += randn() * (0.12 + stretch * 0.55) * PS.err * qf * es
        d += randn() * (0.03 + stretch * 0.07) * PS.err * qf * es
        if on_rise:
            tx += randn() * 0.18 * PS.err * es
            d += randn() * 0.05 * PS.err * es
        d *= 0.85 + 0.15 * hq
    d = clampf(d, 0.02, 1.04)
    var tz := NZ + dir * (2.2 + d * (L / 2.0 - 2.2))
    launch(tx, tz, T, max(ball.y, 0.5))
    ball.last = e.id
    ball.bounces = 0
    ball.serving = false
    ball.in_play = true
    ball.hit_id += 1
    rally_hits += 1
    serve_unreturned = false
    e.swing = 0.34
    e.kind = kind
    e.cool = 0.4
    e.flash = 0.12
    events.append({"t": "hit", "id": e.id, "kind": kind, "x": ball.x, "y": ball.y, "z": ball.z, "rise": on_rise, "perfect": perfect})

func do_serve(e: Player, q: float) -> void:
    serve_unreturned = true
    var dir := 1.0 if e.near else -1.0
    var box_sign := -signf(e.x)
    var tx := 0.0
    var tzr := 0.0
    var err := 0.0
    var serve_T := 1.0
    if e.id == 0 and not demo:
        tx = box_sign * clamp(2.0 + inp.x * box_sign * 1.6, 0.7, 3.8)
        # v0.17: saque con intencion - arriba plano y rapido, abajo seguro,
        # y arriesgar a linea suma error (riesgo/recompensa)
        var flat: bool = inp.y > 0.4
        var safe: bool = inp.y < -0.4
        tzr = 6.0 if flat else (4.3 if safe else 4.9)
        err = ((1.0 - q) * 1.6 + 0.1) * PS.err
        err *= 1.0 + 1.7 * clampf((absf(tx) - 1.5) / 2.3, 0.0, 1.0)
        if safe:
            err *= 0.75
        serve_T = lerpf(1.12, 0.85, q) if flat else (lerpf(1.25, 1.0, q) if safe else lerpf(1.18, 0.88, q))
    else:
        # v0.17: primer saque agresivo y al hueco; segundo saque seguro
        var rec = pl[1 - e.id]
        if serve_fault > 0:
            tx = box_sign * randf_range(1.2, 2.8)
            tzr = randf_range(4.4, 5.0)
            err = (AIP.err * 0.7 + 0.1) * 0.6
            serve_T = 1.05
        else:
            var rec_pos: float = clampf(rec.x * box_sign, 0.0, 4.0)
            var gamble := randf()
            if gamble < 0.6:
                tx = box_sign * (3.3 if rec_pos < 1.8 else 1.1)
            elif gamble < 0.8:
                tx = box_sign * clampf(rec_pos + randf_range(-0.4, 0.4), 0.7, 3.8)
            else:
                tx = box_sign * randf_range(1.0, 3.5)
            tzr = randf_range(4.8, 5.9)
            err = (AIP.err * 0.7 + 0.1) * 1.25
            serve_T = 0.97
    tx += randn() * err
    tzr += randn() * err * (0.9 if (e.id == 0 and not demo and inp.y > 0.4) else 0.5)
    launch(tx, NZ + dir * tzr, serve_T, max(ball.y, 2.0))
    ball.last = e.id
    ball.bounces = 0
    ball.in_play = true
    ball.held = false
    ball.toss = false
    ball.serving = true
    ball.hit_id += 1
    e.swing = 0.4
    e.kind = "serve"
    events.append({"t": "serve", "id": e.id, "q": q, "x": ball.x, "y": ball.y, "z": ball.z})
    serve_stage = "hit"
    rally_hits = 1

func toss_ball() -> void:
    ball.held = false
    ball.toss = true
    ball.toss_t = 0.0
    ball.vy = 9.5
    ball.vx = 0.0
    ball.vz = 0.0
    serve_stage = "toss"
    events.append({"t": "toss"})

func step_ball(dt: float) -> void:
    var sv = pl[M.server]
    var sdir := 1.0 if sv.near else -1.0
    if ball.held:
        ball.x = sv.x + 0.28
        ball.z = sv.z + 0.3 * sdir
        ball.y = 0.95
        ball.vx = 0.0
        ball.vy = 0.0
        ball.vz = 0.0
        return
    if ball.toss:
        ball.toss_t += dt
        ball.vy -= G * dt
        ball.y += ball.vy * dt
        ball.x = sv.x + 0.28
        ball.z = sv.z + 0.3 * sdir
        if ball.vy < 0.0 and ball.y < 1.2:
            ball.toss = false
            ball.in_play = false
            fault("Lanzamiento perdido")
        return
    if not ball.in_play and state != "point":
        return
    var pz := ball.z
    ball.trail.append(Vector3(ball.x, ball.y, ball.z))
    if ball.trail.size() > 9:
        ball.trail.pop_front()
    ball.vy -= G * dt
    ball.x += ball.vx * dt
    ball.y += ball.vy * dt
    ball.z += ball.vz * dt
    if ball.in_play and (pz - NZ) * (ball.z - NZ) < 0 and ball.y < NET_H:
        events.append({"t": "net"})
        ball.vx *= 0.1
        ball.vz *= -0.12
        ball.vy = max(ball.vy, 0.0) * 0.2
        ball.z = NZ + (0.06 if pz > NZ else -0.06)
        ball.in_play = false
        if state == "serve":
            fault("Red")
        else:
            award_point(1 - ball.last, "RED", "")
        return
    if ball.in_play and ball.bounces >= 1 and (ball.z < -2.8 or ball.z > L + 2.8) and state == "play":
        ball.in_play = false
        award_point(ball.last, "PUNTO", "")
        return
    if ball.y <= BR and ball.vy < 0:
        ball.y = BR
        var sp := absf(ball.vy)
        ball.vy = -ball.vy * 0.74
        ball.vx *= 0.8
        ball.vz *= 0.78
        if absf(ball.vy) < 1.2:
            ball.vy = 0.0
        events.append({"t": "bounce", "v": clamp(sp / 10.0, 0.2, 1.0), "x": ball.x, "z": ball.z})
        if ball.in_play:
            ball.bounces += 1
            if ball.bounces == 1:
                judge_landing()
            elif ball.bounces >= 2:
                ball.in_play = false
                if state == "play":
                    award_point(ball.last, "PUNTO", "")

func judge_landing() -> void:
    var hitter = pl[ball.last]
    var dir := 1.0 if hitter.near else -1.0
    var x := ball.x
    var z := ball.z
    var eps := 0.11  # radio visual de la bola: si la bola toca la linea es buena
    var on_opp: bool = z > NZ if dir > 0 else z < NZ
    if state == "serve":
        var box_sign := -signf(hitter.x)
        var in_z: bool
        if dir > 0:
            in_z = z > NZ and z <= NZ + 6.4 + eps
        else:
            in_z = z < NZ and z >= NZ - 6.4 - eps
        var in_x: bool = absf(x) <= 4.11 + eps and x * box_sign >= -eps
        if in_z and in_x:
            state = "play"
            state_t = 0.0
            ball.serving = false
            serve_stage = "rally"
            return
        ball.in_play = false
        fault("Fuera del cuadro" if on_opp else "Red")
        return
    var inside: bool = absf(x) <= 4.11 + eps and z >= -eps and z <= L + eps
    if on_opp and inside:
        return
    ball.in_play = false
    award_point(1 - ball.last, "FUERA", "" if on_opp else "Bola corta")

func predict(e: Player) -> Vector3:
    var bx := ball.x
    var by := ball.y
    var bz := ball.z
    var bvx := ball.vx
    var bvy := ball.vy
    var bvz := ball.vz
    var bn := ball.bounces
    var dt := 0.02
    for i in 220:
        bvy -= G * dt
        bx += bvx * dt
        by += bvy * dt
        bz += bvz * dt
        if by <= BR and bvy < 0:
            by = BR
            bvy *= -0.74
            bvx *= 0.8
            bvz *= 0.78
            bn += 1
        var past: bool = bz < -1.6 if e.near else bz > L + 1.6
        if (bn >= 1 and by < 1.5 and bvy < 0 and (bz < 4.5 if e.near else bz > L - 4.5)) or past:
            break
    return Vector3(bx, by, bz)

# Punto y tiempo del primer bote previsto (para el anillo de bote)
func predict_bounce() -> Dictionary:
    var r := {"ok": false, "x": 0.0, "z": 0.0, "t": 0.0}
    if not ball.in_play:
        return r
    var bx := ball.x
    var by := ball.y
    var bz := ball.z
    var bvx := ball.vx
    var bvy := ball.vy
    var bvz := ball.vz
    var dt := 0.02
    var t := 0.0
    for i in 220:
        bvy -= G * dt
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

func ai_control(e: Player, dt: float) -> void:
    var D = AIP
    var dir := 1.0 if e.near else -1.0
    var opp = pl[1 - e.id]
    if state == "serve" and M.server == e.id:
        e.tvx = 0.0
        e.tvz = 0.0
        return
    var coming: bool = ball.in_play and ball.last != e.id and ball.vz * dir < 0 and (state == "play" or state == "serve")
    var tx := clampf(ball.x * 0.3, -2.0, 2.0)
    var tz := -1.0 if e.near else L + 1.0
    if state == "serve" and M.server != e.id:
        # v0.18: posicion de resto - aguantar el lado del cuadro de saque
        # en vez de derivar hacia la bola durante el lanzamiento rival
        var srv = pl[M.server]
        tx = -signf(srv.x) * 2.2
        tz = -0.6 if e.near else L + 0.6
    var mv: float = D.speed * 0.7
    if coming:
        if e.pred_for != ball.hit_id:
            e.pred_for = ball.hit_id
            var srv_ret: bool = serve_unreturned and M.server != e.id
            e.react = (0.06 + randf_range(0.0, 0.04)) if srv_ret else (D.react + randf_range(0.0, 0.08))
            var p := predict(e)
            e.tx = p.x + randn() * D.err * 0.6
            e.tz = p.z + (-0.2 if e.near else 0.2) + randn() * D.err * 0.3
            e.kind_roll = randf()
        e.react -= dt
        if e.react <= 0.0:
            tx = e.tx
            tz = e.tz
            mv = D.speed * (1.25 if (serve_unreturned and M.server != e.id) else 1.0)
    var ex := tx - e.x
    var ez := tz - e.z
    var d := Vector2(ex, ez).length()
    if d > 0.08:
        var m: float = min(mv, d * 8.0)
        e.tvx = ex / d * m
        e.tvz = ez / d * m
    else:
        e.tvx = 0.0
        e.tvz = 0.0
    if coming and e.cool <= 0.0 and e.swing <= 0.0:
        var dx := absf(ball.x - e.x)
        var dz := absf(ball.z - e.z)
        var srv_ret2: bool = serve_unreturned and M.server != e.id
        var gx := 1.8 if srv_ret2 else 1.45
        var gz := 1.85 if srv_ret2 else 1.35
        if dx < gx and dz < gz and ball.y < 2.9 and ball.y > 0.15 and (state != "serve" or ball.bounces >= 1):
            var stretch := dx > 1.0 or dz > 1.0
            if not (stretch and randf() < D.miss):
                var kind := "drive"
                var r: float = e.kind_roll
                # v0.15: repertorio con criterio - la CPU elige el golpe segun
                # donde esta el rival y lo estirada que llega ella
                var opp_deep: bool = (opp.z < 0.3) if opp.near else (opp.z > L - 0.3)
                var opp_net: bool = (opp.z > 5.5) if opp.near else (opp.z < L - 5.5)
                var opp_wide: bool = absf(opp.x) > 2.8
                var self_inside: bool = (e.z > -1.6) if e.near else (e.z < L + 1.6)
                if opp_net:
                    if r < 0.5:
                        kind = "lob"  # rival sube a la red: globo por encima
                elif opp_deep and self_inside and D.err < 0.8:
                    var drop_p := 0.14 + (0.16 if opp_wide else 0.0)
                    if r > 1.0 - drop_p:
                        kind = "drop"  # rival atras (y mas si esta abierto): dejada
                if kind == "drive" and stretch:
                    var def_lob_p: float = 0.04 + (0.9 - D.err) * 0.05
                    if r < def_lob_p:
                        kind = "lob"  # llega estirada: globo defensivo para recuperar
                do_hit(e, kind, true)
            else:
                e.cool = 0.3
                e.swing = 0.3
                e.kind = "drive"

func human_control(e: Player, dt: float) -> void:
    e.tvx = inp.x * PS.speed
    e.tvz = inp.y * PS.speed
    var want_hit: bool = inp.hit
    var want_lob: bool = inp.lob
    inp.hit = false
    inp.lob = false
    if state == "serve" and M.server == 0:
        if want_hit or want_lob:
            if serve_stage == "ready":
                toss_ball()
            elif serve_stage == "toss":
                do_serve(e, 1.0 - clamp(absf(ball.toss_t - 0.50) / 0.35, 0.0, 1.0))
        return
    if want_hit or want_lob:
        if e.swing <= 0.0:
            e.swing = 0.3
            e.kind = "lob" if want_lob else ("drop" if inp.y < -0.4 else "drive")
            e.want = e.kind
            e.want_t = 0.3
    if e.want_t > 0.0:
        e.want_t -= dt
        if ball.in_play and ball.last != e.id and ball.vz < 0 and e.cool <= 0.0 and state == "play":
            var dx := absf(ball.x - e.x)
            var dz := absf(ball.z - e.z)
            if dx < 1.75 and dz < 1.5 and ball.y < 3.1:
                do_hit(e, e.want, false)
                e.want_t = 0.0

func update_player(e: Player, dt: float) -> void:
    e.cool = max(0.0, e.cool - dt)
    e.swing = max(0.0, e.swing - dt)
    e.flash = max(0.0, e.flash - dt)
    var k: float = minf(1.0, dt * 11.0)
    e.vx += (e.tvx - e.vx) * k
    e.vz += (e.tvz - e.vz) * k
    e.x += e.vx * dt
    e.z += e.vz * dt
    if state == "serve" and M.server == e.id:
        e.x = clamp(e.x, -4.1, 4.1)
        e.z = clamp(e.z, -2.2, -0.3) if e.near else clamp(e.z, L + 0.3, L + 2.2)
    else:
        e.x = clamp(e.x, -6.4, 6.4)
        e.z = clamp(e.z, -2.4, NZ - 2.2) if e.near else clamp(e.z, NZ + 2.2, L + 2.4)
    var sp := Vector2(e.vx, e.vz).length()
    e.run += sp * dt * 1.9
    e.speed = sp
    var target := 1.0 if ball.x > e.x else -1.0
    e.side += (target - e.side) * minf(1.0, dt * 10.0)

func update(dt: float) -> void:
    time += dt
    state_t += dt
    if demo:
        ai_control(pl[0], dt)
    else:
        human_control(pl[0], dt)
    ai_control(pl[1], dt)
    if state == "serve" and (demo or M.server == 1) and cpu_serve_at > 0.0 and time > cpu_serve_at:
        if serve_stage == "ready":
            toss_ball()
            cpu_serve_at = time + 0.3 + randf_range(0.0, 0.08)
        elif serve_stage == "toss":
            do_serve(pl[M.server], 0.75 + randf_range(0.0, 0.25))
            cpu_serve_at = 0.0
    update_player(pl[0], dt)
    update_player(pl[1], dt)
    var sub := 2
    for i in sub:
        step_ball(dt / sub)
    if state == "point" and state_t > 2.0:
        if match_over and not demo:
            if not over_sent:
                over_sent = true
                events.append({"t": "over"})
        else:
            start_point()
    if demo and state == "play" and state_t > 40.0:
        start_point()
