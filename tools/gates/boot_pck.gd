extends SceneTree



var frames: = 0
var tod: = 0
var main
var pck: = "/tmp/exp.pck"
var prefix: = "/tmp/bootp"
func _init() -> void :
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0: pck = a[0]
	if a.size() > 1: prefix = a[1]
	if a.size() > 2: tod = int(a[2])
	print("PACK: ", ProjectSettings.load_resource_pack(pck))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
func _process(_dt: float) -> bool:
	frames += 1
	if frames == 30:
		root.get_texture().get_image().save_png(prefix + "_menu.png")
		print("SHOT menu")
	if frames == 28:
		main.menus.show_exhibition()
	if frames == 30:
		root.get_texture().get_image().save_png(prefix + "_exhi.png")
		print("SHOT exhi")
	if frames == 31:
		main._on_quick_match("clay", 1, 1, tod)
	if frames == 130:
		root.get_texture().get_image().save_png(prefix + "_match.png")
		print("SHOT match")
	if frames >= 131:
		print("BOOT OK")
		return true
	return false
