class_name TouchControls
extends CanvasLayer

# v0.34: controles tactiles para la version web en movil/tablet.
# REGLA DE ORO (pedido del usuario): solo existen cuando el navegador es
# movil o tablet; en navegador de PC NUNCA se crean (ni ocultos).
# Joystick virtual a la izquierda (alimenta los ejes move_* con fuerza
# analogica) y botones GOLPE/GLOBO/DEJADA/II a la derecha (inyectan
# InputEventAction reales, igual que una tecla).

const DEAD := 0.18

var joy_touch := -1
var joy_center := Vector2.ZERO
var joy_ofs := Vector2.ZERO
var joy_layer: Control
var _vp := Vector2.ZERO

# Deteccion estricta: UA de movil/tablet, o iPadOS (se anuncia como Mac con
# pantalla tactil). Un portatil Windows con tactil NO entra (el usuario fue
# explicito: en PC nunca). Solo tiene sentido en web.
static func should_show() -> bool:
    if not OS.has_feature("web"):
        return false
    var js := "(/Android|webOS|iPhone|iPod|BlackBerry|Opera Mini|IEMobile|Mobile|Tablet/i.test(navigator.userAgent)) || (/Macintosh/.test(navigator.userAgent) && navigator.maxTouchPoints > 1)"
    var r = JavaScriptBridge.eval(js)
    return r == true

func _ready() -> void:
    layer = 25
    # Si el arbol se pausa, seguir procesando: un dedo que se levanta durante
    # la pausa no puede dejar ejes clavados.
    process_mode = Node.PROCESS_MODE_ALWAYS
    _vp = get_viewport().get_visible_rect().size
    joy_layer = Control.new()
    joy_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    joy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joy_layer.draw.connect(_draw_joy)
    add_child(joy_layer)
    var m: float = minf(_vp.x, _vp.y)
    _make_button("GOLPE", "hit", Vector2(_vp.x - m * 0.145, _vp.y - m * 0.19), m * 0.105, Color(0.95, 0.62, 0.12, 0.55))
    _make_button("GLOBO", "lob", Vector2(_vp.x - m * 0.385, _vp.y - m * 0.125), m * 0.082, Color(0.35, 0.55, 0.95, 0.55))
    _make_button("DEJADA", "drop", Vector2(_vp.x - m * 0.16, _vp.y - m * 0.455), m * 0.075, Color(0.45, 0.85, 0.45, 0.55))
    _make_button("SLICE", "slice", Vector2(_vp.x - m * 0.385, _vp.y - m * 0.31), m * 0.07, Color(0.45, 0.74, 0.82, 0.55))
    _make_button("TOP", "topspin", Vector2(_vp.x - m * 0.39, _vp.y - m * 0.49), m * 0.07, Color(0.90, 0.40, 0.30, 0.55))
    _make_button("II", "pause", Vector2(_vp.x - m * 0.055, m * 0.075), m * 0.045, Color(0.7, 0.7, 0.75, 0.5))

func _make_button(txt: String, action: String, center: Vector2, r: float, col: Color) -> void:
    var b := Button.new()
    b.text = txt
    b.focus_mode = Control.FOCUS_NONE
    b.position = center - Vector2(r, r)
    b.size = Vector2(r * 2.0, r * 2.0)
    var st := StyleBoxFlat.new()
    st.bg_color = col
    st.corner_radius_top_left = int(r)
    st.corner_radius_top_right = int(r)
    st.corner_radius_bottom_left = int(r)
    st.corner_radius_bottom_right = int(r)
    st.border_width_bottom = 2
    st.border_width_top = 2
    st.border_width_left = 2
    st.border_width_right = 2
    st.border_color = Color(1, 1, 1, 0.65)
    b.add_theme_stylebox_override("normal", st)
    var st2: StyleBoxFlat = st.duplicate()
    st2.bg_color = Color(col.r + 0.15, col.g + 0.15, col.b + 0.15, 0.8)
    b.add_theme_stylebox_override("hover", st2)
    b.add_theme_stylebox_override("pressed", st2)
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_font_size_override("font_size", int(r * 0.38))
    b.button_down.connect(func(): _inject(action, true))
    b.button_up.connect(func(): _inject(action, false))
    add_child(b)

func _inject(action: String, pressed: bool) -> void:
    var ev := InputEventAction.new()
    ev.action = action
    ev.pressed = pressed
    Input.parse_input_event(ev)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and joy_touch == -1 and event.position.x < _vp.x * 0.45:
            joy_touch = event.index
            joy_center = event.position
            joy_ofs = Vector2.ZERO
            joy_layer.queue_redraw()
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
    _axis("move_left", "move_right", v.x)
    _axis("move_up", "move_down", v.y)

func _axis(neg: String, pos: String, s: float) -> void:
    if s > 0.0:
        Input.action_release(neg)
        Input.action_press(pos, s)
    elif s < 0.0:
        Input.action_release(pos)
        Input.action_press(neg, -s)
    else:
        Input.action_release(neg)
        Input.action_release(pos)

func _draw_joy() -> void:
    if joy_touch == -1:
        return
    var r := _joy_r()
    joy_layer.draw_arc(joy_center, r, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
    joy_layer.draw_circle(joy_center + joy_ofs, r * 0.42, Color(1, 1, 1, 0.45))
