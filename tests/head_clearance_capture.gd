extends SceneTree
func _initialize():call_deferred("run")
func run():
 var target:int=1531;var focus:int=0;var out:String="/tmp/head-clearance.png"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("frame="):target=int(arg.substr(6))
  if arg.begins_with("focus="):focus=int(arg.substr(6))
  if arg.begins_with("out="):out=arg.substr(4)
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(42117)
 for i in target+1:mv._physics_process(1.0/60)
 var f=mv.rigs[focus];mv.cam.position=f.position+Vector3(2.5,1.8,3.5 if focus==0 else -3.5);mv.cam.look_at(f.position+Vector3(0,1,0));mv.cam.fov=34;mv.cam.near=0.05
 print("CAPTURE frame=",target," actor=",focus," kind=",mv.sim.pl[focus].kind," side=",mv.sim.pl[focus].hit_side," age=",f._full_stroke_age)
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
