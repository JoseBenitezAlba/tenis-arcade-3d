extends SceneTree
# Compare cached transforms to the original per-frame formulas, including empty seats.
func _initialize():call_deferred("run")
func run():
 if DisplayServer.get_name()=="headless":
  print("SKIP crowd transforms require a rendering backend, not the dummy renderer");quit();return
 var c=CrowdFX.new();root.add_child(c);c.build()
 var checked:int=0
 for frame in 180:
  c.force_ovation=frame>=60 and frame<120;c.sil_t=1.0 if frame>=120 else 0.0
  c.ball_pos=Vector3(sin(frame*.03)*5,1,cos(frame*.03)*11+11)
  c.update([1.0/60,1.0/30,.1,.012][frame%4],float(frame%60)/60)
  if frame%6!=0 or c.vis_acc>0.0:continue
  var ova:bool=c.force_ovation or c.ova_t>0.0
  for i in c.n:
   if c.empty[i]:
    for mm in [c.mm_body,c.mm_head,c.mm_legs,c.mm_cap]:assert(mm.multimesh.get_instance_transform(i).basis.determinant()==0.0)
    continue
   var p:Vector3=c.base_pos[i]+Vector3(0,.13,0)
   var y:float=0.0
   if c.sil_t>0 and not ova:y=-.05
   elif ova:y=absf(sin(c.time*7.5*c.jitters[i]-(p.x+p.z)*.35+c.phases[i]))*.22*(2.0 if c.stand_up[i] else 1.0)
   else:y=sin(c.time*(1.3+4.5*c.exc)*c.jitters[i]+c.phases[i])*(.03+.11*c.exc)
   var body_sy:float=(1.14 if ova and c.stand_up[i] else .9)*c.builds[i].y
   var body:Transform3D=Transform3D(c.face_rot[i].scaled(Vector3(1.18*c.builds[i].x,body_sy,1.05*c.builds[i].x)),p+Vector3(0,y+.42,0))
   var legs:Transform3D=Transform3D(c.face_rot[i].scaled(Vector3(1,.9,.9)),p+Vector3(0,y+.16,0))
   # MultiMesh storage rounds to float32; compare within its precision.
   if not c.mm_body.multimesh.get_instance_transform(i).is_equal_approx(body):
    print("FAIL body frame=",frame," seat=",i," expected=",body," got=",c.mm_body.multimesh.get_instance_transform(i)," delta=",c.mm_body.multimesh.get_instance_transform(i).origin-body.origin);quit(1);return
   assert(c.mm_legs.multimesh.get_instance_transform(i).is_equal_approx(legs))
   checked+=2
 print("PASS crowd cached transforms checked=",checked," states=normal/ovation/silence variable_dt")
 c.free();quit()
