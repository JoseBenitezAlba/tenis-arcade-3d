class_name TexGen
extends RefCounted


const LINE_W_BASE: = 0.13
const LINE_W_SIDE: = 0.085

const THEMES: = {
	"clay": {"court": Color("#805025"), "court2": Color("#79502a"), "surround": Color("#7c502a"), "out": Color("#76502b"), "out2": Color("#6b4729"), "line": Color("#f6f1e6")},
	"hard": {"court": Color("#0d47a1"), "court2": Color("#0b3f91"), "surround": Color("#2e7d32"), "out": Color("#256b2a"), "out2": Color("#1e5a24"), "line": Color("#f4f6fa")},
	"grass": {"court": Color("#3a6832"), "court2": Color("#355e2d"), "surround": Color("#1c341d"), "out": Color("#214022"), "out2": Color("#1a361c"), "line": Color("#f6f8f2")},
}
const NIGHT_THEMES: = {
	"hard": {"court": Color("#173a5e"), "court2": Color("#143352"), "surround": Color("#2c5d32"), "out": Color("#28542d"), "out2": Color("#1f4325"), "line": Color("#f4f6fa")},
	"clay": {"court": Color("#64411a"), "court2": Color("#5e3c18"), "surround": Color("#543614"), "out": Color("#3d2917"), "out2": Color("#2e1f10"), "line": Color("#f6f1e6")},
}
const L: = 23.77
const NZ: = L / 2.0


static func court_texture(surface: String, night: bool = false) -> ImageTexture:
	var T: Dictionary = NIGHT_THEMES[surface] if night and NIGHT_THEMES.has(surface) else THEMES[surface]
	var w: = 1024
	var h: = 2048
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(T.surround)
	var pxm_x: = w / 14.4
	var pxm_z: = h / 31.37
	var z_of: = func(py: float) -> float: return -4.0 + py / pxm_z
	var py_of: = func(z: float) -> float: return (z + 4.0) * pxm_z
	var px_of: = func(x: float) -> float: return (x + 7.2) * pxm_x

	var ix0: = int(px_of.call(-5.6))
	var ix1: = int(px_of.call(5.6))
	var iy0: = int(py_of.call(-0.15))
	var iy1: = int(py_of.call(L + 0.15))
	img.fill_rect(Rect2i(ix0, iy0, ix1 - ix0, iy1 - iy0), T.court)

	if surface == "grass":
		var k: = 0
		var z: = -4.0
		while z < L + 3.6:
			if k % 2 == 1:
				var y0: = int(py_of.call(max(z, -0.05)))
				var y1: = int(py_of.call(min(z + 3.0, L + 0.05)))
				if y1 > y0:
					img.fill_rect(Rect2i(ix0, y0, ix1 - ix0, y1 - y0), T.court2)
			z += 6.0
			k += 1

	var rng: = RandomNumberGenerator.new()
	rng.seed = 7
	if surface == "clay":
		# Variacion mineral en varias escalas, sin bandas rectas de desgaste.
		var soil: = Image.create(256, 512, false, Image.FORMAT_RGBA8)
		for sy in 512:
			var zz: float = -4.0 + float(sy) / 512.0 * 31.37
			for sx in 256:
				var xx: float = -7.2 + float(sx) / 256.0 * 14.4
				var inside: bool = absf(xx) < 5.6 and zz > -0.15 and zz < L + 0.15
				var base: Color = T.court if inside else T.surround
				var grain: float = 0.57 * _vnoise(xx * 1.2 + 12.0, zz * 1.2) + 0.28 * _vnoise(xx * 4.8, zz * 4.8) + 0.15 * _vnoise(xx * 15.0, zz * 15.0)
				var tone: Color = base.lerp(Color("#bc8e55"), maxf(0.0, grain - 0.42) * 0.16)
				tone = tone.lerp(Color("#4e321c"), maxf(0.0, 0.50 - grain) * 0.12)
				var baseline: float = exp(-pow(minf(absf(zz - 0.4), absf(zz - L + 0.4)), 2.0) / 1.4)
				var lateral: float = 1.0 - smoothstep(2.4, 5.3, absf(xx))
				tone = tone.lerp(Color("#9b703d"), baseline * lateral * grain * 0.10)
				soil.set_pixel(sx, sy, tone)
		soil.resize(w, h, Image.INTERPOLATE_BILINEAR)
		img = soil

	elif surface == "grass":
		var wear_c: = Color(0.33, 0.36, 0.20)
		for zc in [0.7, L - 0.7]:
			var px0: int = int(px_of.call(-4.6))
			var px1: int = int(px_of.call(4.6))
			var py0: int = int(py_of.call(zc - 1.2))
			var py1: int = int(py_of.call(zc + 1.2))
			for yy in range(py0, py1):
				var zz: float = z_of.call(yy)
				var dep: float = exp(-pow(zz - zc, 2.0) / (2.0 * 0.45 * 0.45))
				for xx in range(px0, px1):
					var wx: float = xx / pxm_x - 7.2
					var lat: float = 1.0 - smoothstep(2.0, 4.2, absf(wx))
					if lat <= 0.0:
						continue
					var nse: float = 0.65 * _vnoise(wx * 1.7, zz * 1.7) + 0.35 * _vnoise(wx * 5.1 + 40.0, zz * 5.1)
					var a: float = clampf(lat * dep * (0.30 + 0.70 * nse), 0.0, 1.0) * 0.14
					if a > 0.004:
						img.set_pixel(xx, yy, img.get_pixel(xx, yy).lerp(wear_c, a))
	var _ss: float = 0.06 if surface == "clay" else 0.035
	for n in 14000:
		var x: = rng.randi() % w
		var y: = rng.randi() % h
		var c: = Color(1, 1, 1, rng.randf_range(_ss * 0.3, _ss)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(_ss * 0.3, _ss))
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

	for n in 2400:
		var zx: float = [0.6, L - 0.6, NZ - 1.2, NZ + 1.2][rng.randi() % 4]
		var x: = int(px_of.call(rng.randf_range(-3.4, 3.4)))
		var y: = int(py_of.call(zx + rng.randf_range(-0.5, 0.5)))
		if x >= 0 and x < w and y >= 0 and y < h:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(Color(1, 1, 1, rng.randf_range(0.04, 0.1))))


	if surface == "grass":
		var dry: = Color("#5d6b3c")
		for zone in [[0.0, 0.05, 2.9, 1.1], [0.0, L - 0.05, 2.9, 1.1], [0.0, NZ - 6.4, 2.2, 0.8], [0.0, NZ + 6.4, 2.2, 0.8]]:
			for n2 in 3000:
				var a: = rng.randf() * TAU
				var rr: = sqrt(rng.randf())
				var zx2: float = zone[1] + sin(a) * rr * zone[3]
				var xx2: float = zone[0] + cos(a) * rr * zone[2]
				var x2: = int(px_of.call(xx2))
				var y2: = int(py_of.call(zx2))
				if x2 >= 0 and x2 < w and y2 >= 0 and y2 < h:
					img.set_pixel(x2, y2, img.get_pixel(x2, y2).lerp(dry, rng.randf_range(0.03, 0.07)))

	var line_c: Color = T.line
	var line: = func(x1: float, z1: float, x2: float, z2: float, w_m: float) -> void :
		var cx1: = int(px_of.call(x1))
		var cx2: = int(px_of.call(x2))
		var cy1: = int(py_of.call(z1))
		var cy2: = int(py_of.call(z2))
		var dx: int = cx2 - cx1
		var dy: int = cy2 - cy1
		var steps: int = max(abs(dx), abs(dy), 1)
		var hw: int = max(1, int(w_m * pxm_x / 2.0))
		for i in steps + 1:
			var t: = float(i) / steps
			var px: = int(cx1 + dx * t)
			var py: = int(cy1 + dy * t)
			img.fill_rect(Rect2i(px - hw, py - hw, hw * 2, hw * 2), line_c)
	line.call(-5.485, 0, 5.485, 0, LINE_W_BASE)
	line.call(-5.485, L, 5.485, L, LINE_W_BASE)
	line.call(-4.115, 0, -4.115, L, LINE_W_SIDE)
	line.call(4.115, 0, 4.115, L, LINE_W_SIDE)
	line.call(-5.485, 0, -5.485, L, LINE_W_SIDE)
	line.call(5.485, 0, 5.485, L, LINE_W_SIDE)
	line.call(-4.115, NZ - 6.4, 4.115, NZ - 6.4, LINE_W_SIDE)
	line.call(-4.115, NZ + 6.4, 4.115, NZ + 6.4, LINE_W_SIDE)
	line.call(0, NZ - 6.4, 0, NZ + 6.4, LINE_W_SIDE)
	line.call(0, 0, 0, 0.1, LINE_W_SIDE)
	line.call(0, L, 0, L - 0.1, LINE_W_SIDE)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _hash2(x: int, y: int) -> float:
	var n: int = x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0x7fffffff) / float(0x7fffffff)

static func _vnoise(x: float, y: float) -> float:
	var xi: int = int(floor(x))
	var yi: int = int(floor(y))
	var xf: float = x - xi
	var yf: float = y - yi
	var u: float = xf * xf * (3.0 - 2.0 * xf)
	var v: float = yf * yf * (3.0 - 2.0 * yf)
	var a: float = _hash2(xi, yi)
	var b: float = _hash2(xi + 1, yi)
	var c: float = _hash2(xi, yi + 1)
	var d: float = _hash2(xi + 1, yi + 1)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)

static func ground_texture(surface: String, night: bool = false) -> ImageTexture:
	var T: Dictionary = NIGHT_THEMES[surface] if night and NIGHT_THEMES.has(surface) else THEMES[surface]
	var w: = 512
	var h: = 512
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t: = float(y) / h
		img.fill_rect(Rect2i(0, y, w, 1), T.out2.lerp(T.out, t))
	var rng: = RandomNumberGenerator.new()
	rng.seed = 3
	for n in 1400:
		var x: = rng.randi() % w
		var y: = rng.randi() % h
		var c: = Color(1, 1, 1, rng.randf_range(0.02, 0.05)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.02, 0.06))
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func net_texture() -> ImageTexture:


	var w: = 1024
	var h: = 96
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cord: = Color(0.05, 0.06, 0.08, 0.62)
	for x in range(0, w, 4):
		img.fill_rect(Rect2i(x, 10, 1, h - 10), cord)
	for y in range(10, h, 4):
		img.fill_rect(Rect2i(0, y, w, 1), cord)

	img.fill_rect(Rect2i(0, 0, w, 9), Color("#f2f2f2"))
	img.fill_rect(Rect2i(0, 9, w, 2), Color(0.75, 0.75, 0.78, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func string_texture() -> ImageTexture:


	var w: = 256
	var h: = 320
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var main_c: = Color(0.96, 0.95, 0.9, 0.75)
	var cross_c: = Color(0.88, 0.87, 0.82, 0.6)

	var cx: = w / 2.0
	var cy: = h / 2.0
	var rx: = w * 0.465
	var ry: = h * 0.475
	for x in range(6, w - 4, 13):
		var dxn: = (x + 1.0 - cx) / rx
		var hy: = ry * sqrt(maxf(0.0, 1.0 - dxn * dxn))
		img.fill_rect(Rect2i(x, int(cy - hy), 2, int(hy * 2.0)), main_c)
	for y in range(6, h - 4, 15):
		var dyn: = (y + 1.0 - cy) / ry
		var hx: = rx * sqrt(maxf(0.0, 1.0 - dyn * dyn))
		img.fill_rect(Rect2i(int(cx - hx), y, int(hx * 2.0), 3), cross_c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func crowd_texture() -> ImageTexture:
	var w: = 512
	var h: = 256
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("#18203a"))
	var pal: = [Color("#c94b4b"), Color("#e8d7a8"), Color("#4b78c9"), Color("#e0a13a"), Color("#7b5fc2"), Color("#d9d9e6"), Color("#3f9e7a"), Color("#2a2f55")]
	var rng: = RandomNumberGenerator.new()
	rng.seed = 11
	for row in range(20, h, 12):
		var depth: = 1.0 - float(row) / h
		for x in range(0, w, 5):
			if rng.randf() < 0.82:
				var c: Color = pal[rng.randi() % pal.size()]
				c.a = 0.25 + rng.randf() * 0.6 * depth
				img.fill_rect(Rect2i(x + rng.randi() % 2, row + rng.randi() % 4, 3, 4), img.get_pixel(x, row).blend(c))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func tier_texture() -> ImageTexture:
	var w: = 1536
	var h: = 384
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("#151c2c"))
	var rng: = RandomNumberGenerator.new()
	rng.seed = 23
	var shirts: = [Color("#d94b3f"), Color("#e8b53a"), Color("#3f7fd9"), Color("#45a36b"), Color("#e8e4da"), Color("#d97f3a"), Color("#b45ad9"), Color("#3fb8b8"), Color("#e06a8a"), Color("#4a5f9e"), Color("#c9c04a"), Color("#35b8e0"), Color("#f07a3c"), Color("#7fd14a"), Color("#8a4f2e"), Color("#5d6472")]
	var skins: = [Color("#f2c79b"), Color("#d9a06b"), Color("#a06b3f"), Color("#7a4a28"), Color("#f5d7b5"), Color("#8a5a35")]
	var hairs: = [Color("#241a12"), Color("#3a2a18"), Color("#141414"), Color("#7a4a1e"), Color("#8a8078"), Color("#c9a25e")]
	var pants: = [Color("#1c2230"), Color("#222a3a"), Color("#2b3345"), Color("#3a4250"), Color("#141a24"), Color("#d9d4c8")]
	var muted: = [Color("#2a3242"), Color("#3a4250"), Color("#4a5262"), Color("#5d6472"), Color("#8a8078"), Color("#6b5a4a"), Color("#1c2230"), Color("#735f4f")]
	var rows: = 12
	var row_h: = h / rows
	var cols: = 64
	var col_w: = w / cols
	for r in rows:
		var base_y: = h - (r + 1) * row_h
		var depth: = float(r) / float(rows - 1)
		var dim: = lerpf(1.0, 0.78, depth)
		img.fill_rect(Rect2i(0, base_y + row_h - 6, w, 6), Color("#1d2536"))
		img.fill_rect(Rect2i(0, base_y + row_h - 8, w, 2), Color("#323c52"))
		for c in cols:
			if c % 11 == 5:
				continue
			if rng.randf() < 0.03:
				continue
			var x: = int(c * col_w + col_w * 0.5 + rng.randf_range(-4.0, 4.0))
			var y: = base_y + 7 + int(rng.randf_range(0.0, 3.0))
			var col: Color = shirts[rng.randi() % shirts.size()]
			if rng.randf() < 0.4:
				col = muted[rng.randi() % muted.size()]
			col = col.lerp(Color(0.2, 0.19, 0.2), rng.randf_range(0.06, 0.24)) * dim
			var skin: Color = skins[rng.randi() % skins.size()] * dim
			var hair: Color = hairs[rng.randi() % hairs.size()] * dim
			var pc: Color = pants[rng.randi() % pants.size()] * dim
			var bw: = 11
			var bh: = 17
			img.fill_rect(Rect2i(x - bw, y - 2, bw * 2, 3), pc)
			for by in range(0, bh):
				var k: float = float(by) / float(bh)
				var hw: int = int(bw * (1.0 - 0.2 * absf(k * 2.0 - 1.0)))
				img.fill_rect(Rect2i(x - hw, y + by, hw * 2, 1), col)
			img.fill_rect(Rect2i(x - bw, y + 2, 2, 10), col.lightened(0.18))
			img.fill_rect(Rect2i(x + bw - 2, y + 2, 2, 10), col.darkened(0.28))
			img.fill_rect(Rect2i(x - 2, y - 4, 4, 5), skin)
			for hy in range( -8, 5):
				var hw: int = int(sqrt(maxf(0.0, 64.0 - hy * hy)))
				if hy < -2:
					img.fill_rect(Rect2i(x - hw, y - 10 + hy, hw * 2, 1), hair)
				else:
					img.fill_rect(Rect2i(x - hw, y - 10 + hy, hw * 2, 1), skin)
			if rng.randf() < 0.22:
				img.fill_rect(Rect2i(x - 8, y - 14, 16, 3), Color("#e8e4da") * dim)
	for ax in [10, 30, 51]:
		img.fill_rect(Rect2i(int(ax * col_w) - 4, 0, 8, h), Color("#0a0f19"))
		img.fill_rect(Rect2i(int(ax * col_w) + 4, 0, 2, h), Color("#252d40"))
	img.fill_rect(Rect2i(0, int(h * 0.44), w, 11), Color("#111826"))
	img.fill_rect(Rect2i(0, int(h * 0.44), w, 2), Color("#5b6a86"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func night_sky_panorama() -> ImageTexture:
	var w: = 512
	var h: = 256
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top: = Color("#010b1c")
	var mid: = Color("#021024")
	var hor: = Color("#071a38")
	var rng: = RandomNumberGenerator.new()
	rng.seed = 91
	for y in h:
		var t: = float(y) / h
		var c: Color
		if t < 0.52:
			c = top.lerp(mid, pow(t / 0.52, 1.4))
			c = c.lerp(hor, pow(maxf(0.0, (t - 0.34) / 0.18), 1.6))
		else:
			c = hor.lerp(Color("#030814"), minf(1.0, (t - 0.52) / 0.12))
		img.fill_rect(Rect2i(0, y, w, 1), c)
		for k in 96:
			var x: = rng.randi() % w
			var d: = rng.randf_range(-0.004, 0.004)
			img.set_pixel(x, y, Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func glow_texture() -> ImageTexture:
	var s: = 128
	var img: = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: = s / 2.0
	for y in s:
		for x in s:
			var d: = Vector2(x - c, y - c).length() / c
			if d < 1.0:
				var a: float = pow(1.0 - d, 2.2)
				img.set_pixel(x, y, Color(1, 0.97, 0.86, a * 0.85))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func ball_texture() -> ImageTexture:


	var w: = 64
	var h: = 64
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("#e6ff4d"))
	for x in w:
		var t: = float(x) / w * TAU
		var y1: = h * 0.5 + sin(t) * h * 0.22
		var y2: = h * 0.5 + sin(t + PI) * h * 0.22
		for dy in [-1, 0, 1]:
			img.set_pixel(x, (int(y1) + dy + h) % h, Color("#f7ffe0"))
			img.set_pixel(x, (int(y2) + dy + h) % h, Color("#f7ffe0"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func shadow_texture() -> ImageTexture:
	var s: = 128
	var img: = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: = s / 2.0
	for y in s:
		for x in s:
			var d: = Vector2(x - c, y - c).length() / c
			if d < 1.0:
				var a: float = clamp(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.85))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func ring_texture() -> ImageTexture:
	var s: = 128
	var img: = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: = s / 2.0
	for y in s:
		for x in s:
			var d: = Vector2(x - c, y - c).length() / c

			var ring: float = clampf(1.0 - absf(d - 0.7) / 0.16, 0.0, 1.0)
			var halo: float = clampf(1.0 - absf(d - 0.9) / 0.1, 0.0, 1.0)
			var fill: float = clampf(1.0 - d / 0.52, 0.0, 1.0) * 0.18
			var dot: float = clampf(1.0 - d / 0.12, 0.0, 1.0)
			var a: float = maxf(ring, maxf(halo * 0.75, maxf(fill, dot)))
			if a <= 0.0:
				continue
			var shade: float = 0.85 if halo > ring else 1.0
			img.set_pixel(x, y, Color(shade, shade, shade, clampf(a, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func sky_panorama() -> ImageTexture:

	var w: = 2048
	var h: = 1024
	var img: = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top: = Color("#2f6fc4")
	var hor: = Color("#9ec0e8")
	var gnd: = Color("#7aa06a")
	for y in h:
		var t: = float(y) / h
		var c: Color
		if t < 0.5:
			c = top.lerp(hor, pow(t * 2.0, 1.6))
		else:
			c = hor.lerp(gnd, (t - 0.5) * 2.0)
		img.fill_rect(Rect2i(0, y, w, 1), c)
	var rng: = RandomNumberGenerator.new()
	rng.seed = 7
	for b in 34:
		var rx: = 110.0 + rng.randf() * 220.0
		var ry: = rx * (0.1 + rng.randf() * 0.1)
		var cx: = int(rx + rng.randf() * (w - 2.0 * rx))
		var cy: = int(h * (0.36 + rng.randf() * 0.13))
		var base_a: = 0.3 + rng.randf() * 0.3
		for py in range(maxi(cy - int(ry), 0), mini(cy + int(ry), h / 2)):
			for px in range(cx - int(rx), cx + int(rx)):
				var dx: = float(px - cx) / rx
				var dy: = float(py - cy) / ry
				var d: = dx * dx + dy * dy
				if d < 1.0:
					var a: = (1.0 - d) * (1.0 - d) * base_a
					var old: = img.get_pixel(px, py)
					img.set_pixel(px, py, old.lerp(Color(1, 1, 1, 1), a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
