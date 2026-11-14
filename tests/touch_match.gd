extends SceneTree
func _initialize():call_deferred("run")
func press(id:int,p:Vector2,value:bool):
 var e=InputEventScreenTouch.new();e.index=id;e.position=p;e.pressed=value;Input.parse_input_event(e)
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var mv=MatchView.new();mv.set_meta("force_touch",true);mv.setup({"demo":false,"AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv)
 await process_frame
 var tc:TouchControls
 for child in mv.get_children():
  if child is TouchControls:tc=child
 mv.set_physics_process(false)
 var hit=tc._buttons[0];var hp=hit.position+Vector2.ONE*75
 # Cooldown de 0,4 s al entrar al saque: un toque inmediato no lanza.
 press(1,hp,true);await process_frame;mv._physics_process(1.0/60)
 press(1,hp,false);await process_frame
 print("TOUCH SERVE cooldown stage ",mv.sim.serve_stage);assert(mv.sim.serve_stage=="ready")
 mv.sim.state_t=0.45
 press(1,hp,true);await process_frame;mv._physics_process(1.0/60)
 press(1,hp,false);await process_frame
 print("TOUCH SERVE stage ",mv.sim.serve_stage);assert(mv.sim.serve_stage=="toss")
 while mv.sim.ball.toss_t < 0.36:
  mv._physics_process(1.0/60);await process_frame
 press(1,hp,true);await process_frame;mv._physics_process(1.0/60)
 press(1,hp,false);await process_frame
 print("TOUCH SERVE after second ",mv.sim.serve_stage);assert(mv.sim.serve_stage=="hit")
 mv.set_physics_process(true)
 var b=tc._buttons[4];var center=b.position+Vector2.ONE*36
 var prev=mv.cam_mode
 press(2,center,true);await process_frame;await physics_frame
 press(2,center,false);await process_frame
 print("CAMTOUCH ",prev," -> ",mv.cam_mode);assert(prev != mv.cam_mode)
 b=tc._buttons[3];center=b.position+Vector2.ONE*36
 press(2,center,true);await process_frame
 press(2,center,false);await process_frame
 print("PAUSETOUCH ",mv.paused_game);assert(mv.paused_game)
 press(2,center,true);await process_frame
 press(2,center,false);await process_frame
 assert(not mv.paused_game)
 print("PAUSE RESUME PASSED")
 mv.queue_free();host.free();await process_frame;quit()
