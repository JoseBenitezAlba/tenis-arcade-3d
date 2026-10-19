extends SceneTree




const MV: = preload("res://scripts/match_view.gd")
var ok: = true
func _init() -> void :

	var tex: ImageTexture = TexGen.ball_texture()
	var img: = tex.get_image()
	var felt: = false
	var seam: = false
	for x in img.get_width():
		for y in img.get_height():
			var c: = img.get_pixel(x, y)
			if c.b < 0.45 and c.r > 0.7:
				felt = true
			if c.r > 0.9 and c.g > 0.9 and c.b > 0.8:
				seam = true
	print("A fieltro=", felt, " costura=", seam)
	if not felt or not seam:
		print("FAIL A: la textura no tiene fieltro y costura");ok = false

	var rtop: float = MV.spin_rate(0.85, 20.0)
	var rslice: float = MV.spin_rate(-0.75, 14.0)
	var rflat: float = MV.spin_rate(0.0, 20.0)
	print("B rate top=", snappedf(rtop, 0.01), " slice=", snappedf(rslice, 0.01), " plano=", rflat)
	if rtop <= 0.0 or rslice >= 0.0 or rflat != 0.0:
		print("FAIL B: signos");ok = false
	if rtop < 2.0 or rtop > 8.0:
		print("FAIL B: rate de rally fuera de banda legible: ", rtop);ok = false
	var ax: Vector3 = MV.spin_axis(0.0, 20.0)
	if absf(ax.y) > 0.001 or absf(ax.dot(Vector3(0, 0, 1))) > 0.001:
		print("FAIL B: eje no horizontal/perpendicular: ", ax);ok = false
	var ax2: Vector3 = MV.spin_axis(10.0, 10.0)
	if absf(ax2.dot(Vector3(10, 0, 10).normalized())) > 0.001:
		print("FAIL B: eje no perpendicular en diagonal");ok = false
	print("GATE089 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
