extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var clips=["Walk","Run","Run_Back","Run_Left","Run_Right"]
 for sd in [42117,1234,8853]:
  seed(sd);var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(sd)
  var prior=[{},{}];var events=[]
  for i in 1800:
   mv._physics_process(1.0/60)
   for k in 2:
    var f=mv.rigs[k];var e=mv.sim.pl[k];var feet=[]
    for side in ["L","R"]:feet.append(f.skel.global_transform*f._current_global_pose(f.skel.find_bone("Foot_"+side)).origin)
    if not prior[k].is_empty() and f.state in clips and prior[k].state in clips and f.state!=prior[k].state and f.tennis_contact_weight<0.1 and prior[k].weight<0.1 and e.swing<=0:
     events.append({"frame":i,"actor":k,"from":prior[k].state,"to":f.state,"oldphase":prior[k].phase,"newphase":f.ap.current_animation_position,"step":maxf(feet[0].distance_to(prior[k].feet[0]),feet[1].distance_to(prior[k].feet[1])),"reposition":f.repositioning})
    prior[k]={"state":f.state,"phase":f.ap.current_animation_position,"feet":feet,"weight":f.tennis_contact_weight}
  events.sort_custom(func(a,b):return a.step>b.step);print("GAIT_SWITCH seed=",sd," count=",events.size()," worst=",events.slice(0,10))
  mv._amb.stop();mv.queue_free();await process_frame
 host.free();quit()
