extends SceneTree
class Reference extends PlayerFig:
 func _init():super(0,true)
 func _override_branch(bone:int,target:Transform3D,_amount:float=1.0,_persistent:bool=true)->void:
  var old=skel.get_bone_global_pose(bone);var delta=target*old.affine_inverse();var poses={}
  for bi in skel.get_bone_count():
   var ancestor=bi
   while ancestor>=0 and ancestor!=bone:ancestor=skel.get_bone_parent(ancestor)
   if ancestor==bone:poses[bi]=delta*skel.get_bone_global_pose(bi)
  for bi in poses:
   skel.set_bone_global_pose_override(bi,poses[bi],1.0,true);_pose_overrides[bi]=poses[bi]
  skel.force_update_all_bone_transforms()
func _initialize():call_deferred('run')
func run():
 var count=0
 for near in [true,false]:
  for clip in ['drive','slice','drop','lob','toplob','volley','smash','serve','Wave','Punch_Left','Punch_Right','Sword_Slash','HitRecieve','HitRecieve_2']:
   var a=Reference.new();var b=PlayerFig.new(0,true);root.add_child(a);root.add_child(b)
   var e={"x":0.0,"z":0.0,"near":near,"speed":0.0,"vx":0.0,"vz":0.0,"swing":0.0,"kind":"drive","want_t":0.0,"prep_t":0.0,"prep_k":0.0,"want":"drive","wait_serve":false,"dive_t":0.0,"getup_t":0.0,"hit_side":"fore"}
   if clip in PlayerFig.CELEB_ANIMS:a.celebrate(clip,2.0);b.celebrate(clip,2.0)
   for i in 90:
    if not clip in PlayerFig.CELEB_ANIMS:
     e.kind=clip;e.prep_k=minf(1.0,i/29.0) if i<30 else 0.0;e.want_t=.2 if i<30 else 0.0;e.swing=maxf(0,.34-(i-30)/60.0) if i>=30 else 0.0
    a.update_from_sim(e,1.0/60);b.update_from_sim(e,1.0/60)
    var pa=a.capture_visual_pose();var pb=b.capture_visual_pose()
    assert(pa==pb);count+=pa.bones.size()
   a.free();b.free()
 print('PASS exact pose equivalence boneframes=',count,' 14 actions, near/far, 90 frames')
 quit()
