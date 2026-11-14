extends SceneTree
# Reproduces four thirty-second trajectories. Checks the prepared side, not
# ball contact. Seed8853 still has one documented last-instant ambiguity.
func _initialize():call_deferred("run")
func run():
 var host=load("res://scripts/main.gd").new();host._register_inputs()
 var total:int=0;var errors:int=0
 for test_seed in [42117,1234,72,8853]:
  seed(test_seed)
  var mv=MatchView.new();mv.set_meta("surface","clay");mv.setup({"demo":true,"surface":"clay","AIP":host.DIFF_PARAMS[1],"sets_to_win":1});root.add_child(mv);mv.set_physics_process(false);await process_frame;seed(test_seed)
  var previous:Array[float]=[0.0,0.0];var prepared:Array=[{},{}];var samples:int=0;var wrong:int=0
  for i in 1800:
   mv._physics_process(1.0/60)
   for k in 2:
    var f=mv.rigs[k];var e=mv.sim.pl[k]
    if e.swing>previous[k] and not e.kind in ["serve","smash"] and not prepared[k].is_empty():
     samples+=1
     if bool(prepared[k].side)!=(e.hit_side=="back"):
      wrong+=1;print("PREP_WRONG seed=",test_seed," frame=",i," actor=",k," actual=",e.hit_side)
    if e.swing>previous[k]:prepared[k]={}
    elif f.approach_active and f._prep_side_set:prepared[k]={"side":f._prep_side_back}
    previous[k]=e.swing
  print("PREP_SIDE seed=",test_seed," samples=",samples," wrong=",wrong)
  total+=samples;errors+=wrong
  assert(samples>0)
  assert(wrong<=1 if test_seed==8853 else wrong==0)
  mv._amb.stop();mv.queue_free();await process_frame
 host.free();print("PASS preparation regression samples=",total," residual_wrong=",errors," (known ceiling1, not zero)");quit()
