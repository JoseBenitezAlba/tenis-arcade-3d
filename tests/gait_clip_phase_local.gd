extends SceneTree
func _initialize():call_deferred("run")
func run():
 var f=PlayerFig.new(0,true);root.add_child(f);await process_frame
 for clip in ["Walk","Run","Run_Back","Run_Left","Run_Right"]:
  var a=f.ap.get_animation(clip)
  print("CLIP ",clip," length=",a.length)
  for i in 16:
   f._pose_overrides.clear();f.skel.clear_bones_global_pose_override();f.ap.play(clip,0);f.ap.seek(a.length*i/16.0,true);f.ap.advance(0);f._sync_mocap_feet()
   var vs=[]
   for side in ["L","R"]:
    var b=f.skel.find_bone("Foot_"+side);var p=f._current_global_pose(b);vs.append(p.origin)
   print("phase=",i/16.0," L=",vs[0]," R=",vs[1])
 f.queue_free();await process_frame;quit()
