class_name Career
extends RefCounted

# Port del modo carrera de la versión web.
const SAVE_PATH := "user://career.save"
# v0.32: save atomico (tmp + rename) con backup .bak del ultimo estado bueno
const SAVE_TMP := "user://career.save.tmp"
const SAVE_BAK := "user://career.save.bak"
const SAVE_VERSION := 1
const RNAMES := ["Octavos", "Cuartos", "Semifinal", "Final"]
# v0.35: estilo explicito por rival (0 defensivo, 1 equilibrado, 2 agresivo),
# asignado por arquetipo real para que cada uno se sienta distinto.
const POOL0 := [
    ["Carlos Alcaca", 0.98, 2600, 2], ["Janiel Sinnar", 0.98, 2800, 1], ["Novak Djokovitz", 0.94, 2200, 0],
    ["Alex Zvereff", 0.9, 2000, 1], ["Daniil Medelle", 0.86, 1700, 0], ["Jack Drapper", 0.84, 1500, 2],
    ["Taylor Fritzz", 0.84, 1500, 2], ["Holger Runne", 0.8, 1300, 2], ["Kasper Ruud", 0.8, 1300, 0],
    ["Andrei Rubleff", 0.8, 1250, 2], ["Alex de Minaurr", 0.78, 1150, 0], ["Lorenzo Musseti", 0.76, 1050, 1],
    ["Stefanos Tsitsipass", 0.75, 1000, 1], ["Ben Chelton", 0.74, 950, 2], ["Tommy Paull", 0.72, 850, 1],
    ["Grigor Dimitroff", 0.72, 800, 1], ["Hubert Hurkatz", 0.7, 750, 2], ["Frances Tiafo", 0.7, 700, 2],
    ["Alexei Popyrine", 0.66, 600, 2], ["Francisco Serundolo", 0.64, 550, 0], ["Sebastian Kordda", 0.62, 500, 1],
    ["Ugo Humber", 0.6, 450, 1], ["Jakub Mensikk", 0.6, 400, 2], ["Joao Fonsecca", 0.6, 350, 2],
]
# v0.31: nombres reales -> inventados; mapa para migrar saves antiguas
const RENAME := {"Carlos Alcaraz": "Carlos Alcaca", "Jannik Sinner": "Janiel Sinnar", "Novak Djokovic": "Novak Djokovitz", "Alexander Zverev": "Alex Zvereff", "Daniil Medvedev": "Daniil Medelle", "Jack Draper": "Jack Drapper", "Taylor Fritz": "Taylor Fritzz", "Holger Rune": "Holger Runne", "Casper Ruud": "Kasper Ruud", "Andrey Rublev": "Andrei Rubleff", "Alex de Minaurr": "Alex de Minaurr", "Lorenzo Musetti": "Lorenzo Musseti", "Stefanos Tsitsipas": "Stefanos Tsitsipass", "Ben Shelton": "Ben Chelton", "Tommy Paul": "Tommy Paull", "Grigor Dimitrov": "Grigor Dimitroff", "Hubert Hurkacz": "Hubert Hurkatz", "Frances Tiafoe": "Frances Tiafo", "Alexei Popyrin": "Alexei Popyrine", "Francisco Cerúndolo": "Francisco Serundolo", "Sebastian Korda": "Sebastian Kordda", "Ugo Humbert": "Ugo Humber", "Jakub Mensik": "Jakub Mensikk", "Joao Fonseca": "Joao Fonsecca"}

const TIERS := {
    "C": {"n": "Challenger", "pts": 80, "rounds": 3, "lo": 10, "hi": 23},
    "250": {"n": "ATP 250", "pts": 250, "rounds": 3, "lo": 6, "hi": 23},
    "500": {"n": "ATP 500", "pts": 500, "rounds": 4, "lo": 3, "hi": 23},
    "1000": {"n": "Masters 1000", "pts": 1000, "rounds": 4, "lo": 0, "hi": 23},
    "GS": {"n": "Grand Slam", "pts": 2000, "rounds": 4, "lo": 0, "hi": 23},
    "F": {"n": "Finales", "pts": 1500, "rounds": 3, "lo": 0, "hi": 11},
}
const CAL := [
    {"n": "Challenger del Sur", "t": "C", "s": "clay", "d": true},
    {"n": "Open Costa Azul", "t": "250", "s": "hard", "d": true},
    {"n": "Abierto de Oceanía", "t": "GS", "s": "hard", "d": false},
    {"n": "Copa del Golfo", "t": "500", "s": "hard", "d": true},
    {"n": "Masters Palmeral", "t": "1000", "s": "grass", "d": true},
    {"n": "Masters Tierra Roja", "t": "1000", "s": "clay", "d": true},
    {"n": "Gran Premio Condal", "t": "500", "s": "grass", "d": true},
    {"n": "Grand Slam de la Capital", "t": "GS", "s": "clay", "d": true},
    {"n": "Abierto del Atlántico", "t": "500", "s": "hard", "d": false},
    {"n": "Finales del Circuito", "t": "F", "s": "hard", "d": false},
]

var data := {}

static func randn() -> float:
    return (randf() + randf() + randf() - 1.5) / 0.75

static func exists_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BAK)

static func _load_from(path: String) -> Career:
    if not FileAccess.file_exists(path):
        return null
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if typeof(parsed) != TYPE_DICTIONARY or parsed.get("v", 0) != SAVE_VERSION:
        return null
    var c := Career.new()
    c.data = parsed
    return c

static func load_saved() -> Career:
    # v0.32: si el save principal esta corrupto (apagon a mitad de escritura,
    # por ejemplo), se recupera el ultimo estado bueno del .bak
    var c := _load_from(SAVE_PATH)
    if c == null:
        c = _load_from(SAVE_BAK)
    if c == null:
        return null
    c._migrate_names()
    return c

func _migrate_names() -> void:
    # v0.31: cambia nombres reales guardados por los inventados
    if data.has("pool"):
        for pl in data.pool:
            if RENAME.has(pl.get("n", "")):
                pl.n = RENAME[pl.n]
            # v0.35: saves antiguas no tenian estilo -> todos quedaban en 1 (risk 0.5)
            if not pl.has("sty"):
                pl["sty"] = _style_of(pl.get("n", ""))
    if data.has("tour") and typeof(data.tour) == TYPE_DICTIONARY:
        var t: Dictionary = data.tour
        for k in ["opps", "field"]:
            if t.has(k) and typeof(t[k]) == TYPE_ARRAY:
                for i in t[k].size():
                    if RENAME.has(t[k][i]):
                        t[k][i] = RENAME[t[k][i]]
        save()

static func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

func new_career(pname: String) -> void:
    var pool := []
    for p in POOL0:
        pool.append({"n": p[0], "r": p[1], "pts": p[2], "sty": int(p[3]) if p.size() > 3 else hash(p[0]) % 3})
    data = {
        "v": 1, "name": pname, "stats": {"pw": 3, "sp": 3, "pr": 3}, "free": 3,
        "season": 1, "tIdx": 0, "pts": 0, "pool": pool, "tour": null,
        "hist": [], "won": 0, "lost": 0, "titles": 0,
    }
    save()

func save() -> void:
    # v0.32: escritura atomica - se escribe a .tmp y se renombra encima, de modo
    # que el save nunca queda a medias; el anterior queda en .bak por si acaso
    data["v"] = SAVE_VERSION
    var f := FileAccess.open(SAVE_TMP, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify(data))
    f.close()
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, SAVE_BAK)
    DirAccess.rename_absolute(SAVE_TMP, SAVE_PATH)

func standings() -> Array:
    var a := []
    for p in data.pool:
        a.append({"n": p.n, "pts": p.pts, "r": p.r, "me": false})
    a.append({"n": data.name, "pts": data.pts, "r": 0.0, "me": true})
    a.sort_custom(func(x, y): return x.pts > y.pts if x.pts != y.pts else x.r > y.r)
    return a

func my_rank() -> int:
    var st := standings()
    for i in st.size():
        if st[i].me:
            return i + 1
    return st.size()

func round_name(t: Dictionary, i: int) -> String:
    return RNAMES.slice(4 - t.rounds)[i]

func start_tournament() -> void:
    var def: Dictionary = CAL[data.tIdx]
    var T: Dictionary = TIERS[def.t]
    var idxs := range(data.pool.size())
    idxs.sort_custom(func(a, b): return data.pool[a].r > data.pool[b].r if data.pool[a].r != data.pool[b].r else a < b)
    var eligible := []
    for i in range(T.lo, T.hi + 1):
        eligible.append(data.pool[idxs[i]])
    for i in range(eligible.size() - 1, 0, -1):
        var j := randi() % (i + 1)
        var tmp = eligible[i]
        eligible[i] = eligible[j]
        eligible[j] = tmp
    var need := int(pow(2, T.rounds)) - 1
    var field: Array = eligible.slice(0, need)
    if field.size() < need:
        var rest := []
        for p in data.pool:
            if not field.has(p):
                rest.append(p)
        field.append_array(rest.slice(0, need - field.size()))
    field.sort_custom(func(a, b): return a.r < b.r)
    var opps := []
    for i in T.rounds:
        opps.append(field[round(i * (field.size() - 1.0) / (T.rounds - 1.0))].n)
    var field_names := []
    for f in field:
        field_names.append(f.n)
    data.tour = {"idx": data.tIdx, "round": 0, "opps": opps, "field": field_names}
    save()

func opp_profile(pname: String) -> Dictionary:
    for p in data.pool:
        if p.n == pname:
            return p
    return {}

func current_opp() -> Dictionary:
    return opp_profile(data.tour.opps[data.tour.round])

static func _style_of(pname: String) -> int:
    for p in POOL0:
        if p[0] == pname and p.size() > 3:
            return int(p[3])
    return 1

static func style_name(sty: int) -> String:
    return ["Defensivo", "Equilibrado", "Agresivo"][clampi(sty, 0, 2)]

static func params_for(r: float, sty: int = 1) -> Dictionary:
    # v0.32: estilos - 0 defensivo, 1 equilibrado, 2 agresivo
    # v0.35: personalidades visibles, no solo risk. El ranking r sigue marcando
    # la dificultad; el estilo modula COMO juega:
    # - defensivo: cubre mas pista (+vel), comete menos (-err), busca menos el winner
    # - agresivo: gatillo mas rapido (-react), mas winners (+risk) pero mas fallos (+err)
    var risk: float = [0.3, 0.5, 0.75][clampi(sty, 0, 2)]
    var spd: float = [1.07, 1.0, 0.97][clampi(sty, 0, 2)]
    var rea: float = [1.0, 1.0, 0.88][clampi(sty, 0, 2)]
    var errm: float = [0.82, 1.0, 1.18][clampi(sty, 0, 2)]
    return {
        "speed": clampf((4.3 + 2.6 * r) * spd, 3.5, 7.4),
        "react": clampf((0.46 - 0.34 * r) * rea, 0.06, 0.5),
        "err": clampf((0.95 - 0.7 * r) * errm, 0.2, 1.6),
        "miss": 0.32 - 0.27 * r,
        "risk": risk,
    }

func player_from_stats() -> Dictionary:
    # v0.22: defensivo - saves antiguas pueden no tener "stats"
    var st: Dictionary = data.get("stats", {}) if data else {}
    var sp: float = float(st.get("sp", 3))
    var pw: float = float(st.get("pw", 3))
    var pr: float = float(st.get("pr", 3))
    return {"speed": 5.8 + 0.28 * sp, "T": 1.08 - 0.02 * pw, "err": 1.5 - 0.1 * pr}

func finish_tournament(wins: int) -> String:
    var def: Dictionary = CAL[data.tour.idx]
    var T: Dictionary = TIERS[def.t]
    var n: int = T.rounds
    var fr := [0.05, 0.15, 0.4, 0.7, 1.0] if n == 4 else [0.15, 0.4, 0.7, 1.0]
    var pts := int(round(T.pts * fr[wins]))
    data.pts += pts
    var champ := wins == n
    var res := "¡Campeón!" if champ else ("Finalista" if wins == n - 1 else "Eliminado en " + round_name(T, wins))
    if champ:
        data.titles += 1
    var others := []
    for p in data.pool:
        if data.tour.field.has(p.n):
            others.append({"p": p, "s": p.r + randn() * 0.12})
    others.sort_custom(func(a, b): return a.s > b.s)
    var order := [1, .7, .4, .4, .15, .15, .15, .15, .05, .05, .05, .05, .05, .05, .05] if n == 4 else [1, .7, .4, .4, .15, .15, .15]
    var rank0 := my_rank()
    var k := 0
    for o in others:
        var f = order[k + 1] if champ and k + 1 < order.size() else (order[k] if k < order.size() else 0.05)
        if champ:
            f = order[k + 1] if k + 1 < order.size() else 0.05
        else:
            f = order[k] if k < order.size() else 0.05
        o.p.pts += int(round(T.pts * f))
        k += 1
    data.hist.append({"n": def.n, "t": def.t, "res": res, "pts": pts})
    data.tIdx += 1
    data.tour = null
    var r1 := my_rank()
    save()
    return def.n + ": " + res + " · +" + str(pts) + " pts" + (" · ranking #" + str(rank0) + " → #" + str(r1) if r1 != rank0 else " · ranking #" + str(r1))

func on_career_end(win: bool) -> Dictionary:
    var def: Dictionary = CAL[data.tour.idx]
    var T: Dictionary = TIERS[def.t]
    var gain: int
    var msg := ""
    var ok := false
    if win:
        data.won += 1
        gain = 2
        data.free += gain
        data.tour.round += 1
        if data.tour.round >= T.rounds:
            msg = finish_tournament(T.rounds)
            ok = true
        else:
            msg = "¡Victoria! Pasas a " + round_name(T, data.tour.round) + " (" + def.n + "). +" + str(gain) + " puntos de mejora."
            ok = true
            save()
    else:
        data.lost += 1
        gain = 1
        data.free += gain
        msg = finish_tournament(data.tour.round)
        msg += " · +" + str(gain) + " punto de mejora"
    save()
    return {"msg": msg, "ok": ok}

func end_season() -> void:
    data.season += 1
    data.tIdx = 0
    data.tour = null
    data.pts = int(round(data.pts * 0.5))
    for p in data.pool:
        p.pts = int(round(p.pts * 0.5 + 300.0 * p.r))
    data.hist = []
    save()

static func stars(r: float) -> String:
    var n: int = clamp(int(round((r - 0.5) * 10.0)), 1, 5)
    return "★".repeat(n) + "☆".repeat(5 - n)
