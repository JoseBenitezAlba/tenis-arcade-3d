class_name TexGen
extends RefCounted

const THEMES := {
    "clay": {"court": Color("#c4602f"), "court2": Color("#b95a2b"), "out": Color("#2c5e46"), "out2": Color("#1f4a37"), "line": Color("#f6f1e6")},
    "hard": {"court": Color("#2f6fb5"), "court2": Color("#2a65a8"), "out": Color("#1a6b4d"), "out2": Color("#145539"), "line": Color("#f4f6fa")},
    "grass": {"court": Color("#3f7a36"), "court2": Color("#397131"), "out": Color("#2f6330"), "out2": Color("#265122"), "line": Color("#f6f8f2")},
}
const L := 23.77
const NZ := L / 2.0

# Textura de la pista: x en [-7.2, 7.2], z en [-4, L+3.6]
static func court_texture(surface: String) -> ImageTexture:
    var T: Dictionary = THEMES[surface]
    var w := 1024
    var h := 2048
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(T.court)
    var pxm_x := w / 14.4
    var pxm_z := h / 31.37
    var z_of := func(py: float) -> float: return -4.0 + py / pxm_z
    var py_of := func(z: float) -> float: return (z + 4.0) * pxm_z
    # franjas alternas cada 1.4m
    var k := 0
    var z := -4.0
    while z < L + 3.6:
        if k % 2 == 1:
            var y0 := int(py_of.call(z))
            var y1 := int(py_of.call(min(z + 1.4, L + 3.6)))
            img.fill_rect(Rect2i(0, y0, w, max(1, y1 - y0)), T.court2)
        z += 1.4
        k += 1
    # grano
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for n in 9000:
        var x := rng.randi() % w
        var y := rng.randi() % h
        var c := Color(1, 1, 1, rng.randf_range(0.02, 0.07)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.02, 0.07))
        img.set_pixel(x, y, img.get_pixel(x, y).blend(c))
    # lineas blancas
    var line_c: Color = T.line
    var lw: float = 0.07 * pxm_x
    var line := func(x1: float, z1: float, x2: float, z2: float) -> void:
        var cx1 := int((x1 + 7.2) * pxm_x)
        var cx2 := int((x2 + 7.2) * pxm_x)
        var cy1 := int(py_of.call(z1))
        var cy2 := int(py_of.call(z2))
        var dx: int = cx2 - cx1
        var dy: int = cy2 - cy1
        var steps: int = max(abs(dx), abs(dy), 1)
        var hw: int = max(1, int(lw / 2.0))
        for i in steps + 1:
            var t := float(i) / steps
            var px := int(cx1 + dx * t)
            var py := int(cy1 + dy * t)
            img.fill_rect(Rect2i(px - hw, py - hw, hw * 2, hw * 2), line_c)
    line.call(-5.49, 0, 5.49, 0)
    line.call(-5.49, L, 5.49, L)
    line.call(-4.11, 0, -4.11, L)
    line.call(4.11, 0, 4.11, L)
    line.call(-5.49, 0, -5.49, L)
    line.call(5.49, 0, 5.49, L)
    line.call(-4.11, NZ - 6.4, 4.11, NZ - 6.4)
    line.call(-4.11, NZ + 6.4, 4.11, NZ + 6.4)
    line.call(0, NZ - 6.4, 0, NZ + 6.4)
    line.call(0, 0, 0, 0.3)
    line.call(0, L, 0, L - 0.3)
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
    var w := 512
    var h := 64
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var mesh_c := Color(0.05, 0.06, 0.1, 0.85)
    for x in range(0, w, 8):
        img.fill_rect(Rect2i(x, 0, 2, h), mesh_c)
    for y in range(0, h, 8):
        img.fill_rect(Rect2i(0, y, w, 2), mesh_c)
    img.fill_rect(Rect2i(0, 0, w, 8), Color("#f6f6f6"))
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
