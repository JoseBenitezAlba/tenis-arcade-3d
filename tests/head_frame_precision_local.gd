extends SceneTree
# Precision check for head_racket_clearance worst frame (seed 42117, f1055 actor0).
# Pass 1: exact skinned vertex-vertex + point-to-triangle min distance racket<->head, frames 1048-1062.
# Pass 2: close-up captures frames 1053-1057, two angles.
func _initialize():call_deferred("run")

var head_local:PackedVector3Array=[]
var head_tris:Array=[]  # Array of Vector3i indices into head_local
var rk_parts:Array=[]   # {name, verts, tris(Array Vector3i), rel:Transform3D}

func collect_head(f)->void:
 var hi:int=f.skel.find_bone("Head")
 for mi in f.skel.find_children("*","MeshInstance3D",true,false):
  if mi.skin==null:continue
  var map:Array=[]
  for k in mi.skin.get_bind_count():
   var bone:int=mi.skin.get_bind_bone(k)
   if bone<0:bone=f.skel.find_bone(mi.skin.get_bind_name(k))
   map.append(bone)
  for si in mi.mesh.get_surface_count():
   var ar:Array=mi.mesh.surface_get_arrays(si);var vs:PackedVector3Array=ar[Mesh.ARRAY_VERTEX];var bs:PackedInt32Array=ar[Mesh.ARRAY_BONES];var ws:PackedFloat32Array=ar[Mesh.ARRAY_WEIGHTS];var idx:PackedInt32Array=ar[Mesh.ARRAY_INDEX]
   if bs.is_empty():continue
   var n:int=bs.size()/vs.size()
   var remap:Dictionary={}
   for vi in vs.size():
    var head_w:float=0.0
    for k in n:
     if map[bs[vi*n+k]]==hi:head_w+=ws[vi*n+k]
    if head_w>0.99:
     remap[vi]=head_local.size()
     head_local.append(f._skin_bind[hi].affine_inverse()*vs[vi])
   var tri_count:int=(idx.size() if idx.size()>0 else vs.size())/3
   for t in tri_count:
    var i0:int=(idx[t*3] if idx.size()>0 else t*3)
    var i1:int=(idx[t*3+1] if idx.size()>0 else t*3+1)
    var i2:int=(idx[t*3+2] if idx.size()>0 else t*3+2)
    if remap.has(i0) and remap.has(i1) and remap.has(i2):
     head_tris.append(Vector3i(remap[i0],remap[i1],remap[i2]))
 print("HEAD_MESH verts=",head_local.size()," tris=",head_tris.size())

func collect_racket(f)->void:
 var rk:Node3D=f.racket_node
 for mi in rk.find_children("*","MeshInstance3D",true,false):
  var rel:Transform3D=mi.transform
  var node:Node=mi.get_parent()
  while node!=rk:
   rel=node.transform*rel;node=node.get_parent()
  for si in mi.mesh.get_surface_count():
   var ar:Array=mi.mesh.surface_get_arrays(si);var vs:PackedVector3Array=ar[Mesh.ARRAY_VERTEX];var idx:PackedInt32Array=ar[Mesh.ARRAY_INDEX]
   var tris:Array=[]
   var tri_count:int=(idx.size() if idx.size()>0 else vs.size())/3
   for t in tri_count:
    if idx.size()>0:tris.append(Vector3i(idx[t*3],idx[t*3+1],idx[t*3+2]))
    else:tris.append(Vector3i(t*3,t*3+1,t*3+2))
   rk_parts.append({"name":mi.name,"verts":vs,"tris":tris,"rel":rel})
   print("RK_PART ",mi.name," verts=",vs.size()," tris=",tris.size())

static func closest_pt_tri(p:Vector3,a:Vector3,b:Vector3,c:Vector3)->Vector3:
 var ab:Vector3=b-a;var ac:Vector3=c-a;var ap:Vector3=p-a
 var d1:float=ab.dot(ap);var d2:float=ac.dot(ap)
 if d1<=0.0 and d2<=0.0:return a
 var bp:Vector3=p-b;var d3:float=ab.dot(bp);var d4:float=ac.dot(bp)
 if d3>=0.0 and d4<=d3:return b
 var vc:float=d1*d4-d3*d2
 if vc<=0.0 and d1>=0.0 and d3<=0.0:return a+ab*(d1/(d1-d3))
 var cp:Vector3=p-c;var d5:float=ab.dot(cp);var d6:float=ac.dot(cp)
 if d6>=0.0 and d5<=d6:return c
 var vb:float=d5*d2-d1*d6
 if vb<=0.0 and d2>=0.0 and d6<=0.0:return a+ac*(d2/(d2-d6))
 var va:float=d3*d6-d5*d4
 if va<=0.0 and (d4-d3)>=0.0 and (d5-d6)>=0.0:
  var w:float=(d4-d3)/((d4-d3)+(d5-d6));return b+(c-b)*w
 var denom:float=1.0/(va+vb+vc);var v:float=vb*denom;var w2:float=vc*denom
 return a+ab*v+ac*w2

func min_tri_dist(p:Vector3,verts:Array,tris:Array,x:Transform3D)->float:
 var best:float=INF
 for t in tris:
  var q:Vector3=closest_pt_tri(p,x*verts[t.x],x*verts[t.y],x*verts[t.z])
  best=minf(best,p.distance_squared_to(q))
 return sqrt(best)

func frame_min(f,hw:PackedVector3Array)->Array:
 # returns [min_vertex_vertex, min_surface_estimate, part_name, head_local_pt]
 var hi:int=f.skel.find_bone("Head")
 var g_head:Transform3D=f._current_global_pose(hi)
 var g_rk:Transform3D=f._current_global_pose(f.racket_hand_idx)*f.racket_node.transform
 var best:float=INF;var best_part:String="";var best_h:int=-1;var best_rv:Vector3=Vector3.ZERO
 for part in rk_parts:
  var x:Transform3D=g_rk*part.rel
  for v in part.verts:
   var w:Vector3=x*v
   for j in hw.size():
    var d:float=w.distance_squared_to(hw[j])
    if d<best:best=d;best_part=part.name;best_h=j;best_rv=w
 var vv:float=sqrt(best)
 # refine: closest racket vertex -> head triangles; closest head vertex -> racket triangles of best part
 var surf:float=vv
 var d1:float=min_tri_dist(best_rv,head_local,head_tris,g_head)
 surf=minf(surf,d1)
 var hp:Vector3=g_head*head_local[best_h]
 for part in rk_parts:
  var x2:Transform3D=g_rk*part.rel
  var d2:float=min_tri_dist(hp,part.verts,part.tris,x2)
  surf=minf(surf,d2)
 return [vv,surf,best_part,head_local[best_h]]

func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 collect_head(mv.rigs[0]);collect_racket(mv.rigs[0])
 for i in 1063:
  mv._physics_process(1.0/60)
  if i>=1048:
   var f=mv.rigs[0];var hi:int=f.skel.find_bone("Head");var g_head:Transform3D=f._current_global_pose(hi)
   var hw:PackedVector3Array=[]
   for p in head_local:hw.append(g_head*p)
   var r:Array=frame_min(f,hw)
   var pr:Vector3=f._current_global_pose(hi).affine_inverse()*(f._current_global_pose(f.racket_hand_idx)*f.racket_node.transform*Vector3(0,0.6,0))
   print("PRECISE frame=",i," vv=",snapped(r[0],0.0001)," surf=",snapped(r[1],0.0001)," part=",r[2]," head_pt=",r[3])
 mv.queue_free();host.free();await process_frame
 # pass 2: close-up captures
 var host2=load("res://scripts/main.gd").new();host2._register_inputs();seed(42117)
 var mv2=MatchView.new();mv2.set_meta("surface","clay");mv2.setup({"demo":true,"surface":"clay","AIP":host2.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv2);await process_frame;mv2.set_physics_process(false)
 DirAccess.make_dir_recursive_absolute("/tmp/v105-headclose")
 for i in 1058:
  mv2._physics_process(1.0/60)
  if i<1053:continue
  var f=mv2.rigs[0];var hi:int=f.skel.find_bone("Head")
  var hw3:Vector3=(f.skel.global_transform*f._current_global_pose(hi)).origin
  for ai in 2:
   var off:Vector3=(Vector3(0.85,0.12,0.55) if ai==0 else Vector3(-0.75,0.3,-0.6))
   mv2.cam.position=hw3+off;mv2.cam.look_at(hw3);mv2.cam.fov=22;mv2.cam.near=0.05;mv2.cam.far=100.0
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("/tmp/v105-headclose/frame_%04d_%s.png"%[i,"a" if ai==0 else "b"])
 print("CAPTURES done")
 mv2._amb.stop();mv2.queue_free();host2.free();await process_frame;quit()
