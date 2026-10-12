class_name TexGen
extends RefCounted

const THEMES := {
    "clay": {"court": Color("#b85a28"), "court2": Color("#ad5322"), "surround": Color("#9c4e20"), "out": Color("#2c5e46"), "out2": Color("#1f4a37"), "line": Color("#f6f1e6")},
    "hard": {"court": Color("#1d4f9c"), "court2": Color("#1b4993"), "surround": Color("#33649f"), "out": Color("#1a6b4d"), "out2": Color("#145539"), "line": Color("#f4f6fa")},
    "grass": {"court": Color("#3f7a36"), "court2": Color("#397131"), "surround": Color("#2f6330"), "out": Color("#2f6330"), "out2": Color("#265122"), "line": Color("#f6f8f2")},
}
const L := 23.77
const NZ := L / 2.0

# Textura de la pista: x en [-7.2, 7.2], z en [-4, L+3.6]
static func court_texture(surface: String) -> ImageTexture:
    var T: Dictionary = THEMES[surface]
    var w := 1024
    var h := 2048
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(T.surround)
    var pxm_x := w / 14.4
    var pxm_z := h / 31.37
    var z_of := func(py: float) -> float: return -4.0 + py / pxm_z
    var py_of := func(z: float) -> float: return (z + 4.0) * pxm_z
    var px_of := func(x: float) -> float: return (x + 7.2) * pxm_x
    # rectangulo de juego: hasta el borde exterior de lineas de dobles y fondos
    var ix0 := int(px_of.call(-5.51))
    var ix1 := int(px_of.call(5.51))
    var iy0 := int(py_of.call(-0.05))
    var iy1 := int(py_of.call(L + 0.05))
    img.fill_rect(Rect2i(ix0, iy0, ix1 - ix0, iy1 - iy0), T.court)
    # franjas de siega cada 1.4m solo en hierba (realismo), dentro del rectangulo
    if surface == "grass":
        var k := 0
        var z := -4.0
        while z < L + 3.6:
            if k % 2 == 1:
                var y0 := int(py_of.call(max(z, -0.05)))
                var y1 := int(py_of.call(min(z + 1.4, L + 0.05)))
                if y1 > y0:
                    img.fill_rect(Rect2i(ix0, y0, ix1 - ix0, y1 - y0), T.court2)
            z += 1.4
            k += 1
    # grano: mas denso y fino
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for n in 26000:
        var x := rng.randi() % w
        var y := rng.randi() % h
        var c := Color(1, 1, 1, rng.randf_range(0.02, 0.06)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.02, 0.06))
        img.set_pixel(x, y, img.get_pixel(x, y).blend(c))
    # leve desgaste en zonas de juego (fondos y red)
    for n in 2400:
        var zx: float = [0.6, L - 0.6, NZ - 1.2, NZ + 1.2][rng.randi() % 4]
        var x := int(px_of.call(rng.randf_range(-3.4, 3.4)))
        var y := int(py_of.call(zx + rng.randf_range(-0.5, 0.5)))
        if x >= 0 and x < w and y >= 0 and y < h:
            img.set_pixel(x, y, img.get_pixel(x, y).blend(Color(1, 1, 1, rng.randf_range(0.04, 0.1))))
    # lineas: 5cm reglamentarias, 10cm las de fondo
    var line_c: Color = T.line
    var line := func(x1: float, z1: float, x2: float, z2: float, w_m: float) -> void:
        var cx1 := int(px_of.call(x1))
        var cx2 := int(px_of.call(x2))
        var cy1 := int(py_of.call(z1))
        var cy2 := int(py_of.call(z2))
        var dx: int = cx2 - cx1
        var dy: int = cy2 - cy1
        var steps: int = max(abs(dx), abs(dy), 1)
        var hw: int = max(1, int(w_m * pxm_x / 2.0))
        for i in steps + 1:
            var t := float(i) / steps
            var px := int(cx1 + dx * t)
            var py := int(cy1 + dy * t)
            img.fill_rect(Rect2i(px - hw, py - hw, hw * 2, hw * 2), line_c)
    line.call(-5.485, 0, 5.485, 0, 0.10)
    line.call(-5.485, L, 5.485, L, 0.10)
    line.call(-4.115, 0, -4.115, L, 0.05)
    line.call(4.115, 0, 4.115, L, 0.05)
    line.call(-5.485, 0, -5.485, L, 0.05)
    line.call(5.485, 0, 5.485, L, 0.05)
    line.call(-4.115, NZ - 6.4, 4.115, NZ - 6.4, 0.05)
    line.call(-4.115, NZ + 6.4, 4.115, NZ + 6.4, 0.05)
    line.call(0, NZ - 6.4, 0, NZ + 6.4, 0.05)
    line.call(0, 0, 0, 0.1, 0.05)
    line.call(0, L, 0, L - 0.1, 0.05)
    return ImageTexture.create_from_image(img)

static func ground_texture(surface: String) -> ImageTexture:
    var T: Dictionary = THEMES[surface]
    var w := 512
    var h := 512
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    for y in h:
        var t := float(y) / h
        img.fill_rect(Rect2i(0, y, w, 1), T.out2.lerp(T.out, t))
    var rng := RandomNumberGenerator.new()
    rng.seed = 3
    for n in 2500:
        var x := rng.randi() % w
        var y := rng.randi() % h
        var c := Color(1, 1, 1, rng.randf_range(0.02, 0.05)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.02, 0.06))
        img.set_pixel(x, y, img.get_pixel(x, y).blend(c))
    return ImageTexture.create_from_image(img)

static func net_texture() -> ImageTexture:
    # malla real: agujeros transparentes, cordeles oscuros, cinta blanca arriba
    # 12.8m x 1.07m -> celda ~4cm = 3.2px a 1024px; usamos 4px de celda
    var w := 1024
    var h := 96
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var cord := Color(0.05, 0.06, 0.08, 0.95)
    for x in range(0, w, 4):
        img.fill_rect(Rect2i(x, 10, 1, h - 10), cord)
    for y in range(10, h, 4):
        img.fill_rect(Rect2i(0, y, w, 1), cord)
    # cinta blanca superior (~7cm) con su linea de cordon
    img.fill_rect(Rect2i(0, 0, w, 9), Color("#f2f2f2"))
    img.fill_rect(Rect2i(0, 9, w, 2), Color(0.75, 0.75, 0.78, 1.0))
    return ImageTexture.create_from_image(img)

static func crowd_texture() -> ImageTexture:
    var w := 512
    var h := 256
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color("#18203a"))
    var pal := [Color("#c94b4b"), Color("#e8d7a8"), Color("#4b78c9"), Color("#e0a13a"), Color("#7b5fc2"), Color("#d9d9e6"), Color("#3f9e7a"), Color("#2a2f55")]
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    for row in range(20, h, 12):
        var depth := 1.0 - float(row) / h
        for x in range(0, w, 5):
            if rng.randf() < 0.82:
                var c: Color = pal[rng.randi() % pal.size()]
                c.a = 0.25 + rng.randf() * 0.6 * depth
                img.fill_rect(Rect2i(x + rng.randi() % 2, row + rng.randi() % 4, 3, 4), img.get_pixel(x, row).blend(c))
    return ImageTexture.create_from_image(img)

static func tier_texture() -> ImageTexture:
    # grada de estadio: bandas horizontales de hormigon + asientos apagados;
    # el color lo ponen las figuras 3D del publico delante
    var w := 512
    var h := 256
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color("#4a5266"))
    var rng := RandomNumberGenerator.new()
    rng.seed = 23
    var seat_pal := [Color("#5a6478"), Color("#566073"), Color("#4e586c"), Color("#6b6a72"), Color("#5e5a68")]
    for row in range(0, h, 16):
        # pasillo de la grada (banda mas clara)
        img.fill_rect(Rect2i(0, row, w, 5), Color("#6a7387"))
        # asientos de la fila
        for x in range(0, w, 7):
            if rng.randf() < 0.75:
                var c: Color = seat_pal[rng.randi() % seat_pal.size()]
                img.fill_rect(Rect2i(x, row + 7, 5, 7), c)
    return ImageTexture.create_from_image(img)

static func shadow_texture() -> ImageTexture:
    var s := 128
    var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c := s / 2.0
    for y in s:
        for x in s:
            var d := Vector2(x - c, y - c).length() / c
            if d < 1.0:
                var a: float = clamp(1.0 - d, 0.0, 1.0)
                img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.5))
    return ImageTexture.create_from_image(img)

static func ring_texture() -> ImageTexture:
    var s := 128
    var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c := s / 2.0
    for y in s:
        for x in s:
            var d := Vector2(x - c, y - c).length() / c
            var a: float = clamp(1.0 - abs(d - 0.8) / 0.16, 0.0, 1.0)
            if a > 0.0:
                img.set_pixel(x, y, Color(1, 1, 1, a * 0.9))
    return ImageTexture.create_from_image(img)

static func sky_panorama() -> ImageTexture:
    # cielo diurno con nubes suaves pintadas (panorama equirectangular 2:1)
    var w := 2048
    var h := 1024
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    var top := Color("#2f6fc4")
    var hor := Color("#9ec0e8")
    var gnd := Color("#7aa06a")
    for y in h:
        var t := float(y) / h
        var c: Color
        if t < 0.5:
            c = top.lerp(hor, pow(t * 2.0, 1.6))
        else:
            c = hor.lerp(gnd, (t - 0.5) * 2.0)
        img.fill_rect(Rect2i(0, y, w, 1), c)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for b in 34:
        var rx := 110.0 + rng.randf() * 220.0
        var ry := rx * (0.10 + rng.randf() * 0.10)
        var cx := int(rx + rng.randf() * (w - 2.0 * rx))
        var cy := int(h * (0.36 + rng.randf() * 0.13))
        var base_a := 0.3 + rng.randf() * 0.3
        for py in range(maxi(cy - int(ry), 0), mini(cy + int(ry), h / 2)):
            for px in range(cx - int(rx), cx + int(rx)):
                var dx := float(px - cx) / rx
                var dy := float(py - cy) / ry
                var d := dx * dx + dy * dy
                if d < 1.0:
                    var a := (1.0 - d) * (1.0 - d) * base_a
                    var old := img.get_pixel(px, py)
                    img.set_pixel(px, py, old.lerp(Color(1, 1, 1, 1), a))
    return ImageTexture.create_from_image(img)
