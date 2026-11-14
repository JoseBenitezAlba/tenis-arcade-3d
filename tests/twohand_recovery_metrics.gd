extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var last:Array[float]=[0.0,0.0]
 var samples:int=0;var maxgap:float=0.0;var gapframes:int=0
 for i in 1800:
  mv._physics_process(1.0/60)
  for k in 2:
   var f=mv.rigs[k];var e=mv.sim.pl[k]
   var r:Transform3D=f._current_global_pose(f.racket_hand_idx)
   var center:Vector3=r*f._fist_center_hand+(r.basis*f.grip_basis.y)*0.095/f.CHAR_SCALE
   var gap:float=center.distance_to(f._closed_left.position)*f.CHAR_SCALE
   if f._closed_left.visible:
    samples+=1
    if gap>maxgap:
     maxgap=gap;print("WORST_GRIP frame=",i," actor=",k," gap=",gap," weight=",f.tennis_contact_weight," age=",f._full_stroke_age)
   if e.swing>last[k] and e.hit_side=="back" and not e.kind in ["serve","smash"]:
    assert(f._closed_left.visible and gap<0.003)
    print("BACK_CONTACT frame=",i," actor=",k," kind=",e.kind," gap_m=",gap," closed=",f._closed_left.visible)
   last[k]=e.swing
 print("CLOSED_GRIP samples=",samples," maxgap_m=",maxgap)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
