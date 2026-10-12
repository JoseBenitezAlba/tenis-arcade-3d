extends SceneTree
# Test: pausar y reanudar con la accion "pause" (bug: pausa sin salida) y salir con "quit".
func _act(name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = name
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 10:
		await process_frame
	main._start_match({"surface": "clay", "AIP": {"speed": 5.6, "react": 0.27, "err": 0.5, "miss": 0.15}})
	for i in 10:
		await process_frame
	var mv = main.match_view
	assert(mv != null, "match_view existe")
	await _act("pause")
	assert(paused, "P1: el arbol queda en pausa")
	assert(mv.pause_layer.visible, "P2: overlay de pausa visible")
	await _act("pause")
	assert(not paused, "P3: reanuda con el segundo pause")
	assert(not mv.pause_layer.visible, "P4: overlay oculto")
	await _act("pause")
	assert(paused, "P5: pausa de nuevo")
	await _act("quit")
	assert(not paused, "P6: quit sale de la pausa")
	for i in 6:
		await process_frame
	assert(main.match_view == null, "P7: vuelve al menu")
	print("PAUSE TEST PASS")
	quit(0)
