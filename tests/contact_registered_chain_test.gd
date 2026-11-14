extends SceneTree
var errors: Array[String] = []
func _initialize():call_deferred("run")
func run():
 for near in [true,false]:
  for side in ["fore","back"]:
   for speed in [0.0,4.0,7.0]:
    for height in [0.5,1.25,1.8]:
     var f=PlayerFig.new(0,true);root.add_child(f)
     var e={"x":0.0,"z":0.0,"near":near,"speed":speed,"vx":speed,"vz":0.0,"swing":0.0,"kind":"drive","want_t":0.0,"prep_t":0.0,"prep_k":0.0,"want":"drive","wait_serve":false,"dive_t":0.0,"getup_t":0.0,"hit_side":side}
     for i in 70:
      e.x += speed/60.0
      e.prep_k=minf(1.0,i/29.0) if i<30 else 0.0
      e.swing=maxf(0.0,0.34-(i-30)/60.0) if i>=30 else 0.0
      if i==30:f.register_contact(Vector3(e.x+(-0.8 if side=="fore" else 0.8),height,0.65 if near else -0.65))
      f.update_from_sim(e,1.0/60)
      for chain in [["UpperArm.R","LowerArm.R","Wrist.R"],["UpperArm.L","LowerArm.L","Wrist.L"],["UpperLeg.R","LowerLeg.R","Foot.R"],["UpperLeg.L","LowerLeg.L","Foot.L"]]:
       for j in 2:
        var a=f.skel.find_bone(f._bone_name(f.skel,chain[j]));var b=f.skel.find_bone(f._bone_name(f.skel,chain[j+1]))
        var got=f._current_global_pose(a).origin.distance_to(f._current_global_pose(b).origin)
        var expected=f._skin_bind[a].origin.distance_to(f._skin_bind[b].origin)
        if absf(got-expected)>0.003: errors.append(str(near," ",side," ",speed," frame=",i," ",chain[j]," delta=",got-expected))
     f.free()
 if errors.is_empty():print("PASS contact chain lengths: 36 registered-contact cases, 70 frames, four limbs")
 else:
  for x in errors.slice(0,10):print("FAIL ",x)
  print("TOTAL ERRORS ",errors.size())
 quit(0 if errors.is_empty() else 1)
