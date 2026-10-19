extends SceneTree




const SS: = preload("res://scripts/static_shadows.gd")
const NZ: = 23.77 / 2.0
var ok: = true
func _init() -> void :

	var sp: Array = SS.spec(NZ)
	if sp.size() != 6:
		print("FAIL A: spec size ", sp.size());ok = false
	var net = sp[0]
	if net[1].x < 12.8 or absf(net[0].z - (NZ + 0.3)) > 0.01:
		print("FAIL A: banda de red mal: ", net);ok = false
	for it in sp:
		if it[2] < 0.1 or it[2] > 0.35:
			print("FAIL A: alpha fuera de banda: ", it);ok = false

	var n: = Node3D.new()
	root.add_child(n)
	var img: = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var tex: = ImageTexture.create_from_image(img)
	var c: int = SS.add_to(n, tex, NZ)
	print("B quads creados: ", c, " hijos: ", n.get_child_count())
	if c != sp.size() or n.get_child_count() != sp.size():
		print("FAIL B: no se crean todos");ok = false
	var q0: MeshInstance3D = n.get_child(0)
	var mat: StandardMaterial3D = q0.mesh.material
	if absf(mat.albedo_color.a - sp[0][2]) > 0.001:
		print("FAIL B: alpha no aplicada: ", mat.albedo_color.a);ok = false
	if absf(q0.position.z - (NZ + 0.3)) > 0.001:
		print("FAIL B: posicion no aplicada");ok = false
	print("A spec ok, B creacion ok")
	print("GATE088 " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _process(_dt: float) -> bool:
	return true
