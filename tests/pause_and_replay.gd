extends SceneTree
func _initialize():call_deferred("run")
func press(id:int,p:Vector2,value:bool):
 var e=InputEventScreenTouch.new();e.index=id;e.position=p;e.pressed=value;Input.parse_input_event(e)
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var mv=MatchView.new();mv.set_meta("force_touch",true);mv.setup({"demo":false,"AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv)
 await process_frame
 mv.set_physics_process(false)
 var tc:TouchControls
 for c in mv.get_children():
  if c is TouchControls:tc=c
 var ev=InputEventAction.new();ev.action="pause";ev.pressed=true
 mv._on_pause_input(ev)
 print("PAUSE_VISIBLE=",mv.pause_layer.visible," PAUSE_BUTTONS=",mv.pause_layer.find_children("*","BaseButton",true,false).size())
 assert(mv.paused_game and not tc.visible)
 var timer=mv.sim.state_t
 for i in 4:await physics_frame
 assert(mv.sim.state_t==timer)
 mv._request_menu();assert(mv.pause_confirm and mv.paused_game)
 mv._resume_pause();assert(not mv.paused_game and tc.visible)
 mv.hud.set_hint("");mv._open_pause();mv._resume_pause();assert(not mv.hud.hint.visible)
 var left=[false];mv.quit_to_menu.connect(func():left[0]=true)
 mv._open_pause();mv._request_menu();assert(not left[0]);mv._request_menu();assert(left[0] and not paused)
 print("PAUSE_FREEZE_RESUME_CONFIRM_EXIT=PASS")
 paused=false
 await create_timer(0.1).timeout;mv.queue_free();host.free();await create_timer(0.2).timeout;quit()
