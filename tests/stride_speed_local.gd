extends SceneTree
func _initialize():call_deferred("run")
func run():
 var f=PlayerFig.new(0,true);root.add_child(f);await process_frame
 for clip in ["Walk","Run","Run_Back","Run_Left","Run_Right"]:
  var a=f.ap.get_animation(clip);var before={};var speeds=[];var signed=[]
  var dir=Vector3(0,0,1)
  if clip=="Run_Back":dir=Vector3(0,0,-1)
  if clip=="Run_Left":dir=Vector3(1,0,0)
  if clip=="Run_Right":dir=Vector3(-1,0,0)
  for i in range(0,241):
   var t:float=a.length*float(i)/240.0
   f._pose_overrides.clear();f.skel.clear_bones_global_pose_override();f.ap.play(clip,0);f.ap.seek(minf(t,a.length-0.000001),true);f.ap.advance(0);f._sync_mocap_feet()
   for side in ["L","R"]:
    var b=f.skel.find_bone("Foot_"+side);var p:Transform3D=f.skel.global_transform*f._current_global_pose(b);var low:float=INF
    for point in f._foot_points.get(b,[]):low=minf(low,(p*point).y)
    if before.has(side) and i>1:
     var v:Vector3=(p.origin-before[side].p)/(a.length/240.0)
     var push:float=-v.dot(dir)
     # Stationary stance segment, not the heel landing or toe lift.
     if low<0.035 and before[side].low<0.035 and push>0.3:
      speeds.append(push);signed.append(v)
    before[side]={"p":p.origin,"low":low}
  speeds.sort();var mean:float=0
  for s in speeds:mean+=s
  print("STRIDE clip=",clip," n=",speeds.size()," stance_back_speed_mean=",mean/maxi(1,speeds.size())," median=",speeds[speeds.size()/2] if speeds.size()>0 else -1," bounds=",speeds[0] if speeds.size()>0 else -1,"..",speeds[-1] if speeds.size()>0 else -1)
 f.queue_free();await process_frame;quit()
