extends SceneTree
func _initialize():call_deferred("run")
func run():
 var out:String="/tmp/players-v25-replay-runtime";DirAccess.make_dir_recursive_absolute(out)
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.replay_test=true;mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 for i in 360:mv._physics_process(1.0/60)
 mv._start_replay();var samples:int=0;var error:float=0.0
 for i in 450:
  if not mv.replaying:break
  mv._replay_tick(1.0/60)
  if not mv.replaying:break
  if i%6!=0:continue
  var expected:Dictionary=mv.rec[int(mv.replay_i)]
  await process_frame;await RenderingServer.frame_post_draw
  for k in 2:
   var actual:Dictionary=mv.rigs[k].capture_visual_pose();var source:Dictionary=expected["v"+str(k)]
   error=maxf(error,actual.world.origin.distance_to(source.world.origin))
   for bi in source.bones.size():error=maxf(error,actual.bones[bi].origin.distance_to(source.bones[bi].origin))
  samples+=1;root.get_texture().get_image().save_png(out+"/frame_%04d.png"%i)
 print("PASS replay runtime samples=",samples," max_error_after_draw=",error," ended=",not mv.replaying);assert(error<0.00001 and samples>40 and not mv.replaying)
 mv._physics_process(1.0/60);mv.cam.near=0.05
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/after_return.png")
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
