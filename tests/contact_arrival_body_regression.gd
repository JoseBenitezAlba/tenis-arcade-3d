extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 for test_seed in [42117,8853]:
  seed(test_seed)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
  var previous:Dictionary={};var mx:Dictionary={};var onset_step:float=INF
  var first:int=230 if test_seed==42117 else 350
  var last:int=260 if test_seed==42117 else 380
  for i in last+1:
   mv._physics_process(1.0/60)
   if i<first:continue
   var f=mv.rigs[1]
   for bone in ["Body","UpperLeg_L","UpperArm_R","Head","Foot_L","Foot_R"]:
    var v:Vector3=f.skel.global_transform*f._current_global_pose(f.skel.find_bone(bone)).origin
    if previous.has(bone):
     var step:float=v.distance_to(previous[bone]);mx[bone]=maxf(mx.get(bone,0.0),step)
     if bone=="Body" and i==(243 if test_seed==42117 else 362):onset_step=step
     if bone=="Body":print("BODY seed=",test_seed," frame=",i," step=",step," pos=",v," age=",f._full_stroke_age)
    previous[bone]=v
  print("BODY_SUMMARY seed=",test_seed," max_frame_displacement=",mx)
  assert(onset_step<0.12 and mx.get("Body",1.0)<0.20)
  print("PASS known arrival body onset seed=",test_seed," step_m=",onset_step," (world motion including locomotion, not a general smoothness test)")
  mv._amb.stop();mv.queue_free();await process_frame
 host.free();quit()
