extends SceneTree
func _initialize():call_deferred("run")
func run():
 var out:String="/tmp/players-v18-replay"
 DirAccess.make_dir_recursive_absolute(out)
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.setup({"demo":true,"AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var saved:Array=[]
 for i in 1600:
  mv._physics_process(1.0/60)
  if i not in [145,167,229,309,785,1065,1512]:continue
  var focus:int=1 if i in [229,785] else 0
  var f=mv.rigs[focus];mv.cam.position=f.position+Vector3(3.0,2.0,4.3 if focus==0 else -4.3);mv.cam.look_at(f.position+Vector3(0,1.45,0));mv.cam.fov=40;mv.cam.near=0.05
  saved.append({"frame":i,"v0":mv.rigs[0].capture_visual_pose(),"v1":mv.rigs[1].capture_visual_pose(),"camera":mv.cam.transform,"ball":mv.ball_mesh.position})
  await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/live_%04d.png"%i)
 for frame in saved:
  mv.rigs[0].restore_visual_pose(frame.v0);mv.rigs[1].restore_visual_pose(frame.v1);mv.cam.transform=frame.camera;mv.cam.near=0.05;mv.cam.fov=40;mv.ball_mesh.position=frame.ball
  await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(out+"/replay_%04d.png"%frame.frame)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
