extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var last=[0.0,0.0]
 var cases:int=0
 var chain_max:float=0.0
 var chain_fail:int=0
 if "far" in OS.get_cmdline_user_args():mv.sim.M.server=1;mv.sim.prep_serve()
 for i in 200:
  mv._physics_process(1.0/60)
  for p in 2:
   var e=mv.sim.pl[p];var f=mv.rigs[p]
   for side in ["L","R"]:
    for chain in [["UpperArm_","LowerArm_","Wrist_"],["UpperLeg_","LowerLeg_","Foot_"]]:
     for pair in 2:
      var a:int=f.skel.find_bone(chain[pair]+side);var b:int=f.skel.find_bone(chain[pair+1]+side)
      var error:float=absf(f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)-f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin))
      chain_max=maxf(chain_max,error)
      if error>0.001:
       chain_fail+=1
       if chain_fail<8:print("CHAIN_FAIL frame=",i," actor=",p," pair=",chain[pair]+side," error=",error)
   if e.swing>last[p] and e.kind=="serve":
    var w=f._current_global_pose(f.racket_hand_idx)
    var head=f.skel.global_transform*(w*(f._fist_center_hand+f.grip_basis.y*0.57/PlayerFig.CHAR_SCALE))
    var a=f._current_global_pose(f.skel.find_bone("UpperArm_R")).origin;var b=f._current_global_pose(f.skel.find_bone("LowerArm_R")).origin;var c=f._current_global_pose(f.skel.find_bone("Wrist_R")).origin
    cases+=1
    assert(head.distance_to(f._serve_contact)<0.003)
    assert(rad_to_deg((b-a).angle_to(c-b))<35.0)
    print("EXACT_EVENT miss=",head.distance_to(f._serve_contact)," event=",f._serve_contact)
    print("SERVE_ELBOW ",rad_to_deg((b-a).angle_to(c-b))," ball=",Vector3(mv.sim.ball.x,mv.sim.ball.y,mv.sim.ball.z))
    print("CONTACT ",i," id=",p," kind=",e.kind," side=",e.hit_side," head=",head," ball_distance=",head.distance_to(Vector3(mv.sim.ball.x,mv.sim.ball.y,mv.sim.ball.z))," speed=",e.speed," vel=",Vector2(e.vx,e.vz)," player=",Vector3(e.x,0,e.z)," weight=",f.tennis_contact_weight)
   last[p]=e.swing
 assert(cases==1)
 assert(chain_fail==0)
 print("PASS serve registered contact and elbow extension; chain_fail=",chain_fail," chain_max=",chain_max)
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
