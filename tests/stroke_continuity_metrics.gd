extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var previous:Array=[{},{}];var nearest:Dictionary={};var jump:Dictionary={};var elapsed_ms:int=0;var max_ms:int=0
 for i in 1800:
  var before:int=Time.get_ticks_usec();mv._physics_process(1.0/60);var us:int=Time.get_ticks_usec()-before;elapsed_ms+=us;max_ms=maxi(max_ms,us)
  for k in 2:
   var e=mv.sim.pl[k];var f=mv.rigs[k];var rp:Transform3D=f._current_global_pose(f.racket_hand_idx)
   var head:Vector3=f.skel.global_transform*(rp*(f._fist_center_hand+f.grip_basis.y*0.57/f.CHAR_SCALE))
   var skull:Vector3=f.skel.global_transform*f._current_global_pose(f.skel.find_bone("Head")).origin
   var mode:String=e.kind+"/"+e.hit_side+("/recovery" if e.swing>0.0 or f._full_stroke_age<0.65 else "/preparation")
   if f.tennis_contact_weight>0.9 and f._full_stroke_age>0.10:
    var gap:float=head.distance_to(skull)
    if gap<float(nearest.get(mode,{"gap":INF}).gap):nearest[mode]={"gap":gap,"frame":i,"actor":k}
    if previous[k].has("head") and previous[k].mode==mode and previous[k].weight>0.9 and absf(previous[k].age-f._full_stroke_age)<0.03 and mv.sim.state=="play":
     var step:float=head.distance_to(previous[k].head)
     if step>float(jump.get(mode,{"step":0.0}).step):jump[mode]={"step":step,"frame":i,"actor":k}
   previous[k]={"head":head,"mode":mode,"weight":f.tennis_contact_weight,"age":f._full_stroke_age}
 print("CONTINUITY nearest_head=",nearest," largest_frame_step=",jump," physics_mean_ms=",float(elapsed_ms)/1800000.0," max_ms=",float(max_ms)/1000)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
