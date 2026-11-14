extends SceneTree
func _initialize():call_deferred("run")
func run():
 var h=load("res://scripts/main.gd").new();h._register_inputs()
 for sd in [1234,42117,8853]:
  seed(sd);var m=MatchView.new();m.set_meta("surface","clay");m.setup({"demo":true,"surface":"clay","AIP":h.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(m);m.set_physics_process(false);await process_frame;seed(sd)
  var worst=[];var last=[{},{}]
  for i in 1800:
   m._physics_process(1.0/60)
   for k in 2:
    var f=m.rigs[k];var e=m.sim.pl[k]
    var v:Vector3=Vector3(e.vx,0,e.vz).rotated(Vector3.UP,-f.rotation.y)
    var axis:Vector3=Vector3(0,0,1)
    if f.state=="Run_Back":axis=Vector3(0,0,-1)
    elif f.state=="Run_Left":axis=Vector3(1,0,0)
    elif f.state=="Run_Right":axis=Vector3(-1,0,0)
    var angle:float=rad_to_deg(atan2(axis.cross(v).y,axis.dot(v)))
    var feet=[];var lows=[]
    for side in ["L","R"]:
     var b=f.skel.find_bone("Foot_"+side);var p:Transform3D=f.skel.global_transform*f._current_global_pose(b);feet.append(p.origin);var low:float=INF
     for point in f._foot_points.get(b,[]):low=minf(low,(p*point).y)
     lows.append(low)
    var valid:bool=f.state in f.GAIT_CLIPS and f.tennis_contact_weight<0.1 and not f.repositioning and e.swing<=0 and e.speed>2
    if valid and not last[k].is_empty() and last[k].valid and last[k].state==f.state:
     for n in 2:
      if lows[n]<0.03 and last[k].lows[n]<0.03:
       var d:Vector3=(feet[n]-last[k].feet[n])*60;d.y=0
       if absf(angle)>25:worst.append({"frame":i,"actor":k,"clip":f.state,"degrees":angle,"v":v,"slide":d.length(),"foot":n})
    last[k]={"valid":valid,"state":f.state,"feet":feet,"lows":lows}
  worst.sort_custom(func(a,b):return absf(a.degrees)>absf(b.degrees))
  print("DIAGONAL seed=",sd," count=",worst.size()," worst=",worst.slice(0,12))
  m._amb.stop();m.queue_free();await process_frame
 h.free();quit()
