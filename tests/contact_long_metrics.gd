extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var last=[0.0,0.0]
 var contacts:int=0
 var misses:int=0
 var max_miss:float=0.0
 var chain_max:float=0.0
 var chain_bad:int=0
 var steps:int=1800
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("seconds="):steps=int(float(arg.substr(8))*60.0)
 for i in steps:
  mv._physics_process(1.0/60)
  for p in 2:
   var e=mv.sim.pl[p];var f=mv.rigs[p]
   for side in ["L","R"]:
    for chain in [["UpperArm_","LowerArm_","Wrist_"],["UpperLeg_","LowerLeg_","Foot_"]]:
     for pair in 2:
      var a:int=f.skel.find_bone(chain[pair]+side);var b:int=f.skel.find_bone(chain[pair+1]+side)
      var delta:float=absf(f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)-f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin))
      chain_max=maxf(chain_max,delta)
      if delta>0.001:chain_bad+=1
   if e.swing>last[p] and e.kind!="serve" and f.has_visual_contact:
    var w=f._current_global_pose(f.racket_hand_idx)
    var head=f.skel.global_transform*(w*(f._fist_center_hand+f.grip_basis.y*0.57/PlayerFig.CHAR_SCALE))
    var miss:float=head.distance_to(f.visual_contact)
    contacts+=1;max_miss=maxf(max_miss,miss)
    if miss>0.003:misses+=1
    print("CONTACT ",i," id=",p," kind=",e.kind," side=",e.hit_side," actual=",f.visual_contact," head=",head," miss=",head.distance_to(f.visual_contact)," speed=",e.speed," vel=",Vector2(e.vx,e.vz)," player=",Vector3(e.x,0,e.z)," weight=",f.tennis_contact_weight)
   last[p]=e.swing
 print("LONG_AUDIT seconds=",float(steps)/60.0," contacts=",contacts," max_miss_m=",max_miss," chain_max_m=",chain_max," bad_chains=",chain_bad)
 assert(contacts>=10 and misses==0 and chain_bad==0)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
