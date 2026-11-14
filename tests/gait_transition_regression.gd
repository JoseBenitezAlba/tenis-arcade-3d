extends SceneTree
# Targeted transition-window regression, not proof of foot planting or naturalness.
func _initialize():call_deferred("run")
func run():
 var chain_max:float=0.0
 var h=load("res://scripts/main.gd").new();h._register_inputs()
 for sd in [1234,42117,8853]:
  seed(sd);var m=MatchView.new();m.set_meta("surface","clay");m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(m);m.set_physics_process(false);await process_frame;seed(sd)
  var previous=[{},{}];var traces=[{},{}];var changes=[[],[]]
  for i in 1800:
   m._physics_process(1.0/60)
   for k in 2:
    var f=m.rigs[k];var e=m.sim.pl[k];var v={}
    for bn in ["Body","Foot_L","Foot_R"]:v[bn]=f.skel.global_transform*f._current_global_pose(f.skel.find_bone(bn)).origin
    for side in ["L","R"]:
     for chain in [["UpperArm_","LowerArm_","Wrist_"],["UpperLeg_","LowerLeg_","Foot_"]]:
      for pair in 2:
       var a:int=f.skel.find_bone(chain[pair]+side);var b:int=f.skel.find_bone(chain[pair+1]+side)
       chain_max=maxf(chain_max,absf(f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)-f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin)))
    var valid:bool=f.state in ["Walk","Run","Run_Back","Run_Left","Run_Right"] and f.tennis_contact_weight<0.1 and e.swing<=0.0
    if i>10 and not previous[k].is_empty() and valid and previous[k].valid:
     var feet_step:float=maxf(v.Foot_L.distance_to(previous[k].v.Foot_L),v.Foot_R.distance_to(previous[k].v.Foot_R));var body_step:float=v.Body.distance_to(previous[k].v.Body)
     traces[k][i]={"feet":feet_step,"body":body_step,"frame":i}
     if previous[k].state!=f.state:changes[k].append(i)
    previous[k]={"v":v,"valid":valid,"state":f.state}
  for k in 2:
   var data=[];var marked={}
   for c in changes[k]:
    for i in range(c,c+9):
     if traces[k].has(i):marked[i]=true
   for i in marked:data.append(traces[k][i])
   data.sort_custom(func(a,b):return a.feet>b.feet)
   var total:float=0
   for x in data:total+=x.feet
   assert(data.size()>50 and data[0].feet<0.48)
   if sd==8853 and k==0:assert(data[0].feet<0.40)
   print("GAIT_WINDOW seed=",sd," actor=",k," samples=",data.size()," mean=",total/maxi(1,data.size())," worst=",data.slice(0,5))
  m._amb.stop();m.queue_free();await process_frame
 assert(chain_max<0.001)
 print("ALL_FRAME_CHAIN max_m=",chain_max)
 print("PASS gait transition windows across three seeds, including eight frames after each switch")
 h.free();quit()
