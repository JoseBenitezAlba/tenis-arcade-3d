extends SceneTree
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs();seed(42117)
 var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);await process_frame;mv.set_physics_process(false)
 var low=INF;var high=-INF;var min_points=999999;var samples=0
 for i in 840:
  mv._physics_process(1.0/60)
  for f in mv.rigs:
   if f.tennis_contact_weight<0.99:continue
   var sole=INF
   for bi in f._foot_points:
    var world=f.skel.global_transform*f._current_global_pose(bi)
    min_points=mini(min_points,f._foot_points[bi].size())
    for point in f._foot_points[bi]:sole=minf(sole,(world*point).y)
   low=minf(low,sole);high=maxf(high,sole);samples+=1
 print("SOLE samples=",samples," points_per_foot_min=",min_points," range=",low,"..",high)
 var passed=min_points>=30 and samples>0 and low>=0.003 and high<=0.005
 print("PASS grounded soles" if passed else "FAIL grounded soles")
 mv._amb.stop();mv.queue_free();host.free();await process_frame;quit(0 if passed else 1)
