extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 for timing in [0.36,0.38,0.4,0.42,0.5,0.6,0.75,0.8,0.82,0.9]:
  seed(42117)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":false,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
  mv.sim.rut_t=1.8
  mv.sim.step_ball(0.0)
  mv.sim.toss_ball()
  var frame:int=0
  while mv.sim.ball.toss and mv.sim.ball.toss_t<timing:
   mv._physics_process(1.0/60);frame+=1
  var actual_t:float=mv.sim.ball.toss_t
  var pre_y:float=mv.sim.ball.y
  var f=mv.rigs[0]
  var r=f._current_global_pose(f.racket_hand_idx)
  var prev_head:Vector3=f.skel.global_transform*(r*(f._fist_center_hand+f.grip_basis.y*0.57/f.CHAR_SCALE))
  mv.sim.inp.hit=true;mv.sim.human_control(mv.sim.pl[0],0.0)
  mv._physics_process(1.0/60)
  r=f._current_global_pose(f.racket_hand_idx)
  var head:Vector3=f.skel.global_transform*(r*(f._fist_center_hand+f.grip_basis.y*0.57/f.CHAR_SCALE))
  var a:Vector3=f._current_global_pose(f.skel.find_bone("UpperArm_R")).origin
  var b:Vector3=f._current_global_pose(f.skel.find_bone("LowerArm_R")).origin
  print("HUMAN t=",actual_t," y=",pre_y," stage=",mv.sim.serve_stage," event=",f._serve_contact," miss=",head.distance_to(f._serve_contact)," step=",head.distance_to(prev_head)," bend=",rad_to_deg((b-a).angle_to(r.origin-b)))
  mv._amb.stop();mv.queue_free();await process_frame
 host.free();quit()
