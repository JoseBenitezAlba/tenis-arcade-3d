extends SceneTree
# Regresión: el joystick táctil debe ser relativo a la pantalla.
# La cámara del partido mira desde -z, así que la derecha de pantalla es -x
# mundo. Arrastrar a la derecha debe pulsar move_left (como el mando con
# pad_inv_x) y mover al jugador a la derecha de la pantalla.
# Nota: en headless parse_input_event no llega a _input, así que se llama
# a tc._input directamente con los mismos eventos sintéticos.

var ok := true

func touch(id: int, p: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = id
	e.position = p
	e.pressed = pressed
	return e

func drag(id: int, p: Vector2, rel: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = id
	e.position = p
	e.relative = rel
	e.velocity = rel * 60.0
	return e

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host = load("res://scripts/main.gd").new()
	host._register_inputs()
	var mv = MatchView.new()
	mv.set_meta("force_touch", true)
	mv.setup({"demo": false, "AIP": host.DIFF_PARAMS[1], "sets_to_win": 1})
	root.add_child(mv)
	await process_frame
	var tc: TouchControls
	for child in mv.get_children():
		if child is TouchControls:
			tc = child
	if tc == null:
		print("FAIL: no TouchControls"); ok = false; _fin(mv, host); return

	# Invariante de cámara: mundo +x aparece a la IZQUIERDA de pantalla.
	var cam3d: Camera3D = mv.get_viewport().get_camera_3d()
	var c0 := cam3d.unproject_position(Vector3(0, 1.0, -8.0))
	var cpx := cam3d.unproject_position(Vector3(1.0, 1.0, -8.0))
	print("pantalla: mundo +x desplaza ", snappedf(cpx.x - c0.x, 0.1), " px")
	if cpx.x - c0.x >= 0.0:
		print("FAIL: la cámara cambió, revisar mapeo del joystick"); ok = false

	var start := Vector2(200, 500)
	tc._input(touch(7, start, true))
	if tc.joy_touch != 7:
		print("FAIL: el toque no abrió joystick"); ok = false

	tc._input(drag(7, start + Vector2(80, 0), Vector2(80, 0)))
	mv._physics_process(1.0 / 60)
	print("arrastre DERECHA -> inp.x=", mv.sim.inp.x)
	if not Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or mv.sim.inp.x >= -0.5:
		print("FAIL: arrastrar a la derecha debe mover a la derecha de pantalla (move_left, inp.x<0)"); ok = false

	tc._input(drag(7, start + Vector2(-80, 0), Vector2(-160, 0)))
	mv._physics_process(1.0 / 60)
	print("arrastre IZQUIERDA -> inp.x=", mv.sim.inp.x)
	if not Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or mv.sim.inp.x <= 0.5:
		print("FAIL: arrastrar a la izquierda debe mover a la izquierda de pantalla (move_right, inp.x>0)"); ok = false

	tc._input(drag(7, start + Vector2(0, 80), Vector2(80, 160)))
	mv._physics_process(1.0 / 60)
	print("arrastre ABAJO -> inp.y=", mv.sim.inp.y)
	if not Input.is_action_pressed("move_down") or mv.sim.inp.y >= -0.5:
		print("FAIL: arrastrar abajo debe acercar a la cámara (move_down, inp.y<0)"); ok = false

	tc._input(touch(7, start + Vector2(0, 80), false))
	mv._physics_process(1.0 / 60)
	if mv.sim.inp.x != 0.0 or mv.sim.inp.y != 0.0:
		print("FAIL: soltar debe soltar los ejes"); ok = false

	print("TOUCH STICK SCREEN " + ("PASS" if ok else "FAIL"))
	_fin(mv, host)

func _fin(mv: Node, host: Node) -> void:
	mv.queue_free(); host.free()
	await process_frame
	quit(0 if ok else 1)
