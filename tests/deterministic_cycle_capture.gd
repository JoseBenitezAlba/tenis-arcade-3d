extends SceneTree
func _initialize():call_deferred("run")
func run():
 var first:int=1507;var last:int=1557;var focus:int=0;var out:String="/tmp/players-v32-cycle"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("first="):first=int(arg.substr(6))
  if arg.begins_with("last="):last=int(arg.substr(5))
  if arg.begins_with("focus="):focus=int(arg.substr(6))
  if arg.begins_with("out="):out=arg.substr(4)
 DirAccess.make_dir_recursive_absolute(out)
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(42117)
 var samples:Array=[]
 for i in last+1:
  mv._physics_process(1.0/60)
  if i>=first and (i-first)%2==0:
   if i%10==0:print("STATE frame=",i," kind=",mv.sim.pl[focus].kind," side=",mv.sim.pl[focus].hit_side," approach=",mv.rigs[focus].approach_active," time=",mv.rigs[focus].approach_time," player=",mv.rigs[focus].position," target=",mv.rigs[focus].approach_contact)
   samples.append({"frame":i,"poses":[mv.rigs[0].capture_visual_pose(),mv.rigs[1].capture_visual_pose()]})
 for sample in samples:
  for k in 2:mv.rigs[k].restore_visual_pose(sample.poses[k])
  var f=mv.rigs[focus];mv.cam.position=f.position+Vector3(2.5,1.8,3.5 if focus==0 else -3.5);mv.cam.look_at(f.position+Vector3(0,1,0));mv.cam.fov=34;mv.cam.near=0.05
  await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/frame_%04d.png"%sample.frame)
 print("CAPTURE pose restoration only, HUD/ball remain final state. samples=",samples.size())
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
