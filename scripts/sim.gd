class_name TennisSim
extends RefCounted

# Port del simulador de la versión web tenis-arcade (mecánicas validadas).
const L := 23.77
const NZ := L / 2.0
const G := 23.0
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
    # v0.33: esquiva de reflejo (bola al cuerpo sin tiempo de armar)
    var dodge_for := -1
    var dodge_t := 0.0
    var letgo_for := -1
    # v0.36: estirada desesperada (dive) - salto a por la bola fuera de alcance
    var dive_t := 0.0
    var dive_cool := 0.0
    var dive_for := -1
    # v0.35: sprint de persecucion (lectura de dejada) y subida a la red
    var chase := 1.0
    var appr_t := 0.0
    # v0.35: espera de resto (ready stance) y armado temprano (visual)
    var wait_serve := false
    var prep_t := 0.0

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
    var hot := 0.0  # v0.26: calor del tiro (estela blanca) - decae en update
    var spin := 0.0  # v0.30: efecto del tiro (+liftado / -cortado) - se aplica en el bote
    var kind := "drive"  # v0.35: tipo del ultimo golpe (la CPU lee la dejada)

# v0.32: parametros tipados (antes diccionarios sueltos). Los campos son los
# unicos que el simulador lee; from_dict admite dicts legacy (DIFF_PARAMS,
# params_for, saves) ignorando claves desconocidas.
class AIParams extends RefCounted:
    var speed := 5.6
    var react := 0.27
    var err := 0.5
    var miss := 0.15
    # v0.32: estilo - riesgo al buscar el winner (0.5 = comportamiento clasico)
    var risk := 0.5
    static func from_dict(d: Dictionary) -> AIParams:
        var p := AIParams.new()
        for k in ["speed", "react", "err", "miss", "risk"]:
            if d.has(k):
                p.set(k, float(d[k]))
        return p

class PlayerStats extends RefCounted:
    var speed := 7.0
    var T := 1.0
    var err := 1.0
    static func from_dict(d: Dictionary) -> PlayerStats:
        var p := PlayerStats.new()
        for k in ["speed", "T", "err"]:
            if d.has(k):
                p.set(k, float(d[k]))
        return p

class MatchState extends RefCounted:
    var pts: Array = [0, 0]
    var games: Array = [0, 0]
    var sets: Array = [0, 0]
    var server := 0
    var sets_to_win := 1
    # v0.32: tie-break al llegar 3-3 de juegos (a 7 con margen 2)
    var tb := false
    var tb_pts: Array = [0, 0]
    var tb_total := 0
    var tb_first_server := 0

var demo := true
var AIP := AIParams.new()
var PS := PlayerStats.new()
var cpu_name := "CPU"

var ball := Ball.new()
var pl: Array = []
var M := MatchState.new()
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
var inp := {"x": 0.0, "y": 0.0, "hit": false, "lob": false, "slice": false, "topspin": false}
var events: Array = []

func _init(p_demo: bool = true, p_aip: Dictionary = {}, p_ps: Dictionary = {}, p_cpu_name: String = "CPU", sets_to_win: int = 1) -> void:
    demo = p_demo
    if not p_aip.is_empty():
        AIP = AIParams.from_dict(p_aip)
    if not p_ps.is_empty():
        PS = PlayerStats.from_dict(p_ps)
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
    var txt := why
    var sb := sub
    events.append({"t": "sfx_point", "w": w})
    if M.tb:
        # tie-break: puntos corridos, saque 1-2-2, a 7 con margen 2
        M.tb_pts[w] += 1
        M.tb_total += 1
        # rotacion de saque: punto 0 lo saca tb_first_server; luego bloques de 2
        var k := M.tb_total  # puntos ya jugados; saque del siguiente punto
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
                sb = ""
        events.append({"t": "point", "w": w, "txt": txt, "sub": sb})
        serve_fault = 0
        return
    M.pts[w] += 1
    if M.pts[w] >= 4:
        M.games[w] += 1
        M.pts = [0, 0]
        M.server = 1 - M.server
        if M.games[w] >= 4 and M.games[1 - w] <= 2:
            M.sets[w] += 1
            M.games = [0, 0]
            txt = "SET"
            sb = "Para ti" if w == 0 else "Para " + cpu_name
            if M.sets[w] >= M.sets_to_win:
                match_over = true
                sb = ""
        elif M.games[0] == 3 and M.games[1] == 3:
            # 3-3: el set se decide en tie-break
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

# v0.32: do_hit troceado en fases con nombre. Mismo orden de ejecucion y de
# llamadas aleatorias que la version monolitica (verificado con A/B sembrado):
# _ai_aim / _player_aim deciden objetivo (tx), profundidad (d) y tiempo de
# vuelo (T); el tramo comun aplica spin, lanza y registra el evento.
func do_hit(e: Player, kind: String, ai: bool) -> void:
    var opp = pl[1 - e.id]
    var dir := 1.0 if e.near else -1.0
    var dx := absf(ball.x - e.x)
    var dz := absf(ball.z - e.z)
    var stretch := maxf(0.0, dx - 0.8) + maxf(0.0, dz - 0.8)
    if ball.y > 2.15 and kind != "lob":
        kind = "smash"
    var aim: Dictionary
    if ai:
        aim = _ai_aim(opp, kind, stretch)
    else:
        aim = _player_aim(e, kind, stretch)
    var on_rise: bool = aim.get("rise", false)
    var perfect: bool = aim.get("perfect", false)
    var tx: float = aim.tx
    var d: float = clampf(aim.d, 0.02, 1.04)
    var T: float = aim.T
    # v0.30: caracter del tiro - la dejada es cortada y muere, el resto sale liftado
    ball.spin = {"drop": -1.0, "slice": -0.68, "lob": 0.25, "smash": 0.5, "topspin": 1.25}.get(kind, 0.85)
    ball.kind = kind
    if kind == "slice":
        d = minf(d + 0.05, 0.82)
    elif kind == "topspin":
        d = minf(d + 0.08, 1.0)
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
    e.want_t = 0.0  # v0.33: contacto -> termina la preparacion
    var spd := Vector3(ball.vx, ball.vy, ball.vz).length()
    ball.hot = clampf((spd - 30.0) / 20.0, 0.0, 1.0)
    events.append({"t": "hit", "id": e.id, "kind": kind, "x": ball.x, "y": ball.y, "z": ball.z, "rise": on_rise, "perfect": perfect, "stretch": stretch, "spd": spd})

# Objetivo de la CPU: cruzar, buscar el winner cuando el rival llega justo,
# y error segun dificultad y estirada. Devuelve {tx, d, T}.
func _ai_aim(opp: Player, kind: String, stretch: float) -> Dictionary:
    var D = AIP
    var tx := 0.0
    var d := 0.0
    var T := 1.0
    # v0.36: la CPU busca esquinas - cruzado ancho y profundo por defecto,
    # solo de vez en cuando un tiro comodo al centro (pedido del usuario)
    tx = (-1.0 if opp.x > 0 else 1.0) * randf_range(1.8, 3.9)
    if randf() < 0.14:
        tx = randf_range(-0.8, 0.8)
    if kind == "lob":
        d = 0.9
        T = 1.5
    elif kind == "drop":
        d = 0.12
        T = 1.0
    elif kind == "smash":
        d = 0.55
        T = 0.52
    else:
        d = 0.62 + randf() * 0.36  # v0.36: fondo de pista, no a media pista
        T = 0.86 + (1.0 - d) * 0.18
    if absf(opp.x) > 3.0 and kind != "drop":
        tx = clampf(-signf(opp.x) * randf_range(2.6, 3.8), -3.9, 3.9)
        d = minf(d + 0.15, 1.0)
        T *= 0.95
    # v0.14: buscar el winner - a la esquina y mas rapido cuando el rival
    # esta lejos del punto de caida o lleva inercia al lado contrario
    var reversing: bool = absf(opp.vx) > 2.5
    var clear_chance: bool = absf(opp.x) > 2.4 or reversing
    if kind != "drop" and kind != "lob" and clear_chance and randf() < 0.55 + 0.4 * D.risk:
        if reversing:
            tx = clampf(-signf(opp.vx) * randf_range(2.8, 3.8), -3.9, 3.9)
        else:
            tx = clampf(signf(tx) * randf_range(2.8, 3.8), -3.9, 3.9)
        T *= 0.70 - 0.16 * D.risk
        d = minf(d + 0.12, 1.0)
        tx += randn() * D.err * 0.5
    tx += randn() * D.err * (0.5 + stretch * 0.7)
    d += randn() * 0.08 * D.err
    return {"tx": tx, "d": d, "T": T}

# Objetivo del jugador: direccion del stick + compensacion por su posicion,
# alzas (bola subiendo), raquetazo perfecto y error por calidad de contacto.
# Devuelve {tx, d, T, rise, perfect}.
func _player_aim(e: Player, kind: String, stretch: float) -> Dictionary:
    var on_rise := false
    var perfect := false
    var tx := 0.0
    var d := 0.0
    var T := 1.0
    tx = clamp(inp.x * 3.1 + (ball.x - e.x) * 1.4, -3.9, 3.9)
    var up: bool = inp.y > 0.4
    if kind == "lob":
        d = 0.88
        T = 1.55
    elif kind == "slice":
        d = 0.48 if up else 0.34
        T = 1.13 * PS.T
    elif kind == "topspin":
        d = 0.84 if up else 0.58
        T = 0.91 * PS.T
    elif kind == "drop":
        d = 0.1
        T = 1.0
    elif kind == "smash":
        d = 0.5 + (0.3 if up else 0.0)
        T = 0.52 * PS.T
    else:
        d = 0.95 if up else 0.62
        T = (0.86 if up else 0.94) * PS.T
        # v0.16: golpear al bote (bola subiendo) quita tiempo al rival
        # pero pide mas precision que esperar a que la bola baje
        if ball.vy > 1.0:
            on_rise = true
            T *= 0.88
            d = minf(d + 0.06, 1.0)
    # v0.18: raquetazo perfecto - contacto en el punto dulce (bola delante
    # del cuerpo y a la cintura): sale mas rapida, mas profunda y casi sin error
    if kind == "drive" or kind == "smash" or kind == "topspin":
        var pdx := absf(ball.x - e.x)
        var pdz := absf(ball.z - e.z)
        perfect = pdx < 0.75 and pdz > 0.25 and pdz < 1.05 and ball.y > 0.85 and ball.y < 1.45
    if perfect:
        T *= 0.82
        d = minf(d + 0.08, 1.0)
    var es: float = 0.35 if perfect else (0.72 if kind == "slice" else 1.0)
    var hq: float = clampf(1.0 - absf(ball.y - 1.05) / 1.6, 0.35, 1.0)
    var qf: float = 2.0 - hq
    tx += randn() * (0.12 + stretch * 0.55) * PS.err * qf * es
    d += randn() * (0.03 + stretch * 0.07) * PS.err * qf * es
    if on_rise:
        tx += randn() * 0.18 * PS.err * es
        d += randn() * 0.05 * PS.err * es
    d *= 0.85 + 0.15 * hq
    return {"tx": tx, "d": d, "T": T, "rise": on_rise, "perfect": perfect}

func do_serve(e: Player, q: float) -> void:
    var serve_spin := 0.6  # v0.35: la CPU varia el efecto segun el tipo de saque
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
        err = ((1.0 - q) * 0.9 + 0.08) * PS.err
        err *= 1.0 + 1.7 * clampf((absf(tx) - 1.5) / 2.3, 0.0, 1.0)
        if safe:
            err *= 0.75
        serve_T = lerpf(1.06, 0.80, q) if flat else (lerpf(1.25, 1.0, q) if safe else lerpf(1.12, 0.84, q))
    else:
        # v0.17: primer saque agresivo y al hueco; segundo saque seguro
        var rec = pl[1 - e.id]
        if serve_fault > 0:
            # v0.35: segundo saque con variedad - direccion abierta y kick que pica
            tx = box_sign * randf_range(0.9, 3.3)
            tzr = randf_range(4.2, 5.3)
            err = (AIP.err * 0.7 + 0.1) * 0.6
            serve_T = 1.05
            serve_spin = randf_range(0.75, 1.0)
        else:
            # v0.21: primer saque de verdad - plano, rapido y con direccion
            # (linea / T / al cuerpo), velocidad segun dificultad
            var rec_pos: float = clampf(rec.x * box_sign, 0.0, 4.0)
            var gamble := randf()
            if gamble < 0.45:
                tx = box_sign * randf_range(3.2, 3.8)  # abierto a la linea
            elif gamble < 0.70:
                tx = box_sign * randf_range(0.8, 1.2)  # a la T
            elif gamble < 0.90:
                tx = box_sign * clampf(rec_pos + randf_range(-0.3, 0.3), 0.7, 3.8)  # al cuerpo
            else:
                tx = box_sign * randf_range(1.0, 3.5)
            tzr = randf_range(5.4, 6.2)  # profundo, cerca de la linea de saque
            err = (AIP.err * 0.7 + 0.1) * 1.25
            var base_T: float = 0.90 if AIP.speed < 5.0 else (0.82 if AIP.speed < 6.2 else 0.76)
            # v0.35: variedad de ritmo y efecto - el patron ya no es unico:
            # bombas planas (mas si el estilo es agresivo), kick lento que pica,
            # y el resto alrededor del ritmo base
            var pace := randf()
            var bomb_p: float = 0.10 + 0.20 * AIP.risk
            if pace < bomb_p:
                serve_T = base_T * 0.92
                serve_spin = 0.45  # bomba plana
            elif pace < bomb_p + 0.22:
                serve_T = base_T * 1.16
                serve_spin = 0.95  # kick: mas lento pero pica alto tras el bote
            else:
                serve_T = base_T * randf_range(0.97, 1.06)
    tx += randn() * err
    tzr += randn() * err * (0.9 if (e.id == 0 and not demo and inp.y > 0.4) else 0.5)
    launch(tx, NZ + dir * tzr, serve_T, max(ball.y, 2.0))
    ball.spin = serve_spin
    var sspd := Vector3(ball.vx, ball.vy, ball.vz).length()
    ball.hot = clampf((sspd - 30.0) / 20.0, 0.0, 1.0)
    ball.last = e.id
    ball.bounces = 0
    ball.in_play = true
    ball.held = false
    ball.toss = false
    ball.serving = true
    ball.hit_id += 1
    e.swing = 0.4
    e.kind = "serve"
    ball.kind = "serve"
    events.append({"t": "serve", "id": e.id, "q": q, "spd": sspd, "x": ball.x, "y": ball.y, "z": ball.z})
    serve_stage = "hit"
    rally_hits = 1

func toss_ball() -> void:
    ball.held = false
    ball.toss = true
    ball.toss_t = 0.0
    ball.vy = 10.5
    ball.vx = 0.0
    ball.vz = 0.0
    serve_stage = "toss"
    events.append({"t": "toss"})

# v0.30: factores de bote segun el efecto. Liftado: pica bajo y SALE (apenas
# pierde velocidad horizontal). Cortado: se queda muerto y bajo. Neutro: como antes.
# v0.33: superficie del partido ("clay"/"grass"/"hard"; hard = comportamiento clasico)
var surface := "hard"

func _bounce_factors(s: float) -> Array:
    # v0.35: el efecto se nota - el liftado pica y acelera tras el bote;
    # el cortado resbala BAJO y muere (antes flotaba alto, al reves)
    var vy_f := 0.74
    var damp := 0.79
    if s > 0.2:
        vy_f = 0.72 + 0.05 * s
        damp = 0.79 + 0.16 * s
    elif s < -0.2:
        vy_f = 0.72 + 0.06 * s
        damp = 0.79 + 0.12 * s
    # v0.33: la superficie cambia el bote - tierra: lento y alto (el liftado
    # muerde y pica mas); hierba: rapido y bajo (resbala)
    # v0.35: la dura deja de ser neutra - corre y pica bajo (contraste claro)
    if surface == "clay":
        vy_f *= 1.10
        damp *= 0.90
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

# v0.30: estima donde cruzara la bola el plano de contacto (~0.55m por delante
# del jugador) dentro de 1s. Devuelve [x, z, t] o t=-1 si no llega a tiempo.
func _intercept(e: Player) -> Array:
    var bx := ball.x
    var by := ball.y
    var bz := ball.z
    var bvx := ball.vx
    var bvy := ball.vy
    var bvz := ball.vz
    var bf := _bounce_factors(ball.spin)
    var zc: float = e.z + 0.55
    var dt := 0.02
    var t := 0.0
    while t < 1.0:
        bvy -= G * dt
        bx += bvx * dt
        by += bvy * dt
        bz += bvz * dt
        t += dt
        if by <= BR and bvy < 0.0:
            by = BR
            bvy = -bvy * bf[0]
            bvx *= bf[1]
            bvz *= bf[1]
        if bz <= zc:
            return [bx, bz, t]
        if by > 3.4:
            break
    return [0.0, 0.0, -1.0]

# v0.30: magnetismo estilo Virtua Tennis - mientras dura el swing, el jugador
# se ajusta solo al punto de contacto. Tope de 2.9m: nada de teletransportes.
func _assist(e: Player) -> void:
    var est := _intercept(e)
    if est[2] < 0.0:
        return
    var tx: float = est[0] - 0.28 * e.side
    var tz: float = est[1] - 0.55
    var ddx: float = tx - e.x
    var ddz: float = tz - e.z
    var dist := Vector2(ddx, ddz).length()
    if dist > 2.9 or dist < 0.12:
        return
    var sp := minf(PS.speed * 1.35, dist / 0.22)
    e.tvx = ddx / dist * sp
    e.tvz = ddz / dist * sp

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
            # v0.29: lanzamiento fallido SIN golpe no es falta - se recoge y se
            # repite el lanzamiento (regla real: solo cuenta si mueves la raqueta)
            ball.toss = false
            ball.held = true
            serve_stage = "ready"
            events.append({"t": "retoss"})
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
    if ball.in_play and (pz - NZ) * (ball.z - NZ) < 0 and ball.y < NET_H + 0.08:
        # v0.35: pelusa de cinta - si pasa rozando la banda en rally, se frena,
        # queda suspendida un instante y cae a cualquiera de los dos lados
        if ball.y >= NET_H and state == "play" and randf() < 0.55:
            events.append({"t": "netcord"})
            ball.vx *= 0.35
            ball.vz *= randf_range(0.05, 0.3)
            if randf() < 0.35:
                ball.vz = -absf(ball.vz) * 0.18  # se queda del lado del que tira
            ball.vy = minf(ball.vy, 0.4)
            ball.spin = 0.0
            return
        if ball.y >= NET_H:
            return  # rozo limpio sin pelusa: sigue su camino
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
    # v0.29: bola al cuerpo - si la bola viva te toca, punto para el rival
    # (antes atravesaba cabeza y torso como un fantasma)
    if ball.in_play and (state == "play" or state == "serve"):
        for i in 2:
            var bp = pl[i]
            var bdx: float = ball.x - bp.x
            var bdz: float = ball.z - bp.z
            if bdx * bdx + bdz * bdz < 0.20 and ball.y > 0.12 and ball.y < 1.62:
                var toward: float = (bp.x - ball.x) * ball.vx + (bp.z - ball.z) * ball.vz
                if toward > 0.0:
                    ball.in_play = false
                    events.append({"t": "body", "who": i, "x": ball.x, "y": ball.y, "z": ball.z})
                    award_point(1 - i, "PUNTO", "Bola al cuerpo")
                    return
    if ball.in_play and ball.bounces >= 1 and (ball.z < -2.8 or ball.z > L + 2.8) and state == "play":
        ball.in_play = false
        award_point(ball.last, "PUNTO", "")
        return
    if ball.y <= BR and ball.vy < 0:
        ball.y = BR
        var sp := absf(ball.vy)
        var bf := _bounce_factors(ball.spin)
        ball.vy = -ball.vy * bf[0]
        ball.vx *= bf[1]
        ball.vz *= bf[1]
        if absf(ball.vy) < 1.2:
            ball.vy = 0.0
        # v0.25: bote audible/polvo solo con bola viva (la bola muerta rodaba sonando cada frame)
        if ball.in_play:
            events.append({"t": "bounce", "v": clamp(sp / 10.0, 0.2, 1.0), "x": ball.x, "z": ball.z})
            ball.bounces += 1
            if ball.bounces == 1:
                judge_landing()
            elif ball.bounces >= 2:
                ball.in_play = false
                if state == "play":
                    award_point(ball.last, "PUNTO", "Dos botes")
            # v0.28: bola que se queda rodando con el punto vivo = bola muerta.
            # Antes seguia "golpeable" un frame mas y la CPU/jugador la recogia del suelo
            # (la dejada que muere rodando nunca cerraba el punto).
            if ball.in_play and ball.vy == 0.0 and ball.bounces >= 1 and state == "play":
                ball.in_play = false
                award_point(ball.last, "PUNTO", "Dos botes")
    # v0.36: el doble bote se canta AL INSTANTE - una bola que muere rodando se
    # detecta cada frame, no solo en el frame exacto del bote (antes podia
    # seguir viva ~1s hasta salir por el fondo y la llamada llegaba tarde)
    if ball.in_play and state == "play" and ball.bounces >= 1 and ball.y <= BR + 0.02 and absf(ball.vy) < 0.05:
        ball.in_play = false
        award_point(ball.last, "PUNTO", "Dos botes")

func judge_landing() -> void:
    var hitter = pl[ball.last]
    var dir := 1.0 if hitter.near else -1.0
    var x := ball.x
    var z := ball.z
    # v0.33: eps = BR (radio fisico Y visual 0.17 - coinciden desde v0.32).
    # Politica real: si el borde de la bola toca la linea es BUENA. Con eps<BR
    # quedaba una franja donde se veia tocar linea y se cantaba fuera.
    var eps := BR
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
    # v0.24: el partido es INDIVIDUALES - el pasillo de dobles es FUERA en rally.
    # La pista dibuja ambas lineas (real), pero el juez mide singles (4.115).
    var inside: bool = absf(x) <= 4.115 + eps and z >= -eps and z <= L + eps
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
            var bf := _bounce_factors(ball.spin)
            bvy *= -bf[0]
            bvx *= bf[1]
            bvz *= bf[1]
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
    e.wait_serve = state == "serve" and M.server != e.id
    if e.wait_serve:
        # v0.18: posicion de resto - aguantar el lado del cuadro de saque
        # en vez de derivar hacia la bola durante el lanzamiento rival
        var srv = pl[M.server]
        tx = -signf(srv.x) * 2.2
        tz = -0.6 if e.near else L + 0.6
    var mv: float = D.speed * 0.7
    e.dodge_t = maxf(0.0, e.dodge_t - dt)
    e.appr_t = maxf(0.0, e.appr_t - dt)
    e.want_t = maxf(0.0, e.want_t - dt)  # v0.33: la ventana de preparacion de la CPU tambien caduca
    if not coming and e.appr_t > 0.0 and state == "play":
        # v0.35: cierre a la red - tras el tiro forzado, ocupar el pasillo central
        tx = clampf(ball.x * 0.5, -1.6, 1.6)
        tz = (NZ - 2.3) if e.near else (NZ + 2.3)
        mv = D.speed
    if coming:
        if e.pred_for != ball.hit_id and e.dodge_t <= 0.0 and e.letgo_for != ball.hit_id:
            e.pred_for = ball.hit_id
            var srv_ret: bool = serve_unreturned and M.server != e.id
            e.react = (0.06 + randf_range(0.0, 0.04)) if srv_ret else (D.react + randf_range(0.0, 0.08))
            # v0.35: lectura tactica - la dejada se lee del armado y se arranca
            # al instante en sprint; el globo se lee pronto (hay tiempo)
            e.chase = 1.0
            if ball.kind == "drop" and not srv_ret:
                e.react *= 0.35
                e.chase = 1.3
            var p := predict(e)
            e.tx = p.x + randn() * D.err * (0.35 if srv_ret else 0.6)
            e.tz = p.z + (-0.2 if e.near else 0.2) + randn() * D.err * 0.3
            e.kind_roll = randf()
            # v0.36: dive de la CPU - bola viva que se le escapa por poco:
            # se tira a por ella en vez de quedarse a un paso (video del usuario)
            if e.dive_t <= 0.0 and e.dive_cool <= 0.0 and e.swing <= 0.0 and e.letgo_for != ball.hit_id:
                var dpd := Vector2(e.tx - e.x, e.tz - e.z).length()
                var t_est: float = (e.z - ball.z) / ball.vz if absf(ball.vz) > 2.0 else 99.0
                var pbd := predict_bounce()
                var alive_d: bool = ball.bounces >= 1 or (pbd.ok and absf(pbd.x) <= 4.115 and pbd.z >= 0.0 and pbd.z <= L)
                var gap: float = dpd - D.speed * 1.48 * maxf(t_est - 0.12, 0.0)
                if alive_d and t_est > 0.12 and t_est < 0.9 and gap > 0.8 and dpd < 4.6:
                    e.dive_t = 0.55
                    e.dive_cool = 2.4
                    e.dive_for = ball.hit_id
                    e.react = 0.0
                    var dl := maxf(dpd, 0.1)
                    e.vx = (e.tx - e.x) / dl * 10.5
                    e.vz = (e.tz - e.z) / dl * 10.5
                    events.append({"t": "dive", "id": e.id, "hid": ball.hit_id})
        # v0.33: lectura de bola muerta - si la bola sale y va al cuerpo, la
        # deja pasar de un salto lateral en vez de intentar el golpe y regalar
        # el punto al contacto (regla real: bola en vuelo que te toca, punto
        # del rival). Tambien esquiva si va al cuerpo en plena recuperacion.
        if e.dodge_for != ball.hit_id and e.dodge_t <= 0.0 and absf(ball.vz) > 8.0:
            var t_arr: float = (e.z - ball.z) / ball.vz
            if t_arr > 0.02 and t_arr < 1.2:
                var xa: float = ball.x + ball.vx * t_arr
                var ya: float = ball.y + ball.vy * t_arr - 0.5 * G * t_arr * t_arr
                if absf(xa - e.x) < 0.5 and ya > 0.25 and ya < 1.65:
                    var locked: bool = e.swing > 0.05 or e.cool > 0.05
                    var pb := predict_bounce()
                    # v0.35: tras el primer bote la bola SIEMPRE esta viva y hay
                    # que jugarla (antes se miraba el SEGUNDO bote, que sale
                    # siempre -> la dejaba pasar y regalaba el punto). La lectura
                    # de bola muerta solo vale antes del primer bote.
                    var playable: bool = ball.bounces >= 1 or (pb.ok and absf(pb.x) <= 4.115 and pb.z >= 0.0 and pb.z <= L)
                    # v0.35: saque/resto plano al cuerpo - aunque la bola entre,
                    # si llega en un suspiro no hay golpeo posible: apartarse SIEMPRE
                    # (regla: bola viva que te toca, punto del rival) y luego
                    # releer la jugada para devolver tras el bote.
                    var no_time: bool = playable and t_arr < 0.6 and absf(ball.vz) > 16.0
                    if locked or not playable or no_time:
                        e.dodge_for = ball.hit_id
                        if not playable:
                            e.letgo_for = ball.hit_id  # bola muerta: no intentar el golpe
                        var chance: float = clampf((1.15 if no_time else 1.05) - D.err, 0.45, 0.97)
                        if randf() < chance:
                            var side_d: float = signf(e.x - xa)
                            if side_d == 0.0:
                                side_d = 1.0 if e.x >= 0.0 else -1.0
                            e.tx = clampf(e.x + side_d * randf_range(1.2, 1.7), -5.4, 5.4)
                            e.tz = e.z
                            e.react = 0.0
                            e.dodge_t = 0.35
                            if playable:
                                # v0.35: bola buena esquivada -> releer la jugada
                                # en cuanto acabe la estocada y buscar el resto
                                e.pred_for = -1
                                e.dodge_t = 0.26
                            # impulso inmediato de estocada (si no, la aceleracion
                            # normal no aparta el cuerpo a tiempo)
                            e.vx = side_d * 7.5
                            e.vz = 0.0
                            events.append({"t": "dodge", "id": e.id, "hid": ball.hit_id})
        e.react -= dt
        if e.react <= 0.0:
            tx = e.tx
            tz = e.tz
            mv = D.speed * (1.48 if (serve_unreturned and M.server != e.id) else e.chase)
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
        var gx := 2.35 if srv_ret2 else 1.45
        var gz := 2.25 if srv_ret2 else 1.35
        if e.dive_t > 0.0:
            gx *= 1.8  # v0.36: en estirada el alcance crece
            gz *= 1.8
        # v0.33: preparacion - la CPU carga el backswing un instante antes del
        # contacto (solo visual: no cambia ni adelanta el golpe, que sigue
        # saliendo en do_hit dentro del mismo radio de siempre)
        if e.want_t <= 0.0 and e.letgo_for != ball.hit_id and ball.y < 3.4:
            var dist := Vector2(ball.x - e.x, ball.z - e.z).length()
            var to_p := Vector2(e.x - ball.x, e.z - ball.z)
            var closing := (ball.vx * to_p.x + ball.vz * to_p.y) / maxf(dist, 0.05)
            var tta := dist / maxf(closing, 5.0)
            if tta < 0.55:
                # v0.35: arma la raqueta mientras se acerca al bote (antes: en 1 frame)
                e.want = "drive"
                e.want_t = 0.3
        if dx < gx and dz < gz and ball.y < 2.9 and ball.y > 0.15 and e.letgo_for != ball.hit_id and (state != "serve" or ball.bounces >= 1):
            var stretch := dx > 1.0 or dz > 1.0
            if not (stretch and randf() < D.miss):
                var kind := "drive"
                var r: float = e.kind_roll
                # v0.35: subir a la red tras el tiro forzado - si el rival va
                # estirado y el estilo lo permite (los agresivos suben mas),
                # se cierra el punto en la red en vez de quedarse atras
                if absf(opp.x) > 2.4 or absf(opp.vx) > 2.5:
                    if randf() < D.risk * 0.55:
                        e.appr_t = 1.6
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
                    # v0.35: mas repertorio defensivo - globo para salir del smash,
                    # de la contradejada y de la estirada (los defensivos, mas)
                    var def_lob_p: float = 0.10 + (0.9 - D.err) * 0.10 + (1.0 - D.risk) * 0.12
                    if ball.kind == "smash":
                        def_lob_p += 0.25
                    elif ball.kind == "drop":
                        def_lob_p += 0.15
                    if r < def_lob_p:
                        kind = "lob"  # llega estirada: globo defensivo para recuperar
                do_hit(e, kind, true)
            else:
                e.cool = 0.3
                e.swing = 0.3
                e.kind = "drive"

func human_control(e: Player, dt: float) -> void:
    var move_input := Vector2(inp.x, inp.y).limit_length(1.0)
    e.tvx = move_input.x * PS.speed
    e.tvz = move_input.y * PS.speed
    e.wait_serve = state == "serve" and M.server != e.id
    # v0.35: armado temprano (solo visual) - lleva la raqueta atras mientras
    # se acerca al bote, en vez de sacar el raquetazo de la nada
    e.prep_t = maxf(0.0, e.prep_t - dt)
    if e.swing <= 0.0 and e.want_t <= 0.0 and ball.in_play and ball.last != e.id and ball.vz < 0.0 and state == "play":
        var pdist := Vector2(ball.x - e.x, ball.z - e.z).length()
        var pto := Vector2(e.x - ball.x, e.z - ball.z)
        var pclose := (ball.vx * pto.x + ball.vz * pto.y) / maxf(pdist, 0.05)
        if pdist / maxf(pclose, 5.0) < 0.6:
            e.prep_t = 0.25
    # v0.36: estirada automatica del humano - corriendo a tope hacia una bola
    # que se te escapa por ~1m, el muñeco se tira y gana alcance (pedido)
    if e.dive_t <= 0.0 and e.dive_cool <= 0.0 and e.swing <= 0.0 and state == "play" and ball.in_play and ball.last != e.id and ball.vz < 0.0 and e.speed > 3.2:
        var bdist := Vector2(ball.x - e.x, ball.z - e.z).length()
        var bto := Vector2(e.x - ball.x, e.z - ball.z)
        var bclose := (ball.vx * bto.x + ball.vz * bto.y) / maxf(bdist, 0.05)
        var tta := bdist / maxf(bclose, 5.0)
        var h_gap: float = bdist - PS.speed * maxf(tta - 0.12, 0.0)
        if tta < 0.75 and h_gap > 0.7 and bdist < 4.2 and e.dive_for != ball.hit_id:
            e.dive_t = 0.55
            e.dive_cool = 2.4
            e.dive_for = ball.hit_id
            var bl := maxf(bdist, 0.1)
            e.vx = (ball.x - e.x) / bl * 10.5
            e.vz = (ball.z - e.z) / bl * 10.5
            if e.want_t <= 0.0:
                e.want = "drive"
                e.want_t = 0.3
            events.append({"t": "dive", "id": e.id, "hid": ball.hit_id})
    var want_hit: bool = inp.hit
    var want_lob: bool = inp.lob
    var want_slice: bool = inp.slice
    var want_topspin: bool = inp.topspin
    inp.hit = false
    inp.lob = false
    inp.slice = false
    inp.topspin = false
    if state == "serve" and M.server == 0:
        if want_hit or want_lob or want_slice or want_topspin:
            if serve_stage == "ready":
                toss_ball()
            elif serve_stage == "toss":
                do_serve(e, 1.0 - clamp(absf(ball.toss_t - 0.50) / 0.45, 0.0, 1.0))
        return
    # v0.25: no iniciar el swing sobre bola muerta (parecia que aun podias pegarle)
    if want_hit or want_lob or want_slice or want_topspin:
        if e.swing <= 0.0 and state == "play" and ball.in_play:
            e.swing = 0.3
            e.kind = "lob" if want_lob else ("slice" if want_slice else ("topspin" if want_topspin else ("drop" if inp.y < -0.4 else "drive")))
            e.want = e.kind
            e.want_t = 0.3
    if e.want_t > 0.0:
        e.want_t -= dt
        if ball.in_play and ball.last != e.id and ball.vz < 0 and e.cool <= 0.0 and state == "play":
            _assist(e)
            var dx := absf(ball.x - e.x)
            var dz := absf(ball.z - e.z)
            # Ventana de contacto arcade: el jugador puede anticipar el golpe
            # mientras llega a la zona, evitando que el input se sienta perdido.
            var hgx := 2.30
            var hgz := 2.00
            if e.dive_t > 0.0:
                hgx *= 1.8  # v0.36: alcance de estirada
                hgz *= 1.8
            if dx < hgx and dz < hgz and ball.y < 3.1:
                do_hit(e, e.want, false)
                e.want_t = 0.0
    # Tras golpear, volver gradualmente a una posicion de recuperacion central.
    if state == "play" and ball.in_play and ball.last == e.id and e.swing <= 0.0 and e.want_t <= 0.0 and move_input.length() < 0.12:
        var home_x := clampf(ball.x * 0.32, -2.2, 2.2)
        var home_z := -0.5 if e.near else L + 0.5
        e.tvx = clampf((home_x - e.x) * 1.4, -PS.speed * 0.62, PS.speed * 0.62)
        e.tvz = clampf((home_z - e.z) * 1.1, -PS.speed * 0.4, PS.speed * 0.4)

func update_player(e: Player, dt: float) -> void:
    e.cool = max(0.0, e.cool - dt)
    e.swing = max(0.0, e.swing - dt)
    e.flash = max(0.0, e.flash - dt)
    e.dive_t = max(0.0, e.dive_t - dt)  # v0.36
    e.dive_cool = max(0.0, e.dive_cool - dt)  # v0.36
    # v0.30: inercia con derrape - al cortar una carrera o cambiar de sentido
    # el cuerpo tarda un pelin mas (derrape corto estilo Virtua Tennis)
    var kvx := 11.0
    var kvz := 11.0
    if e.dive_t > 0.0:
        kvx = 2.2  # v0.36: en estirada manda el impulso del salto
        kvz = 2.2
    if e.tvx == 0.0:
        kvx = 7.5
    elif signf(e.tvx) != signf(e.vx) and absf(e.vx) > 2.2:
        kvx = 4.2  # v0.35: derrape mas visible al cambiar de sentido
    if e.tvz == 0.0:
        kvz = 7.5
    elif signf(e.tvz) != signf(e.vz) and absf(e.vz) > 2.2:
        kvz = 4.2  # v0.35: derrape mas visible al cambiar de sentido
    e.vx += (e.tvx - e.vx) * minf(1.0, dt * kvx)
    e.vz += (e.tvz - e.vz) * minf(1.0, dt * kvz)
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
    ball.hot = maxf(0.0, ball.hot - dt * 2.5)
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
