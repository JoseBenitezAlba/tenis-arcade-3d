class_name SoundKit
extends Node


const RATE: = 22050
var streams: = {}
var muted: = false
var rng: = RandomNumberGenerator.new()

func _ready() -> void :
	rng.seed = 5

	streams["skid"] = _mix([{"n": 0.1, "vol": 0.35}], [{"f": 300.0, "d": 0.1, "vol": 0.1, "slide": -140.0, "w": "tri"}], 0.12)


	streams["bounce_clay"] = _mix([{"n": 0.03, "vol": 0.5, "atk": 0.001}], [{"f": 330.0, "d": 0.03, "vol": 0.16, "slide": -180.0, "w": "tri"}, {"f": 96.0, "d": 0.07, "vol": 0.14, "slide": -30.0}], 0.09)
	streams["skid_clay"] = _mix([{"n": 0.18, "vol": 0.4, "atk": 0.03}], [{"f": 240.0, "d": 0.16, "vol": 0.08, "slide": -120.0, "w": "tri"}], 0.18)

	streams["bounce_grass"] = _mix([{"n": 0.02, "vol": 0.32, "atk": 0.001}], [{"f": 230.0, "d": 0.02, "vol": 0.1, "slide": -120.0, "w": "tri"}, {"f": 120.0, "d": 0.04, "vol": 0.08, "slide": -35.0}], 0.06)
	streams["skid_grass"] = _mix([{"n": 0.07, "vol": 0.2}], [{"f": 340.0, "d": 0.07, "vol": 0.06, "slide": -160.0, "w": "tri"}], 0.08)


	streams["step"] = _mix([{"n": 0.03, "vol": 0.18}], [{"f": 180.0, "d": 0.03, "vol": 0.06, "slide": -60.0, "w": "tri"}], 0.045)
	streams["step_clay"] = _mix([{"n": 0.05, "vol": 0.13, "atk": 0.01}], [{"f": 140.0, "d": 0.04, "vol": 0.05, "slide": -40.0, "w": "tri"}], 0.06)
	streams["step_grass"] = _mix([{"n": 0.025, "vol": 0.1}], [{"f": 200.0, "d": 0.02, "vol": 0.04, "slide": -50.0, "w": "tri"}], 0.035)
	streams["hit_weak"] = _mix([{"n": 0.02, "vol": 0.55, "atk": 0.001}], [{"f": 430.0, "d": 0.02, "vol": 0.2, "slide": -280.0, "w": "tri"}, {"f": 150.0, "d": 0.06, "vol": 0.2, "slide": -50.0}, {"f": 82.0, "d": 0.07, "vol": 0.22, "slide": -15.0}], 0.1)
	streams["hit"] = _mix([{"n": 0.026, "vol": 0.82, "atk": 0.001}], [{"f": 760.0, "d": 0.026, "vol": 0.34, "slide": -520.0, "w": "tri"}, {"f": 190.0, "d": 0.07, "vol": 0.3, "slide": -90.0}, {"f": 86.0, "d": 0.1, "vol": 0.34, "slide": -18.0}], 0.13)

	streams["hit_charge"] = _mix([{"n": 0.032, "vol": 1.0, "atk": 0.001}], [{"f": 900.0, "d": 0.03, "vol": 0.42, "slide": -620.0, "w": "tri"}, {"f": 210.0, "d": 0.08, "vol": 0.38, "slide": -100.0}, {"f": 92.0, "d": 0.11, "vol": 0.45, "slide": -24.0}], 0.14)
	streams["hit_big"] = _mix([{"n": 0.038, "vol": 1.0, "atk": 0.001}], [{"f": 830.0, "d": 0.034, "vol": 0.46, "slide": -580.0, "w": "tri"}, {"f": 195.0, "d": 0.1, "vol": 0.38, "slide": -105.0}, {"f": 76.0, "d": 0.16, "vol": 0.52, "slide": -16.0}], 0.17)
	streams["bounce"] = _mix([{"n": 0.018, "vol": 0.5, "atk": 0.001}], [{"f": 640.0, "d": 0.018, "vol": 0.16, "slide": -360.0, "w": "tri"}, {"f": 150.0, "d": 0.055, "vol": 0.14, "slide": -40.0}], 0.08)
	streams["net"] = _mix([{"n": 0.15, "vol": 0.55, "atk": 0.002}], [{"f": 430.0, "d": 0.03, "vol": 0.18, "slide": -280.0, "w": "tri"}, {"f": 95.0, "d": 0.16, "vol": 0.22, "slide": -40.0}], 0.2)
	streams["serve"] = _mix([{"n": 0.22, "vol": 0.09, "atk": 0.05}], [{"f": 520.0, "d": 0.2, "vol": 0.02, "slide": -300.0, "w": "tri"}], 0.22)
	streams["fault"] = _mix([], [{"f": 200.0, "d": 0.25, "vol": 0.08, "slide": -60.0, "w": "saw"}])
	streams["click"] = _mix([], [{"f": 900.0, "d": 0.04, "vol": 0.05, "w": "square"}])
	streams["judge"] = _mix_seq([[660.0, 0.07], [880.0, 0.1]], 0.1)
	streams["point_win"] = _claps(0.75)
	streams["match_win"] = _mix_seq([[523.25, 0.11], [659.25, 0.11], [783.99, 0.11], [783.99, 0.11], [1046.5, 0.55]], 0.11)
	streams["point_lose"] = _mix([{"n": 0.8, "vol": 0.16, "atk": 0.1}], [{"f": 230.0, "d": 0.8, "vol": 0.04, "slide": -90.0, "w": "tri"}], 0.8)

	streams["murmur"] = _mix([{"n": 2.0, "vol": 0.16, "atk": 0.7}], [{"f": 240.0, "d": 2.0, "vol": 0.05, "slide": -60.0, "w": "tri"}], 2.0)
	streams["ovation"] = _mix([{"n": 2.6, "vol": 0.55, "atk": 0.06}], [{"f": 320.0, "d": 2.6, "vol": 0.1, "slide": -120.0, "w": "tri"}], 2.6)

	streams["dive"] = _mix([{"n": 0.24, "vol": 0.3, "atk": 0.05}], [{"f": 300.0, "d": 0.2, "vol": 0.1, "slide": -180.0, "w": "tri"}], 0.24)


	streams["hit_perfect"] = _mix([{"n": 0.03, "vol": 1.0, "atk": 0.001}], [{"f": 980.0, "d": 0.03, "vol": 0.5, "slide": -720.0, "w": "tri"}, {"f": 220.0, "d": 0.08, "vol": 0.42, "slide": -130.0}, {"f": 90.0, "d": 0.14, "vol": 0.55, "slide": -18.0}], 0.16)

	streams["hit_drop"] = _mix([{"n": 0.05, "vol": 0.22}], [{"f": 150.0, "d": 0.06, "vol": 0.14, "slide": -40.0, "w": "tri"}])


	streams["grunt"] = _mix([{"n": 0.13, "vol": 0.3, "atk": 0.015}], [{"f": 260.0, "d": 0.13, "vol": 0.16, "slide": -90.0, "w": "saw"}, {"f": 620.0, "d": 0.1, "vol": 0.06, "slide": -200.0, "w": "tri"}], 0.14)

	streams["hit_slice"] = _mix([{"n": 0.06, "vol": 0.5, "atk": 0.003}], [{"f": 520.0, "d": 0.025, "vol": 0.18, "slide": -340.0, "w": "tri"}, {"f": 300.0, "d": 0.09, "vol": 0.14, "slide": -150.0, "w": "saw"}, {"f": 120.0, "d": 0.08, "vol": 0.18, "slide": -30.0}], 0.12)

	streams["hit_volley"] = _mix([{"n": 0.022, "vol": 0.8, "atk": 0.001}], [{"f": 700.0, "d": 0.022, "vol": 0.3, "slide": -420.0, "w": "tri"}, {"f": 200.0, "d": 0.055, "vol": 0.28, "slide": -80.0}, {"f": 95.0, "d": 0.06, "vol": 0.26, "slide": -22.0}], 0.09)

	streams["crowd_ooh"] = _mix([{"n": 1.1, "vol": 0.2, "atk": 0.12}], [{"f": 330.0, "d": 1.1, "vol": 0.1, "slide": -120.0, "w": "tri"}], 1.1)

	streams["applause"] = _claps(2.2)


	streams["swish"] = _mix([{"n": 0.2, "vol": 0.42, "atk": 0.05}], [{"f": 620.0, "d": 0.18, "vol": 0.1, "slide": -380.0, "w": "saw"}], 0.22)

	streams["whoosh"] = _mix([{"n": 0.16, "vol": 0.36, "atk": 0.06}], [{"f": 480.0, "d": 0.14, "vol": 0.06, "slide": -260.0, "w": "saw"}], 0.17)

	streams["ole"] = _ole(0.75)

	streams["catch"] = _mix([{"n": 0.04, "vol": 0.16}], [{"f": 190.0, "d": 0.05, "vol": 0.14, "slide": -60.0, "w": "tri"}], 0.07)

	streams["ambience"] = _ambience(4.0)

	streams["tape"] = _mix([{"n": 0.07, "vol": 0.5, "atk": 0.002}], [{"f": 720.0, "d": 0.03, "vol": 0.2, "slide": -420.0, "w": "tri"}, {"f": 500.0, "d": 0.08, "vol": 0.1, "slide": -220.0, "w": "tri"}], 0.11)

	streams["drum"] = _drum(1.9)


	streams["grunt"] = _mix([{"n": 0.1, "vol": 0.2, "atk": 0.01}], [{"f": 130.0, "d": 0.15, "vol": 0.5, "slide": -45.0, "w": "saw"}, {"f": 262.0, "d": 0.11, "vol": 0.22, "slide": -70.0, "w": "tri"}], 0.17)

	_load_samples()

func _load_samples() -> void :
	var files: = {
		"hit_01": "res://assets/audio/tennis_hit_01.mp3",
		"hit_02": "res://assets/audio/tennis_hit_02.mp3",
		"bounce": "res://assets/audio/tennis_bounce.mp3",
		"net": "res://assets/audio/tennis_net.mp3",
	}
	var smp: = {}
	for k in files:
		if ResourceLoader.exists(files[k]):
			smp[k] = load(files[k])
	if smp.is_empty():
		return
	var h1 = smp.get("hit_01")
	var h2 = smp.get("hit_02", h1)
	if h1 != null:
		streams["hit"] = h1
		streams["hit_weak"] = h1
		streams["hit_perfect"] = h1
		streams["hit_slice"] = h1
		streams["hit_volley"] = h1
	if h2 != null:
		streams["hit_big"] = h2
		streams["hit_charge"] = h2
	if smp.get("bounce") != null:
		streams["bounce"] = smp["bounce"]
	if smp.get("net") != null:
		streams["net"] = smp["net"]
		streams["tape"] = smp["net"]

func _mix(noises: Array, tones: Array, dur: = 0.3) -> AudioStreamWAV:
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: = float(i) / RATE
		var v: = 0.0
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
				var ph: = 2.0 * PI * f * t
				var osc: = sin(ph)
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
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	return st



func _ambience(dur: float = 4.0) -> AudioStreamWAV:
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var lp: = 0.0
	for i in n:
		var t: = float(i) / RATE
		var w: = 0.75 + 0.25 * sin(2.0 * PI * 0.23 * t)
		var nz: = (rng.randf() * 2.0 - 1.0)
		lp = lp * 0.82 + nz * 0.18
		var v: = lp * 0.5 * w + sin(2.0 * PI * 190.0 * t) * 0.015 * w
		var sm: int = clamp(int(v * 30000), -32768, 32767)
		data.encode_s16(i * 2, sm)
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = n
	st.data = data
	return st



func _drum(dur: float = 1.9) -> AudioStreamWAV:
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var beats: = [[0.0, 1.0], [0.3, 0.7], [0.95, 1.0], [1.25, 0.7]]
	for i in n:
		var t: = float(i) / RATE
		var v: = 0.0
		for b in beats:
			var d: float = t - b[0]
			if d >= 0.0 and d < 0.16:
				var env: float = pow(1.0 - d / 0.16, 2.2)
				v += sin(2.0 * PI * (58.0 - d * 60.0) * d) * 0.55 * b[1] * env
				v += (rng.randf() * 2.0 - 1.0) * 0.08 * b[1] * pow(1.0 - d / 0.16, 4.0)
		var sm: int = clamp(int(v * 30000), -32768, 32767)
		data.encode_s16(i * 2, sm)
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	return st



func _ole(dur: float = 0.75) -> AudioStreamWAV:
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t: = float(i) / RATE
		var v: = (rng.randf() * 2.0 - 1.0) * 0.05 * minf(1.0, t / 0.12)
		for syl in [[0.02, 0.24, 392.0], [0.28, 0.55, 494.0]]:
			if t >= syl[0] and t <= syl[1]:
				var tt: float = t - syl[0]
				var sd: float = syl[1] - syl[0]
				var env: float = sin(PI * tt / sd)
				for det in [-6.0, 0.0, 5.0]:
					v += sin(2.0 * PI * (syl[2] + det) * tt) * 0.09 * env
		var g: float = 1.0 - pow(minf(1.0, t / dur), 2.0) * 0.5
		var sm: int = clamp(int(v * g * 30000), -32768, 32767)
		data.encode_s16(i * 2, sm)
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	return st


func _claps(dur: float) -> AudioStreamWAV:
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var bursts: Array = []
	var t: = 0.0
	while t < dur - 0.05:
		bursts.append(t)
		t += rng.randf_range(0.03, 0.09)
	for i in n:
		var tt: = float(i) / RATE
		var v: = (rng.randf() * 2.0 - 1.0) * 0.06 * minf(1.0, tt / 0.3)
		for b in bursts:
			var d: float = tt - b
			if d >= 0.0 and d < 0.035:
				v += (rng.randf() * 2.0 - 1.0) * 0.5 * pow(1.0 - d / 0.035, 2.0)
		var g: float = 1.0 - pow(minf(1.0, tt / dur), 3.0) * 0.7
		var sm: int = clamp(int(v * g * 30000), -32768, 32767)
		data.encode_s16(i * 2, sm)
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	return st

func _mix_seq(notes: Array, vol: float, slide: float = 0.0) -> AudioStreamWAV:
	var dur: = 0.0
	for nt in notes:
		dur += nt[1]
	dur += 0.1
	var n: = int(RATE * dur)
	var data: = PackedByteArray()
	data.resize(n * 2)
	var t0: = 0.0
	for nt in notes:
		var f: float = nt[0]
		var d: float = nt[1]
		for i in int(RATE * d):
			var t: = float(i) / RATE
			var ph: = 2.0 * PI * (f + slide * t) * t
			var osc: = 1.0 if sin(ph) > 0 else -1.0
			var v: = osc * vol * (1.0 - t / d)
			var idx: = int((t0 + t) * RATE) * 2
			if idx + 1 < data.size():
				var cur: = data.decode_s16(idx)
				data.encode_s16(idx, clamp(cur + int(v * 30000), -32768, 32767))
		t0 += d
	var st: = AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.data = data
	return st


func hush() -> void :
	for c in get_children():
		if c is AudioStreamPlayer and (c.stream == streams.get("murmur") or c.stream == streams.get("ovation")):
			c.queue_free()


var play_counts: Dictionary = {}


func surf_name(base: String, surface: String) -> String:
	var v: = base + "_" + surface
	return v if streams.has(v) else base

func play(name: String, vol: float = 1.0, pitch: float = 1.0) -> void :
	if muted or not streams.has(name):
		return
	play_counts[name] = int(play_counts.get(name, 0)) + 1
	var p: = AudioStreamPlayer.new()
	p.stream = streams[name]
	p.volume_db = linear_to_db(max(vol, 0.01))
	p.pitch_scale = pitch
	if p.stream is AudioStreamMP3 and (name.begins_with("hit") or name == "bounce"):
		p.pitch_scale *= rng.randf_range(0.94, 1.06)
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
