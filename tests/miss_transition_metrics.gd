extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(42117)
 var prior:Array=[{},{}];var events:Array=[];var sum:float=0;var count:int=0
 for i in 1800:
  mv._physics_process(1.0/60)
  for k in 2:
   var f=mv.rigs[k];var e=mv.sim.pl[k];var p:Transform3D=f._current_global_pose(f.racket_hand_idx);var head:Vector3=f.skel.global_transform*(p*(f._fist_center_hand+f.grip_basis.y*0.57/f.CHAR_SCALE))
   if prior[k].has("active") and prior[k].active and not f.approach_active and e.swing<=0 and f._full_stroke_age>0.65:
    var step:float=prior[k].head.distance_to(head);events.append({"frame":i,"actor":k,"step":step,"kind":e.kind});sum+=step;count+=1
   prior[k]={"head":head,"active":f.approach_active}
 events.sort_custom(func(a,b):return a.step>b.step)
 print("MISS_TRANSITIONS count=",count," mean_step_m=",sum/maxi(count,1)," worst=",events.slice(0,10))
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
