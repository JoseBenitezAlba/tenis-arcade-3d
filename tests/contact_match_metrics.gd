extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var last=[0.0,0.0]
 for i in 840:
  mv._physics_process(1.0/60)
  for p in 2:
   var e=mv.sim.pl[p];var f=mv.rigs[p]
   if e.swing>last[p] and e.kind!="serve" and f.has_visual_contact:
    var w=f._current_global_pose(f.racket_hand_idx)
    var head=f.skel.global_transform*(w*(f._fist_center_hand+f.grip_basis.y*0.57/PlayerFig.CHAR_SCALE))
    print("CONTACT ",i," id=",p," kind=",e.kind," side=",e.hit_side," actual=",f.visual_contact," head=",head," miss=",head.distance_to(f.visual_contact)," speed=",e.speed," vel=",Vector2(e.vx,e.vz)," player=",Vector3(e.x,0,e.z)," weight=",f.tennis_contact_weight)
   last[p]=e.swing
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
