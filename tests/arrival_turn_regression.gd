extends SceneTree
# Cap preparation/root locomotion, not the registered-contact fit.
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var worst_sole:float=0.0;var chain_max:float=0.0;var grip_max:float=0.0;var grip_fail:int=0;var ground_contacts:int=0
 var total:int=0;var violations:int=0;var worst:float=0.0;var contacts:int=0;var max_miss:float=0.0
 for test_seed in [42117,1234,72,8853]:
  seed(test_seed)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
  var yaw:Array[float]=[mv.rigs[0].rotation.y,mv.rigs[1].rotation.y];var swing:Array[float]=[0.0,0.0]
  for frame in 1800:
   mv._physics_process(1.0/60.0)
   for actor in 2:
    var f=mv.rigs[actor];var e=mv.sim.pl[actor]
    var actual:bool=f.has_visual_contact and e.swing>0.0
    if frame>0 and mv.sim.state=="play" and not actual:
     var step:float=rad_to_deg(absf(angle_difference(yaw[actor],f.rotation.y)))
     total+=1;worst=maxf(worst,step)
     if step>4.51:violations+=1;print("PREPARATION_TURN seed=",test_seed," frame=",frame," actor=",actor," degrees=",step)
    if actual and e.swing>swing[actor] and e.kind!="serve":
     var hand:Transform3D=f._current_global_pose(f.racket_hand_idx)
     var head:Vector3=f.skel.global_transform*(hand*(f._fist_center_hand+f.grip_basis.y*0.57/PlayerFig.CHAR_SCALE))
     var miss:float=head.distance_to(f.visual_contact)
     var sole:float=INF
     for side in ["L","R"]:
      var foot:int=f.skel.find_bone("Foot_"+side)
      var fp:Transform3D=f.skel.global_transform*f._current_global_pose(foot)
      for point in f._foot_points.get(foot,[]):sole=minf(sole,(fp*point).y)
      for chain in [["UpperArm_","LowerArm_","Wrist_"],["UpperLeg_","LowerLeg_","Foot_"]]:
       for pair in 2:
        var a:int=f.skel.find_bone(chain[pair]+side);var b:int=f.skel.find_bone(chain[pair+1]+side)
        chain_max=maxf(chain_max,absf(f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)-f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin)))
     if e.kind!="smash":
      ground_contacts+=1;worst_sole=maxf(worst_sole,absf(sole-0.004))
      if e.hit_side=="back":
       var center:Vector3=hand*f._fist_center_hand+(hand.basis*f.grip_basis.y)*0.095/f.CHAR_SCALE
       var gap:float=center.distance_to(f._closed_left.position)*f.CHAR_SCALE
       grip_max=maxf(grip_max,gap)
       if not f._closed_left.visible or gap>=0.003:
        grip_fail+=1;print("CONTACT_GRIP seed=",test_seed," frame=",frame," actor=",actor," gap_m=",gap," closed=",f._closed_left.visible)
     if e.kind!="smash" and absf(sole-0.004)>0.005:print("CONTACT_FOOT seed=",test_seed," frame=",frame," actor=",actor," sole_m=",sole," kind=",e.kind)
     max_miss=maxf(max_miss,miss);contacts+=1
     if miss>0.003:print("CONTACT_MISS seed=",test_seed," frame=",frame," actor=",actor," miss_m=",miss," kind=",e.kind)
    yaw[actor]=f.rotation.y;swing[actor]=e.swing
  mv._amb.stop();mv.queue_free();await process_frame
 print("ARRIVAL_TURN samples=",total," violations=",violations," max_degrees_per_frame=",worst," contacts=",contacts," max_miss_m=",max_miss," sole_error_m=",worst_sole," chain_max_m=",chain_max," ground_contacts=",ground_contacts," grip_max_m=",grip_max," grip_failures=",grip_fail)
 assert(total>1000 and violations==0 and contacts>20 and max_miss<0.003 and worst_sole<0.005 and chain_max<0.001 and grip_fail==0)
 host.free();quit()
