class_name SoundKit
extends Node

# SFX sintetizados por codigo (tonos + ruido), sin assets externos.
const RATE := 22050
var streams := {}
var muted := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 5
    # v0.36: golpe con cuerpo - capa grave (thump ~80Hz) bajo el chasquido
    streams["hit"] = _mix([{"n": 0.10, "vol": 0.55}], [{"f": 175.0, "d": 0.09, "vol": 0.28, "slide": -80.0, "w": "tri"}, {"f": 82.0, "d": 0.12, "vol": 0.40, "slide": -22.0}])
    streams["hit_big"] = _mix([{"n": 0.13, "vol": 0.85}], [{"f": 190.0, "d": 0.11, "vol": 0.40, "slide": -110.0, "w": "tri"}, {"f": 72.0, "d": 0.16, "vol": 0.55, "slide": -18.0}])
    streams["bounce"] = _mix([{"n": 0.06, "vol": 0.25}], [{"f": 120.0, "d": 0.05, "vol": 0.12, "slide": -40.0}])
    streams["net"] = _mix([{"n": 0.18, "vol": 0.3}], [{"f": 90.0, "d": 0.2, "vol": 0.2, "slide": -40.0}])
    streams["serve"] = _mix([], [{"f": 700.0, "d": 0.08, "vol": 0.08, "slide": 300.0}])
    streams["fault"] = _mix([], [{"f": 200.0, "d": 0.25, "vol": 0.08, "slide": -60.0, "w": "saw"}])
    streams["click"] = _mix([], [{"f": 900.0, "d": 0.04, "vol": 0.05, "w": "square"}])
    streams["point_win"] = _mix_seq([[523.0, 0.12], [659.0, 0.12], [784.0, 0.2]], 0.08)
    streams["point_lose"] = _mix_seq([[300.0, 0.2], [220.0, 0.3]], 0.07, -70.0)
    # v0.35: ambiente de grada - murmullo de expectacion y ovacion
    streams["murmur"] = _mix([{"n": 2.0, "vol": 0.16, "atk": 0.7}], [{"f": 240.0, "d": 2.0, "vol": 0.05, "slide": -60.0, "w": "tri"}], 2.0)
    streams["ovation"] = _mix([{"n": 2.6, "vol": 0.55, "atk": 0.06}], [{"f": 320.0, "d": 2.6, "vol": 0.10, "slide": -120.0, "w": "tri"}], 2.6)
    # v0.36: estirada - whoosh de cuerpo que se tira
    streams["dive"] = _mix([{"n": 0.24, "vol": 0.30, "atk": 0.05}], [{"f": 300.0, "d": 0.2, "vol": 0.10, "slide": -180.0, "w": "tri"}], 0.24)

func _mix(noises: Array, tones: Array, dur := 0.3) -> AudioStreamWAV:
    var n := int(RATE * dur)
    var data := PackedByteArray()
    data.resize(n * 2)
    for i in n:
        var t := float(i) / RATE
        var v := 0.0
        for nz in noises:
            if t < nz.n:
                var env: float = pow(1.0 - t / nz.n, 1.6)
                var atk: float = nz.get("atk", 0.0)
                if atk > 0.0:
                    env *= minf(1.0, t / atk)
                v += (rng.randf() * 2.0 - 1.0) * nz.vol * env
        for tn in tones:
            if t < tn.d:
                var f: float = tn.f + tn.get("slide", 0.0) * (t / tn.d)
                var ph := 2.0 * PI * f * t
                var osc := sin(ph)
                match tn.get("w", "sine"):
                    "square":
                        osc = 1.0 if sin(ph) > 0 else -1.0
                    "tri":
                        osc = 2.0 / PI * asin(sin(ph))
                    "saw":
                        osc = 2.0 * (f * t - floor(f * t + 0.5))
                v += osc * tn.vol * pow(1.0 - t / tn.d, 1.4)
        var s: int = clamp(int(v * 30000), -32768, 32767)
        data.encode_s16(i * 2, s)
    var st := AudioStreamWAV.new()
    st.format = AudioStreamWAV.FORMAT_16_BITS
    st.mix_rate = RATE
    st.data = data
    return st

func _mix_seq(notes: Array, vol: float, slide: float = 0.0) -> AudioStreamWAV:
    var dur := 0.0
    for nt in notes:
        dur += nt[1]
    dur += 0.1
    var n := int(RATE * dur)
    var data := PackedByteArray()
    data.resize(n * 2)
    var t0 := 0.0
    for nt in notes:
        var f: float = nt[0]
        var d: float = nt[1]
        for i in int(RATE * d):
            var t := float(i) / RATE
            var ph := 2.0 * PI * (f + slide * t) * t
            var osc := 1.0 if sin(ph) > 0 else -1.0
            var v := osc * vol * (1.0 - t / d)
            var idx := int((t0 + t) * RATE) * 2
            if idx + 1 < data.size():
                var cur := data.decode_s16(idx)
                data.encode_s16(idx, clamp(cur + int(v * 30000), -32768, 32767))
        t0 += d
    var st := AudioStreamWAV.new()
    st.format = AudioStreamWAV.FORMAT_16_BITS
    st.mix_rate = RATE
    st.data = data
    return st

# v0.36: silencio de grada - corta murmullo/ovacion al empezar el saque
func hush() -> void:
    for c in get_children():
        if c is AudioStreamPlayer and (c.stream == streams.get("murmur") or c.stream == streams.get("ovation")):
            c.queue_free()

func play(name: String, vol: float = 1.0) -> void:
    if muted or not streams.has(name):
        return
    var p := AudioStreamPlayer.new()
    p.stream = streams[name]
    p.volume_db = linear_to_db(max(vol, 0.01))
    p.finished.connect(p.queue_free)
    add_child(p)
    p.play()
