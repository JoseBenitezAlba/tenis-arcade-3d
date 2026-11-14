extends SceneTree
func _initialize():call_deferred("run")
func run():
 var test_seed:int=42117;var first:int=1300;var last:int=1390;var focus:int=1;var out:String="/tmp/v58-case"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("seed="):test_seed=int(arg.substr(5))
  if arg.begins_with("first="):first=int(arg.substr(6))
  if arg.begins_with("last="):last=int(arg.substr(5))
  if arg.begins_with("focus="):focus=int(arg.substr(6))
  if arg.begins_with("out="):out=arg.substr(4)
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(test_seed)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
 DirAccess.make_dir_recursive_absolute(out)
 for i in last+1:
  mv._physics_process(1.0/60)
  if i<first:continue
  var f=mv.rigs[focus];mv.cam.position=f.position+Vector3(2.5,1.8,3.5 if focus==0 else -3.5);mv.cam.look_at(f.position+Vector3(0,1,0));mv.cam.fov=34;mv.cam.near=0.05
  if true:
   await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/frame_%04d.png"%i)
 print("LIVE samples=",DirAccess.get_files_at(out).size())
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
