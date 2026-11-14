extends SceneTree
func _initialize():call_deferred("run")
func run():
 var h=load("res://scripts/main.gd").new();h._register_inputs()
 var sd:int=int(OS.get_cmdline_user_args()[0])
 seed(sd);var m=MatchView.new();m.set_meta("surface","clay");m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(m);m.set_physics_process(false);await process_frame;seed(sd)
 var previous=[{},{}];var traces=[{},{}];var changes=[[],[]]
 for i in 1800:
  m._physics_process(1.0/60)
  for k in 2:
   var f=m.rigs[k];var e=m.sim.pl[k];var v={}
   for bn in ["Body","Foot_L","Foot_R"]:v[bn]=f.skel.global_transform*f._current_global_pose(f.skel.find_bone(bn)).origin
   var valid:bool=f.state in ["Walk","Run","Run_Back","Run_Left","Run_Right"] and f.tennis_contact_weight<0.1 and e.swing<=0.0
   if i>10 and not previous[k].is_empty() and valid and previous[k].valid:
    var feet_step:float=maxf(v.Foot_L.distance_to(previous[k].v.Foot_L),v.Foot_R.distance_to(previous[k].v.Foot_R))
    traces[k][i]={"feet":feet_step,"frame":i}
    if previous[k].state!=f.state:changes[k].append([i,previous[k].state+"->"+f.state])
   previous[k]={"v":v,"valid":valid,"state":f.state}
 for k in 2:
  var data=[];var marked={}
  for c in changes[k]:
   for i in range(c[0],c[0]+9):
    if traces[k].has(i):marked[i]=true
  for i in marked:data.append(traces[k][i])
  data.sort_custom(func(a,b):return a.feet>b.feet)
  print("PROBE seed=",sd," actor=",k," switches=",changes[k].size()," samples=",data.size()," worst=",data.slice(0,4))
  print("  changes: ",changes[k].slice(0,20))
 m._amb.stop();m.queue_free();await process_frame
 h.free();quit()
