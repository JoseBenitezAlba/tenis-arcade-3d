extends SceneTree
func _initialize():call_deferred("run")
func head_bounds(f)->AABB:
 var hi:int=f.skel.find_bone("Head");var points:PackedVector3Array=[]
 for mi in f.skel.find_children("*","MeshInstance3D",true,false):
  if mi.skin==null:continue
  var map:Array=[]
  for k in mi.skin.get_bind_count():
   var bone:int=mi.skin.get_bind_bone(k)
   if bone<0:bone=f.skel.find_bone(mi.skin.get_bind_name(k))
   map.append(bone)
  for si in mi.mesh.get_surface_count():
   var ar:Array=mi.mesh.surface_get_arrays(si);var vs:PackedVector3Array=ar[Mesh.ARRAY_VERTEX];var bs:PackedInt32Array=ar[Mesh.ARRAY_BONES];var ws:PackedFloat32Array=ar[Mesh.ARRAY_WEIGHTS]
   if bs.is_empty():continue
   var n:int=bs.size()/vs.size()
   for vi in vs.size():
    for k in n:
     if map[bs[vi*n+k]]==hi and ws[vi*n+k]>0.99:points.append(f._skin_bind[hi].affine_inverse()*vs[vi])
 assert(points.size()>20)
 var box:AABB=AABB(points[0],Vector3.ZERO)
 for point in points:box=box.expand(point)
 print("HEAD_BOUNDS samples=",points.size()," local=",box)
 return box
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var bounds:Array=[head_bounds(mv.rigs[0]),head_bounds(mv.rigs[1])];var counts:Dictionary={};var worst:Array=[]
 var points:PackedVector3Array=[]
 for k in 30:points.append(Vector3(0,k*0.015,0))
 for x in range(-8,9):
  for y in range(-8,9):
   var xx:float=x/8.0;var yy:float=y/8.0
   if xx*xx+yy*yy<=1.0:points.append(Vector3(xx*0.16,0.6+yy*0.19,0))
 var seconds:float=30.0;var strict:bool=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("seconds="):seconds=float(arg.substr(8))
  if arg=="strict":strict=true
 for i in int(seconds*60):
  mv._physics_process(1.0/60)
  for k in 2:
   var f=mv.rigs[k];var hi:int=f.skel.find_bone("Head");var t:Transform3D=f._current_global_pose(hi).affine_inverse()*f._current_global_pose(f.racket_hand_idx)*f.racket_node.transform
   var box:AABB=bounds[k];var center:Vector3=box.get_center();var extent:Vector3=box.size*0.5
   var ratio:float=INF
   for point in points:
    var q:Vector3=t*point-center;q=Vector3(q.x/extent.x,q.y/extent.y,q.z/extent.z);ratio=minf(ratio,q.length())
   if ratio<1.0:
    var key:String=mv.sim.pl[k].kind+"/"+mv.sim.pl[k].hit_side;counts[key]=counts.get(key,0)+1
    worst.append({"frame":i,"actor":k,"ratio":ratio,"kind":key,"swing":mv.sim.pl[k].swing,"age":f._full_stroke_age,"prep":f.approach_time})
 worst.sort_custom(func(a,b):return a.ratio<b.ratio)
 print("APPROX_HEAD_COLLISIONS counts=",counts," worst=",worst.slice(0,12))
 if strict:assert(counts.is_empty())
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit()
