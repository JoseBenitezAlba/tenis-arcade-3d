extends SceneTree
# Pose fixtures, not a mobile performance or touch-input measurement.
func _initialize():call_deferred("run")
func run():
 var checked:int=0;var max_chain_error:float=0.0;var min_axis_dot:float=1.0
 for near in [true,false]:
  for clip in PlayerFig.CELEB_ANIMS:
   var f=PlayerFig.new(0,true);root.add_child(f)
   var e={"x":0.0,"z":0.0,"near":near,"speed":0.0,"vx":0.0,"vz":0.0,"swing":0.0,"kind":"drive","want_t":0.0,"prep_t":0.0,"prep_k":0.0,"want":"drive","wait_serve":false,"dive_t":0.0,"getup_t":0.0,"hit_side":"fore"}
   f.celebrate(clip,2.0)
   for i in 90:
    f.update_from_sim(e,1.0/60)
    var axis:Vector3=(f.skel.global_transform.basis*f._current_global_pose(f.racket_hand_idx).basis*f.grip_basis.y).normalized()
    var expected:Vector3=Vector3(-0.8,-0.7,0.08) if clip in ["Punch_Left","Punch_Right"] else Vector3(0.12,-1.0,0.08)
    var dot:float=axis.dot((f.global_transform.basis*expected).normalized())
    min_axis_dot=minf(min_axis_dot,dot);assert(dot>0.998)
    # The handle's butt remains at the baked fist, no translation or scaling.
    assert((f.racket_node.position+f.racket_node.basis*Vector3(0,0.03,0)).distance_to(f._fist_center_hand)<0.00001)
    for chain in [["UpperArm.R","LowerArm.R","Wrist.R"],["UpperArm.L","LowerArm.L","Wrist.L"],["UpperLeg.R","LowerLeg.R","Foot.R"],["UpperLeg.L","LowerLeg.L","Foot.L"]]:
     for j in 2:
      var a=f.skel.find_bone(f._bone_name(f.skel,chain[j]));var b=f.skel.find_bone(f._bone_name(f.skel,chain[j+1]))
      var error:float=absf(f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)-f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin))
      max_chain_error=maxf(max_chain_error,error);assert(error<0.003)
    checked+=1
   f.free()
 print("PASS celebration grip frames=",checked," min_axis_dot=",min_axis_dot," max_chain_error=",max_chain_error)
 quit()
