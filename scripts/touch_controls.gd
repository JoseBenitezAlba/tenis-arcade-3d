class_name TouchControls
extends CanvasLayer

const DEAD := 0.18
var joy_touch := -1
var joy_center := Vector2.ZERO
var joy_ofs := Vector2.ZERO
var joy_layer: Control
var _vp := Vector2.ZERO
var _buttons: Array[TouchScreenButton] = []
var _charge := 0.0
var _golpe_center := Vector2.ZERO
var _golpe_r := 0.0

func set_charge(v: float) -> void:
	if absf(v - _charge) > 0.01 or (v <= 0.0) != (_charge <= 0.0):
		_charge = v
		joy_layer.queue_redraw()

static func should_show() -> bool:
	if not OS.has_feature("web"):
		return false
	var mobile = JavaScriptBridge.eval("navigator.maxTouchPoints > 0 && (window.matchMedia('(pointer: coarse)').matches || /Android|iPhone|iPad|Mobile|Tablet/i.test(navigator.userAgent))", true)
	# Web export may return JavaScript booleans as integer 0/1.
	return bool(mobile)

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	joy_layer = Control.new()
	joy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_layer.draw.connect(_draw_joy)
	add_child(joy_layer)
	_make_button("GOLPE", "hit", Color(0.95, 0.62, 0.12, 0.65))
	_make_button("GLOBO", "lob", Color(0.35, 0.55, 0.95, 0.65))
	_make_button("DEJADA", "drop", Color(0.45, 0.75, 0.45, 0.65))
	_make_button("II", "pause", Color(0.35, 0.4, 0.5, 0.7))
	_make_button("CÁM", "camera", Color(0.35, 0.4, 0.5, 0.7))
	get_viewport().size_changed.connect(_layout)
	_layout()

func _make_button(txt: String, action_name: String, col: Color) -> void:
	var b := TouchScreenButton.new()
	b.action = action_name
	b.set_meta("color", col)
	add_child(b)
	_buttons.append(b)
	var label := Label.new()
	label.text = txt
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(label)

func _button_texture(col: Color) -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length()
			image.set_pixel(x, y, Color(1, 1, 1, 0.85) if d > 60.0 and d < 63.0 else (col if d <= 60.0 else Color.TRANSPARENT))
	return ImageTexture.create_from_image(image)

func _layout() -> void:
	_release_all()
	_vp = get_viewport().get_visible_rect().size
	var m := minf(_vp.x, _vp.y)
	var centers := [Vector2(_vp.x - m * 0.15, _vp.y - m * 0.19), Vector2(_vp.x - m * 0.39, _vp.y - m * 0.13), Vector2(_vp.x - m * 0.18, _vp.y - m * 0.45), Vector2(_vp.x - m * 0.075, m * 0.08), Vector2(_vp.x - m * 0.23, m * 0.08)]
	var radii := [m * 0.105, m * 0.085, m * 0.08, m * 0.05, m * 0.05]
	for i in _buttons.size():
		var b := _buttons[i]
		var r: float = radii[i]
		b.position = centers[i]
		b.texture_normal = _button_texture(b.get_meta("color"))
		b.texture_pressed = _button_texture(Color(0.95, 0.85, 0.4, 0.9))
		b.scale = Vector2.ONE * (r * 2.0 / 128.0)
		# Texture and touch shape share a center; no mouse emulation required.
		b.position -= Vector2(r, r)
		var circle := CircleShape2D.new()
		circle.radius = 64.0
		b.shape = circle
		var label: Label = b.get_child(0)
		label.position = Vector2.ZERO
		label.size = Vector2(128, 128)
		label.add_theme_font_size_override("font_size", 24 if i < 3 else 25)
	_golpe_center = centers[0]
	_golpe_r = radii[0]
	joy_center = Vector2(m * 0.20, _vp.y - m * 0.23)
	joy_layer.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()

func _exit_tree() -> void:
	_release_all()

func _release_all() -> void:
	joy_touch = -1
	joy_ofs = Vector2.ZERO
	for action_name in ["move_left", "move_right", "move_up", "move_down", "hit", "lob", "drop", "pause", "camera"]:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
	if is_instance_valid(joy_layer):
		joy_layer.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and joy_touch == -1 and event.position.x < _vp.x * 0.45:
			joy_touch = event.index
			joy_center = event.position
			joy_ofs = Vector2.ZERO
		elif not event.pressed and event.index == joy_touch:
			joy_touch = -1
			joy_ofs = Vector2.ZERO
			_set_axes(Vector2.ZERO)
		joy_layer.queue_redraw()
	elif event is InputEventScreenDrag and event.index == joy_touch:
		joy_ofs = (event.position - joy_center).limit_length(_joy_r())
		_set_axes(joy_ofs / _joy_r())
		joy_layer.queue_redraw()

func _joy_r() -> float:
	return minf(_vp.x, _vp.y) * 0.13

func _set_axes(v: Vector2) -> void:
	if v.length() < DEAD:
		v = Vector2.ZERO
	else:
		v = v.normalized() * ((v.length() - DEAD) / (1.0 - DEAD))
	# La camara del partido mira desde -z: la derecha de la pantalla es -x mundo.
	# El eje X del joystick sigue el mismo criterio que el mando (pad_inv_x):
	# arrastrar a la derecha mueve al jugador a la derecha de la pantalla.
	_axis("move_right", "move_left", v.x)
	_axis("move_up", "move_down", v.y)

func _axis(neg: String, pos: String, s: float) -> void:
	Input.action_release(neg)
	Input.action_release(pos)
	if s > 0.0:
		Input.action_press(pos, s)
	elif s < 0.0:
		Input.action_press(neg, -s)

func _draw_joy() -> void:
	if _charge > 0.0 and _golpe_r > 0.0:
		joy_layer.draw_arc(_golpe_center, _golpe_r + 7.0, -PI / 2.0, -PI / 2.0 + TAU * _charge, 48, Color(1.0, 0.9, 0.3, 0.95), 7.0, true)
	var r := _joy_r()
	joy_layer.draw_circle(joy_center, r, Color(0.05, 0.08, 0.14, 0.22))
	joy_layer.draw_arc(joy_center, r, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
	joy_layer.draw_circle(joy_center + joy_ofs, r * 0.40, Color(1, 1, 1, 0.55 if joy_touch >= 0 else 0.22))
