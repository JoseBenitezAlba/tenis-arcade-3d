extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 DirAccess.make_dir_recursive_absolute("/tmp/v105-headclose")
 var first:int=1053;var last:int=1057
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("first="):first=int(arg.substr(6))
  if arg.begins_with("last="):last=int(arg.substr(5))
 for i in last+1:
  mv._physics_process(1.0/60)
  if i<first:continue
  var f=mv.rigs[0];var hi:int=f.skel.find_bone("Head")
  var hw3:Vector3=(f.skel.global_transform*f._current_global_pose(hi)).origin
  for ai in 2:
   var off:Vector3=(Vector3(0.85,0.12,0.55) if ai==0 else Vector3(-0.75,0.3,-0.6))
   mv.cam.position=hw3+off;mv.cam.look_at(hw3);mv.cam.fov=22;mv.cam.near=0.05;mv.cam.far=100.0
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("/tmp/v105-headclose/frame_%04d_%s.png"%[i,"a" if ai==0 else "b"])
 print("CAPTURES done ",DirAccess.get_files_at("/tmp/v105-headclose").size())
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
