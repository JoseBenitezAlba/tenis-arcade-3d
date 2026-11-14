extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.replay_test=true;mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var samples:Array=[]
 for i in 360:
  mv._physics_process(1.0/60)
  if i in [134,160,167,175,229,240,304,330]:samples.append({"index":mv.rec.size()-1,"p0":mv.rigs[0].capture_visual_pose(),"p1":mv.rigs[1].capture_visual_pose()})
 var frame_count:int=mv.rec.size();assert(frame_count>200)
 var max_error:float=0.0
 mv._start_replay()
 for sample in samples:
  mv.replay_i=float(sample.index)-0.6
  mv._replay_tick(1.0/60)
  for k in 2:
   var expected:Dictionary=sample["p"+str(k)];var actual:Dictionary=mv.rigs[k].capture_visual_pose()
   max_error=maxf(max_error,actual.world.origin.distance_to(expected.world.origin))
   for bi in expected.bones.size():
    max_error=maxf(max_error,actual.bones[bi].origin.distance_to(expected.bones[bi].origin))
    assert(actual.bones[bi].basis.is_equal_approx(expected.bones[bi].basis))
 assert(max_error<0.00001)
 print("PASS replay ",samples.size()," frames both players all bones max_error=",max_error," recorded=",frame_count)
 mv._end_replay();mv._physics_process(1.0/60)
 assert(mv.rec.size()>0)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
