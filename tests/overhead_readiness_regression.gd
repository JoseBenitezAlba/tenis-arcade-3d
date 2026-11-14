extends SceneTree
# A high lob crossing the player's horizontal position is not an overhead
# impact while the ball is still many metres above the reachable racket.
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var samples:int=0;var raised:int=0;var max_above:float=-INF
 for test_seed in [42117,8853]:
  seed(test_seed)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
  var high_age:Array[float]=[0.0,0.0]
  for frame in 1800:
   mv._physics_process(1.0/60.0)
   for actor in 2:
    var f=mv.rigs[actor];var e=mv.sim.pl[actor]
    var high:bool=f.approach_active and f.approach_contact.y>4.0 and mv.sim.ball.y>6.0 and e.swing<=0.0 and f._full_stroke_age>0.65
    high_age[actor]=high_age[actor]+1.0/60.0 if high else 0.0
    if high_age[actor]<=0.20:continue
    var hand:Vector3=f._current_global_pose(f.racket_hand_idx).origin
    var head:Vector3=f._current_global_pose(f.skel.find_bone("Head")).origin
    var above:float=(hand.y-head.y)*PlayerFig.CHAR_SCALE
    samples+=1;max_above=maxf(max_above,above)
    if above>0.08:
     raised+=1;print("EARLY_OVERHEAD seed=",test_seed," frame=",frame," actor=",actor," hand_above_head_m=",above)
  mv._amb.stop();mv.queue_free();await process_frame
 print("OVERHEAD_READINESS samples=",samples," early_raised=",raised," max_hand_above_head_m=",max_above)
 assert(samples>=20 and raised==0)
 host.free();quit()
